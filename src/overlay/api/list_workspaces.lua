local http = require("http")
local security = require("security")
local reader = require("reader")

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

    local limit = tonumber(req:query("limit")) or 20
    local offset = tonumber(req:query("offset")) or 0
    local status_filter = req:query("status")
    local include_entries = req:query("include_entries") == "true"
    local include_permissions = req:query("include_permissions") == "true"
    local include_reviews = req:query("include_reviews") == "true"
    local include_ops = req:query("include_ops") == "true"

    if limit > 100 then
        limit = 100
    elseif limit < 1 then
        limit = 1
    end

    local workspace_reader, reader_err = reader.for_user(user_id)
    if reader_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to create workspace reader: " .. reader_err
        })
        return
    end

    if status_filter and status_filter ~= "" then
        workspace_reader = workspace_reader:with_statuses(status_filter)
    end

    if include_entries then
        workspace_reader = workspace_reader:include_entries()
    end

    if include_permissions then
        workspace_reader = workspace_reader:include_permissions()
    end

    if include_reviews then
        workspace_reader = workspace_reader:include_reviews()
    end

    if include_ops then
        workspace_reader = workspace_reader:include_ops()
    end

    local workspaces, err = workspace_reader:all()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to retrieve workspaces: " .. err
        })
        return
    end

    local total_count, count_err = workspace_reader:count()
    if count_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to count workspaces: " .. count_err
        })
        return
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        workspaces = workspaces or {},
        count = total_count,
        pagination = {
            limit = limit,
            offset = offset,
            has_more = total_count > offset + limit
        }
    })
end

return {
    handler = handler
}