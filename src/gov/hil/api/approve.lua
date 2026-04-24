local http = require("http")
local security = require("security")
local json = require("json")

local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Authentication required"
        })
        return
    end

    local user_id = actor:id()
    local request_id = req:param("request_id")

    if not request_id or request_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing request ID in path"
        })
        return
    end

    local body, body_err = req:body_json()
    local reason = nil

    if body and type(body) == "table" then
        reason = body.reason
    end

    -- Find the HIL linter process waiting for this request
    local process_name = "hil.request." .. request_id
    local linter_pid = process.registry.lookup(process_name)

    if not linter_pid then
        res:set_status(http.STATUS.NOT_FOUND)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "HIL request not found or expired"
        })
        return
    end

    -- Send approval decision to the linter process
    local success = process.send(linter_pid, "hil_decision", {
        approved = true,
        reason = reason,
        user_id = user_id
    })

    if not success then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to send approval to HIL process"
        })
        return
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        message = "Request approved successfully"
    })
end

return {
    handler = handler
}