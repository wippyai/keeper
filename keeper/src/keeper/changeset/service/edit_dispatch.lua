local hash = require("hash")
local consts = require("consts")
local repo = require("repo")
local fs_view = require("fs_view")
local state_ops = require("state_ops")

local M = {}

type ChangesetRow = {
    changeset_id: string,
    state_branch: string,
    state: string?,
}

type LiveState = {
    state: string?,
}

type EntryEdit = {
    id: string,
    kind?: string,
    definition?: string,
    content?: string,
    attributes?: unknown,
}

type EditArgs = {
    changeset_id: string,
    kind: string,
    entry?: EntryEdit,
    entry_id?: string,
    rel_path?: string,
    content?: string,
}

-- Supported edit kinds:
--   registry_set    — writes an entry to the changeset's overlay branch
--   registry_delete — marks an entry deleted in the changeset's overlay branch
--   fs_write        — writes a file to the changeset's scratch FS
--   fs_delete       — marks a file deleted in the changeset

local KINDS = consts.EDIT_KINDS
M.KINDS = KINDS

local VALID_KINDS = {
    [KINDS.REGISTRY_SET]    = true,
    [KINDS.REGISTRY_DELETE] = true,
    [KINDS.FS_WRITE]        = true,
    [KINDS.FS_DELETE]       = true,
}

function M.assert_live(changeset: LiveState?): (boolean?, string?)
    if not changeset then return nil, consts.ERRORS.NOT_FOUND end
    if changeset.state == consts.STATES.MERGED
        or changeset.state == consts.STATES.DROPPED then
        return nil, consts.ERRORS.INVALID_STATE .. ": " .. changeset.state
    end
    return true, nil
end

local function optional_string(value: unknown): string?
    if type(value) == "string" then return value end
    return nil
end

local function normalize_args(args: unknown): (EditArgs?, string?)
    if type(args) ~= "table" then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id"
    end
    local changeset_id = args.changeset_id
    if type(changeset_id) ~= "string" or changeset_id == "" then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id"
    end
    local kind = args.kind
    if type(kind) ~= "string" or kind == "" then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": kind"
    end
    if not VALID_KINDS[kind] then
        return nil, "unknown edit kind: " .. tostring(kind)
    end
    local entry
    if type(args.entry) == "table" then
        local entry_id = args.entry.id
        if type(entry_id) == "string" then
            entry = {
                id = entry_id,
                kind = optional_string(args.entry.kind),
                definition = optional_string(args.entry.definition),
                content = optional_string(args.entry.content),
                attributes = args.entry.attributes,
            }
        end
    end
    return {
        changeset_id = changeset_id,
        kind = kind,
        entry = entry,
        entry_id = optional_string(args.entry_id),
        rel_path = optional_string(args.rel_path),
        content = optional_string(args.content),
    }, nil
end

function M.validate_args(args: unknown): string?
    local _, err = normalize_args(args)
    return err
end

function M.compute_entry_hash(entry: { definition: string?, content: string? }): string?
    local def = tostring(entry.definition or "")
    local content = tostring(entry.content or "")
    local combined = def .. "\n---\n" .. content
    local h, _ = hash.sha256(combined)
    return h
end

local function preserved(branch: string, entry_id: string, chunk_type: string): (string?, string?)
    local txt, err = repo.read_chunk_text(branch, entry_id, chunk_type)
    if err then return nil, err end
    if txt ~= nil then
        if type(txt) ~= "string" then return nil, "chunk content is not a string" end
        return txt, nil
    end
    local fallback, fallback_err = repo.read_chunk_text(consts.MAIN_BRANCH, entry_id, chunk_type)
    if fallback_err then return nil, fallback_err end
    if fallback ~= nil and type(fallback) ~= "string" then return nil, "chunk content is not a string" end
    return fallback, nil
end

local function record_pending(changeset_id: string, category: string, op: string, target: string, current_hash: string?)
    local _, err = repo.upsert_pending_change({
        changeset_id = changeset_id,
        category     = category,
        op           = op,
        target       = target,
        current_hash = current_hash,
    })
    if err then return nil, "journal upsert failed: " .. tostring(err) end
    return true, nil
end

local function run_state_op(changeset: ChangesetRow, command_type: string, payload: {[string]: unknown}, err_prefix: string)
    return repo.transact(function(tx)
        payload.branch = changeset.state_branch
        local result, exec_err = state_ops.execute(tx, {
            { type = command_type, payload = payload },
        })
        if exec_err then return nil, err_prefix .. ": " .. exec_err end
        return result, nil
    end)
end

