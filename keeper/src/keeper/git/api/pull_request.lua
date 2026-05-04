local http = require("http")
local security = require("security")
local git_client = require("git_client")

local function write_error(res, status, message)
    res:set_status(status)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = false, error = message })
end

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        return write_error(res, http.STATUS.UNAUTHORIZED, "Authentication required")
    end

    local body = req:body_json() or {}
    local result, err = git_client.pull_request(body)
    if err then
        return write_error(res, http.STATUS.BAD_REQUEST, err)
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, result = result })
end

return { handler = handler }
