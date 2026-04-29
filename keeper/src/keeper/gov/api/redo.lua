local http = require("http")
local registry = require("registry")
local helpers = require("helpers")

local function find_next_version(current_id)
    local history = registry.history()
    if not history then return nil, "Registry history unavailable" end
    local versions, hist_err = history:versions()
    if hist_err then return nil, "Failed to get registry versions: " .. hist_err end
    local next_id = current_id + 1
    for _, v in ipairs(versions) do
        if tonumber(v:id()) == next_id then return v, nil end
    end
    return nil, "No version with ID " .. next_id .. " found (cannot redo)"
end

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

    local current_id = tonumber(current_version:id())
    if not current_id then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            message = "Failed to parse current version ID as a number"
        })
        return
    end

    local next_version, find_err = find_next_version(current_id)
    if not next_version then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ success = false, message = find_err })
        return
    end

    local result, apply_err = helpers.apply_version_with_journal(next_version:id())
    if not result then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            message = "Failed to apply next version: " .. (apply_err or "unknown error")
        })
        return
    end

    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        message = "Successfully advanced to newer version",
        previous_version = current_version:id(),
        current_version = next_version:id(),
        journaled = result.journaled
    })
end

return {
    handler = handler
}
