local gov_client = require("gov_client")
local journal = require("journal")
local helpers = require("gov_helpers")

local function handler(input)
    return helpers.run_sync({
        tool_name = "sync_to_fs",
        direction = "registry -> FS download",
        gov_fn    = gov_client.request_download,
        diff_fn   = journal.record_download_diff,
    }, input)
end

return { handler = handler }
