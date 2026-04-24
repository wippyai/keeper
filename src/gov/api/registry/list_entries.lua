local http = require("http")

local registry_ops = require("registry_ops")

local STATUS_MAP = {
    [registry_ops.ERR.BAD_REQUEST] = http.STATUS.BAD_REQUEST,
    [registry_ops.ERR.INTERNAL]    = http.STATUS.INTERNAL_ERROR,
}

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local result, err = registry_ops.list_entries({
        limit     = tonumber(req:query("limit")),
        offset    = tonumber(req:query("offset")),
        kind      = req:query("kind"),
        namespace = req:query("namespace"),
        meta_type = req:query("meta.type"),
    })
    if err then
        res:set_status(STATUS_MAP[err.code] or http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err.message })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success   = true,
        count     = result.count,
        total     = result.total,
        offset    = result.offset,
        limit     = result.limit,
        namespace = result.namespace,
        kind      = result.kind,
        meta_type = result.meta_type,
        has_more  = result.has_more,
        entries   = result.entries,
    })
end

return { handler = handler }
