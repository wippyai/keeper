local json = require("json")
local crypto = require("crypto")
local sql = require("sql")
local time = require("time")
local hash = require("hash")
local consts = require("mcp_consts")

local tokens = {}

-- access_mode values:
--   "any"        — full trait catalog + all tools (root)
--   "traits"     — traits matching trait_filter are activatable; tool surface
--                  derives from active traits
--   "tools_only" — direct tool catalog filtered by tool_filter, no trait layer
--
-- trait_filter / tool_filter shape (see consts.lua):
--   nil  -> no restriction
--   { namespaces, tags_any, tags_all, include_ids, exclude_ids }
--
-- DB columns `available_traits` / `available_tools` hold the serialized filter
-- JSON (object or null); the literal-allowlist semantics they once carried
-- are gone.
local VALID_ACCESS_MODES = { any = true, traits = true, tools_only = true }

-- Raw bearer tokens never sit in the DB. Every column keyed by `token`
-- (keeper_mcp_tokens.token, keeper_mcp_session_state.token) stores the
-- sha256 of the raw value; clients keep sending the raw token and lookups
-- hash it on the way in. Raw value is shown exactly once on create.
local function digest(raw)
    if raw == nil or raw == "" then return nil, "token required" end
    local d, err = hash.sha256(raw)
    if err then return nil, "hash failed: " .. tostring(err) end
    return d, nil
end
tokens.digest = digest

local function bytes_to_hex(bytes)
    local out = {}
    for i = 1, #bytes do
        out[i] = string.format("%02x", string.byte(bytes, i))
    end
    return table.concat(out)
end

local function generate_raw_token()
    local bytes, err = crypto.random.bytes(32)
    if err then return nil, "Failed to generate random token bytes: " .. tostring(err) end
    return "wkmcp_" .. bytes_to_hex(bytes), nil
end
tokens.generate_raw_token = generate_raw_token

local function encode_value(v)
    if v == nil then return nil end
    return json.encode(v)
end

local function decode_value(s, default)
    if not s or s == "" then return default end
    local ok, decoded = pcall(json.decode, s)
    if not ok then return default end
    return decoded
end

local function row_to_session(row)
    if not row then return nil end
    local access_mode = row.access_mode
    if not access_mode or access_mode == "" then access_mode = "tools_only" end

    return {
        token = nil,           -- raw value known only to the client; injected by tokens.get
        token_hash = row.token,
        label = row.label,
        identity = row.identity,
        scopes = decode_value(row.scopes, {}),
        access_mode = access_mode,
        trait_filter = decode_value(row.available_traits, nil),
        tool_filter = decode_value(row.available_tools, nil),
        default_active = decode_value(row.default_active, {}),
        issued_by = row.issued_by,
        created_at = row.created_at,
        expires_at = row.expires_at,
        revoked_at = row.revoked_at,
        revoked_by = row.revoked_by,
    }
end

function tokens.create(params)
    local access_mode = params.access_mode or "tools_only"
    if not VALID_ACCESS_MODES[access_mode] then
        return nil, "invalid access_mode: " .. tostring(access_mode)
    end

    local raw_token, uerr = generate_raw_token()
    if uerr then return nil, uerr end
    local token_hash, herr = digest(raw_token)
    if herr then return nil, herr end

    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return nil, "Database error: " .. tostring(db_err) end

    local now = time.now():unix()
    local expires = params.expires_at or 0
    local issued_by = params.issued_by or params.identity or ""

    local _, exec_err = db:execute([[
        INSERT INTO keeper_mcp_tokens
          (token, label, identity, scopes, access_mode, available_traits, available_tools, default_active, issued_by, created_at, expires_at, revoked)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
    ]], {
        token_hash,
        params.label or "",
        params.identity or "root",
        encode_value(params.scopes or {}),
        access_mode,
        encode_value(params.trait_filter),
        encode_value(params.tool_filter),
        encode_value(params.default_active or {}),
        issued_by,
        now,
        expires,
    })
    db:release()

    if exec_err then return nil, "Insert failed: " .. tostring(exec_err) end

    return {
        token = raw_token,
        label = params.label or "",
        identity = params.identity or "root",
        scopes = params.scopes or {},
        access_mode = access_mode,
        trait_filter = params.trait_filter,
        tool_filter = params.tool_filter,
        default_active = params.default_active or {},
        issued_by = issued_by,
        created_at = now,
        expires_at = params.expires_at,
    }, nil
