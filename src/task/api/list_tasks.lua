local http = require("http")
local reader = require("task_reader")

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local q = reader.tasks()
    if req:query("status") then q = q:with_status(req:query("status")) end
    if req:query("actor_id") then q = q:with_actor(req:query("actor_id")) end
    local archived_q = req:query("archived")
    if archived_q == "true" or archived_q == "1" then
        q = q:with_archived(true)
    elseif archived_q == "all" then
        q = q:with_archived(nil)
    end
    q = q:limit(tonumber(req:query("limit")) or 100)

    local tasks, err = q:all()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, tasks = tasks, count = #tasks })
end

return { handler = handler }
