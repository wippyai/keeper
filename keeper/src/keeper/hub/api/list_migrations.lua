local http = require("http")
local hub_service = require("hub_service")
local api_http = require("api_http")

local function query_entry_ids(req)
    local raw = req:query("entry_ids")
    if type(raw) == "table" then raw = raw[1] end
    if not raw or raw == "" then return nil end
    local out = {}
    for part in string.gmatch(tostring(raw), "([^,]+)") do
        part = string.match(part, "^%s*(.-)%s*$") or ""
        if part ~= "" then table.insert(out, part) end
    end
    return #out > 0 and out or nil
end

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    if not api_http.require_actor(res) then return end

    local result, service_err = hub_service.list_migrations({
        component = req:query("component"),
        entry_ids = query_entry_ids(req),
    })
    if not result then
        api_http.write_service_error(res, service_err)
        return
    end
    api_http.write_ok(res, result)
end

return { handler = handler }
