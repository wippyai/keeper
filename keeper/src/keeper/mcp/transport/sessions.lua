-- MCP transport sessions are distinct from bearer-token identities. The token
-- selects the actor and scopes; the issued session ID selects one live broker.

local crypto = require("crypto")

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

function M.create(session, runtime, identity, host)
    runtime = runtime or process
    identity = identity or auth.admin_identity
    host = host or config.process_host()

    local id, id_err = new_id()
    if not id then return nil, "session ID generation failed: " .. tostring(id_err) end
    local name = M.name(session, id)
    if not name then return nil, "session broker key unavailable" end

    local actor, scope, ident_err = identity(session, "mcp.sse")
    if ident_err then return nil, ident_err end

    local broker_pid, spawn_err = runtime
        .with_context({})
        :with_actor(actor)
        :with_scope(scope)
        :spawn(BROKER_ID, host)
    if spawn_err or not broker_pid then
        return nil, "broker spawn failed: " .. tostring(spawn_err)
    end

    local reg_ok, reg_err = runtime.registry.register(name, broker_pid)
    if not reg_ok then
        runtime.cancel(broker_pid, 0)
        return nil, "broker register failed: " .. tostring(reg_err)
    end
    return id, broker_pid
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
