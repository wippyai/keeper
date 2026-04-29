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

    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        scopes = policy.list_scopes(),
        presets = policy.list_presets(),
        config = {
            enabled = auth.enabled(),
            public_enabled = auth.public_enabled(),
            internal_url = auth.internal_url(),
            public_url = auth.public_url(),
            public_path = auth.PUBLIC_PATH,
        },
    })
end

return { handler = handler }
