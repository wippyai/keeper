local http = require("http")
local registry = require("registry")
local helpers = require("helpers")

local function handler()
    local res = http.response()
    local req = http.request()

    if not req or not res then
        return nil, "Failed to get HTTP context"
    end

    res:set_content_type(http.CONTENT.JSON)

    local current_version, err = registry.current_version()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            message = "Failed to get current registry version: " .. err
        })
        return
    end

    local prev_version = current_version:previous()
    if not prev_version then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            message = "No previous version available to undo to"
        })
        return
    end

    local result, apply_err = helpers.apply_version_with_journal(prev_version:id())
    if not result then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            message = "Failed to apply previous version: " .. (apply_err or "unknown error")
        })
        return
    end

    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        message = "Successfully reverted to previous version",
        previous_version = current_version:id(),
        current_version = prev_version:id(),
        journaled = result.journaled
    })
end

return {
    handler = handler
}
