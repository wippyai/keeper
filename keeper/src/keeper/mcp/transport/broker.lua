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

local function run()
    local streams = stream_targets.new()

    local joins = process.listen("sse.join", { message = true })
    local leaves = process.listen("sse.leave", { message = true })
    local notifies = process.listen(consts.MCP_NOTIFY_TOPIC, { message = true })
    local events = process.events()
    local idle_timeout

    while true do
        local cases = {
            joins:case_receive(),
            leaves:case_receive(),
            notifies:case_receive(),
            events:case_receive(),
        }
        if streams:current() then
            idle_timeout = nil
        else
            idle_timeout = idle_timeout or time.after(consts.SSE_IDLE_TIMEOUT)
            cases[#cases + 1] = idle_timeout:case_receive()
        end
        local result = channel.select(cases)

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
                process.send(stream_pid, consts.SSE_MESSAGE_TOPIC, msg:payload():data())
            end
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

return { run = run }
