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

    local limit = tonumber(req:query("limit")) or 50
    local offset = tonumber(req:query("offset")) or 0

    if limit > 200 then
        limit = 200
    elseif limit < 1 then
        limit = 1
    end

    local ops_reader, reader_err = reader.for_ops(workspace_id)
    if reader_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to create ops reader: " .. reader_err
        })
        return
    end

    local ops, err = ops_reader:all()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to retrieve ops: " .. err
        })
        return
    end

    local total_count, count_err = ops_reader:count()
    if count_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to count ops: " .. count_err
        })
        return
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        workspace_id = workspace_id,
        ops = ops or {},
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