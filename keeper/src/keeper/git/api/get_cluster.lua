local http = require("http")
local security = require("security")
local git_client = require("git_client")

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

    local cluster, err = git_client.get_cluster(id)
    if err then
        local status = err:find("unknown") and http.STATUS.NOT_FOUND or http.STATUS.INTERNAL_ERROR
        res:set_status(status)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, cluster = cluster })
end

return { handler = handler }
