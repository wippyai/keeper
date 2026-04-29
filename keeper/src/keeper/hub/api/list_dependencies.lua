local http = require("http")
local hub_service = require("hub_service")
local api_http = require("api_http")

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    if not api_http.require_actor(res) then return end

    local result, service_err = hub_service.list_dependencies({
        component = req:query("component"),
        include_entries = api_http.query_bool(req, "entries", true),
        include_migrations = api_http.query_bool(req, "migrations", true),
    })
    if not result then
        api_http.write_service_error(res, service_err)
        return
    end
    api_http.write_ok(res, result)
end

return { handler = handler }
