local http = require("http")
local security = require("security")
local user_repo = require("user_repo")
local user_groups_repo = require("user_groups_repo")

local function format_timestamp(timestamp)
    if not timestamp then return nil end
    if type(timestamp) == "number" then
        return timestamp * 1000
    end
    return timestamp
end

local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({
            success = false,
            error = "Authentication required"
        })
        return
    end

    local user_id = req:param("id")
    if not user_id or user_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = "User ID is required"
        })
        return
    end

    local user, err = user_repo.get(user_id)
    if err then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    user.password_hash = nil

    user.created_at = format_timestamp(user.created_at)
    user.updated_at = format_timestamp(user.updated_at)

    local groups_result, groups_err = user_groups_repo.get_user_groups(user.user_id)
    local groups = {}
    local cleaned_groups = {}

    if groups_result and not groups_err then
        groups = groups_result.groups or {}
        for _, group_id in ipairs(groups) do
            local cleaned_name = group_id
            if string.find(group_id, ":") then
                cleaned_name = string.match(group_id, ":(.+)$") or group_id
            end
            table.insert(cleaned_groups, {
                id = group_id,
                name = cleaned_name
            })
        end
    end

    user.security_groups = groups
    user.security_groups_display = cleaned_groups

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        user = user,
        current_user_id = actor:id()
    })
end

return {
    handler = handler
}