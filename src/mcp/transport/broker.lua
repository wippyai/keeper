-- Per-session SSE broker.
--
-- A tiny forwarder process spawned by handler_get for each MCP SSE session.
-- The sse_relay middleware attaches its internal stream PID to this broker;
-- we learn that PID from the sse.join payload and use it as the forwarding
-- target. POST handlers publish notifications to this broker via
-- process.send(broker_pid, mcp.notify, payload); we forward each payload to
-- the stream PID on the configured SSE message topic, which the middleware
-- frames as `event: message\ndata: <json>\n\n` for the client.

local channel = require("channel")

local consts = require("mcp_consts")

local function run()
    local stream_pid = nil

    local joins = process.listen("sse.join", { message = true })
    local leaves = process.listen("sse.leave", { message = true })
    local notifies = process.listen(consts.MCP_NOTIFY_TOPIC, { message = true })
    local events = process.events()

    while true do
        local result = channel.select {
            joins:case_receive(),
            leaves:case_receive(),
            notifies:case_receive(),
            events:case_receive(),
        }

        if result.channel == joins then
            local msg = result.value
            if msg then
                -- sse.join is delivered FROM the stream PID TO this broker;
                -- msg:from() is the authoritative stream PID.
                stream_pid = msg:from()
            end
        elseif result.channel == leaves then
            -- Stream detached — SSE session ended. Exit so sse_relay's
            -- managed-mode monitor can tear down cleanly and the named
            -- registry slot frees up for the next connect.
            return
        elseif result.channel == notifies then
            local msg = result.value
            if msg and stream_pid then
                process.send(stream_pid, consts.SSE_MESSAGE_TOPIC, msg:payload():data())
            end
        elseif result.channel == events then
            local ev = result.value
            if ev and (ev.kind == process.event.CANCEL or ev.kind == process.event.EXIT) then
                return
            end
        end
    end
end

return { run = run }
