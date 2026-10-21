local json = require("json")
local crypto = require("crypto")
local sql = require("sql")
local time = require("time")
local hash = require("hash")
local consts = require("mcp_consts")
local collections = require("mcp_collections")

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
    return json.decode(s)
end

local function truthy(v)
    return v == true or v == 1 or v == "1"
end

local function row_to_session(row)
    if not row then return nil end
    local access_mode = row.access_mode
    if not access_mode or access_mode == "" then access_mode = "tools_only" end

    local scopes, scopes_err = collections.decode(row.scopes)
    if scopes_err then return nil, "Invalid token scopes: " .. tostring(scopes_err) end
    local active, active_err = collections.decode(row.default_active)
    if active_err then return nil, "Invalid token default_active: " .. tostring(active_err) end
    local trait_filter, trait_err = decode_value(row.available_traits, nil)
    if trait_err then return nil, "Invalid token trait_filter: " .. tostring(trait_err) end
    local tool_filter, tool_err = decode_value(row.available_tools, nil)
    if tool_err then return nil, "Invalid token tool_filter: " .. tostring(tool_err) end

    return {
        token = nil,           -- raw value known only to the client; injected by tokens.get
        token_hash = row.token,
        label = row.label,
        identity = row.identity,
        scopes = scopes,
        access_mode = access_mode,
        trait_filter = trait_filter,
        tool_filter = tool_filter,
        default_active = active,
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

    local scopes, scopes_err = collections.strings(params.scopes)
    if scopes_err then return nil, "Invalid token scopes: " .. tostring(scopes_err) end
    local active, active_err = collections.strings(params.default_active)
    if active_err then return nil, "Invalid token default_active: " .. tostring(active_err) end

    local raw_token, uerr = generate_raw_token()
    if uerr then return nil, uerr end
    local token_hash, herr = digest(raw_token)
    if herr then return nil, herr end

    local db, db_err = sql.get(consts.db_id())
    if db_err then return nil, "Database error: " .. tostring(db_err) end

    local now = time.now():unix()
    local expires = params.expires_at or 0
    local issued_by = params.issued_by or params.identity or ""

    local _, exec_err = sql.builder.insert("keeper_mcp_tokens")
        :set_map({
            token = token_hash,
            label = params.label or "",
            identity = params.identity or "root",
            scopes = encode_value(scopes),
            access_mode = access_mode,
            available_traits = encode_value(params.trait_filter),
            available_tools = encode_value(params.tool_filter),
            default_active = encode_value(active),
            issued_by = issued_by,
            created_at = now,
            expires_at = expires,
            revoked = 0,
        })
        :run_with(db)
        :exec()
    db:release()

    if exec_err then return nil, "Insert failed: " .. tostring(exec_err) end

    return {
        token = raw_token,
        label = params.label or "",
        identity = params.identity or "root",
        scopes = scopes,
        access_mode = access_mode,
        trait_filter = params.trait_filter,
        tool_filter = params.tool_filter,
        default_active = active,
        issued_by = issued_by,
        created_at = now,
        expires_at = params.expires_at,
    }, nil
end

function tokens.get(raw_token)
    local token_hash, herr = digest(raw_token)
    if herr then return nil, herr end

    local db, db_err = sql.get(consts.db_id())
    if db_err then return nil, "Database error: " .. tostring(db_err) end

    local rows, query_err = sql.builder.select(
            "token", "label", "identity", "scopes", "access_mode", "available_traits", "available_tools",
            "default_active", "issued_by", "created_at", "expires_at", "revoked", "revoked_at", "revoked_by"
        )
        :from("keeper_mcp_tokens")
        :where("token = ?", token_hash)
        :run_with(db)
        :query()
    db:release()

    if query_err then return nil, "Query failed: " .. tostring(query_err) end
    if not rows or #rows == 0 then return nil end

    local row = rows[1]
    if truthy(row.revoked) then return nil, "Token revoked" end

    local now = time.now():unix()
    if row.expires_at and row.expires_at > 0 and row.expires_at < now then
        return nil, "Token expired"
    end

    local session, session_err = row_to_session(row)
    if session_err then return nil, session_err end
    -- Callers (handler, dispatch, broker naming) key everything off session.token.
    -- Return the caller's raw value so downstream keys (session_state, SSE
    -- broker name) match across requests from the same bearer.
    session.token = raw_token
    return session, nil
end

function tokens.list()
    local db, db_err = sql.get(consts.db_id())
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
        local entry, entry_err = row_to_session(row)
        if entry_err then return nil, entry_err end
        entry.revoked = truthy(row.revoked)
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

    local db, db_err = sql.get(consts.db_id())
    if db_err then return nil, "Database error: " .. tostring(db_err) end

    local now = time.now():unix()
    local result, exec_err = sql.builder.update("keeper_mcp_tokens")
        :set_map({ revoked = 1, revoked_at = now, revoked_by = revoked_by or "" })
        :where("token = ?", token_hash)
        :run_with(db)
        :exec()
    db:release()

    if exec_err then return nil, "Revoke failed: " .. tostring(exec_err) end
    if not result or tonumber(result.rows_affected or 0) == 0 then
        return false, "token not found"
    end
    return true, nil
end

-- Trait activation remains credential-scoped, in the unassigned session row.
-- Transport context uses a separate row for each validated session ID.

