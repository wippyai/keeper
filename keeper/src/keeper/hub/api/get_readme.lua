local http = require("http")
local hub = require("hub")
local api_http = require("api_http")
local hub_token = require("hub_token")

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

    local opts = {}
    local version = req:query("version")
    if version and version ~= "" then opts.version = version end
    local token = hub_token.resolve()
    if token then opts.token = token end

    local result, call_err = hub.modules.readme(module_ref, opts)
    if not result then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({ success = false, error = tostring(call_err) })
        return
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        content = result.content or "",
        filename = result.filename or "",
        version = result.version or version or "",
    })
end

return { handler = handler }
