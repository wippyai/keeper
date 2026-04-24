local http = require("http")

local registry_ops = require("registry_ops")

local STATUS_MAP = {
    [registry_ops.ERR.BAD_REQUEST] = http.STATUS.BAD_REQUEST,
    [registry_ops.ERR.NOT_FOUND]   = http.STATUS.NOT_FOUND,
    [registry_ops.ERR.CONFLICT]    = http.STATUS.INTERNAL_ERROR,
    [registry_ops.ERR.INTERNAL]    = http.STATUS.INTERNAL_ERROR,
}

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local result, err = registry_ops.get_entry(req:query("id"))
    if err then
        res:set_status(STATUS_MAP[err.code] or http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err.message })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success = true,
        entry   = result.entry,
        version = result.version,
    })
end

return { handler = handler }
