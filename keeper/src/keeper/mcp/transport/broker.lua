-- Per-session SSE broker.
--
-- A tiny forwarder process spawned by handler_get for each MCP SSE session.
-- The sse_relay middleware attaches its internal stream PID to this broker;
-- we learn that PID from the sse.join payload and use it as the forwarding
-- target. POST handlers publish notifications to this broker via
-- process.send(broker_pid, mcp.notify, payload); we forward each payload to
-- one attached stream PID on the configured SSE message topic, which the
-- middleware frames as `event: message\ndata: <json>\n\n` for the client.

local channel = require("channel")
local time = require("time")

local consts = require("mcp_consts")
local stream_targets = require("mcp_stream_targets")

local function run(channel_api, time_api, stream_targets_api, transport_consts, process_api)
    channel_api = channel_api or channel
    time_api = time_api or time
    stream_targets_api = stream_targets_api or stream_targets
    transport_consts = transport_consts or consts
    process_api = process_api or process

    local streams = stream_targets_api.new()

    local joins = process_api.listen("sse.join", { message = true })
    local leaves = process_api.listen("sse.leave", { message = true })
    local notifies = process_api.listen(transport_consts.MCP_NOTIFY_TOPIC, { message = true })
    local activity = process_api.listen(transport_consts.MCP_ACTIVITY_TOPIC, { message = true })
    local events = process_api.events()
    local idle_timeout

    while true do
        local cases = {
            joins:case_receive(),
            leaves:case_receive(),
            notifies:case_receive(),
            activity:case_receive(),
            events:case_receive(),
        }
        if streams:current() then
            idle_timeout = nil
        else
            idle_timeout = idle_timeout or time_api.after(transport_consts.SSE_IDLE_TIMEOUT)
            cases[#cases + 1] = idle_timeout:case_receive()
        end
        local result = channel_api.select(cases)

        if result.channel == joins then
            local msg = result.value
            if msg then
                -- sse.join is delivered FROM the stream PID TO this broker;
                -- msg:from() is the authoritative stream PID.
                streams:join(msg:from())
            end
        elseif result.channel == leaves then
            local msg = result.value
            if msg then streams:leave(msg:from()) end
        elseif result.channel == notifies then
            local msg = result.value
            local stream_pid = streams:current()
            if msg and stream_pid then
                process_api.send(stream_pid, transport_consts.SSE_MESSAGE_TOPIC, msg:payload():data())
            end
        elseif result.channel == activity then
            -- A POST is real session activity even when the client does not
            -- maintain an SSE GET stream. Re-arm the detached-session timer.
            idle_timeout = nil
        elseif result.channel == events then
            local ev = result.value
            if ev and (ev.kind == process.event.CANCEL or ev.kind == process.event.EXIT) then
                return
            end
        elseif idle_timeout and result.channel == idle_timeout then
            return
        end
    end
end

return { run = run, _run_with = run }
