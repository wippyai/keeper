-- GET / — Streamable HTTP SSE channel per MCP 2025-03-26.
--
-- Resolves the initialized session broker and hands the connection to
-- sse_relay via X-SSE-Relay. The middleware:
--   * attaches an internal stream PID to the broker (sse.join fires)
--   * frames outbound messages tagged with SSE_MESSAGE_TOPIC as
--     `event: message\ndata: <json>\n\n`
--   * auto-closes on broker exit (managed mode), client disconnect, or
--     timeout.
--
-- POST handlers push JSON-RPC notifications into the broker via process.send;
-- the broker forwards each notification to one attached stream.

local http = require("http")
local json = require("json")

local auth = require("mcp_auth")
local consts = require("mcp_consts")
local sessions = require("mcp_sessions")

local function write_error(res, status, message)
    res:set_status(status)
    res:set_content_type("application/json")
    res:write_json({ error = message })
end

local function transport_enabled(res)
    if not auth.enabled() then
        write_error(res, http.STATUS.NOT_FOUND, "MCP disabled")
        return false
    end
    return true
end

local function serve_get(req, res, session, runtime)
    local session_id = req:header("Mcp-Session-Id")
    if not session_id or session_id == "" then
        write_error(res, http.STATUS.BAD_REQUEST, "Mcp-Session-Id required")
        return
    end
    local broker_pid = sessions.lookup(session, session_id, runtime)
    if not broker_pid then
        write_error(res, http.STATUS.NOT_FOUND, "MCP session not found")
        return
    end

    local relay = {
        target_pid = broker_pid,
        message_topic = consts.SSE_MESSAGE_TOPIC,
        heartbeat_interval = "25s",
        metadata = {
            session_key = session_id,
            session_label = session.label or "env",
            identity = session.identity or "root",
        },
    }
    res:set_header("X-SSE-Relay", json.encode(relay))
    -- Body empty; sse_relay middleware takes over and writes the SSE stream.
end

local function handle_get()
    local res = http.response()
    if not transport_enabled(res) then return end

    local req = http.request()
    local session, auth_err = auth.session_from_request(req)
    if not session then
        write_error(res, http.STATUS.UNAUTHORIZED, auth_err or "unauthorized")
        return
    end

    serve_get(req, res, session, process)
end

return {
    handle_get = handle_get,
    _serve_get = serve_get,
}
