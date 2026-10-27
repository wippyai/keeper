local http = require("http")
local hub = require("hub")
local api_http = require("api_http")

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    if not api_http.require_actor(res) then return end

    local status, call_err = hub.auth.status()
    if not status then
        api_http.write_service_error(res, call_err)
        return
    end

    api_http.write_ok(res, { registry = status.registry or "" })
end

return { handler = handler }