-- Write a registry entry into the changeset's overlay branch.
-- Args: changeset_id, entry = { id, kind, definition?, content?, attributes? }
-- If a part is nil, the current value (branch > main fallback) is preserved so
-- callers can edit one chunk without wiping the other.
local function run_registry_set(changeset: ChangesetRow, args: EditArgs)
    local entry = args.entry
    if not entry then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": entry.id"
    end

    local kind = entry.kind
    if not kind or kind == "" then
        local existing_kind, kerr = repo.read_entry_kind(changeset.state_branch, entry.id)
        if kerr then return nil, "state_ops.set_entry failed: " .. kerr end
        if not existing_kind then
            existing_kind = select(1, repo.read_entry_kind(consts.MAIN_BRANCH, entry.id))
        end
        kind = existing_kind
    end
    if not kind or kind == "" then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": entry.kind"
    end

    local definition = entry.definition
    if definition == nil then
        local kept, derr = preserved(changeset.state_branch, entry.id, consts.CHUNKS.DEFINITION)
        if derr then return nil, "state_ops.set_entry failed: " .. derr end
        definition = kept
    end
    if not definition or definition == "" then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": entry.definition"
    end

    local content = entry.content
    if content == nil then
        local kept, cerr = preserved(changeset.state_branch, entry.id, consts.CHUNKS.CONTENT)
        if cerr then return nil, "state_ops.set_entry failed: " .. cerr end
        content = kept
    end

    local result, err = run_state_op(changeset, state_ops.COMMAND.SET_ENTRY, {
        id         = entry.id,
        kind       = kind,
        definition = definition,
        content    = content,
        attributes = entry.attributes,
    }, "state_ops.set_entry failed")
    if err then return nil, err end

    local _, jerr = record_pending(
        changeset.changeset_id,
        consts.CATEGORIES.REGISTRY,
        consts.OPS.UPDATE,
        entry.id,
        M.compute_entry_hash({ definition = definition, content = content })
    )
    if jerr then return nil, jerr end

    return { ok = true, entry_id = entry.id, result = result }, nil
end

-- Delete a registry entry in the changeset's overlay branch.
local function run_registry_delete(changeset: ChangesetRow, args: EditArgs)
    local entry_id = args.entry_id
    if not entry_id then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": entry_id"
    end

    local result, err = run_state_op(changeset, state_ops.COMMAND.DELETE_ENTRY, {
        id = entry_id,
    }, "state_ops.delete_entry failed")
    if err then return nil, err end

    local _, jerr = record_pending(
        changeset.changeset_id,
        consts.CATEGORIES.REGISTRY,
        consts.OPS.DELETE,
        entry_id,
        nil
    )
    if jerr then return nil, jerr end

    return { ok = true, entry_id = entry_id, result = result }, nil
end

-- Write a file to the changeset scratch FS.
local function run_fs_write(changeset: ChangesetRow, args: EditArgs)
    local rel_path = args.rel_path
    local content = args.content
    if not rel_path then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": rel_path"
    end
    if not content then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": content (string)"
    end

    local view, view_err = fs_view.open(changeset.changeset_id)
    if view_err then return nil, view_err end

    local h, werr = view:write(rel_path, content)
    if werr then return nil, werr end

    local _, jerr = record_pending(
        changeset.changeset_id,
        consts.CATEGORIES.FILESYSTEM,
        consts.OPS.UPDATE,
        rel_path,
        h
    )
    if jerr then return nil, jerr end

    return { ok = true, rel_path = rel_path, current_hash = h }, nil
end

-- Mark a file deleted in the changeset.
local function run_fs_delete(changeset: ChangesetRow, args: EditArgs)
    local rel_path = args.rel_path
    if not rel_path then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": rel_path"
    end

    local view, view_err = fs_view.open(changeset.changeset_id)
    if view_err then return nil, view_err end

    local _, derr = view:delete(rel_path)
    if derr then return nil, derr end

    local _, jerr = record_pending(
        changeset.changeset_id,
        consts.CATEGORIES.FILESYSTEM,
        consts.OPS.DELETE,
        rel_path,
        nil
    )
    if jerr then return nil, jerr end

    return { ok = true, rel_path = rel_path }, nil
end

-- Public entry point called by the central supervisor.
-- Args: { changeset_id, kind, ... kind-specific fields }
function M.run(raw_args: unknown)
    local args, verr = normalize_args(raw_args)
    if verr then return nil, verr end
    if not args then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local changeset, err = repo.get_changeset(args.changeset_id)
    if err then return nil, err end
    if not changeset then return nil, consts.ERRORS.NOT_FOUND end
    if type(changeset.changeset_id) ~= "string" or type(changeset.state_branch) ~= "string" then
        return nil, "changeset row is missing branch metadata"
    end
    local row: ChangesetRow = {
        changeset_id = changeset.changeset_id,
        state_branch = changeset.state_branch,
        state = type(changeset.state) == "string" and changeset.state or nil,
    }
    local _, live_err = M.assert_live(row)
    if live_err then return nil, live_err end

    if args.kind == KINDS.REGISTRY_SET then
        return run_registry_set(row, args)
    elseif args.kind == KINDS.REGISTRY_DELETE then
        return run_registry_delete(row, args)
    elseif args.kind == KINDS.FS_WRITE then
        return run_fs_write(row, args)
    elseif args.kind == KINDS.FS_DELETE then
        return run_fs_delete(row, args)
    end
end

return M