end

function tokens.get(raw_token)
    local token_hash, herr = digest(raw_token)
    if herr then return nil, herr end

    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return nil, "Database error: " .. tostring(db_err) end

    local rows, query_err = db:query([[
        SELECT token, label, identity, scopes, access_mode, available_traits, available_tools,
               default_active, issued_by, created_at, expires_at, revoked, revoked_at, revoked_by
        FROM keeper_mcp_tokens WHERE token = ?
    ]], { token_hash })
    db:release()

    if query_err then return nil, "Query failed: " .. tostring(query_err) end
    if not rows or #rows == 0 then return nil end

    local row = rows[1]
    if row.revoked == 1 then return nil, "Token revoked" end

    local now = time.now():unix()
    if row.expires_at and row.expires_at > 0 and row.expires_at < now then
        return nil, "Token expired"
    end

    local session = row_to_session(row)
    -- Callers (handler, dispatch, broker naming) key everything off session.token.
    -- Return the caller's raw value so downstream keys (session_state, SSE
    -- broker name) match across requests from the same bearer.
    session.token = raw_token
    return session, nil
end

function tokens.list()
    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return nil, "Database error: " .. tostring(db_err) end

    local rows, query_err = db:query([[
        SELECT token, label, identity, scopes, access_mode, available_traits, available_tools,
               default_active, issued_by, created_at, expires_at, revoked, revoked_at, revoked_by
        FROM keeper_mcp_tokens ORDER BY created_at DESC
    ]])
    db:release()

    if query_err then return nil, "Query failed: " .. tostring(query_err) end

    local result = {}
    for _, row in ipairs(rows or {}) do
        local entry = row_to_session(row)
        entry.revoked = row.revoked == 1
        table.insert(result, entry)
    end
    return result, nil
end

-- Revoke by hashed identifier (as surfaced by tokens.list). Raw tokens are
-- never recoverable from the DB, so the admin surface identifies rows by
-- their hash.
function tokens.revoke(token_hash, revoked_by)
    if not token_hash or token_hash == "" then
        return nil, "token hash required"
    end

    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return nil, "Database error: " .. tostring(db_err) end

    local now = time.now():unix()
    local _, exec_err = db:execute([[
        UPDATE keeper_mcp_tokens
           SET revoked = 1,
               revoked_at = ?,
               revoked_by = ?
         WHERE token = ?
    ]], { now, revoked_by or "", token_hash })
    db:release()

    if exec_err then return nil, "Revoke failed: " .. tostring(exec_err) end
    return true, nil
end

-- Session state (runtime active_traits per token). Token key matches either a
-- real DB token value or the env-token string; the separate session_state
-- table lets the env-token (no tokens row) still persist its active set.

-- Returns (active_traits, err). A `nil` active_traits value (with no err)
-- signals "no persisted state for this token" so callers can fall back to
-- default_active. An empty array means the caller explicitly cleared the set.
function tokens.get_active_traits(raw_token)
    local key, herr = digest(raw_token)
    if herr then return nil, herr end

    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return nil, "Database error: " .. tostring(db_err) end

    local rows, query_err = db:query(
        "SELECT active_traits FROM keeper_mcp_session_state WHERE token = ?",
        { key }
    )
    db:release()

    if query_err then return nil, "Query failed: " .. tostring(query_err) end
    if not rows or #rows == 0 then return nil, nil end

    return decode_value(rows[1].active_traits, {}), nil
end

