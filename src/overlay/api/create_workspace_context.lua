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

    local label = body.label
    local content = body.content
    local content_type = body.content_type
    local metadata = body.metadata

    if not label or type(label) ~= "string" or label == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Label is required and must be a non-empty string"
        })
        return
    end

    if content_type and type(content_type) ~= "string" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Content type must be a string"
        })
        return
    end

    if metadata and type(metadata) ~= "table" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Metadata must be an object"
        })
        return
    end

    local result, err = writer.create_workspace_context(workspace_id, label, content, content_type, metadata)
    if err then
        local status_code = http.STATUS.INTERNAL_ERROR
        if err:match("invalid") or err:match("required") or err:match("too long") then
            status_code = http.STATUS.BAD_REQUEST
        elseif err:match("access denied") or err:match("insufficient permissions") then
            status_code = http.STATUS.FORBIDDEN
        elseif err:match("not found") then
            status_code = http.STATUS.NOT_FOUND
        end

        res:set_status(status_code)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    local context_id = result.results[1].context_id

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.CREATED)
    res:write_json({
        success = true,
        context_id = context_id,
        workspace_id = workspace_id,
        label = label,
        content = content,
        content_type = content_type or "text/plain",
        metadata = metadata or {},
        message = "Workspace context created successfully"
    })
end

return {
    handler = handler
}