local http = require("http")
local security = require("security")
local crypto = require("crypto")
local user_repo = require("user_repo")
local user_groups_repo = require("user_groups_repo")
local consts = require("consts")

local function generate_user_id(email)
    local username = string.match(email or "", "^([^@]+)@")
    if not username or username == "" then
        local random_suffix, _ = crypto.random.string(8, "0123456789abcdefghijklmnopqrstuvwxyz")
        return "user-" .. (random_suffix or "default")
    end
    return string.lower(username)
end

local function generate_password()
    local password, err = crypto.random.string(16, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*")
    if err then
        return nil, "Failed to generate password: " .. err
    end
    return password
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

    local body, parse_err = req:body_json()
    if parse_err then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = "Invalid JSON in request body"
        })
        return
    end

    if not body.email or body.email == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = "Email is required"
        })
        return
    end

    local user_id = generate_user_id()

    local password = body.password
    local generated_password = false
    if not password or password == "" then
        local gen_pass, gen_err = generate_password()
        if gen_err then
            res:set_status(http.STATUS.INTERNAL_ERROR)
            res:write_json({
                success = false,
                error = gen_err
            })
            return
        end
        password = gen_pass
        generated_password = true
    end

    local user_data = {
        user_id = user_id,
        email = body.email,
        full_name = body.full_name or "",
        password = password,
        status = body.status or consts.DEFAULTS.USER_STATUS
    }

    local created_user, create_err = user_repo.create(user_data)
    if create_err then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = create_err
        })
        return
    end

    local assigned_groups = {}
    if body.security_groups and type(body.security_groups) == "table" then
        for _, group_id in ipairs(body.security_groups) do
            if group_id and group_id ~= "" then
                local assign_result, assign_err = user_groups_repo.assign_user_to_group(user_id, group_id)
                if assign_result and not assign_err then
                    table.insert(assigned_groups, group_id)
                else
                    print("Warning: Failed to assign user to group " .. group_id .. ": " .. (assign_err or "unknown error"))
                end
            end
        end
    end

    if #assigned_groups == 0 then
        local config = consts.get_config()
        if config.default_group_id then
            local assign_result, assign_err = user_groups_repo.assign_user_to_group(user_id, config.default_group_id)
            if assign_result and not assign_err then
                table.insert(assigned_groups, config.default_group_id)
            end
        end
    end

    local response_data = {
        success = true,
        user = {
            user_id = created_user.user_id,
            email = created_user.email,
            full_name = created_user.full_name,
            status = created_user.status,
            created = created_user.created,
            security_groups = assigned_groups
        }
    }

    if generated_password then
        response_data.generated_password = password
        response_data.message = "User created successfully. Please save the generated password as it won't be shown again."
    else
        response_data.message = "User created successfully"
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.CREATED)
    res:write_json(response_data)
end

return {
    handler = handler
}