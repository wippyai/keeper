local http = require("http")
local security = require("security")
local writer = require("writer")
local consts = require("consts")

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

    -- Validate individual fields before building updates
    local updates = {}

    if body.title then
        if type(body.title) ~= "string" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Title must be a string"
            })
            return
        end
        if #body.title > consts.LIMITS.MAX_WORKSPACE_TITLE_LENGTH then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Title too long (max " .. consts.LIMITS.MAX_WORKSPACE_TITLE_LENGTH .. " characters)"
            })
            return
        end
        updates.title = body.title
    end

    if body.description then
        if type(body.description) ~= "string" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Description must be a string"
            })
            return
        end
        if #body.description > consts.LIMITS.MAX_WORKSPACE_DESCRIPTION_LENGTH then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Description too long (max " .. consts.LIMITS.MAX_WORKSPACE_DESCRIPTION_LENGTH .. " characters)"
            })
            return
        end
        updates.description = body.description
    end

    if body.status then
        if type(body.status) ~= "string" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Status must be a string"
            })
            return
        end
        if not consts.VALID_VALUES.WORKSPACE_STATUS[body.status] then
            -- Build list of valid statuses for error message
            local valid_statuses = {}
            for status, _ in pairs(consts.VALID_VALUES.WORKSPACE_STATUS) do
                table.insert(valid_statuses, status)
            end
            table.sort(valid_statuses)

            res:set_status(http.STATUS.BAD_REQUEST)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Invalid status '" .. body.status .. "'. Valid statuses are: " .. table.concat(valid_statuses, ", ")
            })
            return
        end
        updates.status = body.status
    end

    if body.metadata then
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

    local result, err = writer.update_workspace(workspace_id, updates)
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
        changes_made = result.changes_made,
        updated_fields = updates
    })
end

return {
    handler = handler
}