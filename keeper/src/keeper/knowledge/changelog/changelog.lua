local sql = require("sql")
local json = require("json")
local time = require("time")
local registry = require("registry")
local gov_consts = require("gov_consts")

local consts = require("kb_consts")

local OPS = gov_consts.REGISTRY_OPERATIONS

local function get_db()
    local db_id = consts.db_id()
    local db = sql.get(db_id)
    if not db then error("database " .. db_id .. " is not available") end
    return db
end

local M = {}

local function now_iso()
    return time.now():format("2006-01-02T15:04:05Z")
end

function M.record_changeset(args)
    if not args or not args.changeset or not args.result then return end
    if not args.result.success then return end

    local db = get_db()
    local ts = now_iso()
    local version = args.result.version
    local user_id = args.user_id
    local request_id = args.request_id

    for _, op in ipairs(args.changeset) do
        local entry_id = op.entry and op.entry.id
        local namespace = entry_id and entry_id:match("(.+):.+")
        local entry_kind = op.entry and op.entry.kind
        local entry_meta_type = op.entry and op.entry.meta and op.entry.meta.type

        local op_type = "update"
        if op.kind == OPS.CREATE then op_type = "create"
        elseif op.kind == OPS.DELETE then op_type = "delete" end

        db:execute([[
            INSERT INTO keeper_changelog (version, timestamp, user_id, request_id, op_type, entry_id, entry_kind, entry_meta_type, namespace, summary, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], { version, ts, user_id, request_id, op_type, entry_id, entry_kind, entry_meta_type, namespace, "{}", ts })
    end
end

function M.list(params)
    local db = get_db()
    params = params or {}
    local where, values = {}, {}
    if params.namespace then table.insert(where, "namespace = ?"); table.insert(values, params.namespace) end
    if params.entry_id then table.insert(where, "entry_id = ?"); table.insert(values, params.entry_id) end
    if params.op_type then table.insert(where, "op_type = ?"); table.insert(values, params.op_type) end
    if params.since then table.insert(where, "timestamp >= ?"); table.insert(values, params.since) end

    local where_clause = #where > 0 and (" WHERE " .. table.concat(where, " AND ")) or ""
    table.insert(values, params.limit or 100)
    table.insert(values, params.offset or 0)

    local rows, err = db:query("SELECT * FROM keeper_changelog" .. where_clause .. " ORDER BY id DESC LIMIT ? OFFSET ?", values)
    if err then return nil, "Failed to list changelog: " .. err end

    local entries = {}
    for _, row in ipairs(rows or {}) do
        table.insert(entries, {
            id = row.id, version = row.version, timestamp = row.timestamp,
            user_id = row.user_id, request_id = row.request_id, op_type = row.op_type,
            entry_id = row.entry_id, entry_kind = row.entry_kind, entry_meta_type = row.entry_meta_type,
            namespace = row.namespace, summary = json.decode(row.summary or "{}"), created_at = row.created_at,
        })
    end
    return entries
end

function M.list_versions(params)
    local db = get_db()
    params = params or {}
    local rows, err = db:query([[
        SELECT version, MIN(timestamp) as timestamp, user_id, request_id,
            COUNT(*) as change_count,
            SUM(CASE WHEN op_type = 'create' THEN 1 ELSE 0 END) as creates,
            SUM(CASE WHEN op_type = 'update' THEN 1 ELSE 0 END) as updates,
            SUM(CASE WHEN op_type = 'delete' THEN 1 ELSE 0 END) as deletes,
            GROUP_CONCAT(DISTINCT namespace) as namespaces
        FROM keeper_changelog GROUP BY version, request_id ORDER BY version DESC LIMIT ?
    ]], { params.limit or 50 })
    if err then return nil, "Failed to list versions: " .. err end

    local versions = {}
    for _, row in ipairs(rows or {}) do
        local ns = {}
        if row.namespaces then for n in row.namespaces:gmatch("[^,]+") do table.insert(ns, n) end end
        table.insert(versions, {
            version = row.version, timestamp = row.timestamp, user_id = row.user_id,
            request_id = row.request_id, change_count = row.change_count,
            creates = row.creates, updates = row.updates, deletes = row.deletes, namespaces = ns,
        })
    end
    return versions
end

function M.stats()
    local db = get_db()
    local rows, err = db:query([[
        SELECT COUNT(*) as total, COUNT(DISTINCT version) as versions,
            COUNT(DISTINCT namespace) as namespaces,
            MIN(timestamp) as first_change, MAX(timestamp) as last_change
        FROM keeper_changelog
    ]])
    if err then return nil, err end
    return (rows and #rows > 0) and rows[1] or { total = 0, versions = 0, namespaces = 0 }
end

return M
