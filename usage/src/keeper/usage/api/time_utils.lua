local time = require("time")
local sql = require("sql")
local registry = require("registry")

local M = {}

M.PERIOD = {
    TODAY = "today",
    WEEK = "week",
    MONTH = "month",
    CUSTOM = "custom"
}

local TOTAL_FIELDS = {
    "prompt_tokens",
    "completion_tokens",
    "thinking_tokens",
    "cache_read_tokens",
    "cache_write_tokens",
    "total_tokens",
    "request_count",
}

function M.get_time_range(period, start_param, end_param)
    local now = time.now()
    local now_unix = now:unix()

    local start_unix, end_unix
    if period == M.PERIOD.TODAY then
        start_unix = now_unix - (now_unix % 86400)
        end_unix = now_unix
    elseif period == M.PERIOD.WEEK then
        start_unix = now_unix - (7 * 86400)
        end_unix = now_unix
    elseif period == M.PERIOD.MONTH then
        start_unix = now_unix - (30 * 86400)
        end_unix = now_unix
    else
        start_unix = tonumber(start_param) or (now_unix - 86400)
        end_unix = tonumber(end_param) or now_unix
    end

    return {
        start_unix = start_unix,
        end_unix = end_unix,
        start_iso = time.unix(start_unix, 0):utc():format(time.RFC3339),
        end_iso = time.unix(end_unix, 0):utc():format(time.RFC3339),
        start_formatted = time.unix(start_unix, 0):format(time.RFC3339),
        end_formatted = time.unix(end_unix, 0):format(time.RFC3339),
        period = period,
    }
end

-- Validates period + optional custom range. Returns (tr, nil) on success,
-- (nil, message) on bad input so handlers can return 400 directly.
function M.validate_range(period, start_param, end_param)
    period = period or M.PERIOD.TODAY
    if period ~= M.PERIOD.TODAY and period ~= M.PERIOD.WEEK
        and period ~= M.PERIOD.MONTH and period ~= M.PERIOD.CUSTOM then
        return nil, "Invalid period parameter. Must be one of: today, week, month, custom"
    end
    if period == M.PERIOD.CUSTOM and (not start_param or not end_param) then
        return nil, "Custom period requires both start_time and end_time parameters"
    end
    return M.get_time_range(period, start_param, end_param)
end

-- Aggregates token fields across a list of rows.
function M.compute_totals(rows)
    local totals = {}
    for _, f in ipairs(TOTAL_FIELDS) do totals[f] = 0 end
    for _, row in ipairs(rows or {}) do
        for _, f in ipairs(TOTAL_FIELDS) do
            totals[f] = (totals[f] or 0) + (tonumber(row[f]) or 0)
        end
    end
    return totals
end

-- Annotates each row with .percentage based on row.total_tokens / grand total.
function M.apply_percentages(rows, total_tokens)
    if not total_tokens or total_tokens <= 0 then return end
    for _, row in ipairs(rows or {}) do
        row.percentage = math.floor((row.total_tokens / total_tokens) * 10000) / 100
    end
end

function M.get_db()
    local entry, _ = registry.get("wippy.usage:target_db")
    if not entry then return nil, "usage target_db not found" end
    local db_id = entry.data and entry.data.default
    if not db_id then return nil, "no default db" end
    return sql.get(tostring(db_id))
end

function M.query_summary(tr)
    local db, err = M.get_db()
    if err then return nil, err end
    if not db then return nil, "usage db unavailable" end

    local rows, err = db:query([[
        SELECT
            COALESCE(SUM(prompt_tokens + completion_tokens), 0) as total_tokens,
            COALESCE(SUM(prompt_tokens), 0) as prompt_tokens,
            COALESCE(SUM(completion_tokens), 0) as completion_tokens,
            COALESCE(SUM(thinking_tokens), 0) as thinking_tokens,
            COALESCE(SUM(cache_read_tokens), 0) as cache_read_tokens,
            COALESCE(SUM(cache_write_tokens), 0) as cache_write_tokens,
            COUNT(*) as request_count
        FROM token_usage
        WHERE timestamp >= ? AND timestamp <= ?
    ]], { tr.start_iso, tr.end_iso })
    db:release()
    if err then return nil, err end
    return rows and rows[1] or {}
end

function M.query_by_model(tr)
    local db, err = M.get_db()
    if err then return nil, err end
    if not db then return nil, "usage db unavailable" end

    local rows, err = db:query([[
        SELECT model_id,
            COALESCE(SUM(prompt_tokens + completion_tokens), 0) as total_tokens,
            COALESCE(SUM(prompt_tokens), 0) as prompt_tokens,
            COALESCE(SUM(completion_tokens), 0) as completion_tokens,
            COALESCE(SUM(thinking_tokens), 0) as thinking_tokens,
            COALESCE(SUM(cache_read_tokens), 0) as cache_read_tokens,
            COALESCE(SUM(cache_write_tokens), 0) as cache_write_tokens,
            COUNT(*) as request_count
        FROM token_usage
        WHERE timestamp >= ? AND timestamp <= ?
        GROUP BY model_id
        ORDER BY total_tokens DESC
    ]], { tr.start_iso, tr.end_iso })
    db:release()
    if err then return nil, err end
    return rows or {}
end

function M.query_by_user(tr)
    local db, err = M.get_db()
    if err then return nil, err end
    if not db then return nil, "usage db unavailable" end

    local rows, err = db:query([[
        SELECT user_id,
            COALESCE(SUM(prompt_tokens + completion_tokens), 0) as total_tokens,
            COALESCE(SUM(prompt_tokens), 0) as prompt_tokens,
            COALESCE(SUM(completion_tokens), 0) as completion_tokens,
            COALESCE(SUM(thinking_tokens), 0) as thinking_tokens,
            COALESCE(SUM(cache_read_tokens), 0) as cache_read_tokens,
            COALESCE(SUM(cache_write_tokens), 0) as cache_write_tokens,
            COUNT(*) as request_count
        FROM token_usage
        WHERE timestamp >= ? AND timestamp <= ?
        GROUP BY user_id
        ORDER BY total_tokens DESC
    ]], { tr.start_iso, tr.end_iso })
    db:release()
    if err then return nil, err end
    return rows or {}
end

function M.query_by_time(tr, interval)
    local db, err = M.get_db()
    if err then return nil, err end
    if not db then return nil, "usage db unavailable" end

    local fmt
    if interval == "hour" then
        fmt = "%Y-%m-%dT%H:00:00Z"
    elseif interval == "day" then
        fmt = "%Y-%m-%dT00:00:00Z"
    else
        fmt = "%Y-%m-%dT00:00:00Z"
    end

    local rows, err = db:query([[
        SELECT strftime(']] .. fmt .. [[', timestamp) as time_period,
            COALESCE(SUM(prompt_tokens + completion_tokens), 0) as total_tokens,
            COALESCE(SUM(prompt_tokens), 0) as prompt_tokens,
            COALESCE(SUM(completion_tokens), 0) as completion_tokens,
            COALESCE(SUM(thinking_tokens), 0) as thinking_tokens,
            COALESCE(SUM(cache_read_tokens), 0) as cache_read_tokens,
            COALESCE(SUM(cache_write_tokens), 0) as cache_write_tokens,
            COUNT(*) as request_count
        FROM token_usage
        WHERE timestamp >= ? AND timestamp <= ?
        GROUP BY time_period
        ORDER BY time_period
    ]], { tr.start_iso, tr.end_iso })
    db:release()
    if err then return nil, err end
    return rows or {}
end

return M
