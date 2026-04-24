local ctx = require("ctx")
local funcs = require("funcs")
local cs_client = require("cs_client")
local contracts = require("contracts")
local state_reader = require("state_reader")
local materialize = require("materialize")

local M = {}

local MAX_PATCHES = 50

local ERR = {
    NO_ACTION          = "NO_ACTION",
    INVALID_ACTION     = "INVALID_ACTION",
    NO_CHANGESET       = "NO_CHANGESET",
    NO_BRANCH          = "NO_BRANCH",
    NO_PATCHES         = "NO_PATCHES",
    TOO_MANY_PATCHES   = "TOO_MANY_PATCHES",
    INVALID_PATCH      = "INVALID_PATCH",
    INVALID_TARGET     = "INVALID_TARGET",
    UNSUPPORTED_TARGET = "UNSUPPORTED_TARGET",
    INVALID_OP         = "INVALID_OP",
    PATCH_APPLY_FAILED = "PATCH_APPLY_FAILED",
    PREFLIGHT_FAILED   = "PREFLIGHT_FAILED",
    PUSH_FAILED        = "PUSH_FAILED",
    ABANDON_FAILED     = "ABANDON_FAILED",
}
M.ERR = ERR

-- commit is deliberately absent: agents do not publish. The integrate phase
-- runner (keeper.develop.integrate:run) is the only publisher; submit is a
-- staging-only primitive for authoring + dry-run preview.
local VALID_ACTIONS = { stage = true, abandon = true }
local VALID_OPS     = { create = true, update = true, delete = true }

local err_entry = contracts.err_entry

local function active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return overlay_branch
    end
    return nil
end

local LOOKUP_BY_BRANCH_FN = "keeper.changeset.service:lookup_by_branch"

local function active_changeset()
    local changeset_id, err = ctx.get("changeset_id")
    if not err and changeset_id and changeset_id ~= "" then
        return changeset_id
    end
    local branch = active_branch()
    if not branch or branch == "main" then return nil end
    local executor, exec_err = funcs.new()
    if exec_err then return nil end
    local ok, result = pcall(executor.call, executor, LOOKUP_BY_BRANCH_FN, { branch = branch })
    if not ok or not result or result.ok == false or not result.found then
        return nil
    end
    return result.changeset_id
end

function M.validate_patch(patch, index)
    local patch_id = "patches[" .. tostring(index) .. "]"

    if type(patch) ~= "table" then
        return nil, err_entry(ERR.INVALID_PATCH, "validate", patch_id,
            "patch must be an object",
            "patch shape: {target, op, body?, replace?}")
    end

    if type(patch.target) ~= "table" then
        return nil, err_entry(ERR.INVALID_TARGET, "validate", patch_id,
            "patch.target must be an object {kind, id|path}",
            "entry: {kind='entry', id='ns:name'}; fs: {kind='fs', path='frontend/...'}")
    end

    local target_kind = patch.target.kind
    if target_kind ~= "entry" and target_kind ~= "fs" then
        return nil, err_entry(ERR.UNSUPPORTED_TARGET, "validate", patch_id,
            "target.kind must be 'entry' or 'fs' (got " .. tostring(target_kind) .. ")",
            "use 'entry' for registry entries, 'fs' for frontend files")
    end

    if target_kind == "entry" then
        local id = patch.target.id
        if type(id) ~= "string" or id == "" or not id:find(":", 1, true) then
            return nil, err_entry(ERR.INVALID_TARGET, "validate", patch_id,
                "entry target.id must be 'namespace:name'",
                "example: 'keeper.state.tools:submit'")
        end
    else
        local path = patch.target.path
        if type(path) ~= "string" or path == "" then
            return nil, err_entry(ERR.INVALID_TARGET, "validate", patch_id,
                "fs target.path must be a non-empty relative path",
                "example: 'frontend/applications/keeper/src/app/app.vue'")
        end
    end

    if not VALID_OPS[patch.op] then
        return nil, err_entry(ERR.INVALID_OP, "validate", patch_id,
            "patch.op must be one of create|update|delete (got " .. tostring(patch.op) .. ")",
            "use 'create' for new, 'update' for modify, 'delete' for tombstone/remove")
    end

    if patch.op == "create" and target_kind == "entry" then
        if type(patch.body) ~= "table" or type(patch.body.file_text) ~= "string" or patch.body.file_text == "" then
            return nil, err_entry(ERR.INVALID_PATCH, "validate", patch_id,
                "create entry requires body.file_text with <definition>...</definition>[<source>...</source>]",
                "wrap YAML in <definition>...</definition>; wrap code in <source>...</source>")
        end
    end

    if patch.op == "update" and target_kind == "entry" then
        if not patch.replace or type(patch.replace) ~= "table" or #patch.replace == 0 then
            return nil, err_entry(ERR.INVALID_PATCH, "validate", patch_id,
                "update entry requires replace=[{old,new},...]",
                "each replace: {old='text-to-find', new='replacement'}")
        end
        for i, r in ipairs(patch.replace) do
            if type(r) ~= "table" or type(r.old) ~= "string" or type(r.new) ~= "string" then
                return nil, err_entry(ERR.INVALID_PATCH, "validate", patch_id .. ".replace[" .. i .. "]",
                    "replace item must be {old=string, new=string}",
                    "strings must match exactly (edit tool uses str_replace semantics)")
            end
        end
    end

    if patch.op == "create" and target_kind == "fs" then
        if type(patch.body) ~= "table" or type(patch.body.content) ~= "string" then
            return nil, err_entry(ERR.INVALID_PATCH, "validate", patch_id,
                "create fs requires body.content (string)",
                "encoding defaults to utf8")
        end
    end

    return patch, nil
