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

    local entries, err = changelog_repo.list({
        namespace = req:query("namespace"),
        entry_id = req:query("entry_id"),
        op_type = req:query("op_type"),
        since = req:query("since"),
        limit = tonumber(req:query("limit")) or 100,
        offset = tonumber(req:query("offset")) or 0,
    })
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    entries = entries or {}
    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, entries = entries, count = #entries })
end

return { handler = handler }
