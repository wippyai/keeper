-- keeper.debug.flow:repo
--
-- Query layer for dataflow debug tooling. Wraps vendor readers and adds
-- rollup queries that would be painful to compose via the reader fluent API.

local sql = require("sql")
local json = require("json")

local dataflow_repo = require("dataflow_repo")
local node_reader = require("node_reader")
local data_reader = require("data_reader")
local commit_repo = require("commit_repo")

local APP_DB = "app:db"

local M = {}

local function db()
    local d, err = sql.get(APP_DB)
    if err then error("db: " .. err) end
    return d
end

local function parse_json(s)
    if type(s) ~= "string" or s == "" then return {} end
    local ok, v = pcall(json.decode, s)
    if not ok or type(v) ~= "table" then return {} end
    return v
end

-- List recent flows with rollups in one shot. Returns up to `limit` rows.
-- filters: { status?, has_failures?, has_running?, min_nodes?, since? }
function M.overview(filters, limit)
    filters = filters or {}
    limit = limit or 30

    local d = db()
    local where_parts = {}
    local params = {}

    if filters.status then
        table.insert(where_parts, "f.status = ?")
        table.insert(params, filters.status)
    end
    if filters.since then
        table.insert(where_parts, "f.created_at >= ?")
        table.insert(params, filters.since)
    end

    local where_sql = #where_parts > 0 and (" WHERE " .. table.concat(where_parts, " AND ")) or ""
    local having_parts = {}
    if filters.has_failures then
        table.insert(having_parts, "failed_nodes > 0")
    end
    if filters.has_running then
        table.insert(having_parts, "running_nodes > 0")
    end
    if filters.min_nodes then
        table.insert(having_parts, "node_count >= " .. tonumber(filters.min_nodes))
    end
    local having_sql = #having_parts > 0 and (" HAVING " .. table.concat(having_parts, " AND ")) or ""

    local query = [[
        SELECT
          f.dataflow_id,
          f.status,
          f.type,
          f.actor_id,
          f.metadata,
          f.created_at,
          f.updated_at,
          COUNT(n.node_id) AS node_count,
          SUM(CASE WHEN n.status = 'failed' THEN 1 ELSE 0 END) AS failed_nodes,
          SUM(CASE WHEN n.status = 'running' THEN 1 ELSE 0 END) AS running_nodes,
          SUM(CASE WHEN n.type = 'userspace.dataflow.node.agent:node' THEN 1 ELSE 0 END) AS agent_nodes,
          SUM(CASE WHEN n.type = 'tool.call' THEN 1 ELSE 0 END) AS tool_calls
        FROM dataflows f
        LEFT JOIN dataflow_nodes n ON n.dataflow_id = f.dataflow_id
    ]] .. where_sql .. [[
        GROUP BY f.dataflow_id
    ]] .. having_sql .. [[
        ORDER BY f.created_at DESC
        LIMIT ?
    ]]

    table.insert(params, limit)

    local rows, err = d:query(query, params)
    d:release()
    if err then error("overview query: " .. tostring(err)) end

    for _, r in ipairs(rows or {}) do
        r.metadata = parse_json(r.metadata)
        r.node_count = tonumber(r.node_count) or 0
        r.failed_nodes = tonumber(r.failed_nodes) or 0
        r.running_nodes = tonumber(r.running_nodes) or 0
        r.agent_nodes = tonumber(r.agent_nodes) or 0
        r.tool_calls = tonumber(r.tool_calls) or 0
    end

    return rows or {}
end

-- Fetch a single flow header.
function M.get_flow(dataflow_id)
    local f, err = dataflow_repo.get(dataflow_id)
    if err then return nil, err end
    return f
end

-- All nodes of a flow, with config/metadata parsed. Cheap enough up to several
-- thousand nodes because metadata parse is inline and we return refs not copies.
function M.all_nodes(dataflow_id)
    local nodes, err = node_reader.with_dataflow(dataflow_id):all()
    if err then error("all_nodes: " .. err) end
    return nodes or {}
end

-- Status counts for a flow's nodes.
function M.status_counts(dataflow_id)
    local counts, err = node_reader.with_dataflow(dataflow_id):count_by_status()
    if err then error("status_counts: " .. err) end
    return counts or {}
end

-- Get one node.
function M.get_node(dataflow_id, node_id)
    local n, err = node_reader.with_dataflow(dataflow_id):with_nodes(node_id):one()
    if err then error("get_node: " .. err) end
    return n
end

-- All data rows scoped to a node, ordered by created_at.
function M.node_data(dataflow_id, node_id, opts)
    opts = opts or {}
    local r = data_reader.with_dataflow(dataflow_id):with_nodes(node_id)
    if opts.types then r = r:with_data_types(unpack(opts.types)) end
    r = r:fetch_options({ content = opts.content ~= false, metadata = true })
    return r:all()
