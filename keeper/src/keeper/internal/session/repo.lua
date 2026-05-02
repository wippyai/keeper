-- keeper.internal.session:repo
--
-- Query layer for session debug tooling. All reads are scoped to the current
-- user — the handler resolves user_id via security.actor() and passes it in.
-- Custom SQL is used for rollups and cross-table joins that vendor repos don't
-- expose directly.

local sql = require("sql")
local json = require("json")

local session_repo = require("session_repo")
local message_repo = require("message_repo")
local artifact_repo = require("artifact_repo")

local config = require("keeper_config")
local sql_dialect = require("sql_dialect")

local M = {}

local function db(): any
    local d, err = sql.get(config.app_db())
    if err then error("db: " .. err) end
    return d
end

local function db_query(d: any, statement: string, params: any): any
    return sql_dialect.query(d, statement, params)
end

-- Overview: list user's sessions with rolled-up message count and recent activity.
function M.overview(user_id, opts)
    opts = opts or {}
    local limit = math.min(math.max(tonumber(opts.limit) or 20, 1), 100)
    local offset = math.max(tonumber(opts.offset) or 0, 0)

    local d = db()
    local where_parts = { "s.user_id = ?" }
    local params = { user_id }
    if opts.status then
        table.insert(where_parts, "s.status = ?")
        table.insert(params, opts.status)
    end
    if opts.kind then
        table.insert(where_parts, "s.kind = ?")
        table.insert(params, opts.kind)
    end
    if opts.since then
        table.insert(where_parts, "s.last_message_date >= ?")
        table.insert(params, opts.since)
    end
    local where_sql = " WHERE " .. table.concat(where_parts, " AND ")

    local q = [[
        SELECT s.session_id, s.user_id, s.status, s.title, s.kind,
               s.meta, s.config, s.start_date, s.last_message_date,
               s.primary_context_id,
               COUNT(m.message_id) AS message_count,
               SUM(CASE WHEN m.type = 'user' THEN 1 ELSE 0 END) AS user_msgs,
               SUM(CASE WHEN m.type = 'assistant' THEN 1 ELSE 0 END) AS assistant_msgs,
               SUM(CASE WHEN m.type = 'function' THEN 1 ELSE 0 END) AS function_msgs,
               SUM(CASE WHEN m.type = 'artifact' THEN 1 ELSE 0 END) AS artifact_msgs
        FROM sessions s
        LEFT JOIN messages m ON m.session_id = s.session_id
    ]] .. where_sql .. [[
        GROUP BY s.session_id
        ORDER BY s.last_message_date DESC
        LIMIT ? OFFSET ?
    ]]
    table.insert(params, limit)
    table.insert(params, offset)

    local rows, err = db_query(d, q, params)
    d:release()
    if err then error("overview query: " .. tostring(err)) end

    for _, r in ipairs(rows or {}) do
        if type(r.meta) == "string" then
            local ok, v = pcall(json.decode, r.meta)
            r.meta = (ok and type(v) == "table") and v or {}
        end
        if type(r.config) == "string" then
            local ok, v = pcall(json.decode, r.config)
            r.config = (ok and type(v) == "table") and v or {}
        end
        r.message_count = tonumber(r.message_count) or 0
        r.user_msgs = tonumber(r.user_msgs) or 0
        r.assistant_msgs = tonumber(r.assistant_msgs) or 0
        r.function_msgs = tonumber(r.function_msgs) or 0
        r.artifact_msgs = tonumber(r.artifact_msgs) or 0
    end
    return rows or {}
end

-- Fetch one session, enforcing ownership.
function M.get_session(session_id, user_id)
    local s, err = session_repo.get(session_id, user_id)
    if err then return nil, err end
    return s
end

-- Paginated messages. Wraps message_repo.list_by_session (cursor-based).
function M.messages(session_id, opts)
    opts = opts or {}
    local limit = math.min(math.max(tonumber(opts.limit) or 50, 1), 500)
    local page, err = message_repo.list_by_session(
        session_id,
        limit,
        opts.cursor,
        opts.direction or "after"
    )
    if err then error("messages: " .. tostring(err)) end
    return page
