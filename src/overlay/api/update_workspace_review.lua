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

    local review_id = req:param("review_id")
    if not review_id or review_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing review ID in path"
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

    if body.content ~= nil then
        if type(body.content) ~= "string" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Content must be a string"
            })
            return
        end
        updates.content = body.content
    end

    if body.content_type ~= nil then
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

    if body.meta ~= nil then
        if type(body.meta) ~= "table" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Meta must be an object"
            })
            return
        end
        updates.meta = body.meta
    end

    if body.status ~= nil then
        if type(body.status) ~= "string" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Status must be a string"
            })
            return
        end
        updates.status = body.status
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

    local result, err = writer.update_workspace_review(review_id, updates)
    if err then
        local status_code = http.STATUS.INTERNAL_ERROR
        if err:match("not found") then
            status_code = http.STATUS.NOT_FOUND
        elseif err:match("access denied") or err:match("insufficient permissions") then
            status_code = http.STATUS.FORBIDDEN
        elseif err:match("invalid") or err:match("required") then
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

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        workspace_id = workspace_id,
        review_id = review_id,
        changes_made = result.changes_made,
        updated_fields = updates,
        message = "Review updated successfully"
    })
end

return {
    handler = handler
}