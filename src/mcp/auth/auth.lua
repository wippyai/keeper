-- Admin actor + scope synthesis for MCP sessions.
--
-- MCP bearer tokens (env or token-store) carry no wippy security context of
-- their own, so any downstream call that hits governance or a managed
-- registry needs a synthesized admin actor bound to the app.security:admin
-- scope. Call sites that share this pattern:
--   * handler.lua — dispatch a dynamic tool via funcs.call
--   * handler_get.lua — spawn the per-session SSE broker process

local security = require("security")
local funcs = require("funcs")
local sql = require("sql")
local env = require("env")
local consts = require("mcp_consts")

local ADMIN_SCOPE_ID = "app.security:admin"
local ADMIN_IDENTITY_ENV = "keeper.mcp:admin_identity"

local M = {}

M.ADMIN_SCOPE_ID = ADMIN_SCOPE_ID

function M.extract_token(req)
    local header = req:header("Authorization")
    if header and header:sub(1, 7) == "Bearer " then
        return header:sub(8)
    end
    return nil
end

-- Confirms a user_id exists in app_users and is a member of the
-- app.security:admin group. Returns (true, nil) on success, (false, reason)
-- otherwise. Centralized so every surface that trusts a bearer to impersonate
-- an admin routes through the same check.
function M.verify_admin_user(user_id)
    if not user_id or user_id == "" then
        return false, "admin user_id required"
    end
    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return false, "db unavailable: " .. tostring(db_err) end

    local rows, q_err = db:query([[
        SELECT u.user_id
          FROM app_users u
          JOIN app_user_groups g
            ON g.user_id = u.user_id
         WHERE u.user_id = ?
           AND u.status = 'active'
           AND g.group_id = ?
         LIMIT 1
    ]], { user_id, ADMIN_SCOPE_ID })
    db:release()

    if q_err then return false, "admin lookup failed: " .. tostring(q_err) end
    if not rows or #rows == 0 then
        return false, "not an active admin user: " .. tostring(user_id)
    end
    return true, nil
end

-- Resolves the identity that the env bearer token impersonates. Reads
-- MCP_ADMIN_IDENTITY via the keeper.mcp:admin_identity env entry and confirms
-- the value is a real admin user. Returns (user_id, nil) or (nil, reason).
-- The env token cannot authenticate unless this resolves successfully.
function M.resolve_env_identity()
    local user_id = env.get(ADMIN_IDENTITY_ENV)
    if not user_id or user_id == "" then
        return nil, "env MCP bearer disabled: " ..
            ADMIN_IDENTITY_ENV .. " is not configured"
    end
    local ok, verr = M.verify_admin_user(user_id)
    if not ok then return nil, verr end
    return user_id, nil
end

function M.admin_actor(session, via)
    local identity = session and session.identity
    if not identity or identity == "" then
        error("admin_actor: session.identity missing — refuse to synthesize an anonymous actor")
    end
    return security.new_actor(identity, {
        via = via or "mcp",
        token_label = session and session.label or "env",
    })
end

function M.admin_scope()
    local scope, err = security.named_scope(ADMIN_SCOPE_ID)
    if err then return nil, "named_scope failed: " .. tostring(err) end
    return scope, nil
end

function M.admin_identity(session, via)
    local actor = M.admin_actor(session, via)
    local scope, err = M.admin_scope()
    if err then return nil, nil, err end
    return actor, scope, nil
end

-- admin_call builds an executor bound to the synthesized admin actor/scope for
-- a session and invokes a registry function. Centralizes the funcs.new +
-- with_actor/with_scope/with_context chain used by handler.lua and meta.lua.
function M.admin_call(session, via, fn_id, args, context)
    local actor, scope, ident_err = M.admin_identity(session, via)
    if ident_err then return nil, ident_err end

    local executor, err = funcs.new()
    if err then return nil, "funcs.new failed: " .. tostring(err) end

    local bound = executor:with_actor(actor):with_scope(scope)
    if context and next(context) then
        bound = bound:with_context(context)
    end

    local result, call_err = bound:call(fn_id, args or {})
    if call_err then return nil, tostring(call_err) end
    return result, nil
end

return M
