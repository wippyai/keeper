local http = require("http")
local security = require("security")

local auth = require("mcp_auth")
local policy = require("mcp_policy")

local function handler()
    local res = http.response()

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local presets, presets_err = policy.list_presets()
    if presets_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({ success = false, error = presets_err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        scopes = policy.list_scopes(),
        presets = presets,
        config = {
            enabled = auth.enabled(),
            url = auth.public_url(),
            path = auth.path(),
        },
    })
end

return { handler = handler }
