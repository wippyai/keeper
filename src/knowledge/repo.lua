local sql = require("sql")
local json = require("json")
local uuid = require("uuid")
local time = require("time")
local registry = require("registry")

local consts = require("kb_consts")

local M = {}

M.TYPE = consts.NODE_TYPE
M.SOURCE = consts.SOURCE

local function get_db()
    local db = sql.get(consts.DB_ID)
    if not db then error("database " .. consts.DB_ID .. " is not available") end
    return db
end

local function now_iso()
    return time.now():format("2006-01-02T15:04:05Z")
end

local function publish(event, data)
    pcall(function()
        process.send(consts.CENTRAL, consts.TOPIC, { event = event, data = data })
    end)
end

local function parse_json_field(val, default)
    if not val or val == "" then return default end
    local result, err = json.decode(val)
    if err then return default end
    return result
end

-- KB operations

function M.create_kb(params)
    if not params.name or params.name == "" then return nil, "KB name is required" end
    local db = get_db()
    local id = uuid.v4()
    local ts = now_iso()

    local _, err = db:execute([[
        INSERT INTO keeper_kbs (id, name, description, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?)
    ]], { id, params.name, params.description or "", ts, ts })
    if err then
        local err_str = tostring(err)
        if err_str:find("UNIQUE constraint") then
            return nil, "KB with name '" .. params.name .. "' already exists"
        end
        return nil, "Failed to create KB: " .. err_str
    end

    local kb = { id = id, name = params.name, description = params.description or "", created_at = ts, updated_at = ts }
    publish(consts.EVENTS.KB_CREATED, kb)
    return kb
end

function M.list_kbs()
    local db = get_db()
    local rows, err = db:query([[
        SELECT k.*, COUNT(n.id) as node_count
        FROM keeper_kbs k LEFT JOIN keeper_kb_nodes n ON n.kb_id = k.id
        GROUP BY k.id ORDER BY k.name
    ]])
    if err then return nil, "Failed to list KBs: " .. err end

    local kbs = {}
    for _, row in ipairs(rows or {}) do
        table.insert(kbs, {
            id = row.id,
            name = row.name,
            description = row.description,
            node_count = row.node_count or 0,
            created_at = row.created_at,
            updated_at = row.updated_at,
        })
    end
    return kbs
end

function M.get_kb(id)
    local db = get_db()
    local rows, err = db:query("SELECT * FROM keeper_kbs WHERE id = ?", { id })
    if err or not rows or #rows == 0 then return nil end
    return rows[1]
end

function M.get_kb_by_name(name)
    local db = get_db()
    local rows, err = db:query("SELECT * FROM keeper_kbs WHERE name = ?", { name })
    if err or not rows or #rows == 0 then return nil end
    return rows[1]
end

function M.resolve_kb(name_or_id)
    if not name_or_id or name_or_id == "" then return nil end
    local kb = M.get_kb_by_name(name_or_id)
    if kb then return kb end
    return M.get_kb(name_or_id)
end

function M.update_kb(id, params)
    local db = get_db()
    local ts = now_iso()
    local sets, values = {}, {}

    if params.name ~= nil then table.insert(sets, "name = ?"); table.insert(values, params.name) end
    if params.description ~= nil then table.insert(sets, "description = ?"); table.insert(values, params.description) end

    if #sets == 0 then return nil, "No fields to update" end

    table.insert(sets, "updated_at = ?"); table.insert(values, ts); table.insert(values, id)
    local _, err = db:execute("UPDATE keeper_kbs SET " .. table.concat(sets, ", ") .. " WHERE id = ?", values)
    if err then return nil, "Failed to update KB: " .. err end

    publish(consts.EVENTS.KB_UPDATED, { id = id })
    return { id = id, updated_at = ts }
end

