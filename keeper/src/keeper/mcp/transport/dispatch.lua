-- Shared context binding and tool dispatch for both MCP tool entry paths.
local auth = require("mcp_auth")
local token_store = require("mcp_tokens")

local M = {}

function M.build_context(session, base_context)
    if not (session and session.token) then return nil, "MCP credential required" end
    local binding, err = token_store.get_session_context(session.token, session.mcp_session_id)
    if err then return nil, err end
    local ctx = {}
    for k, v in pairs(base_context or {}) do
        if k ~= "overlay_branch" and k ~= "changeset_id" then
            ctx[k] = v
        end
    end
    ctx.overlay_branch = binding.overlay_branch
    ctx.changeset_id = binding.changeset_id
    return ctx, nil
end

function M.apply_control(session, result)
    if type(result) ~= "table" or type(result._control) ~= "table" then return true, nil end
    local ctl = result._control
    if type(ctl.context) ~= "table" or type(ctl.context.session) ~= "table" then return true, nil end
    if not (session and session.token) then return false, "MCP credential required" end
    local control = ctl.context.session
    return token_store.update_session_context(session.token, session.mcp_session_id,
        control.set, control.delete)
end

function M.call(session, registry_id, arguments, base_context, via)
    local context, context_err = M.build_context(session, base_context)
    if context_err then return nil, context_err end
    local ok, result_or_err, err = pcall(auth.admin_call, session, via or "mcp",
        registry_id, arguments or {}, context)
    if not ok then
        return nil, "dispatch crashed: " .. tostring(result_or_err)
    end
    if err then
        return nil, tostring(err)
    end
    local applied, control_err = M.apply_control(session, result_or_err)
    if not applied then return nil, control_err end
    return result_or_err, nil
end

return M
