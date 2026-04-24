-- keeper.changeset.service:reader
--
-- Read-side facade for changeset HTTP handlers. Owns input validation, DTO
-- sanitization, and composition of diff.compute + repo reads so handlers
-- stay thin adapters.

local consts = require("consts")
local diff = require("diff")
local repo = require("repo")

local M = {}

local TERMINAL_STATES = {
    [consts.STATES.MERGED]   = true,
    [consts.STATES.DROPPED]  = true,
    [consts.STATES.REJECTED] = true,
}

local DISPLAY_JOURNAL_STATUSES = {
    [consts.CHANGE_STATUSES.APPLIED]  = true,
    [consts.CHANGE_STATUSES.PENDING]  = true,
    [consts.CHANGE_STATUSES.REJECTED] = true,
}

M.ERR = {
    BAD_REQUEST  = "bad_request",
    NOT_FOUND    = "not_found",
    FORBIDDEN    = "forbidden",
    UNAUTHORIZED = "unauthorized",
    CONFLICT     = "conflict",
    INTERNAL     = "internal",
}

local function fail(code, message, extra)
    local err = { code = code, message = message }
    if extra then
        for k, v in pairs(extra) do err[k] = v end
    end
    return nil, err
end

local function sanitize(ws)
    if not ws then return nil end
    return {
        changeset_id     = ws.changeset_id,
        kind             = ws.kind,
        title            = ws.title,
        description      = ws.description,
        actor_id         = ws.actor_id,
        session_id       = ws.session_id,
        parent_changeset = ws.parent_workspace,
        task_id          = ws.task_id,
        state            = ws.state,
        state_reason     = ws.state_reason,
        created_at       = ws.created_at,
        updated_at       = ws.updated_at,
        closed_at        = ws.closed_at,
    }
end

M.sanitize = sanitize

M.DEFAULT_LIST_LIMIT = 100
M.MAX_LIST_LIMIT     = 500

function M.clamp_limit(n)
    local v = tonumber(n) or M.DEFAULT_LIST_LIMIT
    if v > M.MAX_LIST_LIMIT then v = M.MAX_LIST_LIMIT end
    return v
end

function M.validate_changeset_id(id)
    if not id or id == "" then
        return { code = M.ERR.BAD_REQUEST, message = "workspace id is required" }
    end
    return nil
end

function M.list(filters)
    filters = filters or {}
    local limit = M.clamp_limit(filters.limit)

    local rows, err = repo.list_changesets({
        state      = filters.state,
        kind       = filters.kind,
        actor_id   = filters.actor_id,
        session_id = filters.session_id,
        limit      = limit,
    })
    if err then return fail(M.ERR.INTERNAL, "Failed to load workspaces") end

    local out = {}
    for _, row in ipairs(rows or {}) do
        table.insert(out, sanitize(row))
    end
    return out
end

function M.get(changeset_id)
    local verr = M.validate_changeset_id(changeset_id)
    if verr then return nil, verr end
    local ws, err = repo.get_changeset(changeset_id)
    if err or not ws then return fail(M.ERR.NOT_FOUND, "Changeset not found") end
    return sanitize(ws)
end

function M.project_journal(journal)
    local registry, filesystem = {}, {}
    for _, row in ipairs(journal or {}) do
        if DISPLAY_JOURNAL_STATUSES[row.status] then
            local change = {
                category      = row.category,
                op            = row.op,
                target        = row.target,
                baseline_hash = row.baseline_hash,
                current_hash  = row.current_hash,
            }
            if row.category == consts.CATEGORIES.REGISTRY then
                table.insert(registry, change)
            elseif row.category == consts.CATEGORIES.FILESYSTEM then
                table.insert(filesystem, change)
            end
        end
    end
    return { registry = registry, filesystem = filesystem }
end

function M.list_changes(changeset_id)
    local verr = M.validate_changeset_id(changeset_id)
    if verr then return nil, verr end

    local cs, cserr = repo.get_changeset(changeset_id)
    if cserr or not cs then return fail(M.ERR.NOT_FOUND, "Changeset not found") end

    local journal, jerr = repo.list_changes_for_changeset(changeset_id, {})
    if jerr then return fail(M.ERR.INTERNAL, jerr) end

    local computed
    if TERMINAL_STATES[cs.state] then
        computed = M.project_journal(journal)
    else
        local c, derr = diff.compute(changeset_id)
        if derr then return fail(M.ERR.INTERNAL, derr) end
        computed = c
    end

    return { computed = computed, journal = journal }
end

return M
