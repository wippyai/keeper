local funcs = require("funcs")
local cs_client = require("cs_client")
local cs_consts = require("cs_consts")
local gov_consts = require("gov_consts")

local M = {}

local PUSH_FN = "keeper.state.tools:push"
local RECORD_CHANGES_FN = "keeper.changeset.service:record_changes"
local MAX_EDITS = 200

local CATEGORIES = cs_consts.CATEGORIES
local OPS = cs_consts.OPS
local SOURCES = cs_consts.SOURCES
local STATUSES = cs_consts.CHANGE_STATUSES
local REGISTRY_OPS = gov_consts.REGISTRY_OPERATIONS

local OP_BY_KIND = {
    [REGISTRY_OPS.CREATE] = OPS.CREATE,
    [REGISTRY_OPS.UPDATE] = OPS.UPDATE,
    [REGISTRY_OPS.DELETE] = OPS.DELETE,
}

local EDIT_KINDS = cs_consts.EDIT_KINDS

local EDIT_OPS = {
    [EDIT_KINDS.REGISTRY_SET]    = EDIT_KINDS.REGISTRY_SET,
    [EDIT_KINDS.REGISTRY_DELETE] = EDIT_KINDS.REGISTRY_DELETE,
    [EDIT_KINDS.FS_WRITE]        = EDIT_KINDS.FS_WRITE,
    [EDIT_KINDS.FS_DELETE]       = EDIT_KINDS.FS_DELETE,
}
M.EDIT_OPS = EDIT_OPS

local ERR = {
    NO_EDITS         = "NO_EDITS",
    TOO_MANY_EDITS   = "TOO_MANY_EDITS",
    INVALID_EDIT     = "INVALID_EDIT",
    INVALID_EDIT_OP  = "INVALID_EDIT_OP",
    CREATE_FAILED    = "CREATE_FAILED",
    EDIT_FAILED      = "EDIT_FAILED",
    PUSH_FAILED      = "PUSH_FAILED",
    MISSING_FIELD    = "MISSING_FIELD",
    DIFF_FAILED      = "DIFF_FAILED",
    INVALID_SOURCE   = "INVALID_SOURCE",
    INVALID_OP       = "INVALID_OP",
}
M.ERR = ERR

local VALID_SOURCES = {
    [SOURCES.DETECTED_DRIFT] = true,
    [SOURCES.MATERIALIZED]   = true,
    [SOURCES.PUSHED]         = true,
    [SOURCES.REJECTED]       = true,
    [SOURCES.SYNCED_FROM_FS] = true,
    [SOURCES.SYNCED_TO_FS]   = true,
    [SOURCES.FS_FLUSHED]     = true,
    [SOURCES.VERSION_REVERT] = true,
}

local VALID_CATEGORIES = {
    [CATEGORIES.REGISTRY]   = true,
    [CATEGORIES.FILESYSTEM] = true,
}

local VALID_OPS = {
    [OPS.CREATE] = true,
    [OPS.UPDATE] = true,
    [OPS.DELETE] = true,
}

local function err(code, message, context)
    return { code = code, message = tostring(message or ""), context = context }
end

local function stage_fail(stage, code, message, context, extra)
    local resp = { ok = false, stage = stage, errors = { err(code, message, context) } }
    if extra then
        for k, v in pairs(extra) do resp[k] = v end
    end
    return resp, nil
end

local function rows_fail(code, message, context)
    return {
        ok = false,
        rows_written = 0,
        errors = { err(code, message, context) },
    }, nil
end