end

-- Count + counts-by-type rollup for one session.
function M.message_counts(session_id)
    local d = db()
    local rows, err = db_query(d, [[
        SELECT type, COUNT(*) AS c FROM messages
        WHERE session_id = ?
        GROUP BY type
    ]], { session_id })
    d:release()
    if err then error("message_counts: " .. tostring(err)) end
    local by_type = {}
    local total = 0
    for _, r in ipairs(rows or {}) do
        local c = tonumber(r.c) or 0
        by_type[r.type] = c
        total = total + c
    end
    return { total = total, by_type = by_type }
end

-- Get one message.
function M.get_message(message_id)
    local m, err = message_repo.get(message_id)
    if err then return nil, err end
    return m
end

-- List artifacts for a session.
function M.artifacts(session_id, opts)
    opts = opts or {}
    local list, err = artifact_repo.list_by_session(
        session_id,
        tonumber(opts.limit) or 50,
        tonumber(opts.offset) or 0
    )
    if err then error("artifacts: " .. tostring(err)) end
    return list or {}
end

-- Get artifact meta (no content).
function M.get_artifact(artifact_id)
    local d = db()
    local rows, err = db_query(d, [[
        SELECT artifact_id, session_id, user_id, kind, title, meta, created_at, updated_at
        FROM artifacts
        WHERE artifact_id = ?
        LIMIT 1
    ]], { artifact_id })
    d:release()
    if err then error("get_artifact: " .. tostring(err)) end
    local r = rows and rows[1]
    if not r then return nil, "artifact not found" end
    if type(r.meta) == "string" then
        local ok, v = pcall(json.decode, r.meta)
        r.meta = (ok and type(v) == "table") and v or {}
    end
    return r
end

-- Token usage for a user within a time window, grouped by model.
function M.usage_by_model(user_id, opts)
    opts = opts or {}
    local d = db()
    local where = { "user_id = ?" }
    local params = { user_id }
    if opts.since then table.insert(where, "timestamp >= ?"); table.insert(params, opts.since) end
    if opts.until_ then table.insert(where, "timestamp < ?"); table.insert(params, opts.until_) end
    local q = [[
        SELECT model_id,
               COUNT(*) AS calls,
               SUM(prompt_tokens) AS prompt_tokens,
               SUM(completion_tokens) AS completion_tokens,
               SUM(COALESCE(thinking_tokens, 0)) AS thinking_tokens,
               SUM(COALESCE(cache_read_tokens, 0)) AS cache_read_tokens,
               SUM(COALESCE(cache_write_tokens, 0)) AS cache_write_tokens
        FROM token_usage
        WHERE ]] .. table.concat(where, " AND ") .. [[
        GROUP BY model_id
        ORDER BY (SUM(prompt_tokens) + SUM(completion_tokens)) DESC
    ]]
    local rows, err = db_query(d, q, params)
    d:release()
    if err then error("usage_by_model: " .. tostring(err)) end
    local out = {}
    for _, r in ipairs(rows or {}) do
        r.calls = tonumber(r.calls) or 0
        r.prompt_tokens = tonumber(r.prompt_tokens) or 0
        r.completion_tokens = tonumber(r.completion_tokens) or 0
        r.thinking_tokens = tonumber(r.thinking_tokens) or 0
        r.cache_read_tokens = tonumber(r.cache_read_tokens) or 0
        r.cache_write_tokens = tonumber(r.cache_write_tokens) or 0
        r.total_tokens = r.prompt_tokens + r.completion_tokens + r.thinking_tokens
        table.insert(out, r)
    end
    return out
end

