local http = require("http")
local planner = require("planner")
local api_http = require("api_http")

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local actor = api_http.require_admin_actor(res)
    if not actor then return end

    local body, body_err = api_http.json_body(req)
    if not body then
        api_http.write_error(res, "BAD_REQUEST", body_err)
        return
    end

    local result, service_err = planner.plan_install(body)
    if not result then
        api_http.write_service_error(res, service_err)
        return
    end
    api_http.write_ok(res, result)
end

return { handler = handler }
