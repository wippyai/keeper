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

    local user_data, err = time_utils.query_by_user(tr)
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Failed to get usage by user: " .. err })
        return
    end

    local totals = time_utils.compute_totals(user_data)
    time_utils.apply_percentages(user_data, totals.total_tokens)

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, time_range = {
            start_time = tr.start_unix,
            end_time = tr.end_unix,
            period = tr.period,
            start_formatted = tr.start_formatted,
            end_formatted = tr.end_formatted,
        },
        users = user_data,
        totals = totals, })
end

return { handler = handler }
