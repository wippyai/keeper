local funcs = require("funcs")
local consts = require("consts")
local gov_consts = require("gov_consts")

local M = {}

local RECORD_FN = "keeper.changeset.service:record_changes"

local CATEGORIES = consts.CATEGORIES
local OPS        = consts.OPS
local SOURCES    = consts.SOURCES
local STATUSES   = consts.CHANGE_STATUSES
local REGISTRY_OPS = gov_consts.REGISTRY_OPERATIONS

type JournalOp = {
    category: string,
    op: string,
    target: string,
    baseline_hash: string?,
    current_hash: string?,
}

local OP_BY_KIND = {
    [REGISTRY_OPS.CREATE] = OPS.CREATE,
    [REGISTRY_OPS.UPDATE] = OPS.UPDATE,
    [REGISTRY_OPS.DELETE] = OPS.DELETE,
}

local function err(message: string)
    return { code = "JOURNAL_FAILED", message = message }
end

local function record(rows: {JournalOp})
    if #rows == 0 then
        return { ok = true, rows_written = 0, errors = {} }, nil
    end
    local executor, fn_err = funcs.new()
    if fn_err then
        return { ok = false, rows_written = 0, errors = { err("funcs.new failed: " .. tostring(fn_err)) } }, nil
    end
    local result, call_err = executor:call(RECORD_FN, { rows = rows })
    if call_err then
        return { ok = false, rows_written = 0, errors = { err("record_changes call failed: " .. tostring(call_err)) } }, nil
    end
    if not result or result.ok == false then
        return {
            ok = false,
            rows_written = (result and result.written) or 0,
            errors = { err((result and result.error) or "record_changes returned empty") },
        }, nil
    end
    return { ok = true, rows_written = result.written or #rows, errors = {} }, nil
end

local function registry_ops_from_changeset(changeset: unknown): {JournalOp}
    local ops: {JournalOp} = {}
    if type(changeset) ~= "table" then return ops end
    for _, op in ipairs(changeset) do
        local target
        if type(op.entry) == "table" and type(op.entry.id) == "string" then target = op.entry.id
        elseif type(op.entry_id) == "string" then target = op.entry_id end
        local mapped = OP_BY_KIND[op.kind]
        if target and mapped then
            table.insert(ops, { category = CATEGORIES.REGISTRY, op = mapped, target = target })
        end
    end
    return ops
end

local function rows_from(source: string, ops: {JournalOp}): {JournalOp}
    local rows: {JournalOp} = {}
    for _, op in ipairs(ops) do
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
    return rows
end

function M.record_upload_diff(result: unknown)
    if type(result) ~= "table" then
        return { ok = true, rows_written = 0, errors = {} }, nil
    end
    return record(rows_from(SOURCES.SYNCED_FROM_FS, registry_ops_from_changeset(result.changeset)))
end

function M.record_download_diff(result: unknown)
    if type(result) ~= "table" or type(result.file_ops) ~= "table" then
        return { ok = true, rows_written = 0, errors = {} }, nil
    end
    local ops: {JournalOp} = {}
    for _, fo in ipairs(result.file_ops) do
        if type(fo.path) == "string" and type(fo.op) == "string" then
            table.insert(ops, { category = CATEGORIES.FILESYSTEM, op = fo.op, target = fo.path })
        end
    end
    return record(rows_from(SOURCES.SYNCED_TO_FS, ops))
end

function M.record_version_revert(changeset: unknown)
    return record(rows_from(SOURCES.VERSION_REVERT, registry_ops_from_changeset(changeset)))
end

return M
