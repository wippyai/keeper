-- keeper.git central — routes inbox messages to per-op handlers, owns the
-- mutable state struct, restores the latest snapshot on boot, and pulses a
-- 60s ticker so journal growth flips the stale flag.
--
-- All real work is in service/handlers/* and flows/*. This file is dispatch.

local logger = require("logger")
local time = require("time")
local channel = require("channel")
local consts = require("git_consts")

local state_lib = require("state")
local snapshot_handler = require("snapshot_handler")
local decisions_handler = require("decisions_handler")
local rebuild_handler = require("rebuild_handler")
local push_handler = require("push_handler")
local explain_handler = require("explain_handler")
local split_handler = require("split_handler")
local pr_handler = require("pr_handler")

local log = logger:named("keeper.git.central")
local state = state_lib.new()

-- Reply over the inbox response channel.
local function reply(payload, result, err)
    if not payload or not payload.respond_to then return end
    local from = payload._from
    local respond_to = payload.respond_to
    if type(from) ~= "string" or type(respond_to) ~= "string" then return end
    process.send(from, respond_to, err
        and { success = false, error = tostring(err), request_id = payload.id }
        or  { success = true,  result = result,      request_id = payload.id })
end

local function relay(event, data)
    process.send(consts.RELAY_TARGET, consts.RELAY_TOPIC, { event = event, data = data })
end

local deps = { state = state, reply = reply, relay = relay, log = log }

local handlers = {
    [consts.OPERATIONS.LIST_CLUSTERS]          = snapshot_handler.list,
    [consts.OPERATIONS.GET_CLUSTER]            = snapshot_handler.get,
    [consts.OPERATIONS.SET_DECISION]           = decisions_handler.set_decision,
    [consts.OPERATIONS.UPDATE_RECOMMENDATION]  = decisions_handler.update_recommendation,
    [consts.OPERATIONS.REBUILD]                = rebuild_handler.handle,
    [consts.OPERATIONS.PUSH]                   = push_handler.handle,
    [consts.OPERATIONS.EXPLAIN_RECOMMENDATION] = explain_handler.handle,
    [consts.OPERATIONS.SUGGEST_SPLIT]          = split_handler.suggest,
    [consts.OPERATIONS.SPLIT_CLUSTER]          = split_handler.apply,
    [consts.OPERATIONS.PULL_REQUEST]           = pr_handler.handle,
}

local function dispatch(msg)
    local payload = msg:payload():data()
    local from = tostring(msg:from())
    if not payload or not payload.operation then
        log:warn("received message without operation", { from = from })
        return
    end
    payload._from = from   -- handlers reply through this
    local h = handlers[payload.operation]
    if not h then
        return reply(payload, nil,
            consts.ERRORS.UNKNOWN_OP .. ": " .. tostring(payload.operation))
    end
    h(payload, deps)
end

local function run()
    log:info("Starting keeper.git central")
    process.registry.register(consts.PROCESS_NAMES.SERVICE)
    if state:restore_from_db(log) then
        log:info("git snapshot restored", {
            run_id = state.snapshot.run_id,
            cluster_count = #(state.snapshot.cluster_order or {}),
        })
    end

    local inbox = process.inbox()
    local proc_events = process.events()
    local stale_ticker = time.ticker("60s")

    while true do
        local result = channel.select({
            inbox:case_receive(),
            proc_events:case_receive(),
            stale_ticker:channel():case_receive(),
        })
        if not result.ok then
            log:warn("main loop channel closed, shutting down")
            break
        end
        if result.channel == inbox then
            dispatch(result.value)
        elseif result.channel == proc_events then
            local event = result.value
            if event and event.kind == process.event.CANCEL then
                log:info("received cancel signal")
                break
            end
        else
            if state:recompute_stale() then
                relay(consts.EVENTS.STALE, { reason = "journal_growth" })
            end
        end
    end

    stale_ticker:stop()
    log:info("keeper.git central stopped")
end

return { run = run }
