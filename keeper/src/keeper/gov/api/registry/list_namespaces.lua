local http = require("http")

local registry_ops = require("registry_ops")

local function handler()
    local res = http.response()
    if not res then return nil, "Failed to get HTTP response context" end

    local result, err = registry_ops.list_namespaces()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err.message })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success    = true,
        count      = result.count,
        namespaces = result.namespaces,
    })
end

return { handler = handler }