function M.delete_kb(id)
    if id == consts.DEFAULT_KB_ID then return nil, "Cannot delete the default knowledge base" end
    local db = get_db()
    local kb = M.get_kb(id)
    if not kb then return nil, "KB not found" end

    -- Cascade: delete all nodes in this KB (triggers FTS/embedding cleanup)
    local nodes = db:query("SELECT id FROM keeper_kb_nodes WHERE kb_id = ?", { id })
    for _, row in ipairs(nodes or {}) do
        M.delete(row.id)
    end

    local _, err = db:execute("DELETE FROM keeper_kbs WHERE id = ?", { id })
    if err then return nil, "Failed to delete KB: " .. err end

    publish(consts.EVENTS.KB_DELETED, { id = id, name = kb.name })
    return { id = id, name = kb.name, deleted = true }
end

-- Node operations

local function row_to_node(row)
    if not row then return nil end
    return {
        id = row.id,
        kb_id = row.kb_id,
        parent_id = row.parent_id,
        workspace_id = row.workspace_id,
        node_type = row.node_type,
        title = row.title,
        content = row.content,
        source = row.source,
        summary = row.summary or "",
        scope_namespace = row.scope_namespace,
        scope_kind = row.scope_kind,
        scope_meta_type = row.scope_meta_type,
        confidence = row.confidence,
        embedded = row.embedded == 1,
        refs = parse_json_field(row.refs, {}),
        metadata = parse_json_field(row.metadata, {}),
        created_at = row.created_at,
        updated_at = row.updated_at,
    }
end

function M.find_by_title(kb_id, title)
    if not kb_id or not title or title == "" then return nil end
    local db = get_db()
    local rows, err = db:query(
        "SELECT * FROM keeper_kb_nodes WHERE kb_id = ? AND title = ? LIMIT 1",
        { kb_id, title }
    )
    if err then return nil, "Failed to query by title: " .. err end
    if not rows or #rows == 0 then return nil end
    return row_to_node(rows[1])
end

