local http = require("http")
local requirement_fill = require("requirement_fill")
local api_http = require("api_http")

return {handler = function()
    local res, req = http.response(), http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end
    if not api_http.require_admin_actor(res) then return end
    local body, body_err = api_http.json_body(req)
    if not body then api_http.write_error(res, "BAD_REQUEST", body_err); return end
    local filled, fill_err = requirement_fill.fill_gaps(body)
    if fill_err then api_http.write_service_error(res, fill_err); return end
    api_http.write_ok(res, filled)
end}
