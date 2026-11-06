local install_request = require("install_request")
local stub_service = require("stub_service")

local function run(raw_body, opts)
    return install_request.serve(stub_service, raw_body, opts)
end

return { run = run }
