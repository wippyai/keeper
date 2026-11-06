local hub_service = require("hub_service")
local install_request = require("install_request")

local function run(raw_body, opts)
    return install_request.serve(hub_service, raw_body, opts)
end

return { run = run }