end

-- All data rows scoped to the flow (no node filter).
function M.flow_data(dataflow_id, opts)
    opts = opts or {}
    local r = data_reader.with_dataflow(dataflow_id)
    if opts.types then r = r:with_data_types(unpack(opts.types)) end
    r = r:fetch_options({ content = opts.content ~= false, metadata = true })
    return r:all()
end

-- Ordered commits for a flow.
function M.commits(dataflow_id, opts)
    opts = opts or {}
    local c, err = commit_repo.list_by_dataflow(dataflow_id, {
        limit = opts.limit,
        offset = opts.offset,
    })
    if err then error("commits: " .. err) end
    return c or {}
end

-- Decode data content as value (string or parsed JSON).
function M.decode_content(row)
    if row.content == nil then return nil end
    if row.content_type == "application/json" and type(row.content) == "string" then
        local ok, v = pcall(json.decode, row.content)
        if ok then return v end
        return row.content
    end
    return row.content
end

-- Build parent -> children adjacency table for a flow's nodes.
function M.adjacency(nodes)
    local by_id = {}
    local children = {}
    local roots = {}
    for _, n in ipairs(nodes) do
        by_id[n.node_id] = n
        children[n.node_id] = children[n.node_id] or {}
        if n.parent_node_id and n.parent_node_id ~= "" then
            children[n.parent_node_id] = children[n.parent_node_id] or {}
            table.insert(children[n.parent_node_id], n.node_id)
        else
            table.insert(roots, n.node_id)
        end
    end
    return { by_id = by_id, children = children, roots = roots }
end

-- Walk ancestors of a node up to root.
function M.ancestors(nodes, node_id)
    local by_id = {}
    for _, n in ipairs(nodes) do by_id[n.node_id] = n end
    local chain = {}
    local cur = by_id[node_id]
    while cur do
        table.insert(chain, cur)
        if not cur.parent_node_id or cur.parent_node_id == "" then break end
        cur = by_id[cur.parent_node_id]
    end
    return chain
end

