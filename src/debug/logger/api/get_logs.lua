local http = require("http")

local logger_client = require("logger_client")
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

    local count = tonumber(req:query("count")) or 500
    local filter = req:query("filter")
    if filter == "" then filter = nil end
    local reverse = req:query("reverse") ~= "false"

    local result, err = logger_client.get_logs(count, filter, reverse, "10s")
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, logs = result.logs,
        total_count = result.total_count,
        filtered = result.filtered,
        count = #result.logs, })
end

return { handler = handler }
