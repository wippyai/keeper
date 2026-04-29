-- Shared tool dispatch for MCP sessions.
--
-- Centralizes the session-context injection (overlay_branch, changeset_id
-- from token store), admin_call invocation, and post-call `_control` session
-- mutation handling that both the dynamic tool path in handler.lua and the
-- call_tool meta handler depend on. Keeping one dispatcher means token-store
-- side-effects and context-merge rules stay consistent across entry points.

local auth = require("mcp_auth")
local token_store = require("mcp_tokens")

local M = {}

function M.build_context(session, base_context)
    local ctx = {}
    for k, v in pairs(base_context or {}) do
        if k ~= "overlay_branch" and k ~= "changeset_id" then
            ctx[k] = v
        end
    end
    if not (session and session.token) then return ctx end
    if type(token_store.get_overlay_branch) == "function" then
        local branch = token_store.get_overlay_branch(session.token)
        if branch and branch ~= "" and ctx.overlay_branch == nil then
            ctx.overlay_branch = branch
        end
    end
    if type(token_store.get_changeset_id) == "function" then
        local changeset_id = token_store.get_changeset_id(session.token)
        if changeset_id and changeset_id ~= "" and ctx.changeset_id == nil then
            ctx.changeset_id = changeset_id
        end
    end
    return ctx
end

function M.apply_control(session, result)
    if type(result) ~= "table" or type(result._control) ~= "table" then return end
    if not (session and session.token) then return end

    local ctl = result._control
    if type(ctl.context) ~= "table" or type(ctl.context.session) ~= "table" then return end

    local set = ctl.context.session.set
    if type(set) == "table" then
        if set.overlay_branch ~= nil and type(token_store.set_overlay_branch) == "function" then
            token_store.set_overlay_branch(session.token, set.overlay_branch)
        end
        if set.changeset_id ~= nil and type(token_store.set_changeset_id) == "function" then
            token_store.set_changeset_id(session.token, set.changeset_id)
        end
    end

    local delete = ctl.context.session.delete
    if type(delete) == "table" then
        for _, key in ipairs(delete) do
            if key == "overlay_branch" and type(token_store.set_overlay_branch) == "function" then
                token_store.set_overlay_branch(session.token, nil)
            elseif key == "changeset_id" and type(token_store.set_changeset_id) == "function" then
                token_store.set_changeset_id(session.token, nil)
            end
        end
    end
end

-- Invoke a tool by registry id as the session's synthesized admin.
-- Merges session-scoped context (overlay_branch, changeset_id) onto base_context,
-- wraps admin_call in pcall, and applies any _control.session mutations back
-- to the token store on success.
-- Returns (result, err).
function M.call(session, registry_id, arguments, base_context, via)
    local context = M.build_context(session, base_context)
    local ok, result_or_err, err = pcall(auth.admin_call, session, via or "mcp",
        registry_id, arguments or {}, context)
    if not ok then
        return nil, "dispatch crashed: " .. tostring(result_or_err)
    end
    if err then
        return nil, tostring(err)
    end
    M.apply_control(session, result_or_err)
    return result_or_err, nil
end

return M
