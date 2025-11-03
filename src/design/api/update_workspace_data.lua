local http = require("http")
local security = require("security")
local writer = require("writer")

local function update_workspace_data_handler()
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

    local data_id = req:param("data_id")
    if not data_id or data_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing data ID"
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
            error = "Request body must be JSON object"
        })
        return
    end

    local updates = {}
    if body.type then
        updates.type = body.type
    end
    if body.discriminator ~= nil then
        updates.discriminator = body.discriminator
    end
    if body.content ~= nil then
        updates.content = body.content
    end
    if body.content_type then
        updates.content_type = body.content_type
    end
    if body.status ~= nil then
        updates.status = body.status
    end
    if body.position ~= nil then
        updates.position = body.position
    end
    if body.metadata then
        updates.metadata = body.metadata
    end

    if next(updates) == nil then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "No fields to update"
        })
        return
    end

    local ws = writer.existing_workspace(workspace_id)
    ws:update_data(data_id, updates)

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

    local data_result = result.results[1]

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        data_id = data_id,
        workspace_id = data_result.workspace_id,
        changes_made = result.changes_made
    })
end

return {
    handler = update_workspace_data_handler
}