local http = require("http")

local builds = require("builds")
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

    local body = req:body_json() or {}
    local component_id = body.component_id
    if not component_id or component_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "component_id required" })
        return
    end

    local build_id, err = builds.start(component_id, {
        trigger = body.trigger or "user",
        triggered_by = actor:id(),
        session_id = body.session_id,
    })
    if not build_id then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err or "start failed" })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, build_id = build_id })
end

return { handler = handler }
