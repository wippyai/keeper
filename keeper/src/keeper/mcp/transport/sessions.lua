-- MCP transport sessions are distinct from bearer-token identities. The token
-- selects the actor and scopes; the issued session ID selects one live broker.

local channel = require("channel")
local crypto = require("crypto")
local time = require("time")

local auth = require("mcp_auth")
local authorize = require("mcp_authorize")
local consts = require("mcp_consts")
local config = require("keeper_config")

local M = {}
local BROKER_ID = "keeper.mcp.transport:broker"

local function new_id()
    local bytes, err = crypto.random.bytes(32)
    if err or not bytes then return nil, err or "random bytes unavailable" end
    local hex = {}
    for i = 1, #bytes do
        hex[i] = string.format("%02x", string.byte(bytes, i))
    end
    return table.concat(hex)
end

local function slot_prefix(session)
    local token_key = authorize.broker_key(session)
    if not token_key then return nil end
    return consts.SSE_BROKER_NAME_PREFIX .. token_key .. ".slot."
end

function M.name(session, id)
    if type(id) ~= "string" or #id ~= 64 or id:find("[^0-9a-f]") then return nil end
    local token_key = authorize.broker_key(session)
    if not token_key then return nil end
    return consts.SSE_BROKER_NAME_PREFIX .. token_key .. "." .. id
end

function M.lookup(session, id, runtime)
    local name = M.name(session, id)
    if not name then return nil end
    return (runtime or process).registry.lookup(name)
end

local function attempt(session, runtime, identity, host, channel_api, time_api)
    identity = identity or auth.admin_identity
    host = host or config.process_host()
    channel_api = channel_api or channel
    time_api = time_api or time

    local id, id_err = new_id()
    if not id then return nil, "session ID generation failed: " .. tostring(id_err) end
    local name = M.name(session, id)
    local prefix = slot_prefix(session)
    if not name or not prefix then return nil, "session broker key unavailable" end

    local actor, scope, ident_err = identity(session, "mcp.sse")
    if ident_err then return nil, ident_err end

    local ready_topic = consts.SSE_BROKER_READY_TOPIC_PREFIX .. id
    local ready_channel = runtime.listen(ready_topic)
    local broker_args = {
        session_name = name,
        slot_prefix = prefix,
        slot_count = config.mcp_max_sessions_per_token(),
        ready_to = runtime.pid(),
        ready_topic = ready_topic,
    }

    local broker_pid, spawn_err = runtime
        .with_context({})
        :with_actor(actor)
        :with_scope(scope)
        :spawn(BROKER_ID, host, broker_args)
    if spawn_err or not broker_pid then
        return nil, "broker spawn failed: " .. tostring(spawn_err)
    end

    local ready_timeout = time_api.timer(consts.SSE_BROKER_READY_TIMEOUT)
    local timeout_channel = ready_timeout:channel()
    local result = channel_api.select({
        ready_channel:case_receive(),
        timeout_channel:case_receive(),
    })
    ready_timeout:stop()

    if result.channel == timeout_channel then
        runtime.cancel(broker_pid, 0)
        return nil, "broker readiness timed out"
    end

    local ready = result.value
    if not ready then
        runtime.cancel(broker_pid, 0)
        return nil, "broker readiness failed"
    end
    if not ready.success then
        -- The broker sends a failed readiness reply only on its way out. It
        -- owns and releases any names it registered before that reply.
        return nil, ready.error or "broker readiness failed"
    end

    return id, broker_pid
end

-- before answers whether probe answer a ranks for eviction before b: a session no client holds a
-- stream of (a client that exited closed its stream; a live streamable HTTP client keeps one) before
-- one a client streams from, then the one with no activity the longest.
local function before(a, b)
    if (a.streamed == true) ~= (b.streamed == true) then return b.streamed == true end
    return a.last_activity < b.last_activity
end

-- evict_idlest cancels the broker of the token's session that ranks first for eviction (before) and
-- frees its names; false when no broker of the token answers the probe.
local function evict_idlest(session, runtime, channel_api, time_api)
    local prefix = slot_prefix(session)
    local id = new_id()
    if not prefix or not id then return false end
    local reply_topic = consts.MCP_IDLE_PROBE_REPLY_TOPIC_PREFIX .. id
    local replies = runtime.listen(reply_topic)
    local asked = 0
    for index = 1, config.mcp_max_sessions_per_token() do
        local pid = runtime.registry.lookup(prefix .. tostring(index))
        if pid and runtime.send(pid, consts.MCP_IDLE_PROBE_TOPIC, { reply_to = runtime.pid(), reply_topic = reply_topic }) then
            asked = asked + 1
        end
    end
    local timeout = time_api.timer(consts.SSE_BROKER_READY_TIMEOUT)
    local timeout_channel = timeout:channel()
    local idlest
    for _ = 1, asked do
        local result = channel_api.select({ replies:case_receive(), timeout_channel:case_receive() })
        if result.channel == timeout_channel then break end
        local answer = result.value
        if type(answer) == "table" and type(answer.pid) == "string"
            and (not idlest or before(answer, idlest)) then
            idlest = answer
        end
    end
    timeout:stop()
    if not idlest then return false end
    if idlest.session_name then runtime.registry.unregister(idlest.session_name) end
    if idlest.slot_name then runtime.registry.unregister(idlest.slot_name) end
    runtime.cancel(idlest.pid, 0)
    return true
end

-- create starts the broker of a new session of the token. At the per-token cap the session ranked
-- first for eviction (the idlest without an attached stream, else the idlest) is evicted and its slot taken, so sessions of clients that died without closing never
-- lock the token out. Creators at the cap race for the slot an eviction frees: one that finds it
-- taken evicts again, at most once per slot of the token, so the creator that finds no session
-- to evict is the only one refused.
function M.create(session, runtime, identity, host, channel_api, time_api)
    runtime = runtime or process
    channel_api = channel_api or channel
    time_api = time_api or time
    local id, broker_pid_or_err, err = attempt(session, runtime, identity, host, channel_api, time_api)
    for _ = 1, config.mcp_max_sessions_per_token() do
        if id or (err or broker_pid_or_err) ~= "MCP_SESSION_LIMIT" then return id, broker_pid_or_err, err end
        if not evict_idlest(session, runtime, channel_api, time_api) then return nil, "MCP_SESSION_LIMIT" end
        id, broker_pid_or_err, err = attempt(session, runtime, identity, host, channel_api, time_api)
    end
    return id, broker_pid_or_err, err
end

function M.touch(broker_pid, runtime)
    if type(broker_pid) ~= "string" then return false, "session broker unavailable" end
    runtime = runtime or process
    return runtime.send(broker_pid, consts.MCP_ACTIVITY_TOPIC, {})
end

function M.terminate(session, id, runtime)
    runtime = runtime or process
    local name = M.name(session, id)
    if not name then return false end
    local broker_pid = runtime.registry.lookup(name)
    if not broker_pid then return false end
    runtime.registry.unregister(name)
    runtime.cancel(broker_pid, 0)
    return true
end

return M
