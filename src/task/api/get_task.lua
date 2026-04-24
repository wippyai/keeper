local http = require("http")
local sql = require("sql")
local reader = require("task_reader")
local task_consts = require("task_consts")

local function compute_stats(task_id)
    local db, err = sql.get(task_consts.DATABASE.RESOURCE_ID)
    if err or not db then return {} end

    local nodes_q = [[
        SELECT
            COUNT(*) AS total_nodes,
            COUNT(CASE WHEN type IN ('research_task','research_result','finding') THEN 1 END) AS research_count,
            COUNT(CASE WHEN type = 'spec' THEN 1 END) AS spec_count,
            COUNT(CASE WHEN type = 'tool_call' THEN 1 END) AS tool_call_count,
            COUNT(CASE WHEN type = 'integrate_stage' THEN 1 END) AS integrate_stage_count
        FROM keeper_task_nodes WHERE task_id = ?
    ]]
    local rows = db:query(nodes_q, { task_id }) or {}
    local ws_rows = db:query([[
        SELECT COUNT(*) AS changeset_count,
               COUNT(CASE WHEN state = 'merged' THEN 1 END) AS merged_count
        FROM keeper_changesets WHERE task_id = ?
    ]], { task_id }) or {}
    db:release()

    local stats = rows[1] or {}
    if ws_rows and #ws_rows > 0 then
        stats.changeset_count = ws_rows[1].changeset_count
        stats.merged_count    = ws_rows[1].merged_count
    end
    return stats
end

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local task_id = req:param("id") or req:query("id")
    if not task_id or task_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "task id required" })
        return
    end

    local task, err = reader.get_task(task_id)
    if err then
        res:set_status(http.STATUS.NOT_FOUND)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, task = task, stats = compute_stats(task_id) })
end

return { handler = handler }
