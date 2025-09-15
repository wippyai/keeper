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

    local context_id = req:param("context_id")
    if not context_id or context_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing context ID in path"
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

    local updates = {}

    if body.label then
        if type(body.label) ~= "string" or body.label == "" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Label must be a non-empty string"
            })
            return
        end
        updates.label = body.label
    end

    if body.content ~= nil then
        updates.content = body.content
    end

    if body.content_type then
        if type(body.content_type) ~= "string" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Content type must be a string"
            })
            return
        end
        updates.content_type = body.content_type
    end

    if body.metadata then
        if type(body.metadata) ~= "table" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Metadata must be an object"
            })
            return
        end
        updates.metadata = body.metadata
    end

    if next(updates) == nil then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "No valid fields to update"
        })
        return
    end

    local result, err = writer.update_workspace_context(context_id, updates)
    if err then
        local status = http.STATUS.INTERNAL_ERROR
        if err:match("not found") then
            status = http.STATUS.NOT_FOUND
        elseif err:match("access denied") then
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
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        context_id = context_id,
        workspace_id = workspace_id,
        changes_made = result.changes_made,
        updated_fields = updates,
        message = "Workspace context updated successfully"
    })
end

return {
    handler = handler
}