-- Returns (active_traits, err). A `nil` active_traits value (with no err)
-- signals "no persisted state for this token" so callers can fall back to
-- default_active. An empty array means the caller explicitly cleared the set.
function tokens.get_active_traits(raw_token)
    local key, herr = digest(raw_token)
    if herr then return nil, herr end

    local db, db_err = sql.get(consts.db_id())
    if db_err then return nil, "Database error: " .. tostring(db_err) end

    local rows, query_err = sql.builder.select("active_traits")
        :from("keeper_mcp_session_state")
        :where("token = ? AND session_id = ?", key, "")
        :run_with(db)
        :query()
    db:release()

    if query_err then return nil, "Query failed: " .. tostring(query_err) end
    if not rows or #rows == 0 then return nil, nil end

    return collections.decode(rows[1].active_traits)
end

function tokens.set_active_traits(raw_token, trait_ids)
    local key, herr = digest(raw_token)
    if herr then return false, herr end

    local active, active_err = collections.strings(trait_ids)
    if active_err then return false, active_err end
    local payload, encode_err = json.encode(active)
    if encode_err then return false, encode_err end

    local db, db_err = sql.get(consts.db_id())
    if db_err then return false, "Database error: " .. tostring(db_err) end
    local now = time.now():unix()

    local _, exec_err = sql.builder.insert("keeper_mcp_session_state")
        :set_map({ token = key, session_id = "", active_traits = payload, updated_at = now })
        :suffix("ON CONFLICT(token, session_id) DO UPDATE SET active_traits = excluded.active_traits, updated_at = excluded.updated_at")
        :run_with(db)
        :exec()
    db:release()

    if exec_err then return false, "Upsert failed: " .. tostring(exec_err) end
    return true, nil
end

function tokens.clear_active_traits(token)
    return tokens.set_active_traits(token, {})
end

-- Read and mutate the branch/changeset binding in one SQL statement per operation.
local function read_context(raw_token, session_id)
    local key, herr = digest(raw_token)
    if herr then return nil, herr end
    local db, db_err = sql.get(consts.db_id())
    if db_err then return nil, "Database error: " .. tostring(db_err) end
    local rows, query_err = sql.builder.select("overlay_branch", "changeset_id")
        :from("keeper_mcp_session_state")
        :where("token = ? AND session_id = ?", key, session_id)
        :run_with(db):query()
    db:release()
    if query_err then return nil, "Query failed: " .. tostring(query_err) end
    local row = rows and rows[1] or {}
    return {
        overlay_branch = row.overlay_branch ~= "" and row.overlay_branch or nil,
        changeset_id = row.changeset_id ~= "" and row.changeset_id or nil,
    }, nil
end

local function update_context(raw_token, session_id, set, delete)
    local key, herr = digest(raw_token)
    if herr then return false, herr end
    local values = { token = key, session_id = session_id, updated_at = time.now():unix() }
    local updates = {}
    for _, field in ipairs({ "overlay_branch", "changeset_id" }) do
        local value = type(set) == "table" and set[field] or nil
        local remove = false
        for _, name in ipairs(type(delete) == "table" and delete or {}) do
            if name == field then remove = true end
        end
        if remove or value ~= nil then
            values[field] = not remove and value or sql.NULL
            table.insert(updates, field .. " = excluded." .. field)
        end
    end
    if #updates == 0 then return true, nil end
    table.insert(updates, "updated_at = excluded.updated_at")
    local db, db_err = sql.get(consts.db_id())
    if db_err then return false, "Database error: " .. tostring(db_err) end
    local _, exec_err = sql.builder.insert("keeper_mcp_session_state")
        :set_map(values)
        :suffix("ON CONFLICT(token, session_id) DO UPDATE SET " .. table.concat(updates, ", "))
        :run_with(db):exec()
    db:release()
    if exec_err then return false, "Upsert failed: " .. tostring(exec_err) end
    return true, nil
end

local function valid_session_id(id)
    return type(id) == "string" and #id == 64 and not id:find("[^0-9a-f]")
end

function tokens.get_session_context(raw_token, session_id)
    if not valid_session_id(session_id) then return nil, "MCP session ID required" end
    return read_context(raw_token, session_id)
end

function tokens.update_session_context(raw_token, session_id, set, delete)
    if not valid_session_id(session_id) then return false, "MCP session ID required" end
    return update_context(raw_token, session_id, set, delete)
end

-- Existing credential-level accessors retain their unassigned state. Dispatch
-- uses only the transport binding and never inherits these legacy values.
function tokens.get_overlay_branch(raw_token)
    local binding, err = read_context(raw_token, "")
    if err then return nil, err end
    return binding.overlay_branch, nil
end

function tokens.set_overlay_branch(raw_token, branch)
    if branch == nil then return update_context(raw_token, "", nil, { "overlay_branch" }) end
    return update_context(raw_token, "", { overlay_branch = branch })
end

function tokens.clear_overlay_branch(raw_token)
    return tokens.set_overlay_branch(raw_token, nil)
end

function tokens.get_changeset_id(raw_token)
    local binding, err = read_context(raw_token, "")
    if err then return nil, err end
    return binding.changeset_id, nil
end

function tokens.set_changeset_id(raw_token, changeset_id)
    if changeset_id == nil then return update_context(raw_token, "", nil, { "changeset_id" }) end
    return update_context(raw_token, "", { changeset_id = changeset_id })
end

function tokens.clear_changeset_id(raw_token)
    return tokens.set_changeset_id(raw_token, nil)
end

return tokens