local function validate_edit(edit, index)
    local where = "edits[" .. tostring(index) .. "]"

    if type(edit) ~= "table" then
        return err(ERR.INVALID_EDIT, where .. " must be a table")
    end

    local op = edit.op
    if not op or not EDIT_OPS[op] then
        return err(ERR.INVALID_EDIT_OP,
            where .. ".op must be one of registry_set|registry_delete|fs_write|fs_delete (got " ..
            tostring(op) .. ")")
    end

    if op == EDIT_KINDS.REGISTRY_SET then
        local entry = edit.entry
        if type(entry) ~= "table" or not entry.id or not entry.kind or type(entry.definition) ~= "string" then
            return err(ERR.MISSING_FIELD,
                where .. " registry_set requires entry={id, kind, definition, content?, attributes?}")
        end
    elseif op == EDIT_KINDS.REGISTRY_DELETE then
        if not edit.entry_id or edit.entry_id == "" then
            return err(ERR.MISSING_FIELD, where .. " registry_delete requires entry_id")
        end
    elseif op == EDIT_KINDS.FS_WRITE then
        if not edit.rel_path or edit.rel_path == "" then
            return err(ERR.MISSING_FIELD, where .. " fs_write requires rel_path")
        end
        if type(edit.content) ~= "string" then
            return err(ERR.MISSING_FIELD, where .. " fs_write requires content (string)")
        end
    elseif op == EDIT_KINDS.FS_DELETE then
        if not edit.rel_path or edit.rel_path == "" then
            return err(ERR.MISSING_FIELD, where .. " fs_delete requires rel_path")
        end
    end

    return nil
end

local function build_edit_args(changeset_id, edit)
    local kind = EDIT_OPS[edit.op]
    local args = { changeset_id = changeset_id, kind = kind }

    if edit.op == EDIT_KINDS.REGISTRY_SET then
        args.entry = edit.entry
    elseif edit.op == EDIT_KINDS.REGISTRY_DELETE then
        args.entry_id = edit.entry_id
    else
        args.rel_path = edit.rel_path
        if edit.content ~= nil then args.content = edit.content end
    end

    return args
end

local function push_changeset(state_branch, message)
    local caller, fn_err = funcs.new()
    if fn_err then
        return nil, "funcs.new failed: " .. tostring(fn_err)
    end

    local result, call_err = caller:call(PUSH_FN, {
        branch  = state_branch,
        message = message,
    })
    if call_err then
        return nil, tostring(call_err)
    end
    return result, nil
end