function tokens.set_active_traits(raw_token, trait_ids)
    local key, herr = digest(raw_token)
    if herr then return false, herr end

    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return false, "Database error: " .. tostring(db_err) end

    local payload = encode_value(trait_ids or {})
    local now = time.now():unix()

    local _, exec_err = db:execute([[
        INSERT INTO keeper_mcp_session_state (token, active_traits, updated_at)
        VALUES (?, ?, ?)
        ON CONFLICT(token) DO UPDATE SET active_traits = excluded.active_traits, updated_at = excluded.updated_at
    ]], { key, payload, now })
    db:release()

    if exec_err then return false, "Upsert failed: " .. tostring(exec_err) end
    return true, nil
end

function tokens.clear_active_traits(token)
    return tokens.set_active_traits(token, {})
end

-- Session-scoped overlay_branch. Tools that edit via branches (edit, manage,
-- lint, push) read `ctx.get("overlay_branch")`; the branch tool emits
-- `_control.context.session.set.overlay_branch` and the MCP handler persists
-- it here so subsequent calls on the same bearer see it.

function tokens.get_overlay_branch(raw_token)
    local key, herr = digest(raw_token)
    if herr then return nil, herr end

    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return nil, "Database error: " .. tostring(db_err) end

    local rows, query_err = db:query(
        "SELECT overlay_branch FROM keeper_mcp_session_state WHERE token = ?",
        { key }
    )
    db:release()

    if query_err then return nil, "Query failed: " .. tostring(query_err) end
    if not rows or #rows == 0 then return nil, nil end

    local v = rows[1].overlay_branch
    if v == nil or v == "" then return nil, nil end
    return v, nil
end

function tokens.set_overlay_branch(raw_token, branch)
    local key, herr = digest(raw_token)
    if herr then return false, herr end

    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return false, "Database error: " .. tostring(db_err) end

    local now = time.now():unix()
    local _, exec_err = db:execute([[
        INSERT INTO keeper_mcp_session_state (token, active_traits, overlay_branch, updated_at)
        VALUES (?, '[]', ?, ?)
        ON CONFLICT(token) DO UPDATE SET overlay_branch = excluded.overlay_branch, updated_at = excluded.updated_at
    ]], { key, branch, now })
    db:release()

    if exec_err then return false, "Upsert failed: " .. tostring(exec_err) end
    return true, nil
end

function tokens.clear_overlay_branch(token)
    return tokens.set_overlay_branch(token, nil)
end

-- Session-scoped changeset_id. Paired with overlay_branch so the edit/manage/
-- fs tools can read a live changeset off ctx without re-resolving it
-- from the branch on every call. Persisted here so subsequent MCP requests on
-- the same bearer pick up the same workspace.

function tokens.get_changeset_id(raw_token)
    local key, herr = digest(raw_token)
    if herr then return nil, herr end

    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return nil, "Database error: " .. tostring(db_err) end

    local rows, query_err = db:query(
        "SELECT changeset_id FROM keeper_mcp_session_state WHERE token = ?",
        { key }
    )
    db:release()

    if query_err then return nil, "Query failed: " .. tostring(query_err) end
    if not rows or #rows == 0 then return nil, nil end

    local v = rows[1].changeset_id
    if v == nil or v == "" then return nil, nil end
    return v, nil
end

function tokens.set_changeset_id(raw_token, changeset_id)
    local key, herr = digest(raw_token)
    if herr then return false, herr end

    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return false, "Database error: " .. tostring(db_err) end

    local now = time.now():unix()
    local _, exec_err = db:execute([[
        INSERT INTO keeper_mcp_session_state (token, active_traits, changeset_id, updated_at)
        VALUES (?, '[]', ?, ?)
        ON CONFLICT(token) DO UPDATE SET changeset_id = excluded.changeset_id, updated_at = excluded.updated_at
    ]], { key, changeset_id, now })
    db:release()

    if exec_err then return false, "Upsert failed: " .. tostring(exec_err) end
    return true, nil
end

function tokens.clear_changeset_id(token)
    return tokens.set_changeset_id(token, nil)
end

return tokens