-- Cross-flow search. Scans dataflow_data rows for a substring match in the
-- content column, optionally constrained to data_type and time window.
-- opts: { types?=string[], since?=iso8601, limit?=int, flow_limit?=int }
-- Returns list of { dataflow_id, node_id, data_id, type, created_at, snippet }.
function M.search_content(query, opts)
    opts = opts or {}
    if type(query) ~= "string" or query == "" then
        error("search: query is required")
    end

    local d = db()
    local where = { "d.content LIKE ?" }
    local params = { "%" .. query .. "%" }

    if opts.types and #opts.types > 0 then
        local qs = {}
        for _, t in ipairs(opts.types) do
            table.insert(qs, "?"); table.insert(params, t)
        end
        table.insert(where, "d.type IN (" .. table.concat(qs, ",") .. ")")
    end
    if opts.since then
        table.insert(where, "d.created_at >= ?"); table.insert(params, opts.since)
    end

    local limit = math.min(math.max(tonumber(opts.limit) or 50, 1), 200)
    local sql_q = [[
        SELECT d.dataflow_id, d.node_id, d.data_id, d.type, d.created_at, d.content, d.content_type
        FROM dataflow_data d
        WHERE ]] .. table.concat(where, " AND ") .. [[
        ORDER BY d.created_at DESC
        LIMIT ?
    ]]
    table.insert(params, limit)

    local rows, err = d:query(sql_q, params)
    d:release()
    if err then error("search_content: " .. tostring(err)) end

    local results = {}
    for _, r in ipairs(rows or {}) do
        local content = r.content or ""
        if type(content) == "string" then
            local pos = content:lower():find(query:lower(), 1, true)
            local start_i = math.max(1, (pos or 1) - 60)
            local end_i = math.min(#content, (pos or 1) + #query + 120)
            r.snippet = content:sub(start_i, end_i)
            r.content = nil  -- drop full payload, we only kept snippet
        end
        table.insert(results, r)
    end
    return results
end

-- Cross-flow agent stats. Aggregates failed/completed counts + average iteration count
-- by agent_id (parsed from node metadata state.agent_id or config.agent).
-- opts: { since?=iso8601, limit_flows?=int }
function M.agent_stats(opts)
    opts = opts or {}
    local d = db()
    local where = { "n.type = 'userspace.dataflow.node.agent:node'" }
    local params = {}
    if opts.since then
        table.insert(where, "n.created_at >= ?"); table.insert(params, opts.since)
    end
    local sql_q = [[
        SELECT n.node_id, n.dataflow_id, n.status, n.metadata, n.config
        FROM dataflow_nodes n
        WHERE ]] .. table.concat(where, " AND ") .. [[
        ORDER BY n.created_at DESC
        LIMIT 5000
    ]]
    local rows, err = d:query(sql_q, params)
    d:release()
    if err then error("agent_stats: " .. tostring(err)) end

    local by_agent = {}
    for _, r in ipairs(rows or {}) do
        local meta = parse_json(r.metadata)
        local cfg = parse_json(r.config)
        local agent_id = (meta.state and meta.state.agent_id)
            or (cfg.agent) or (cfg.agent_id) or "unknown"
        local iters = (meta.state and tonumber(meta.state.current_iteration)) or tonumber(meta.iteration) or 0

        local bucket = by_agent[agent_id]
        if not bucket then
            bucket = { agent = agent_id, total = 0, completed = 0, failed = 0, running = 0, iter_sum = 0, iter_count = 0 }
            by_agent[agent_id] = bucket
        end
        bucket.total = bucket.total + 1
        if r.status == "completed" then bucket.completed = bucket.completed + 1
        elseif r.status == "failed" then bucket.failed = bucket.failed + 1
        elseif r.status == "running" then bucket.running = bucket.running + 1 end
        if iters > 0 then
            bucket.iter_sum = bucket.iter_sum + iters
            bucket.iter_count = bucket.iter_count + 1
        end
    end

    local list = {}
    for _, b in pairs(by_agent) do
        b.avg_iter = b.iter_count > 0 and (b.iter_sum / b.iter_count) or 0
        b.success_rate = b.total > 0 and (b.completed / b.total) or 0
        table.insert(list, b)
    end
    table.sort(list, function(a, b) return a.total > b.total end)
    return list
end

-- Cross-flow tool.call stats. Aggregates by tool name parsed from metadata.title
-- (tool.call node title is typically the tool name).
function M.tool_stats(opts)
    opts = opts or {}
    local d = db()
    local where = { "n.type = 'tool.call'" }
    local params = {}
    if opts.since then
        table.insert(where, "n.created_at >= ?"); table.insert(params, opts.since)
    end
    local sql_q = [[
        SELECT n.status, n.metadata
        FROM dataflow_nodes n
        WHERE ]] .. table.concat(where, " AND ") .. [[
        LIMIT 20000
    ]]
    local rows, err = d:query(sql_q, params)
    d:release()
    if err then error("tool_stats: " .. tostring(err)) end

    local by_tool = {}
    for _, r in ipairs(rows or {}) do
        local meta = parse_json(r.metadata)
        local name = meta.title or (meta.tool and meta.tool.name) or "unknown"
        if type(name) ~= "string" then name = tostring(name) end
        local b = by_tool[name]
        if not b then
            b = { tool = name, total = 0, completed = 0, failed = 0, running = 0 }
            by_tool[name] = b
        end
        b.total = b.total + 1
        if r.status == "completed" then b.completed = b.completed + 1
        elseif r.status == "failed" then b.failed = b.failed + 1
        elseif r.status == "running" then b.running = b.running + 1 end
    end

    local list = {}
    for _, b in pairs(by_tool) do
        b.fail_rate = b.total > 0 and (b.failed / b.total) or 0
        table.insert(list, b)
    end
    table.sort(list, function(a, b)
        if a.failed ~= b.failed then return a.failed > b.failed end
        return a.total > b.total
    end)
    return list
end

-- Flow-level rollup: completed vs failed flows, avg nodes per flow.
function M.flow_stats(opts)
    opts = opts or {}
    local d = db()
    local where_parts = {}
    local params = {}
    if opts.since then
        table.insert(where_parts, "created_at >= ?"); table.insert(params, opts.since)
    end
    local where = #where_parts > 0 and (" WHERE " .. table.concat(where_parts, " AND ")) or ""
    local sql_q = [[
        SELECT status, COUNT(*) AS cnt FROM dataflows
    ]] .. where .. [[ GROUP BY status ]]
    local rows, err = d:query(sql_q, params)
    if err then d:release(); error("flow_stats: " .. tostring(err)) end

    local agg = { by_status = {}, total = 0 }
    for _, r in ipairs(rows or {}) do
        local c = tonumber(r.cnt) or 0
        agg.by_status[r.status] = c
        agg.total = agg.total + c
    end

    local sql2 = [[
        SELECT COUNT(*) AS c FROM dataflow_nodes
    ]]
    if opts.since then
        sql2 = sql2 .. " WHERE created_at >= ?"
    end
    local r2, err2 = d:query(sql2, opts.since and { opts.since } or {})
    d:release()
    if err2 then error("flow_stats nodes: " .. tostring(err2)) end
    agg.total_nodes = r2 and r2[1] and tonumber(r2[1].c) or 0
    agg.avg_nodes_per_flow = agg.total > 0 and (agg.total_nodes / agg.total) or 0
    return agg
end

return M
