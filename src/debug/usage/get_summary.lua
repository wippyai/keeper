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

    local summary, err = time_utils.query_summary(tr)
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Failed to get usage summary: " .. err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, time_range = {
            start_time = tr.start_unix,
            end_time = tr.end_unix,
            period = tr.period,
            start_formatted = tr.start_formatted,
            end_formatted = tr.end_formatted,
        },
        summary = {
            total_tokens = summary.total_tokens or 0,
            prompt_tokens = summary.prompt_tokens or 0,
            completion_tokens = summary.completion_tokens or 0,
            thinking_tokens = summary.thinking_tokens or 0,
            cache_read_tokens = summary.cache_read_tokens or 0,
            cache_write_tokens = summary.cache_write_tokens or 0,
            request_count = summary.request_count or 0,
        }, })
end

return { handler = handler }