end

local function apply_entry_patch(caller, patch, patch_id)
    local id = patch.target.id

    if patch.op == "create" then
        local _, err = caller:call("keeper.state.tools:edit", {
            command   = "create",
            path      = id,
            file_text = patch.body.file_text,
        })
        if err then
            return nil, err_entry(ERR.PATCH_APPLY_FAILED, "stage", patch_id,
                "create failed for " .. id .. ": " .. tostring(err),
                "fix the error above and re-submit")
        end
        return { target = id, op = "create", applied = true }, nil
    end

    if patch.op == "delete" then
        local _, err = caller:call("keeper.state.tools:edit", {
            command = "delete",
            path    = id,
        })
        if err then
            return nil, err_entry(ERR.PATCH_APPLY_FAILED, "stage", patch_id,
                "delete failed for " .. id .. ": " .. tostring(err),
                "entry may already be deleted or missing on branch")
        end
        return { target = id, op = "delete", applied = true }, nil
    end

    for i, r in ipairs(patch.replace) do
        local _, err = caller:call("keeper.state.tools:edit", {
            command = "str_replace",
            path    = id,
            old_str = r.old,
            new_str = r.new,
        })
        if err then
            return nil, err_entry(ERR.PATCH_APPLY_FAILED, "stage", patch_id .. ".replace[" .. i .. "]",
                "str_replace failed for " .. id .. ": " .. tostring(err),
                "ensure 'old' appears exactly once; call edit view first if unsure")
        end
    end
    return { target = id, op = "update", applied = true, replacements = #patch.replace }, nil
end

local function apply_fs_patch(caller, patch, patch_id)
    local path = patch.target.path

    if patch.op == "delete" then
        local _, err = caller:call("keeper.components.tools:fs", {
            command = "delete",
            path    = path,
        })
        if err then
            return nil, err_entry(ERR.PATCH_APPLY_FAILED, "stage", patch_id,
                "fs delete failed for " .. path .. ": " .. tostring(err),
                "path must start with frontend/; file must exist on overlay or baseline")
        end
        return { target = path, op = patch.op, applied = true }, nil
    end

    if type(patch.body) ~= "table" or type(patch.body.content) ~= "string" then
        return nil, err_entry(ERR.INVALID_PATCH, "stage", patch_id,
            "fs " .. patch.op .. " requires body.content (string)",
            "provide body={content='...'}")
    end

    local fs_command = patch.op == "create" and "create" or "rewrite"
    local _, err = caller:call("keeper.components.tools:fs", {
        command = fs_command,
        path    = path,
        content = patch.body.content,
    })
    if err then
        return nil, err_entry(ERR.PATCH_APPLY_FAILED, "stage", patch_id,
            "fs " .. patch.op .. " failed for " .. path .. ": " .. tostring(err),
            "path must start with frontend/; content size <= 512KB")
    end
    return { target = path, op = patch.op, applied = true }, nil
end

local function stage_patches(caller, patches)
    local diffs  = {}
    local errors = {}

    for i, patch in ipairs(patches) do
        local patch_id = "patches[" .. i .. "]"
        local diff, err
        if patch.target.kind == "entry" then
            diff, err = apply_entry_patch(caller, patch, patch_id)
        else
            diff, err = apply_fs_patch(caller, patch, patch_id)
        end

        if err then
            table.insert(errors, err)
        else
            table.insert(diffs, diff)
        end
    end

    return diffs, errors
end

local function preflight_entries(branch, diffs)
    local entry_ids = {}
    for _, d in ipairs(diffs) do
        if d.op ~= "delete" and type(d.target) == "string" and d.target:find(":", 1, true) then
            table.insert(entry_ids, d.target)
        end
    end
    if #entry_ids == 0 then
        return {}, nil
    end

    local reader, reader_err = state_reader.for_branch(branch, "main")
    if reader_err then
        return nil, err_entry(ERR.PREFLIGHT_FAILED, "preflight", nil,
            "state_reader init failed: " .. tostring(reader_err),
            "re-submit; if persists, branch overlay may be inconsistent")
    end

    local state_entries, fetch_err = reader:with_entries(unpack(entry_ids)):include_chunks():all()
    if fetch_err then
        return nil, err_entry(ERR.PREFLIGHT_FAILED, "preflight", nil,
            "fetching staged entries failed: " .. tostring(fetch_err),
            "re-submit; the overlay read failed mid-flight")
    end

    local errors = {}
    for _, se in ipairs(state_entries or {}) do
        local reg, merr = materialize.state_entry_to_registry(se)
        if not reg then
            table.insert(errors, err_entry(ERR.PREFLIGHT_FAILED, "preflight", se.id,
                "cannot parse entry from overlay: " .. tostring(merr),
                "re-create the entry; definition YAML is malformed"))
        else
            for _, e in ipairs(contracts.validate_registry(reg)) do
                table.insert(errors, e)
            end
        end
    end
    return errors, nil
end

function M.build_persistence(opts)
    opts = opts or {}
    return {
        overlay_applied    = opts.overlay_applied == true,
        published          = opts.published == true,
        registry_version   = opts.registry_version,
        migrations_applied = opts.migrations_applied or {},
        fs_flushed         = opts.fs_flushed == true,
        rolled_back        = opts.rolled_back == true,
    }
end

-- run executes a submit request end-to-end. Returns (response_table, nil) always; the
-- response's .ok field communicates success or failure. This keeps callers free of
-- pcall ceremony and gives them structured diagnostics in every path.
function M.run(params)
    if type(params) ~= "table" then
        return {
            ok     = false,
            stage  = "validate",
            errors = { err_entry(ERR.INVALID_PATCH, "validate", nil,
                "params must be an object",
                "pass a table; see submit tool input_schema") },
        }
    end

    local action = params.action
    if not action or action == "" then
        return {
            ok     = false,
            stage  = "validate",
            errors = { err_entry(ERR.NO_ACTION, "validate", nil,
                "action is required",
                "use action='stage' (dry-run overlay) or 'abandon'") },
        }
    end

    if not VALID_ACTIONS[action] then
        return {
            ok     = false,
            stage  = "validate",
            errors = { err_entry(ERR.INVALID_ACTION, "validate", nil,
                "action must be stage|abandon (got " .. tostring(action) .. ")",
                "stage applies patches to the overlay; abandon drops the changeset. Publishing is owned by the integrate phase runner — there is no agent-side commit path.") },
        }
    end

    local branch = active_branch()
    if not branch then
        return {
            ok     = false,
            stage  = "validate",
            errors = { err_entry(ERR.NO_BRANCH, "validate", nil,
                "no active branch in context",
                "call set_branch with a feature branch name before submit") },
        }
    end

    local changeset_id = active_changeset()
    if not changeset_id then
        return {
            ok     = false,
            stage  = "validate",
            errors = { err_entry(ERR.NO_CHANGESET, "validate", nil,
                "no active changeset in context",
                "submit requires a changeset context (task cycle or session-owned changeset)") },
        }
    end

    local caller = funcs.new()

    if action == "abandon" then
        local _, err = cs_client.drop({
            changeset_id = changeset_id,
            reason       = params.message or "submit: user-initiated abandon",
        })
        if err then
            return {
                ok     = false,
                stage  = "abandon",
                errors = { err_entry(ERR.ABANDON_FAILED, "abandon", changeset_id,
                    "abandon failed: " .. tostring(err),
                    "ensure changeset exists; manual recovery: call changeset drop API directly") },
            }
        end
        return {
            ok            = true,
            stage         = "abandon",
            submission_id = changeset_id,
            persistence   = M.build_persistence({}),
            message       = "changeset " .. changeset_id .. " abandoned",
        }
    end

    local patches = params.patches or {}
    if type(patches) ~= "table" then
        return {
            ok     = false,
            stage  = "validate",
            errors = { err_entry(ERR.INVALID_PATCH, "validate", nil,
                "patches must be an array (or omitted)",
                "each patch: {target={kind,id|path}, op, body?, replace?}") },
        }
    end

    if action == "stage" and #patches == 0 then
        return {
            ok     = false,
            stage  = "validate",
            errors = { err_entry(ERR.NO_PATCHES, "validate", nil,
                "stage requires at least one patch",
                "action='commit' accepts empty patches (publishes whatever is on overlay)") },
        }
    end

    if #patches > MAX_PATCHES then
        return {
            ok     = false,
            stage  = "validate",
            errors = { err_entry(ERR.TOO_MANY_PATCHES, "validate", nil,
                "patches cap is " .. MAX_PATCHES .. " per submit (got " .. #patches .. ")",
                "split into multiple submit calls") },
        }
    end

    local validated = {}
    local val_errors = {}
    for i, patch in ipairs(patches) do
        local ok_patch, verr = M.validate_patch(patch, i)
        if verr then
            table.insert(val_errors, verr)
        else
            table.insert(validated, ok_patch)
        end
    end
    if #val_errors > 0 then
        return { ok = false, stage = "validate", errors = val_errors }
    end

    local diffs, stage_errors = stage_patches(caller, validated)
    if #stage_errors > 0 then
        return {
            ok          = false,
            stage       = "stage",
            diffs       = diffs,
            errors      = stage_errors,
            persistence = M.build_persistence({ overlay_applied = #diffs > 0 }),
        }
    end

    local dry_run = params.dry_run == true
    local checks = params.checks or {}

    local preflight_disabled = checks.preflight == false
    if not preflight_disabled then
        local preflight_errs, preflight_err = preflight_entries(branch, diffs)
        if preflight_err then
            return {
                ok          = false,
                stage       = "preflight",
                diffs       = diffs,
                errors      = { preflight_err },
                persistence = M.build_persistence({ overlay_applied = true }),
            }
        end
        if preflight_errs and #preflight_errs > 0 then
            return {
                ok          = false,
                stage       = "preflight",
                diffs       = diffs,
                errors      = preflight_errs,
                persistence = M.build_persistence({ overlay_applied = true }),
            }
        end
    end

    -- action=stage is the only staging action. Registry governance + the
    -- per-kind contracts (VALIDATE step above) catch structurally-broken
    -- patches; there is no separate lint gate.
    return {
        ok            = true,
        stage         = action,
        submission_id = changeset_id,
        diffs         = diffs,
        persistence   = M.build_persistence({ overlay_applied = true }),
        errors        = {},
    }
end

return M
