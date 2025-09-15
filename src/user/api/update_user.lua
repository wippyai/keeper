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

    -- Check if user exists
    local existing_user, get_err = user_repo.get(target_user_id)
    if get_err then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({
            success = false,
            error = get_err
        })
        return
    end

    -- Prepare update data (only include fields that are provided)
    local update_data = {}

    if body.email and body.email ~= "" then
        update_data.email = body.email
    end

    if body.full_name then
        update_data.full_name = body.full_name
    end

    if body.status then
        update_data.status = body.status
    end

    -- Update user if there are changes
    local updated_user = existing_user
    if next(update_data) ~= nil then
        local update_result, update_err = user_repo.update(target_user_id, update_data)
        if update_err then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:write_json({
                success = false,
                error = update_err
            })
            return
        end

        -- Get updated user data
        updated_user, get_err = user_repo.get(target_user_id)
        if get_err then
            -- This shouldn't happen, but handle gracefully
            updated_user = existing_user
        end
    end

    -- Update security groups if provided
    local assigned_groups = {}
    local groups_updated = false

    if body.security_groups and type(body.security_groups) == "table" then
        local set_result, set_err = user_groups_repo.set_user_groups(target_user_id, body.security_groups)
        if set_err then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:write_json({
                success = false,
                error = "Failed to update security groups: " .. set_err
            })
            return
        end
        assigned_groups = body.security_groups
        groups_updated = true
    else
        -- If no groups provided, get current groups
        local groups_result, groups_err = user_groups_repo.get_user_groups(target_user_id)
        if groups_result and not groups_err then
            assigned_groups = groups_result.groups or {}
        end
    end

    -- Remove sensitive data from response
    updated_user.password_hash = nil

    -- Prepare success response
    local response_data = {
        success = true,
        user = {
            user_id = updated_user.user_id,
            email = updated_user.email,
            full_name = updated_user.full_name,
            status = updated_user.status,
            created_at = updated_user.created_at,
            updated_at = updated_user.updated_at,
            security_groups = assigned_groups
        },
        message = "User updated successfully"
    }

    if groups_updated then
        response_data.message = response_data.message .. " (security groups updated)"
    end

    -- Return success
    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json(response_data)
end

return {
    handler = handler
}