-- Token usage tied to a session's primary_context_id.
function M.usage_for_session(session_id)
    local d = db()
    local rows, err = db_query(d, [[
        SELECT u.model_id, u.prompt_tokens, u.completion_tokens,
               COALESCE(u.thinking_tokens, 0) AS thinking_tokens,
               COALESCE(u.cache_read_tokens, 0) AS cache_read_tokens,
               COALESCE(u.cache_write_tokens, 0) AS cache_write_tokens,
               u.timestamp
        FROM token_usage u
        JOIN sessions s ON s.primary_context_id = u.context_id
        WHERE s.session_id = ?
        ORDER BY u.timestamp ASC
    ]], { session_id })
    d:release()
    if err then error("usage_for_session: " .. tostring(err)) end

    local total = {
        calls = 0, prompt = 0, completion = 0, thinking = 0,
        cache_read = 0, cache_write = 0, by_model = {},
    }
    for _, r in ipairs(rows or {}) do
        total.calls = total.calls + 1
        total.prompt = total.prompt + (tonumber(r.prompt_tokens) or 0)
        total.completion = total.completion + (tonumber(r.completion_tokens) or 0)
        total.thinking = total.thinking + (tonumber(r.thinking_tokens) or 0)
        total.cache_read = total.cache_read + (tonumber(r.cache_read_tokens) or 0)
        total.cache_write = total.cache_write + (tonumber(r.cache_write_tokens) or 0)
        local m = r.model_id or "unknown"
        local b = total.by_model[m]
        if not b then
            b = { model = m, calls = 0, prompt = 0, completion = 0, thinking = 0 }
            total.by_model[m] = b
        end
        b.calls = b.calls + 1
        b.prompt = b.prompt + (tonumber(r.prompt_tokens) or 0)
        b.completion = b.completion + (tonumber(r.completion_tokens) or 0)
        b.thinking = b.thinking + (tonumber(r.thinking_tokens) or 0)
    end
    return total
end

