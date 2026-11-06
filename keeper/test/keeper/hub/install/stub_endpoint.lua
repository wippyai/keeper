local http = require("http")
local install_request = require("install_request")

local function handler()
    local res = http.response()
    local req = http.request()
    install_request.respond(res, req:body(), { actor_id = "hub-install-fixture" }, "app.hub_install:stub_worker")
end

return { handler = handler }
