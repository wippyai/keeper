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

    local limit = tonumber(req:query("limit")) or 50
    local offset = tonumber(req:query("offset")) or 0
    local status_filter = req:query("status")

    if limit > 200 then limit = 200 end
    if limit < 1 then limit = 50 end
    if offset < 0 then offset = 0 end

    local filter_options = {
        limit = limit,
        offset = offset
    }

    if status_filter and status_filter ~= "" then
        filter_options.status = status_filter
    end

    local users, err = user_repo.list(filter_options)
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            error = "Failed to retrieve users: " .. err
        })
        return
    end

    local total_count, count_err = user_repo.count(status_filter and { status = status_filter } or {})
    if count_err then
        total_count = #users
    end

    local enhanced_users = {}
    for _, user in ipairs(users) do
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

        table.insert(enhanced_users, user)
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        users = enhanced_users,
        pagination = {
            limit = limit,
            offset = offset,
            total = total_count,
            count = #enhanced_users,
            has_more = (offset + #enhanced_users) < total_count
        },
        current_user_id = actor:id()
    })
end

return {
    handler = handler
}