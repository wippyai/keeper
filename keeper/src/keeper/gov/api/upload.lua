local http = require("http")
local gov_client = require("gov_client")
local journal = require("journal")

local function handler()
    local res = http.response()
    local req = http.request()

    res:set_content_type(http.CONTENT.JSON)

    local result, err = gov_client.request_upload({}, "90s")

    if not result then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            message = err or "Unknown error during upload operation"
        })
        return
    end

    local diff_resp = journal.record_upload_diff(result)
    local journaled = diff_resp and diff_resp.ok and (diff_resp.rows_written or 0) or 0

    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        message = "Filesystem changes successfully uploaded to registry",
        stats = result.stats,
        version = result.version,
        journaled = journaled
    })
end

return {
    handler = handler
}
