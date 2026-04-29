local http = require("http")
local gov_client = require("gov_client")
local journal = require("journal")

local function handler()
    local res = http.response()
    local req = http.request()

    if not req or not res then
        return nil, "Failed to get HTTP context"
    end

    res:set_content_type(http.CONTENT.JSON)

    local result, err = gov_client.request_download({}, "90s")

    if not result then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            message = err or "Unknown error during download operation"
        })
        return
    end

    local diff_resp = journal.record_download_diff(result)
    local journaled = diff_resp and diff_resp.ok and (diff_resp.rows_written or 0) or 0

    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        message = "Registry successfully downloaded to filesystem",
        stats = result.stats,
        version = result.version,
        journaled = journaled
    })
end

return {
    handler = handler
}