function M.create(params)
    local kb_id = params.kb_id or consts.DEFAULT_KB_ID
    local db = get_db()
    local id = uuid.v4()
    local ts = now_iso()
    local refs_json = json.encode(params.refs or {})
    local meta_json = json.encode(params.metadata or {})
    local summary = params.summary or ""

    local _, err = db:execute([[
        INSERT INTO keeper_kb_nodes (id, kb_id, parent_id, workspace_id, node_type, title, summary, content, source, confidence, embedded, scope_namespace, scope_kind, scope_meta_type, refs, metadata, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        id, kb_id, params.parent_id, params.workspace_id,
        params.node_type or M.TYPE.PATTERN,
        params.title or "", summary, params.content or "",
        params.source or M.SOURCE.HUMAN,
        params.confidence or 1.0,
        params.scope_namespace, params.scope_kind, params.scope_meta_type,
        refs_json, meta_json, ts, ts,
    })
    if err then return nil, "Failed to create node: " .. err end

    db:execute("INSERT INTO keeper_kb_nodes_fts (id, title, content, node_type) VALUES (?, ?, ?, ?)",
        { id, params.title or "", params.content or "", params.node_type or M.TYPE.PATTERN })

    local node = {
        id = id,
        kb_id = kb_id,
        node_type = params.node_type or M.TYPE.PATTERN,
        title = params.title or "",
        content = params.content or "",
        source = params.source or M.SOURCE.HUMAN,
        workspace_id = params.workspace_id,
        created_at = ts,
    }

    publish(consts.EVENTS.NODE_CREATED, node)
    return node
end

function M.update(id, params)
    local db = get_db()
    local ts = now_iso()
    local sets, values = {}, {}

    if params.kb_id ~= nil then table.insert(sets, "kb_id = ?"); table.insert(values, params.kb_id) end
    if params.title ~= nil then table.insert(sets, "title = ?"); table.insert(values, params.title) end
    if params.summary ~= nil then table.insert(sets, "summary = ?"); table.insert(values, params.summary) end
    if params.content ~= nil then table.insert(sets, "content = ?"); table.insert(values, params.content); table.insert(sets, "embedded = ?"); table.insert(values, 0) end
    if params.node_type ~= nil then table.insert(sets, "node_type = ?"); table.insert(values, params.node_type) end
    if params.parent_id ~= nil then table.insert(sets, "parent_id = ?"); table.insert(values, params.parent_id) end
    if params.workspace_id ~= nil then table.insert(sets, "workspace_id = ?"); table.insert(values, params.workspace_id) end
    if params.source ~= nil then table.insert(sets, "source = ?"); table.insert(values, params.source) end
    if params.confidence ~= nil then table.insert(sets, "confidence = ?"); table.insert(values, params.confidence) end
    if params.scope_namespace ~= nil then table.insert(sets, "scope_namespace = ?"); table.insert(values, params.scope_namespace) end
    if params.scope_kind ~= nil then table.insert(sets, "scope_kind = ?"); table.insert(values, params.scope_kind) end
    if params.scope_meta_type ~= nil then table.insert(sets, "scope_meta_type = ?"); table.insert(values, params.scope_meta_type) end
    if params.refs ~= nil then table.insert(sets, "refs = ?"); table.insert(values, json.encode(params.refs)) end
    if params.metadata ~= nil then table.insert(sets, "metadata = ?"); table.insert(values, json.encode(params.metadata)) end

    if #sets == 0 then return nil, "No fields to update" end

    table.insert(sets, "updated_at = ?"); table.insert(values, ts); table.insert(values, id)
    local _, err = db:execute("UPDATE keeper_kb_nodes SET " .. table.concat(sets, ", ") .. " WHERE id = ?", values)
    if err then return nil, "Failed to update node: " .. err end

    db:execute("DELETE FROM keeper_kb_nodes_fts WHERE id = ?", { id })
    local node = M.get(id)
    if node then
        db:execute("INSERT INTO keeper_kb_nodes_fts (id, title, content, node_type) VALUES (?, ?, ?, ?)",
            { id, node.title, node.content, node.node_type })
        publish(consts.EVENTS.NODE_UPDATED, node)
    end
    return { id = id, updated_at = ts }
end

function M.delete(id)
    local db = get_db()
    local node = M.get(id)
    db:execute("UPDATE keeper_kb_nodes SET parent_id = NULL WHERE parent_id = ?", { id })
    db:execute("DELETE FROM keeper_kb_nodes_fts WHERE id = ?", { id })
    db:execute("DELETE FROM keeper_kb_embeddings WHERE node_id = ?", { id })
    local _, err = db:execute("DELETE FROM keeper_kb_nodes WHERE id = ?", { id })
    if err then return nil, "Failed to delete node: " .. err end
    if node then publish(consts.EVENTS.NODE_DELETED, { id = id, title = node.title }) end
    return { id = id, deleted = true }
end

function M.delete_by_workspace(workspace_id)
    local db = get_db()
    local rows = db:query("SELECT id FROM keeper_kb_nodes WHERE workspace_id = ?", { workspace_id })
    local count = 0
    for _, row in ipairs(rows or {}) do
        M.delete(row.id)
        count = count + 1
    end
    return { workspace_id = workspace_id, deleted = count }
end

function M.get(id)
    local db = get_db()
    local rows, err = db:query("SELECT * FROM keeper_kb_nodes WHERE id = ?", { id })
    if err or not rows or #rows == 0 then return nil end
    return row_to_node(rows[1])
end

function M.list(params)
    local db = get_db()
    params = params or {}
    local where, values = {}, {}

    if params.kb_id then table.insert(where, "kb_id = ?"); table.insert(values, params.kb_id) end
    if params.node_type then table.insert(where, "node_type = ?"); table.insert(values, params.node_type) end
    if params.source then table.insert(where, "source = ?"); table.insert(values, params.source) end
    if params.parent_id then table.insert(where, "parent_id = ?"); table.insert(values, params.parent_id) end
    if params.workspace_id then table.insert(where, "workspace_id = ?"); table.insert(values, params.workspace_id) end
    if params.embedded ~= nil then table.insert(where, "embedded = ?"); table.insert(values, params.embedded and 1 or 0) end
    if params.scope_namespace then table.insert(where, "scope_namespace = ?"); table.insert(values, params.scope_namespace) end
    if params.scope_kind then table.insert(where, "scope_kind = ?"); table.insert(values, params.scope_kind) end
    if params.scope_meta_type then table.insert(where, "scope_meta_type = ?"); table.insert(values, params.scope_meta_type) end

    local where_clause = #where > 0 and (" WHERE " .. table.concat(where, " AND ")) or ""
    table.insert(values, params.limit or 200)

    local rows, err = db:query("SELECT * FROM keeper_kb_nodes" .. where_clause .. " ORDER BY updated_at DESC LIMIT ?", values)
    if err then return nil, "Failed to list nodes: " .. err end

    local nodes = {}
    for _, row in ipairs(rows or {}) do table.insert(nodes, row_to_node(row)) end
    return nodes
end

function M.search_text(query, params)
    local db = get_db()
    params = params or {}
    local limit = params.limit or 20

    local kb_filter = ""
    local args = { query, limit }
    if params.kb_id then
        kb_filter = " AND n.kb_id = ?"
        args = { query, params.kb_id, limit }
    end

    local rows, err = db:query([[
        SELECT n.* FROM keeper_kb_nodes n INNER JOIN keeper_kb_nodes_fts f ON f.id = n.id
        WHERE keeper_kb_nodes_fts MATCH ?]] .. kb_filter .. [[ ORDER BY rank LIMIT ?
    ]], args)

    if err then
        local like_query = "%" .. query .. "%"
        if params.kb_id then
            rows, err = db:query("SELECT * FROM keeper_kb_nodes WHERE (title LIKE ? OR content LIKE ?) AND kb_id = ? ORDER BY updated_at DESC LIMIT ?",
                { like_query, like_query, params.kb_id, limit })
        else
            rows, err = db:query("SELECT * FROM keeper_kb_nodes WHERE title LIKE ? OR content LIKE ? ORDER BY updated_at DESC LIMIT ?",
                { like_query, like_query, limit })
        end
        if err then return nil, "Search failed: " .. err end
    end

    local nodes = {}
    for _, row in ipairs(rows or {}) do table.insert(nodes, row_to_node(row)) end
    return nodes
end

function M.search_by_embedding(query_vec, params)
    local db = get_db()
    params = params or {}
    local limit = params.limit or 10

    local rows, err = db:query([[
        SELECT node_id, distance FROM keeper_kb_embeddings
        WHERE embedding MATCH ? AND k = ?
    ]], { json.encode(query_vec), limit })
    if err then return nil, "Semantic search failed: " .. err end

    local results = {}
    for _, row in ipairs(rows or {}) do
        local node = M.get(row.node_id)
        if node then
            if not params.kb_id or node.kb_id == params.kb_id then
                node.distance = row.distance
                table.insert(results, node)
            end
        end
    end
    return results
end

function M.stats(params)
    local db = get_db()
    params = params or {}

    local kb_filter = ""
    local kb_args = {}
    if params.kb_id then
        kb_filter = " WHERE kb_id = ?"
        kb_args = { params.kb_id }
    end

    local rows, err = db:query("SELECT node_type, COUNT(*) as count FROM keeper_kb_nodes" .. kb_filter .. " GROUP BY node_type", kb_args)
    if err then return nil, err end

    local stats = { total = 0, by_type = {}, by_source = {} }
    for _, row in ipairs(rows or {}) do
        stats.by_type[row.node_type] = row.count
        stats.total = stats.total + row.count
    end

    local src_rows = db:query("SELECT source, COUNT(*) as count FROM keeper_kb_nodes" .. kb_filter .. " GROUP BY source", kb_args)
    for _, row in ipairs(src_rows or {}) do stats.by_source[row.source] = row.count end

    local emb_rows = db:query("SELECT COUNT(*) as count FROM keeper_kb_nodes WHERE embedded = 1" .. (params.kb_id and " AND kb_id = ?" or ""), kb_args)
    stats.embedded = (emb_rows and #emb_rows > 0) and emb_rows[1].count or 0

    local ws_rows = db:query("SELECT COUNT(DISTINCT workspace_id) as count FROM keeper_kb_nodes WHERE workspace_id IS NOT NULL" .. (params.kb_id and " AND kb_id = ?" or ""), kb_args)
    stats.workspace_linked = (ws_rows and #ws_rows > 0) and ws_rows[1].count or 0

    return stats
end

return M
