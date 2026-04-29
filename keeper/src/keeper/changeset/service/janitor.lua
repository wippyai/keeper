-- keeper.changeset.service:janitor
--
-- Admin sweep for empty-open changesets. Parses the TTL, enumerates
-- candidates via repo, and dispatches client.drop so the central supervisor
-- serializes the teardown. Returns a report the HTTP handler can hand back
-- verbatim.

local time = require("time")

local client = require("client")
local consts = require("consts")
local repo = require("repo")

local M = {}

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

function M.sweep(params)
    params = params or {}

    local ttl_str = params.ttl
    if not ttl_str or ttl_str == "" then ttl_str = consts.JANITOR.EMPTY_OPEN_TTL end

    local ttl_dur, parse_err = time.parse_duration(ttl_str)
    if parse_err or not ttl_dur then
        return fail(M.ERR.BAD_REQUEST, "invalid ttl: " .. tostring(parse_err or ttl_str))
    end

    local limit = tonumber(params.limit) or consts.JANITOR.BATCH_LIMIT
    local dry_run = params.dry_run == true

    local candidates, list_err = repo.list_empty_open_changesets(ttl_dur:seconds(), limit)
    if list_err then return fail(M.ERR.INTERNAL, list_err) end

    local report = {
        ttl         = ttl_str,
        ttl_seconds = ttl_dur:seconds(),
        limit       = limit,
        candidates  = #candidates,
        dropped     = 0,
        errors      = {},
        entries     = {},
    }

    for _, ws in ipairs(candidates) do
        table.insert(report.entries, {
            changeset_id = ws.changeset_id,
            title        = ws.title,
            updated_at   = ws.updated_at,
            state_branch = ws.state_branch,
        })
        if not dry_run then
            local _, drop_err = client.drop({
                changeset_id = ws.changeset_id,
                reason       = consts.JANITOR.EMPTY_OPEN_REASON,
            })
            if drop_err then
                table.insert(report.errors, {
                    changeset_id = ws.changeset_id,
                    error        = drop_err,
                })
            else
                report.dropped = report.dropped + 1
            end
        end
    end

    return { dry_run = dry_run, report = report }
end

return M
