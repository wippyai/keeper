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

    if not req:is_content_type(http.CONTENT.JSON) then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Request must be application/json" })
        return
    end

    local update_data, parse_err = req:body_json()
    if parse_err then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Failed to parse JSON body: " .. parse_err })
        return
    end

    local result, err = registry_ops.update_entry(req:query("id"), update_data)
    if err then
        res:set_status(STATUS_MAP[err.code] or http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        local body = { success = false, error = err.message }
        if err.stage then body.stage = err.stage end
        if err.changeset_id then body.changeset_id = err.changeset_id end
        res:write_json(body)
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success      = true,
        message      = result.message,
        id           = result.id,
        kind         = result.kind,
        version      = result.version,
        changeset_id = result.changeset_id,
        merge        = result.merge,
        updated      = result.updated,
    })
end

return { handler = handler }
