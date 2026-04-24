local http = require("http")

local changelog_repo = require("changelog_repo")
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

    local limit = tonumber(req:query("limit")) or 50

    local versions, err = changelog_repo.list_versions({ limit = limit })
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    local stats = changelog_repo.stats()

    versions = versions or {}
    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, versions = versions,
        count = #versions,
        stats = stats, })
end

return { handler = handler }
