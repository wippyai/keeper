local gov_client = require("gov_client")
local journal = require("journal")
local helpers = require("gov_helpers")

local function handler(input)
    return helpers.run_sync({
        tool_name = "sync_from_fs",
        direction = "FS -> registry upload",
        gov_fn    = gov_client.request_upload,
        diff_fn   = journal.record_upload_diff,
    }, input)
end

return { handler = handler }
