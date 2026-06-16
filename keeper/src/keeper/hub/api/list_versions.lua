local http = require("http")
local hub = require("hub")
local api_http = require("api_http")

local function tonumber_or(v, fallback)
    if v == nil or v == "" then return fallback end
    local n = tonumber(v)
    return n or fallback
end

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    if not api_http.require_actor(res) then return end

    local module_ref = req:query("module")
    if not module_ref or module_ref == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ success = false, error = "module query parameter is required" })
        return
    end

    local page = tonumber_or(req:query("page"), 1)
    local page_size = math.min(100, tonumber_or(req:query("page_size"), 30))

    local result, call_err = hub.versions.list(module_ref, { page = page, page_size = page_size })
    if not result then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({ success = false, error = tostring(call_err) })
        return
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        items = result.items or {},
        total = result.total or 0,
        page = result.page or page,
        page_size = result.page_size or page_size,
    })
end

return { handler = handler }
