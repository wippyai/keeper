local http = require("http")
local hub = require("hub")
local api_http = require("api_http")
local hub_token = require("hub_token")

local DEFAULT_PAGE_SIZE = 30

local PRIVATE_VISIBILITY = { private = true, internal = true }

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

    local token, connected = hub_token.resolve()

    local query = req:query("q") or req:query("query")
    local page = tonumber_or(req:query("page"), 1)
    local page_size = math.min(100, tonumber_or(req:query("page_size"), DEFAULT_PAGE_SIZE))
    local visibility = req:query("visibility")

    -- Private/internal modules require a connected Hub identity. Without one,
    -- return an empty, well-formed page flagged not_connected so the UI prompts
    -- the user to connect instead of surfacing an error.
    if not connected and visibility and PRIVATE_VISIBILITY[visibility] then
        res:set_content_type(http.CONTENT.JSON)
        res:set_status(http.STATUS.OK)
        res:write_json({
            success = true,
            items = {},
            total = 0,
            page = page,
            page_size = page_size,
            query = query or "",
            connected = false,
            not_connected = true,
        })
        return
    end

    local result, call_err
    if query and query ~= "" then
        local opts = { page = page, page_size = page_size }
        if token then opts.token = token end
        result, call_err = hub.modules.search(query, opts)
    else
        local opts = { page = page, page_size = page_size }
        if token then opts.token = token end
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
        connected = connected,
        not_connected = not connected,
    })
end

return { handler = handler }
