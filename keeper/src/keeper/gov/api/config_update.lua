local http = require("http")
local security = require("security")
local gov_consts = require("gov_consts")
local mcp_auth = require("mcp_auth")

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end
    local admin_ok, admin_err = mcp_auth.verify_admin_user(actor:id())
    if not admin_ok then
        local status, payload = mcp_auth.admin_failure(admin_err)
        res:set_status(status)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json(payload)
        return
    end

    local body, parse_err = req:body_json()
    if parse_err or type(body) ~= "table" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Invalid JSON body" })
        return
    end

    local namespaces, err = gov_consts.set_managed_namespaces(body.managed_namespaces)
    if not namespaces then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err or "Invalid managed namespaces" })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success = true,
        managed_namespaces = namespaces,
        message = "Managed namespaces updated",
    })
end

return { handler = handler }
