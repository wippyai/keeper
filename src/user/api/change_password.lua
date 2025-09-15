local http = require("http")
local security = require("security")
local user_repo = require("user_repo")

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

    -- Parse request body
    local body, parse_err = req:body_json()
    if parse_err then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = "Invalid JSON in request body"
        })
        return
    end

    -- Validate required fields
    if not body.new_password or body.new_password == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = "New password is required"
        })
        return
    end

    local current_user_id = actor:id()
    local is_changing_own_password = (target_user_id == current_user_id)

    -- Check if target user exists
    local existing_user, get_err = user_repo.get(target_user_id)
    if get_err then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({
            success = false,
            error = get_err
        })
        return
    end

    -- Password confirmation logic
    if is_changing_own_password then
        -- User changing their own password - require current password
        if not body.current_password or body.current_password == "" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:write_json({
                success = false,
                error = "Current password is required when changing your own password"
            })
            return
        end

        -- Verify current password
        local password_valid, verify_err = user_repo.verify_password(target_user_id, body.current_password)
        if not password_valid then
            res:set_status(http.STATUS.FORBIDDEN)
            res:write_json({
                success = false,
                error = "Current password is incorrect"
            })
            return
        end
    else
        -- Admin changing another user's password - require admin's current password for security
        if not body.admin_password or body.admin_password == "" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:write_json({
                success = false,
                error = "Your admin password is required to change another user's password"
            })
            return
        end

        -- Verify admin's current password
        local admin_password_valid, admin_verify_err = user_repo.verify_password(current_user_id, body.admin_password)
        if not admin_password_valid then
            res:set_status(http.STATUS.FORBIDDEN)
            res:write_json({
                success = false,
                error = "Admin password is incorrect"
            })
            return
        end
    end

    -- Update the password
    local update_data = {
        password = body.new_password
    }

    local update_result, update_err = user_repo.update(target_user_id, update_data)
    if update_err then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = update_err
        })
        return
    end

    -- Prepare response message
    local message = "Password updated successfully"
    if is_changing_own_password then
        message = "Your password has been updated successfully"
    else
        message = "Password updated successfully for user: " .. existing_user.email
    end

    -- Return success
    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        message = message,
        user_id = target_user_id,
        changed_own_password = is_changing_own_password
    })
end

return {
    handler = handler
}