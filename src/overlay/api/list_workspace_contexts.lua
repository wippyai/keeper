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

    local limit = tonumber(req:query("limit")) or 20
    local offset = tonumber(req:query("offset")) or 0
    local label_filter = req:query("label")

    if limit > 100 then
        limit = 100
    elseif limit < 1 then
        limit = 1
    end

    local context_reader, reader_err = reader.for_context(workspace_id)
    if reader_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to create context reader: " .. reader_err
        })
        return
    end

    if label_filter and label_filter ~= "" then
        context_reader = context_reader:with_labels(label_filter)
    end

    local contexts, err = context_reader:all()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to retrieve workspace contexts: " .. err
        })
        return
    end

    local total_count, count_err = context_reader:count()
    if count_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to count workspace contexts: " .. count_err
        })
        return
    end

    -- Apply pagination manually since the reader doesn't support it directly
    local paginated_contexts = {}
    local start_idx = offset + 1
    local end_idx = math.min(offset + limit, #contexts)
    
    for i = start_idx, end_idx do
        if contexts[i] then
            table.insert(paginated_contexts, contexts[i])
        end
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        contexts = paginated_contexts,
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