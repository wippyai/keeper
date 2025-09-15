local http = require("http")
local json = require("json")
local env = require("env")

local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    -- Check HTTP method
    if req:method() ~= http.METHOD.POST then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Only POST method is allowed"
        })
        return
    end

    -- Check content type
    if not req:is_content_type(http.CONTENT.JSON) then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Request must be application/json"
        })
        return
    end

    -- Parse request body
    local body, err = req:body_json()
    if err then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to parse JSON body: " .. err
        })
        return
    end

    -- Validate required fields
    if not body.key or body.key == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing required field: key"
        })
        return
    end

    if not body.value then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing required field: value"
        })
        return
    end

    -- Convert value to string if it's not already
    local value = tostring(body.value)

    -- Set the environment variable
    local success, err = env.set(body.key, value)
    if not success then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to set environment variable: " .. (err or "unknown error") .. " on " .. body.key
        })
        return
    end

    -- Return success response
    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success = true,
        message = "Environment variable set successfully",
        key = body.key
    })
end

return {
    handler = handler
}