-- Runs a system-originated changeset end-to-end.
--
-- Args:
--   kind         (string, required — see keeper.changeset.consts.KINDS, e.g. "manual", "import")
--   title        (string, required)
--   edits        (array, required — each { op, entry|entry_id|rel_path|content })
--   actor_id     (string, optional — falls back to caller's security actor)
--   session_id   (string, optional)
--   description  (string, optional)
--   message      (string, optional — push message)
--   push         (boolean, default true — set false to leave changeset staged)
--   cs_timeout   (string, default "10s")
--
-- Returns:
--   response table ({ ok, stage, changeset_id, state_branch, edits_applied,
--                     push = {...} or nil, errors = {...} }), nil
function M.run(args)
    if type(args) ~= "table" then
        return stage_fail("validate", ERR.INVALID_EDIT, "args must be a table")
    end
    if not args.kind or args.kind == "" then
        return stage_fail("validate", ERR.MISSING_FIELD, "kind is required")
    end
    if not args.title or args.title == "" then
        return stage_fail("validate", ERR.MISSING_FIELD, "title is required")
    end

    local edits = args.edits or {}
    if type(edits) ~= "table" or #edits == 0 then
        return stage_fail("validate", ERR.NO_EDITS, "edits must be a non-empty array")
    end
    if #edits > MAX_EDITS then
        return stage_fail("validate", ERR.TOO_MANY_EDITS,
            "edits cap is " .. MAX_EDITS .. " per call (got " .. #edits .. ")")
    end

    local validation_errors = {}
    for i, edit in ipairs(edits) do
        local ve = validate_edit(edit, i)
        if ve then table.insert(validation_errors, ve) end
    end
    if #validation_errors > 0 then
        return { ok = false, stage = "validate", errors = validation_errors }, nil
    end

    local cs_timeout = args.cs_timeout or "10s"

    -- Prefer open_or_resume when the caller supplies a state_branch so repeat
    -- system-runs do not leak duplicate workspaces on the same branch. Callers
    -- that omit state_branch still get a freshly allocated branch via create.
    local changeset, create_err
    if args.state_branch and args.state_branch ~= "" then
        changeset, create_err = cs_client.open_or_resume({
            state_branch = args.state_branch,
            title        = args.title,
            kind         = args.kind,
            description  = args.description,
            actor_id     = args.actor_id,
            session_id   = args.session_id,
        }, cs_timeout)
    else
        changeset, create_err = cs_client.create({
            title       = args.title,
            kind        = args.kind,
            description = args.description,
            actor_id    = args.actor_id,
            session_id  = args.session_id,
        }, cs_timeout)
    end
    if not changeset then
        return stage_fail("create", ERR.CREATE_FAILED, create_err or "changeset create failed")
    end

    local changeset_id = changeset.changeset_id
    local state_branch = changeset.state_branch

    local applied = 0
    for i, edit in ipairs(edits) do
        local _, edit_err = cs_client.edit(build_edit_args(changeset_id, edit), cs_timeout)
        if edit_err then
            return stage_fail("edit", ERR.EDIT_FAILED,
                "edits[" .. i .. "] failed: " .. tostring(edit_err),
                { op = edit.op, index = i },
                {
                    changeset_id  = changeset_id,
                    state_branch  = state_branch,
                    edits_applied = applied,
                })
        end
        applied = applied + 1
    end

    local do_push = args.push ~= false
    if not do_push then
        return {
            ok            = true,
            stage         = "edit",
            changeset_id  = changeset_id,
            state_branch  = state_branch,
            edits_applied = applied,
            errors        = {},
        }, nil
    end

    local push_result, push_err = push_changeset(state_branch,
        args.message or ("System changeset: " .. args.title))
    if push_err then
        return stage_fail("push", ERR.PUSH_FAILED, push_err, nil, {
            changeset_id  = changeset_id,
            state_branch  = state_branch,
            edits_applied = applied,
        })
    end

    return {
        ok            = true,
        stage         = "push",
        changeset_id  = changeset_id,
        state_branch  = state_branch,
        edits_applied = applied,
        push          = push_result,
        errors        = {},
    }, nil
end

-- Records a journal-only diff for system bypass paths (sync_from_fs, sync_to_fs).
-- Delegates to keeper.changeset.service:record_changes with changeset_id=NULL so
-- the rows stand alone (orphan system-journal entries).
--
-- Args:
--   source    (string, required) — one of cs_consts.SOURCES.*
--   ops       (array, required) — each:
--                { category = "registry"|"filesystem",
--                  op       = "create"|"update"|"delete",
--                  target   = "<entry_id or rel_path>",
--                  baseline_hash = "..." (optional),
--                  current_hash  = "..." (optional) }
--
-- Returns:
--   { ok = true|false, rows_written, errors = {...} }, nil
function M.record_diff(args)
    if type(args) ~= "table" then
        return rows_fail(ERR.INVALID_EDIT, "args must be a table")
    end

    local source = args.source
    if not source or not VALID_SOURCES[source] then
        return rows_fail(ERR.INVALID_SOURCE,
            "source must be one of cs_consts.SOURCES.* (got " .. tostring(source) .. ")")
    end

    local ops = args.ops or {}
    if type(ops) ~= "table" then
        return rows_fail(ERR.INVALID_EDIT, "ops must be an array")
    end

    if #ops == 0 then
        return { ok = true, rows_written = 0, errors = {} }, nil
    end

    local rows = {}
    for i, op in ipairs(ops) do
        local where = "ops[" .. tostring(i) .. "]"
        if type(op) ~= "table" then
            return rows_fail(ERR.INVALID_EDIT, where .. " must be a table")
        end
        if not op.category or not VALID_CATEGORIES[op.category] then
            return rows_fail(ERR.INVALID_EDIT,
                where .. ".category must be registry|filesystem (got " .. tostring(op.category) .. ")")
        end
        if not op.op or not VALID_OPS[op.op] then
            return rows_fail(ERR.INVALID_OP,
                where .. ".op must be create|update|delete (got " .. tostring(op.op) .. ")")
        end
        if not op.target or op.target == "" then
            return rows_fail(ERR.MISSING_FIELD, where .. ".target is required")
        end
        table.insert(rows, {
            changeset_id  = nil,
            category      = op.category,
            op            = op.op,
            target        = op.target,
            baseline_hash = op.baseline_hash,
            current_hash  = op.current_hash,
            source        = source,
            status        = STATUSES.APPLIED,
        })
    end

    local executor, fn_err = funcs.new()
    if fn_err then
        return rows_fail(ERR.DIFF_FAILED, "funcs.new failed: " .. tostring(fn_err))
    end

    local result, call_err = executor:call(RECORD_CHANGES_FN, { rows = rows })
    if call_err then
        return rows_fail(ERR.DIFF_FAILED, "record_changes call failed: " .. tostring(call_err))
    end
    if not result or result.ok == false then
        return {
            ok = false,
            rows_written = (result and result.written) or 0,
            errors = { err(ERR.DIFF_FAILED, (result and result.error) or "record_changes returned empty") },
        }, nil
    end

    return { ok = true, rows_written = result.written or #rows, errors = {} }, nil
end

-- Convert a registry changeset (from gov_client.request_upload or
-- registry.build_delta) into journal ops. Skips rows without a resolvable
-- target id or with an unmapped kind.
local function registry_ops_from_changeset(changeset)
    local ops = {}
    if type(changeset) ~= "table" then return ops end
    for _, op in ipairs(changeset) do
        local target
        if type(op.entry) == "table" and op.entry.id then
            target = op.entry.id
        elseif op.entry_id then
            target = op.entry_id
        end
        local mapped = OP_BY_KIND[op.kind]
        if target and mapped then
            table.insert(ops, {
                category = CATEGORIES.REGISTRY,
                op       = mapped,
                target   = target,
            })
        end
    end
    return ops
end

-- Journal a gov_client.request_upload result (sync_from_fs path).
-- Accepts the full result table; extracts result.changeset and converts
-- each op into a category=registry, source=synced_from_fs journal row.
function M.record_upload_diff(result)
    if type(result) ~= "table" then
        return { ok = true, rows_written = 0, errors = {} }, nil
    end
    return M.record_diff({
        source = SOURCES.SYNCED_FROM_FS,
        ops    = registry_ops_from_changeset(result.changeset),
    })
end

-- Journal a gov_client.request_download result (sync_to_fs path).
-- Accepts the full result table; extracts result.file_ops and converts
-- each path into a category=filesystem, source=synced_to_fs journal row.
function M.record_download_diff(result)
    if type(result) ~= "table" or type(result.file_ops) ~= "table" then
        return { ok = true, rows_written = 0, errors = {} }, nil
    end
    local ops = {}
    for _, fo in ipairs(result.file_ops) do
        if fo.path and fo.op then
            table.insert(ops, {
                category = CATEGORIES.FILESYSTEM,
                op       = fo.op,
                target   = fo.path,
            })
        end
    end
    return M.record_diff({ source = SOURCES.SYNCED_TO_FS, ops = ops })
end

-- Journal a registry.build_delta changeset produced by a version-revert
-- (undo/redo). Converts each entry op (entry.create|update|delete) into a
-- category=registry, source=version_revert journal row.
function M.record_version_revert(changeset)
    return M.record_diff({
        source = SOURCES.VERSION_REVERT,
        ops    = registry_ops_from_changeset(changeset),
    })
end

return M
