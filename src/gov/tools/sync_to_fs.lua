local gov_client = require("gov_client")
local sys_cs = require("sys_cs")
local helpers = require("gov_helpers")

local function handler(input)
    return helpers.run_sync({
        tool_name = "sync_to_fs",
        direction = "registry -> FS download",
        gov_fn    = gov_client.request_download,
        diff_fn   = sys_cs.record_download_diff,
    }, input)
end

return { handler = handler }
