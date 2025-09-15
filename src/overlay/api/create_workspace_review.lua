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

    if not body.name or body.name == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing required field: name"
        })
        return
    end

    if type(body.name) ~= "string" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Name must be a string"
        })
        return
    end

    local content = body.content
    local content_type = body.content_type
    local meta = body.meta
    local status = body.status

    if content and type(content) ~= "string" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Content must be a string"
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

    if meta and type(meta) ~= "table" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Meta must be an object"
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

    local result, err = writer.create_workspace_review(workspace_id, body.name, content, content_type, meta, status)
    if err then
        local status_code = http.STATUS.INTERNAL_ERROR
        if err:match("not found") then
            status_code = http.STATUS.NOT_FOUND
        elseif err:match("access denied") or err:match("insufficient permissions") then
            status_code = http.STATUS.FORBIDDEN
        elseif err:match("invalid") or err:match("required") or err:match("too long") or err:match("duplicate") then
            status_code = http.STATUS.BAD_REQUEST
        end

        res:set_status(status_code)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    local review_id = result.results[1].review_id

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.CREATED)
    res:write_json({
        success = true,
        workspace_id = workspace_id,
        review_id = review_id,
        name = body.name,
        content_type = content_type or "text/plain",
        status = status or "draft",
        message = "Review created successfully"
    })
end

return {
    handler = handler
}