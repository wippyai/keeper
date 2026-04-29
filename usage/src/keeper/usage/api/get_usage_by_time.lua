local http = require("http")

local time_utils = require("time_utils")
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

    local tr, verr = time_utils.validate_range(
        req:query("period"), req:query("start_time"), req:query("end_time"))
    if verr then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = verr })
        return
    end

    local interval = req:query("interval")
    if interval and interval ~= "hour" and interval ~= "day" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Invalid interval parameter. Must be one of: hour, day" })
        return
    end
    if not interval then
        interval = ((tr.end_unix - tr.start_unix) < 86400) and "hour" or "day"
    end

    local usage_data, err = time_utils.query_by_time(tr, interval)
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Failed to get usage by time: " .. err })
        return
    end

    local totals = time_utils.compute_totals(usage_data)

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, time_range = {
            start_time = tr.start_unix,
            end_time = tr.end_unix,
            period = tr.period,
            interval = interval,
            start_formatted = tr.start_formatted,
            end_formatted = tr.end_formatted,
        },
        periods = usage_data,
        totals = totals, })
end

return { handler = handler }
