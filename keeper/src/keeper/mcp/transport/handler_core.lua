-- MCP JSON-RPC 2.0 HTTP transport.
--
-- Responsibilities:
--   * Parse the incoming JSON-RPC envelope and route the method.
--   * Authenticate the bearer token against env or the token store.
--   * Dispatch tools/call to the meta-tool handler layer, or to the
--     registered registry tool via funcs + synthesized MCP actor/scope.
--
-- All tool catalog composition lives in keeper.mcp.surface:surface. All
-- meta-tool behavior lives in keeper.mcp.surface:meta. This file is
-- transport only.

local http = require("http")
local json = require("json")

local auth = require("mcp_auth")
local authorize = require("mcp_authorize")
local consts = require("mcp_consts")
local dispatch = require("mcp_dispatch")
local mcp_traits = require("mcp_traits")
local surface = require("mcp_surface")
local meta = require("mcp_meta")
local validate = require("mcp_validate")

local META_SCHEMAS = {}
for _, m in ipairs(surface.META_TOOLS) do
    META_SCHEMAS[m.name] = m.inputSchema
end

-- Meta-tools whose success must invalidate the client's tools/list cache.
-- Derived from META_TOOLS.mutates_surface so adding a new trait/tool
-- mutation flag wires up the notification automatically.
local NOTIFY_TOOLS_CHANGED = surface.MUTATES_SURFACE

local function publish_notification(session, method, params)
    if not session or not session.token then return end
    local broker_key = authorize.broker_key(session)
    if not broker_key then return end
    local name = consts.SSE_BROKER_NAME_PREFIX .. broker_key
    local broker_pid = process.registry.lookup(name)
    if not broker_pid then return end
    local envelope = { jsonrpc = "2.0", method = method }
    if params ~= nil then envelope.params = params end
    process.send(broker_pid, consts.MCP_NOTIFY_TOPIC, envelope)
end

-- JSON-RPC helpers

local function jsonrpc_response(id, result)
    return { jsonrpc = "2.0", id = id, result = result }
end

local function jsonrpc_error(id, code, message)
    return { jsonrpc = "2.0", id = id, error = { code = code, message = message } }
end

local function write_disabled(res, message)
    res:set_status(http.STATUS.NOT_FOUND)
    res:set_content_type("application/json")
    res:write_json(jsonrpc_error(nil, -32000, message))
end

local function transport_enabled(res)
    if not auth.enabled() then
        write_disabled(res, "MCP disabled")
        return false
    end
    return true
end

local function tool_error(msg_id, text)
    return jsonrpc_response(msg_id, {
        content = { { type = "text", text = text } },
        isError = true,
    })
end

-- MCP method handlers

local function handle_initialize(msg)
    return jsonrpc_response(msg.id, {
        protocolVersion = consts.PROTOCOL_VERSION,
        capabilities = consts.CAPABILITIES,
        serverInfo = consts.SERVER_INFO,
        instructions = consts.INSTRUCTIONS,
    })
end

local function handle_tools_list(msg, session)
    local tool_list, _, resolve_err = surface.build(session)
    if resolve_err then
        return jsonrpc_error(msg.id, -32000, "trait resolution failed: " .. tostring(resolve_err))
    end
    return jsonrpc_response(msg.id, { tools = tool_list })
end

local function handle_tools_call(msg, session)
    local params = msg.params or {}
    local tool_name = params.name
    if type(tool_name) ~= "string" or tool_name == "" then
        return jsonrpc_error(msg.id, -32602, "missing tool name")
    end

    local arguments = params.arguments or {}

    -- Meta-tool short-circuit. Trait-management tools require any/traits mode;
    -- tools flagged always_visible (session_info) work in every mode.
    local meta_fn = rawget(meta.HANDLERS, tool_name)
    if meta_fn then
        local meta_allowed, meta_err = surface.meta_allowed(session, tool_name)
        if not meta_allowed then
            return tool_error(msg.id, meta_err or ("tool not allowed: " .. tool_name))
        end
    end
    if meta_fn and not (surface.ALWAYS_VISIBLE[tool_name] or surface.supports_traits(session)) then
        return tool_error(msg.id, "tool not available in access_mode=" .. tostring(session.access_mode))
    end
    if meta_fn then
        local schema_err = validate.check(arguments, META_SCHEMAS[tool_name])
        if schema_err then return tool_error(msg.id, schema_err) end
        local ok, result_or_err, err = pcall(meta_fn, arguments, session)
        if not ok then
            return tool_error(msg.id, "meta-tool error: " .. tostring(result_or_err))
        end
        if err then
            return tool_error(msg.id, tostring(err))
        end
        if NOTIFY_TOOLS_CHANGED[tool_name] then
            publish_notification(session, consts.NOTIFICATIONS.TOOLS_LIST_CHANGED)
        end
        return jsonrpc_response(msg.id, {
            content = { { type = "text", text = type(result_or_err) == "table" and json.encode(result_or_err) or tostring(result_or_err or "{}") } },
        })
    end

    -- Dynamic tool: look up registry id from the session's materialized surface.
    local _, lookup, resolve_err = surface.build(session)
    if resolve_err then
        return tool_error(msg.id, "trait resolution failed: " .. tostring(resolve_err))
    end
    local registry_id = lookup.registry and lookup.registry[tool_name]
    if not registry_id then
        local hint
        if surface.supports_traits(session) then
            hint = "unknown tool: " .. tool_name ..
                ". Call session_info to see available tools, or list_traits to find a trait that provides this tool."
        else
            hint = "unknown tool: " .. tool_name .. ". Call session_info to see the current tool surface."
        end
        return tool_error(msg.id, hint)
    end

    local dyn_schema = lookup.schema and lookup.schema[tool_name]
    local schema_err = validate.check(arguments, dyn_schema)
    if schema_err then return tool_error(msg.id, schema_err) end

    local call_allowed, call_err = authorize.tool_call(session, registry_id, nil, arguments)
    if not call_allowed then
        return tool_error(msg.id, call_err or ("tool not allowed by MCP scopes: " .. registry_id))
    end

    local result, dispatch_err = dispatch.call(session, registry_id, arguments,
        lookup.context[tool_name] or {}, "mcp")
    if dispatch_err then return tool_error(msg.id, dispatch_err) end

    if type(result) == "table" and type(result._mcp_content) == "table" then
        return jsonrpc_response(msg.id, {
            content = result._mcp_content,
            isError = result._mcp_is_error == true,
        })
    end

    local text
    if type(result) == "table" then
        text = json.encode(result)
    elseif result ~= nil then
        text = tostring(result)
    else
        text = "{}"
    end

    return jsonrpc_response(msg.id, {
        content = { { type = "text", text = text } },
    })
