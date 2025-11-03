local http = require("http")
local security = require("security")
local reader = require("reader")

local function list_workspace_data_handler()
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

    local limit = tonumber(req:query("limit")) or 500
    local type_filter = req:query("type")
    local discriminator_filter = req:query("discriminator")
    local status_filter = req:query("status")
    local parent_id = req:query("parent_id")
    local depth = tonumber(req:query("depth"))

    if limit > 200 then
        limit = 200
    elseif limit < 1 then
        limit = 1
    end

    local data_reader, reader_err = reader.for_workspace(workspace_id)
    if reader_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = reader_err
        })
        return
    end

    if type_filter and type_filter ~= "" then
        data_reader = data_reader:with_type(type_filter)
    end

    if discriminator_filter and discriminator_filter ~= "" then
        data_reader = data_reader:with_discriminator(discriminator_filter)
    end

    if status_filter and status_filter ~= "" then
        data_reader = data_reader:with_statuses(status_filter)
    end

    if parent_id and parent_id ~= "" then
        if parent_id == "null" then
            data_reader = data_reader:with_depth(0)
        else
            data_reader = data_reader:with_parent_direct(parent_id)
        end
    end

    if depth ~= nil then
        data_reader = data_reader:with_depth(depth)
    end

    data_reader = data_reader:limit(limit):order_by_position()

    local data, err = data_reader:all()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    local total_count, count_err = data_reader:count()
    if count_err then
        total_count = #data
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        data = data or {},
        count = total_count
    })
end

return {
    handler = list_workspace_data_handler
}