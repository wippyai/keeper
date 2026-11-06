local http = require("http")
local api_http = require("api_http")
local install_request = require("install_request")

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local actor = api_http.require_admin_actor(res)
    if not actor then return end

    install_request.respond(res, req:body(), { actor_id = actor:id() })
end

return { handler = handler }
