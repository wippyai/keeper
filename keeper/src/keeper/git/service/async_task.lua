-- Helper for the spawn → relay-started → relay-finished/failed → reply pattern
-- used by every async LLM-backed handler (rebuild AI, suggest_split AI, explain).
--
--   async_task.run({
--     request_id = "...",
--     started_event  = consts.EVENTS.X_STARTED,
--     finished_event = consts.EVENTS.X_FINISHED,
--     failed_event   = consts.EVENTS.X_FAILED,
--     started_data   = {...},     -- payload for the started event
--     work           = function() return ok, fail_payload | finished_payload end,
--     on_success     = function(finished_payload) end,
--     on_failure     = function(failed_payload) end,
--     relay          = relay_fn,
--     log            = logger,
--   })
--
-- `work()` returns (true, payload) on success, (false, payload) on failure.
-- The caller decides what's in payload — async_task just shuttles it through
-- the relay.

local uuid = require("uuid")

local M = {}

local function gen_request_id()
    return uuid.v7() or tostring(math.random(1, 1e9))
end

local function normalize_failure_payload(value)
    if type(value) == "table" then
        local err = value.error or value.message
        if err == nil or err == "" then
            value.error = "work failed"
        elseif type(err) == "string" then
            value.error = err
        else
            value.error = tostring(err)
        end
        return value
    end
    if value == nil or value == "" then
        return { error = "work failed" }
    end
    return { error = tostring(value) }
end

local function safe_hook(name, fn, payload, log)
    if not fn then return end
    local ok, err = pcall(fn, payload)
    if not ok and log then
        log:warn("async_task " .. name .. " hook failed", { error = tostring(err) })
    end
end

function M.run(opts)
    local request_id = opts.request_id or gen_request_id()
    local started = opts.started_data or {}
    started.request_id = request_id
    opts.relay(opts.started_event, started)

    coroutine.spawn(function()
        M._execute(opts, request_id)
    end)

    return request_id
end

function M._execute(opts, request_id)
    local work = opts.work
    local relay = opts.relay
    local finished_event = opts.finished_event
    local failed_event = opts.failed_event
    local started_event = opts.started_event or "async_task"
    local on_success = opts.on_success
    local on_failure = opts.on_failure
    local log = opts.log

    local ran, ok, payload = pcall(work)
    if not ran then
        local thrown = ok
        ok = false
        payload = normalize_failure_payload(thrown)
    elseif not ok then
        payload = normalize_failure_payload(payload)
    end
    payload = payload or {}
    payload.request_id = request_id
    if ok then
        safe_hook("success", on_success, payload, log)
        relay(finished_event, payload)
    else
        safe_hook("failure", on_failure, payload, log)
        if log then log:warn(started_event .. " failed", { error = payload.error }) end
        relay(failed_event, payload)
    end
    return ok, payload
end

return M
