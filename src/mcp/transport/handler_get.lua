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
local env = require("env")

local auth = require("mcp_auth")
local consts = require("mcp_consts")
local token_store = require("mcp_tokens")

local BROKER_ID = "keeper.mcp.transport:broker"
local BROKER_HOST = "app:processes"

local function authorize(req)
    local token = auth.extract_token(req)
    if not token then return nil, "missing Authorization header" end

    local access_token = env.get("keeper.mcp:access_token")
    if access_token and access_token ~= "" and token == access_token then
        local identity, ident_err = auth.resolve_env_identity()
        if not identity then return nil, ident_err end
        return { token = token, identity = identity, label = "env" }
    end

    local session, err = token_store.get(token)
    if err then return nil, err end
    if not session then return nil, "invalid token" end
    return session
end

local function write_error(res, status, message)
    res:set_status(status)
    res:set_content_type("application/json")
    res:write_json({ error = message })
end

local function handle_get()
    local res = http.response()
    local req = http.request()

    local session, auth_err = authorize(req)
    if not session then
        write_error(res, http.STATUS.UNAUTHORIZED, auth_err or "unauthorized")
        return
    end

    local broker_name = consts.SSE_BROKER_NAME_PREFIX .. session.token

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
        :spawn(BROKER_ID, BROKER_HOST)
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
            session_token = session.token,
            session_label = session.label or "env",
            identity = session.identity or "root",
        },
    }
    res:set_header("X-SSE-Relay", json.encode(relay))
    -- Body empty; sse_relay middleware takes over and writes the SSE stream.
end

return { handle_get = handle_get }
