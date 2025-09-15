local http = require("http")
local security = require("security")

-- Hardcoded security groups for now - later this could be made dynamic
local SECURITY_GROUPS = {
    {
        id = "app.security:admin",
        name = "Admin",
        description = "Full administrative access to all resources and actions"
    },
    {
        id = "app.security:user",
        name = "User",
        description = "Standard user access with limited administrative capabilities"
    }
}

local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    -- Security check - ensure user is authenticated
    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({
            success = false,
            error = "Authentication required"
        })
        return
    end

    -- Return the list of available security groups
    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        security_groups = SECURITY_GROUPS,
        count = #SECURITY_GROUPS
    })
end

return {
    handler = handler
}