local fs = require("fs")
local uuid = require("uuid")
local registry = require("registry")
local consts = require("consts")
local repo = require("repo")
local fs_hash = require("fs_hash")

local M = {}

function M.validate_args(args)
    if type(args) ~= "table" then
        return consts.ERRORS.MISSING_REQUIRED .. ": title"
    end
    if not args.title or args.title == "" then
        return consts.ERRORS.MISSING_REQUIRED .. ": title"
    end
    if not args.kind or args.kind == "" then
        return consts.ERRORS.MISSING_REQUIRED .. ": kind"
    end
    return nil
end

function M.resolve_state_branch(changeset_id, explicit)
    local branch = explicit
    if not branch or branch == "" then
        branch = consts.branch_for(changeset_id)
    end
    if branch == consts.MAIN_BRANCH then
        return nil, "state_branch '" .. consts.MAIN_BRANCH .. "' is reserved"
    end
    return branch, nil
end

-- Open a new workspace. Snapshots the baseline (registry version + fe_fs tree hash),
-- allocates a branch name, creates the scratch directory lazily (empty until first
-- write), and inserts the workspace row.
--
-- Args:
--   title            (string, required)
--   kind             (string, required — see consts.KINDS)
--   description      (string, optional)
--   actor_id         (string, optional)
--   session_id       (string, optional)
--   parent_workspace (string, optional — for rejected → reopen forks)
--   changeset_id     (string, optional — caller-supplied UUID for determinism)
--   state_branch     (string, optional — caller-supplied branch name; default: consts.branch_for(changeset_id))
--
-- Returns (workspace, nil) on success, (nil, error) otherwise.
function M.run(args)
    local verr = M.validate_args(args)
    if verr then return nil, verr end

    -- Prevent forking session changesets when an active one exists
    if args.kind == consts.KINDS.SESSION and args.task_id then
        local existing, _ = repo.active_for_task(args.task_id)
        if existing then
            return nil, consts.ERRORS.ACTIVE_SESSION_EXISTS .. 
                " (changeset: " .. existing.changeset_id .. ", task: " .. args.task_id .. ")"
        end
    end

    -- 1. Snapshot registry version
    local current_version, ver_err = registry.current_version()
    if ver_err then
        return nil, "registry.current_version failed: " .. tostring(ver_err)
    end
    local baseline_version = current_version and current_version:id() or "0"

    -- 2. Snapshot fe_fs tree hash (may be empty if ./frontend is fresh).
    -- We also store the full manifest keyed by tree_hash in keeper_fs_manifests
    -- so push rollback can replay the inverse diff without re-walking fe_fs
    -- (which may have drifted between open and rollback).
    local fe_vol, fe_err = fs.get(consts.FS.FE_VOLUME)
    if fe_err then
        return nil, consts.ERRORS.FS_ERROR .. ": fe_fs: " .. tostring(fe_err)
    end
    local fe_snap, fe_snap_err = fs_hash.snapshot(fe_vol, "", {
        skip_dirs = consts.FE_SKIP_DIRS,
    })
    if fe_snap_err then
        return nil, "fe_fs snapshot failed: " .. fe_snap_err
    end
    local baseline_fs_hash = fe_snap.tree_hash

    -- Cache the baseline manifest (INSERT OR REPLACE; multiple workspaces
    -- opened at the same tree hash share the single row).
    local _, manifest_err = repo.store_manifest(
        baseline_fs_hash,
        consts.FS.FE_VOLUME,
        fe_snap.manifest
    )
    if manifest_err then
        return nil, "manifest store failed: " .. manifest_err
    end

    -- 3. Generate workspace id up front so the branch name is deterministic
    local changeset_id = args.changeset_id
    if not changeset_id then
        local id, id_err = uuid.v7()
        if id_err then return nil, "uuid generation failed: " .. tostring(id_err) end
        changeset_id = id
    end

    -- 4. Insert workspace row (starts in OPEN state). The scratch dir is lazy —
    -- fs_view creates it on first write. For now we just record the intended path.
    local scratch_fs_path = changeset_id .. "/"
    local state_branch, branch_err = M.resolve_state_branch(changeset_id, args.state_branch)
    if branch_err then return nil, branch_err end

    local workspace, create_err = repo.create_changeset({
        changeset_id     = changeset_id,
        kind             = args.kind,
        title            = args.title,
        description      = args.description,
        actor_id         = args.actor_id,
        session_id       = args.session_id,
        parent_workspace = args.parent_workspace,
        task_id        = args.task_id,
        state_branch     = state_branch,
        scratch_fs_path  = scratch_fs_path,
        baseline_version = baseline_version,
        baseline_fs_hash = baseline_fs_hash,
    })
    if create_err then return nil, create_err end

    -- 5. Record the opening baseline in the append-only log
    local _, bl_err = repo.record_baseline({
        changeset_id     = changeset_id,
        registry_version = baseline_version,
        fs_tree_hash     = baseline_fs_hash,
        reason           = consts.BASELINE_REASONS.OPEN,
    })
    if bl_err then return nil, "baseline record failed: " .. bl_err end

    return workspace, nil
end

return M
