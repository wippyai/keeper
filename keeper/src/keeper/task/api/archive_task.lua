local http = require("http")
local writer = require("task_writer")
local security = require("security")

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local task_id = req:param("id")
    if not task_id or task_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "task id required" })
        return
    end

    local body = req:body_json() or {}
    local archived = body.archived
    if archived == nil then archived = true end

    local _, err = writer.for_task(task_id)
        :update_task({ archived = archived and true or false, actor_id = actor:id() })
        :execute()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, task_id = task_id, archived = archived })
end

return { handler = handler }
