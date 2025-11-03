local http = require("http")
local security = require("security")
local reader = require("reader")

local function list_workspaces_handler()
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

    local limit = tonumber(req:query("limit")) or 20
    local status_filter = req:query("status")

    if limit > 500 then
        limit = 500
    elseif limit < 1 then
        limit = 1
    end

    local workspace_reader, reader_err = reader.for_user()
    if reader_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = reader_err
        })
        return
    end

    if status_filter and status_filter ~= "" then
        workspace_reader = workspace_reader:with_statuses(status_filter)
    end

    workspace_reader = workspace_reader:limit(limit)

    local workspaces, err = workspace_reader:all()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    local total_count, count_err = workspace_reader:count()
    if count_err then
        total_count = #workspaces
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        workspaces = workspaces or {},
        count = total_count
    })
end

return {
    handler = list_workspaces_handler
}