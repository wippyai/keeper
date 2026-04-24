local consts = require("consts")
local repo   = require("repo")

local M = {}

local VALID_CATEGORIES = {
    [consts.CATEGORIES.REGISTRY]   = true,
    [consts.CATEGORIES.FILESYSTEM] = true,
}

local VALID_OPS = {
    [consts.OPS.CREATE] = true,
    [consts.OPS.UPDATE] = true,
    [consts.OPS.DELETE] = true,
}

local VALID_STATUSES = {
    [consts.CHANGE_STATUSES.PENDING]    = true,
    [consts.CHANGE_STATUSES.APPLIED]    = true,
    [consts.CHANGE_STATUSES.SUPERSEDED] = true,
    [consts.CHANGE_STATUSES.REJECTED]   = true,
}

local APPLIED_SOURCES = {
    [consts.SOURCES.PUSHED]     = true,
    [consts.SOURCES.FS_FLUSHED] = true,
}

function M.validate_rows(rows)
    if type(rows) ~= "table" then
        return "rows must be an array"
    end
    for i, row in ipairs(rows) do
        local where = "rows[" .. tostring(i) .. "]"
        if type(row) ~= "table" then
            return where .. " must be a table"
        end
        if not VALID_CATEGORIES[row.category] then
            return where .. ".category invalid: " .. tostring(row.category)
        end
        if not VALID_OPS[row.op] then
            return where .. ".op invalid: " .. tostring(row.op)
        end
        if not row.target or row.target == "" then
            return where .. ".target is required"
        end
        if not row.source or row.source == "" then
            return where .. ".source is required"
        end
        if not VALID_STATUSES[row.status] then
            return where .. ".status invalid: " .. tostring(row.status)
        end
    end
    return nil
end

function M.is_applied_push(row)
    return row.changeset_id
        and row.status == consts.CHANGE_STATUSES.APPLIED
        and APPLIED_SOURCES[row.source] ~= nil
        and true
        or false
end

-- Batch writer for keeper_changeset_changes. Sole path for journal INSERTs —
-- replaces three raw-SQL bypassers (sys_cs.record_diff + push.lua:record_*).
-- Each row must carry category, op, target, source, status.
-- changeset_id is optional (orphan rows get NULL).
-- Optional head_version updates keeper_changesets.head_version in the same call
-- when a changeset_id is attached.
-- Close-out policy: when rows carry an APPLIED status with a PUSHED/FS_FLUSHED
-- source (the push commit path), existing PENDING rows for (changeset_id,
-- category, target) are upgraded in place instead of duplicated. Any PENDING
-- rows left over for the changeset after the batch are marked SUPERSEDED so
-- net-zero edits leave a closed trail instead of lingering PENDING.
local function handler(args)
    args = args or {}
    local rows = args.rows or {}
    local verr = M.validate_rows(rows)
    if verr then
        return { ok = false, error = verr }
    end

    local written  = 0
    local upgraded = 0
    local ids      = {}
    local applied_changeset_ids = {}

    for _, row in ipairs(rows) do
        local upgraded_here = false
        if M.is_applied_push(row) then
            local ok, uerr = repo.apply_pending_change(
                row.changeset_id, row.category, row.target, row.op, row.current_hash)
            if uerr then
                return { ok = false, error = "apply_pending failed: " .. tostring(uerr), written = written }
            end
            if ok then
                upgraded_here = true
                upgraded = upgraded + 1
                applied_changeset_ids[row.changeset_id] = true
            end
        end

        if not upgraded_here then
            local id, err = repo.record_change({
                changeset_id  = row.changeset_id,
                category      = row.category,
                op            = row.op,
                target        = row.target,
                baseline_hash = row.baseline_hash,
                current_hash  = row.current_hash,
                source        = row.source,
                status        = row.status,
                conflict_with = row.conflict_with,
                detected_at   = row.detected_at,
            })
            if err then
                return { ok = false, error = "row " .. tostring(written + 1) .. ": " .. tostring(err), written = written }
            end
            written = written + 1
            table.insert(ids, id)
            if M.is_applied_push(row) then
                applied_changeset_ids[row.changeset_id] = true
            end
        end
    end

    for cs_id in pairs(applied_changeset_ids) do
        local _, cerr = repo.close_pending_changes(cs_id, consts.CHANGE_STATUSES.SUPERSEDED)
        if cerr then
            return { ok = false, error = "close_pending failed: " .. tostring(cerr), written = written, upgraded = upgraded }
        end
    end

    if args.head_version and args.head_changeset_id then
        local _, herr = repo.set_head(args.head_changeset_id, args.head_version, args.head_fs_hash)
        if herr then
            return { ok = false, error = "head update failed: " .. tostring(herr), written = written, upgraded = upgraded, change_ids = ids }
        end
    end

    return { ok = true, written = written, upgraded = upgraded, change_ids = ids }
end

M.handler = handler
return M
