local http = require("http")
local nodes_reader = require("nodes_reader")

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local q = req:query("q")
    if not q or q == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "q query param required" })
        return
    end

    local task_id = req:query("task_id")
    local limit = tonumber(req:query("limit")) or 20

    local results, err
    if task_id and task_id ~= "" then
        results, err = nodes_reader.search(task_id, q, { limit = limit })
    else
        results, err = nodes_reader.search_global(q, { limit = limit })
    end

    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, results = results, count = #(results or {}) })
end

return { handler = handler }
