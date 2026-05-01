-- GET / — Streamable HTTP SSE channel per MCP 2025-03-26.
--
-- Spawns a per-session broker process, registers it under a token-keyed name,
-- then hands the connection to sse_relay via X-SSE-Relay. The middleware:
--   * attaches an internal stream PID to the broker (sse.join fires)
--   * frames outbound messages tagged with SSE_MESSAGE_TOPIC as
--     `event: message\ndata: <json>\n\n`
--   * auto-closes on broker exit (managed mode), client disconnect, or
--     timeout.
--
-- POST handlers (see keeper.mcp.transport:handler publish_notification) push
-- JSON-RPC notifications into the broker via process.send; the broker
-- forwards them to the stream PID on SSE_MESSAGE_TOPIC. One SSE per token;
-- a reconnect unregisters the prior broker and hot-swaps.

local http = require("http")
local json = require("json")

local auth = require("mcp_auth")
local authorizer = require("mcp_authorize")
local consts = require("mcp_consts")
local config = require("keeper_config")

local BROKER_ID = "keeper.mcp.transport:broker"

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

local function handle_get()
    local res = http.response()
    if not transport_enabled(res) then return end

    local req = http.request()

    local session, auth_err = auth.session_from_request(req)
    if not session then
        write_error(res, http.STATUS.UNAUTHORIZED, auth_err or "unauthorized")
        return
    end

    local broker_key = authorizer.broker_key(session)
    if not broker_key then
        write_error(res, http.STATUS.INTERNAL_SERVER_ERROR, "session broker key unavailable")
        return
    end
    local broker_name = consts.SSE_BROKER_NAME_PREFIX .. broker_key

    -- Hot-swap: cancel any prior broker registered under this token so the
    -- new SSE session owns the name without fighting a zombie forwarder.
    local prior_pid = process.registry.lookup(broker_name)
    if prior_pid then
        process.cancel(prior_pid, 0)
        process.registry.unregister(broker_name)
    end

    local actor, scope, ident_err = auth.admin_identity(session, "mcp.sse")
    if ident_err then
        write_error(res, http.STATUS.INTERNAL_SERVER_ERROR, ident_err)
        return
    end

    local broker_pid, spawn_err = process
        .with_context({})
        :with_actor(actor)
        :with_scope(scope)
        :spawn(BROKER_ID, config.process_host())
    if spawn_err or not broker_pid then
        write_error(res, http.STATUS.INTERNAL_SERVER_ERROR, "broker spawn failed: " .. tostring(spawn_err))
        return
    end

    local reg_ok, reg_err = process.registry.register(broker_name, broker_pid)
    if not reg_ok then
        process.cancel(broker_pid, 0)
        write_error(res, http.STATUS.INTERNAL_SERVER_ERROR, "broker register failed: " .. tostring(reg_err))
        return
    end

    local relay = {
        target_pid = broker_pid,
        message_topic = consts.SSE_MESSAGE_TOPIC,
        heartbeat_interval = "25s",
        metadata = {
            session_key = broker_key,
            session_label = session.label or "env",
            identity = session.identity or "root",
        },
    }
    res:set_header("X-SSE-Relay", json.encode(relay))
    -- Body empty; sse_relay middleware takes over and writes the SSE stream.
end

return {
    handle_get = handle_get,
}
