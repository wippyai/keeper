local http = require("http")
local security = require("security")
local writer = require("writer")

local function delete_workspace_handler()
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

    local workspace_id = req:param("id")
    if not workspace_id or workspace_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing workspace ID"
        })
        return
    end

    local ws = writer.existing_workspace(workspace_id)
    ws:delete()

    local result, err = ws:execute()
    if err then
        local status = http.STATUS.INTERNAL_ERROR
        if err:match("not found") then
            status = http.STATUS.NOT_FOUND
        elseif err:match("access denied") then
            status = http.STATUS.FORBIDDEN
        end

        res:set_status(status)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        workspace_id = workspace_id,
        deleted = true
    })
end

return {
    handler = delete_workspace_handler
}