-- Substring search across current user's messages. Returns match rows with snippet.
function M.search_messages(user_id, query, opts)
    opts = opts or {}
    if type(query) ~= "string" or query == "" then
        error("search: query required")
    end
    local limit = math.min(math.max(tonumber(opts.limit) or 50, 1), 200)

    local d = db()
    local where = { "s.user_id = ?", "m.data LIKE ?" }
    local params = { user_id, "%" .. query .. "%" }
    if opts.types and #opts.types > 0 then
        local qs = {}
        for _, t in ipairs(opts.types) do
            table.insert(qs, "?"); table.insert(params, t)
        end
        table.insert(where, "m.type IN (" .. table.concat(qs, ",") .. ")")
    end
    if opts.session_id then
        table.insert(where, "m.session_id = ?")
        table.insert(params, opts.session_id)
    end
    if opts.since then
        table.insert(where, "m.date >= ?")
        table.insert(params, opts.since)
    end
    local q = [[
        SELECT m.message_id, m.session_id, m.type, m.date, m.data, s.title AS session_title
        FROM messages m
        JOIN sessions s ON s.session_id = m.session_id
        WHERE ]] .. table.concat(where, " AND ") .. [[
        ORDER BY m.date DESC
        LIMIT ?
    ]]
    table.insert(params, limit)
    local rows, err = db_query(d, q, params)
    d:release()
    if err then error("search_messages: " .. tostring(err)) end

    for _, r in ipairs(rows or {}) do
        local s = r.data or ""
        if type(s) == "string" then
            local pos = s:lower():find(query:lower(), 1, true)
            local start_i = math.max(1, (pos or 1) - 60)
            local end_i = math.min(#s, (pos or 1) + #query + 120)
            r.snippet = s:sub(start_i, end_i)
            r.data = nil
        end
    end
    return rows or {}
end

-- Bridge: dataflows launched by this user (actor_id = user_id).
function M.user_dataflows(user_id, opts)
    opts = opts or {}
    local limit = math.min(math.max(tonumber(opts.limit) or 30, 1), 200)
    local d = db()
    local where = { "f.actor_id = ?" }
    local params = { user_id }
    if opts.since then
        table.insert(where, "f.created_at >= ?")
        table.insert(params, opts.since)
    end
    local q = [[
        SELECT f.dataflow_id, f.status, f.type, f.metadata, f.created_at, f.updated_at,
               COUNT(n.node_id) AS node_count,
               SUM(CASE WHEN n.status = 'failed' THEN 1 ELSE 0 END) AS failed_nodes
        FROM dataflows f
        LEFT JOIN dataflow_nodes n ON n.dataflow_id = f.dataflow_id
        WHERE ]] .. table.concat(where, " AND ") .. [[
        GROUP BY f.dataflow_id
        ORDER BY f.created_at DESC
        LIMIT ?
    ]]
    table.insert(params, limit)
    local rows, err = db_query(d, q, params)
    d:release()
    if err then error("user_dataflows: " .. tostring(err)) end

    for _, r in ipairs(rows or {}) do
        if type(r.metadata) == "string" then
            local ok, v = pcall(json.decode, r.metadata)
            r.metadata = (ok and type(v) == "table") and v or {}
        end
        r.node_count = tonumber(r.node_count) or 0
        r.failed_nodes = tonumber(r.failed_nodes) or 0
    end
    return rows or {}
end

-- User-level stats rollup: sessions, messages, artifacts, usage totals.
function M.user_stats(user_id, opts)
    opts = opts or {}
    local d = db()

    local sq_where = { "user_id = ?" }
    local sq_params = { user_id }
    if opts.since then
        table.insert(sq_where, "last_message_date >= ?")
        table.insert(sq_params, opts.since)
    end
    local sq = "SELECT COUNT(*) AS c, status FROM sessions WHERE "
        .. table.concat(sq_where, " AND ") .. " GROUP BY status"
    local srows, err = db_query(d, sq, sq_params)
    if err then d:release(); error("user_stats sessions: " .. tostring(err)) end

    local sess = { total = 0, by_status = {} }
    for _, r in ipairs(srows or {}) do
        local c = tonumber(r.c) or 0
        sess.by_status[r.status or "unknown"] = c
        sess.total = sess.total + c
    end

    -- Messages over all user's sessions
    local mq = [[
        SELECT m.type, COUNT(*) AS c
        FROM messages m
        JOIN sessions s ON s.session_id = m.session_id
        WHERE s.user_id = ?
    ]]
    local mq_params = { user_id }
    if opts.since then
        mq = mq .. " AND m.date >= ?"
        table.insert(mq_params, opts.since)
    end
    mq = mq .. " GROUP BY m.type"
    local mrows, merr = db_query(d, mq, mq_params)
    if merr then d:release(); error("user_stats messages: " .. tostring(merr)) end
    local msgs = { total = 0, by_type = {} }
    for _, r in ipairs(mrows or {}) do
        local c = tonumber(r.c) or 0
        msgs.by_type[r.type or "unknown"] = c
        msgs.total = msgs.total + c
    end

    -- Artifact count
    local ar = [[
        SELECT COUNT(*) AS c FROM artifacts WHERE user_id = ?
    ]]
    local ar_params = { user_id }
    if opts.since then
        ar = ar .. " AND created_at >= ?"
        table.insert(ar_params, opts.since)
    end
    local arows, aerr = db_query(d, ar, ar_params)
    if aerr then d:release(); error("user_stats artifacts: " .. tostring(aerr)) end
    local artifacts_total = (arows and arows[1] and tonumber(arows[1].c)) or 0

    d:release()

    local usage = M.usage_by_model(user_id, opts)

    return {
        sessions = sess,
        messages = msgs,
        artifacts_total = artifacts_total,
        usage_by_model = usage,
    }
end

-- Decode message data for display. Strings pass through; tables -> JSON; nil/else -> "".
function M.decode_message_data(msg)
    if not msg then return "" end
    local d = msg.data
    if d == nil then return "" end
    if type(d) == "string" then return d end
    if type(d) == "table" then
        local ok, enc = pcall(json.encode, d)
        return ok and enc or ""
    end
    return tostring(d)
end

return M
