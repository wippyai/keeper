local http = require("http")
local security = require("security")
local git_client = require("git_client")
local consts = require("git_consts")

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

    local id = req:param("id")
    if not id or id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "cluster id required" })
        return
    end

    local body = req:body_json() or {}
    local decision = body.decision
    if not decision or not consts.is_decision(decision) then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "decision must be one of: pending, approved, skipped, pushed" })
        return
    end

    local result, err = git_client.set_decision(id, decision)
    if err then
        local status = err:find("unknown") and http.STATUS.NOT_FOUND or http.STATUS.INTERNAL_ERROR
        res:set_status(status)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, cluster_id = result.cluster_id, decision = result.decision })
end

return { handler = handler }
