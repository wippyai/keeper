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

    local user_id = actor:id()

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

    local title = body.title
    local description = body.description
    local metadata = body.metadata
    local status = body.status

    if title and type(title) ~= "string" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Title must be a string"
        })
        return
    end

    if description and type(description) ~= "string" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Description must be a string"
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

    if status and type(status) ~= "string" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Status must be a string"
        })
        return
    end

    local result, err = writer.create_workspace(user_id, title, description, metadata)
    if err then
        local status_code = http.STATUS.INTERNAL_ERROR
        if err:match("invalid") or err:match("required") or err:match("too long") then
            status_code = http.STATUS.BAD_REQUEST
        elseif err:match("access denied") or err:match("insufficient permissions") then
            status_code = http.STATUS.FORBIDDEN
        end

        res:set_status(status_code)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    local workspace_id = result.results[1].workspace_id

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.CREATED)
    res:write_json({
        success = true,
        workspace_id = workspace_id,
        user_id = user_id,
        title = title,
        description = description,
        status = status or "draft",
        metadata = metadata or {},
        message = "Workspace created successfully"
    })
end

return {
    handler = handler
}