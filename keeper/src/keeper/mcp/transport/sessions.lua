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

local function evict_idlest(session, runtime, channel_api, time_api)
    local prefix = slot_prefix(session)
    local id = new_id()
    if not prefix or not id then return false end

    local topic = consts.MCP_IDLE_PROBE_REPLY_TOPIC_PREFIX .. id
    local replies = runtime.listen(topic, { message = true })
    local pending = {}
    local asked = 0
    for index = 1, config.mcp_max_sessions_per_token() do
        local pid = runtime.registry.lookup(prefix .. tostring(index))
        if pid and not pending[pid] and runtime.send(pid, consts.MCP_IDLE_PROBE_TOPIC, { reply_topic = topic }) then
            pending[pid] = true
            asked = asked + 1
        end
    end

    local timeout = time_api.timer(consts.SSE_BROKER_READY_TIMEOUT)
    local timeout_channel = timeout:channel()
    local idlest_pid, last_activity, activity_revision
    while asked > 0 do
        local result = channel_api.select({ replies:case_receive(), timeout_channel:case_receive() })
        if result.channel == timeout_channel then break end
        local msg = result.value
        local sender = msg and msg:from()
        if sender and pending[sender] then
            pending[sender] = nil
            asked = asked - 1
            local answer = msg:payload():data()
            if type(answer) == "table" and answer.evictable == true and type(answer.last_activity) == "number" then
                local revision = math.tointeger(answer.activity_revision)
                if revision and (not last_activity or answer.last_activity < last_activity) then
                    idlest_pid, last_activity, activity_revision = sender, answer.last_activity, revision
                end
            end
        end
    end
    timeout:stop()
    runtime.unlisten(replies)
    if not idlest_pid then return false end

    -- The chosen broker rechecks its own state and releases its own names.
    -- A reply can become stale while the HTTP handler is selecting a candidate.
    local evict_topic = topic .. ".evict"
    local confirmation = runtime.listen(evict_topic, { message = true })
    local evicted = false
    if runtime.cancel(idlest_pid, evict_topic .. ":" .. tostring(activity_revision)) then
        local wait = time_api.timer(consts.SSE_BROKER_READY_TIMEOUT)
        local deadline = wait:channel()
        while true do
            local result = channel_api.select({ confirmation:case_receive(), deadline:case_receive() })
            if result.channel == deadline then break end
            local msg = result.value
            if msg and msg:from() == idlest_pid then
                local answer = msg:payload():data()
                evicted = type(answer) == "table" and answer.evicted == true
                break
            end
        end
        wait:stop()
    end
    runtime.unlisten(confirmation)
    return evicted
end

-- Retry at the cap only after an unstreamed broker confirms it released a slot.
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
