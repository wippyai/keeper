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

    local body = req:body_json()
    if not body or not body.title or body.title == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "title is required" })
        return
    end

    local result, err = writer.create_task({
        title       = body.title,
        description = body.description,
        spec        = body.spec,
        actor_id    = actor:id(),
        session_id  = body.session_id,
        metadata    = body.metadata,
    }):execute()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, task_id = result.task_id })
end

return { handler = handler }
