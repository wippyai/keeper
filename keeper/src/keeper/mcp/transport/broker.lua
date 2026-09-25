-- Per-session SSE broker and owner of its registry names.

local channel = require("channel")
local time = require("time")

local consts = require("mcp_consts")
local stream_targets = require("mcp_stream_targets")

local function register_names(args, process_api)
    if type(args) ~= "table"
        or type(args.session_name) ~= "string"
        or type(args.slot_prefix) ~= "string"
        or type(args.slot_count) ~= "number"
        or type(args.ready_to) ~= "string"
        or type(args.ready_topic) ~= "string" then
        return nil, "broker startup arguments are incomplete"
    end

    local slot_name
    for index = 1, args.slot_count do
        local candidate = args.slot_prefix .. tostring(index)
        local registered, register_err = process_api.registry.register(candidate)
        if registered then
            slot_name = candidate
            break
        end

        local current_pid = process_api.registry.lookup(candidate)
        if not current_pid then
            return nil, "session slot registration failed: " .. tostring(register_err)
        end
    end
    if not slot_name then return nil, "MCP_SESSION_LIMIT" end

    local registered, register_err = process_api.registry.register(args.session_name)
    if not registered then
        process_api.registry.unregister(slot_name)
        return nil, "broker register failed: " .. tostring(register_err)
    end
    return slot_name
end

local function report_ready(args: { ready_to: string, ready_topic: string }?, process_api, success: boolean, err: string?)
    if not args or type(args.ready_to) ~= "string" or type(args.ready_topic) ~= "string" then
        return false
    end
    return process_api.send(args.ready_to, args.ready_topic, {
        success = success,
        error = err,
    })
end

local function run_with(channel_api, time_api, stream_targets_api, transport_consts, process_api, args)
    channel_api = channel_api or channel
    time_api = time_api or time
    stream_targets_api = stream_targets_api or stream_targets
    transport_consts = transport_consts or consts
    process_api = process_api or process

    local streams = stream_targets_api.new()
    local state = {
        slot_name = nil,
        session_name = nil,
        streams = streams,
        idle_timer = nil,
        idle_channel = nil,
        idle_active = false,
        activity_count = 0,
    }
    local idle_channel

    local joins = process_api.listen("sse.join", { message = true })
    local leaves = process_api.listen("sse.leave", { message = true })
    local notifies = process_api.listen(transport_consts.MCP_NOTIFY_TOPIC, { message = true })
    local activity = process_api.listen(transport_consts.MCP_ACTIVITY_TOPIC, { message = true })
    local events = process_api.events()

    local function reset_idle_timer()
        if state.idle_timer then
            local reset = state.idle_timer:reset(transport_consts.SSE_IDLE_TIMEOUT)
            if reset ~= false then
                state.idle_active = true
                return
            end
            state.idle_timer:stop()
            state.idle_timer = nil
            state.idle_channel = nil
            idle_channel = nil
        end

        state.idle_timer = time_api.timer(transport_consts.SSE_IDLE_TIMEOUT)
        idle_channel = state.idle_timer:channel()
        state.idle_channel = idle_channel
        state.idle_active = true
    end

    local function stop_idle_timer()
        if state.idle_timer then
            if state.idle_active then state.idle_timer:stop() end
            state.idle_timer = nil
            state.idle_channel = nil
            idle_channel = nil
        end
        state.idle_active = false
    end

    local slot_name, startup_err = register_names(args, process_api)
    if not slot_name then
        state.startup_error = startup_err
        report_ready(args, process_api, false, startup_err)
        return state
    end
    state.slot_name = slot_name
    state.session_name = args.session_name

    local acknowledged = report_ready(args, process_api, true)
    if not acknowledged then
        state.startup_error = "broker readiness acknowledgement failed"
        return state
    end

    while true do
        local cases = {
            joins:case_receive(),
            leaves:case_receive(),
            notifies:case_receive(),
            activity:case_receive(),
            events:case_receive(),
        }
        if streams:current() then
            stop_idle_timer()
        else
            if not state.idle_active then reset_idle_timer() end
            cases[#cases + 1] = idle_channel:case_receive()
        end
        local result = channel_api.select(cases)

        if result.channel == joins then
            local msg = result.value
            if msg then streams:join(msg:from()) end
            if streams:current() then stop_idle_timer() end
        elseif result.channel == leaves then
            local msg = result.value
            if msg then streams:leave(msg:from()) end
            if not streams:current() then reset_idle_timer() end
        elseif result.channel == notifies then
            local msg = result.value
            local stream_pid = streams:current()
            if msg and stream_pid then
                process_api.send(stream_pid, transport_consts.SSE_MESSAGE_TOPIC, msg:payload():data())
            end
        elseif result.channel == activity then
            state.activity_count = state.activity_count + 1
            if not streams:current() then reset_idle_timer() end
        elseif result.channel == events then
            local ev = result.value
            if ev and (ev.kind == process_api.event.CANCEL or ev.kind == process_api.event.EXIT) then
                stop_idle_timer()
                state.exit_kind = ev.kind
                return state
            end
        elseif idle_channel and result.channel == idle_channel then
            state.idle_active = false
            state.exit_kind = "idle"
            return state
        end
    end
end

local function run(args)
    run_with(channel, time, stream_targets, consts, process, args)
end

return {
    run = run,
    _run_with = run_with,
}