end

-- Prompt exposure: surface each active trait's prompt as a separate MCP
-- prompt resource. Clients that implement prompts/* get per-trait behavioral
-- context they can inject alongside the tool surface.

local function handle_prompts_list(msg, session)
    if not surface.supports_traits(session) then
        return jsonrpc_response(msg.id, { prompts = {} })
    end

    local active = mcp_traits.get_active(session) or {}
    local prompts = {}
    for _, tid in ipairs(active) do
        local def = mcp_traits.describe(tid, session)
        if def and def.prompt and def.prompt ~= "" then
            table.insert(prompts, {
                name = def.id,
                description = def.description or def.name,
            })
        end
    end
    return jsonrpc_response(msg.id, { prompts = prompts })
end

local function handle_prompts_get(msg, session)
    if not surface.supports_traits(session) then
        return jsonrpc_error(msg.id, -32601, "prompts not supported in access_mode=" .. tostring(session.access_mode))
    end

    local params = msg.params or {}
    local name = params.name
    if not name then return jsonrpc_error(msg.id, -32602, "missing prompt name") end

    local def, err = mcp_traits.describe(name, session)
    if err or not def then
        return jsonrpc_error(msg.id, -32602, "prompt not found: " .. tostring(name))
    end

    return jsonrpc_response(msg.id, {
        description = def.description or def.name,
        messages = {
            { role = "user", content = { type = "text", text = def.prompt or "" } },
        },
    })
end

local MCP_METHODS = {
    ["initialize"] = function(msg, _) return handle_initialize(msg) end,
    ["initialized"] = function(_, _) return nil end,
    ["notifications/initialized"] = function(_, _) return nil end,
    ["tools/list"] = handle_tools_list,
    ["tools/call"] = handle_tools_call,
    ["prompts/list"] = handle_prompts_list,
    ["prompts/get"] = handle_prompts_get,
    ["ping"] = function(msg, _) return jsonrpc_response(msg.id, { status = "ok" }) end,
}

local function requires_session(_method)
    -- The app gateway mount can be externally reachable, so authenticate the
    -- whole JSON-RPC surface, including initialize/ping.
    return true
end

-- HTTP handler

local function handle()
    local res = http.response()
    if not transport_enabled(res) then return end

    local req = http.request()

    local body = req:body()
    if not body or body == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json(jsonrpc_error(nil, -32700, "empty request body"))
        return
    end

    local msg, decode_err = json.decode(body)
    if decode_err or not msg then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json(jsonrpc_error(nil, -32700, "parse error"))
        return
    end

    local method = msg.method
    if not method then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json(jsonrpc_error(msg.id, -32600, "missing method"))
        return
    end

    local method_fn = MCP_METHODS[method]
    if not method_fn then
        res:write_json(jsonrpc_error(msg.id, -32601, "method not found: " .. method))
        return
    end

    local session
    if requires_session(method) then
        local auth_err
        session, auth_err = auth.session_from_request(req)
        if not session then
            res:set_status(http.STATUS.UNAUTHORIZED)
            res:write_json(jsonrpc_error(msg.id, -32000, auth_err or "unauthorized"))
            return
        end
    end

    local result = method_fn(msg, session)
    if result then
        res:set_content_type("application/json")
        res:write_json(result)
    else
        res:set_status(202)
    end
end

return {
    handle = handle,
    _requires_session = requires_session,
}
