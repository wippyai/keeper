local http = require("http")
local security = require("security")
local writer = require("writer")

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

    local workspace_id = req:param("id")
    if not workspace_id or workspace_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing workspace ID in path"
        })
        return
    end

    local body, body_err = req:body_json()
    if body_err then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Invalid JSON body: " .. body_err
        })
        return
    end

    if not body or type(body) ~= "table" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Request body must be a JSON object"
        })
        return
    end

    if not body.namespace_pattern or body.namespace_pattern == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing required field: namespace_pattern"
        })
        return
    end

    if not body.permission_type or body.permission_type == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing required field: permission_type"
        })
        return
    end

    local result, err = writer.create_workspace_permission(workspace_id, body.namespace_pattern, body.permission_type)
    if err then
        local status = http.STATUS.INTERNAL_ERROR
        if err:match("not found") then
            status = http.STATUS.NOT_FOUND
        elseif err:match("access denied") or err:match("insufficient permissions") then
            status = http.STATUS.FORBIDDEN
        elseif err:match("invalid") or err:match("required") then
            status = http.STATUS.BAD_REQUEST
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
    res:set_status(http.STATUS.CREATED)
    res:write_json({
        success = true,
        workspace_id = workspace_id,
        permission_id = result.results[1].permission_id,
        namespace_pattern = body.namespace_pattern,
        permission_type = body.permission_type,
        message = "Permission created successfully"
    })
end

return {
    handler = handler
}