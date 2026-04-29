local http = require("http")
local hub = require("hub")
local api_http = require("api_http")

local DEFAULT_PAGE_SIZE = 30

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

    local query = req:query("q") or req:query("query")
    local page = tonumber_or(req:query("page"), 1)
    local page_size = math.min(100, tonumber_or(req:query("page_size"), DEFAULT_PAGE_SIZE))

    local result, call_err
    if query and query ~= "" then
        result, call_err = hub.modules.search(query, { page = page, page_size = page_size })
    else
        local opts = { page = page, page_size = page_size }
        local visibility = req:query("visibility")
        if visibility and visibility ~= "" then opts.visibility = visibility end
        local module_type = req:query("type")
        if module_type and module_type ~= "" then opts.type = module_type end
        local sort_order = req:query("sort")
        if sort_order and sort_order ~= "" then opts.sort_order = sort_order end
        result, call_err = hub.modules.list(opts)
    end

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
        query = query or "",
    })
end

return { handler = handler }
