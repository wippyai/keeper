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

    local review_reader, reader_err = reader.for_reviews(workspace_id)
    if reader_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to create review reader: " .. reader_err
        })
        return
    end

    review_reader = review_reader:with_reviews(review_id)

    local review, err = review_reader:one()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to retrieve review: " .. err
        })
        return
    end

    if not review then
        res:set_status(http.STATUS.NOT_FOUND)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Review not found"
        })
        return
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        workspace_id = workspace_id,
        review = review
    })
end

return {
    handler = handler
}