local http = require("http")
local security = require("security")
local user_repo = require("user_repo")
local user_groups_repo = require("user_groups_repo")

local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    -- Security check - ensure user is authenticated
    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({
            success = false,
            error = "Authentication required"
        })
        return
    end

    -- Get user ID from path parameter
    local target_user_id = req:param("id")
    if not target_user_id or target_user_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = "User ID is required"
        })
        return
    end

    local current_user_id = actor:id()

    -- Cannot delete self
    if target_user_id == current_user_id then
        res:set_status(http.STATUS.FORBIDDEN)
        res:write_json({
            success = false,
            error = "Cannot delete your own account"
        })
        return
    end

    -- Check if user exists and get their info for the response
    local existing_user, get_err = user_repo.get(target_user_id)
    if get_err then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({
            success = false,
            error = get_err
        })
        return
    end

    -- Remove all user's security groups first (this handles foreign key constraints)
    local groups_removal_result, groups_err = user_groups_repo.remove_all_user_groups(target_user_id)
    if groups_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            error = "Failed to remove user's security groups: " .. groups_err
        })
        return
    end

    -- Delete the user
    local delete_result, delete_err = user_repo.delete(target_user_id)
    if delete_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            error = delete_err
        })
        return
    end

    -- Return success with deleted user info (excluding sensitive data)
    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        message = "User deleted successfully",
        deleted_user = {
            user_id = existing_user.user_id,
            email = existing_user.email,
            full_name = existing_user.full_name
        },
        groups_removed = groups_removal_result.groups_removed or 0
    })
end

return {
    handler = handler
}