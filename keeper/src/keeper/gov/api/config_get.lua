local http = require("http")
local security = require("security")
local gov_consts = require("gov_consts")
local mcp_auth = require("mcp_auth")

local function handler()
    local res = http.response()
    if not res then return nil, "Failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end
    local admin_ok, admin_err = mcp_auth.verify_admin_user(actor:id())
    if not admin_ok then
        res:set_status(http.STATUS.FORBIDDEN)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Admin required", details = admin_err })
        return
    end

    local config = gov_consts.get_config()
    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success = true,
        managed_namespaces = config.managed_namespaces,
        linter_level = config.linter_level,
        source_fs_id = config.source_fs_id,
        process_host = config.process_host,
        env_ids = gov_consts.ENV_IDS,
    })
end

return { handler = handler }
