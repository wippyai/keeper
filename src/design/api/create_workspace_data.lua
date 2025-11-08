local http = require("http")
local security = require("security")
local writer = require("writer")

local function create_workspace_data_handler()
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
        body = {}
    end

    if not body.type then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing required field: type"
        })
        return
    end

    local ws = writer.existing_workspace(workspace_id)

    local data_spec = {
        type = body.type,
        discriminator = body.discriminator,
        content = body.content,
        content_type = body.content_type,
        status = body.status,
        metadata = body.metadata
    }

    ws:data(data_spec)

    local result, err = ws:execute()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    local data_result = result.results[1]

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.CREATED)
    res:write_json({
        success = true,
        data_id = data_result.data_id,
        workspace_id = workspace_id,
        path = data_result.path,
        depth = data_result.depth
    })
end

return {
    handler = create_workspace_data_handler
}