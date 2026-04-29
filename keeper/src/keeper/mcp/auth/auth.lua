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
local token_store = require("mcp_tokens")
local authorizer = require("mcp_authorize")

local ADMIN_SCOPE_ID = consts.ADMIN_SCOPE_ID or "app.security:admin"
local ADMIN_IDENTITY_ENV = "keeper.mcp:admin_identity"
local ACCESS_TOKEN_ENV = "keeper.mcp:access_token"
local ENABLED_ENV = "keeper.mcp:enabled"
local PUBLIC_ENABLED_ENV = "keeper.mcp:public_enabled"
local PUBLIC_URL_ENV = "keeper.mcp:public_url"
local PUBLIC_API_URL_ENV = "PUBLIC_API_URL"
local PUBLIC_PATH = "/keeper-mcp/"
local INTERNAL_URL = "http://localhost:9067/"
local DEFAULT_PUBLIC_BASE_URL = "http://localhost:8067"

local M = {}

M.ADMIN_SCOPE_ID = ADMIN_SCOPE_ID
M.ENABLED_ENV = ENABLED_ENV
M.PUBLIC_ENABLED_ENV = PUBLIC_ENABLED_ENV
M.PUBLIC_URL_ENV = PUBLIC_URL_ENV
M.PUBLIC_PATH = PUBLIC_PATH
M.INTERNAL_URL = INTERNAL_URL

local function bool_env(id, default)
    local value = env.get(id)
    if value == nil or value == "" then return default end

    value = tostring(value):lower()
    if value == "1" or value == "true" or value == "yes" or value == "on" then
        return true
    end
    if value == "0" or value == "false" or value == "no" or value == "off" then
        return false
    end

    -- Invalid operator input must not accidentally expose a transport.
    return false
end

function M.enabled()
    return bool_env(ENABLED_ENV, true)
end

function M.public_enabled()
    return bool_env(PUBLIC_ENABLED_ENV, false)
end

local function trim_slashes(url)
    url = tostring(url or "")
    while url:sub(-1) == "/" do
        url = url:sub(1, -2)
    end
    return url
end

local function ensure_trailing_slash(url)
    url = tostring(url or "")
    if url == "" or url:sub(-1) == "/" then return url end
    return url .. "/"
end

function M.public_url()
    local explicit = env.get(PUBLIC_URL_ENV)
    if explicit and tostring(explicit) ~= "" then
        return ensure_trailing_slash(explicit)
    end

    local base = env.get(PUBLIC_API_URL_ENV)
    if not base or tostring(base) == "" then base = DEFAULT_PUBLIC_BASE_URL end
    return trim_slashes(base) .. PUBLIC_PATH
end

function M.internal_url()
    return INTERNAL_URL
end

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

function M.verify_active_user(user_id)
    if not user_id or user_id == "" then
        return false, "user_id required"
    end
    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return false, "db unavailable: " .. tostring(db_err) end

    local rows, q_err = db:query([[
        SELECT user_id
          FROM app_users
         WHERE user_id = ?
           AND status = 'active'
         LIMIT 1
    ]], { user_id })
    db:release()

    if q_err then return false, "user lookup failed: " .. tostring(q_err) end
    if not rows or #rows == 0 then
        return false, "not an active user: " .. tostring(user_id)
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

function M.session_from_token(token, opts)
    if not token or token == "" then return nil, "missing Authorization header" end
    opts = opts or {}

    local access_token = env.get(ACCESS_TOKEN_ENV)
    if access_token and access_token ~= "" and token == access_token then
        if opts.public_mount then
            return nil, "env MCP bearer is not accepted on the public MCP mount"
        end
        local identity, ident_err = M.resolve_env_identity()
        if not identity then return nil, ident_err end
        local token_hash, hash_err = token_store.digest(token)
        if hash_err then return nil, hash_err end
        return {
            token = token,
            token_hash = token_hash,
            label = "env",
            identity = identity,
            scopes = { consts.ROOT_SCOPE },
            access_mode = "any",
            trait_filter = nil,
            tool_filter = nil,
            default_active = {},
            internal_root = true,
        }, nil
    end

    local session, err = token_store.get(token)
    if err then return nil, err end
    if not session then return nil, "invalid token" end

    local ok, subject_err = authorizer.validate_subject(session)
    if not ok then return nil, subject_err end
    return session, nil
end

function M.session_from_request(req, opts)
    local token = M.extract_token(req)
    return M.session_from_token(token, opts)
end

function M.admin_actor(session, via)
    local identity = session and session.identity
    if type(identity) ~= "string" or identity == "" then
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
    if type(fn_id) ~= "string" or fn_id == "" then
        return nil, "function id is required"
    end

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
