local json = require("json")
local security = require("security")
local writer = require("writer")

local function handler(params)
    local response = {
        success = false,
        workspace_id = nil,
        error = nil
    }

    if not params.title or params.title == "" then
        response.error = "Workspace title is required"
        return response
    end

    if not params.permissions or type(params.permissions) ~= "table" or #params.permissions == 0 then
        response.error = "At least one permission is required"
        return response
    end

    -- Validate permissions
    for i, perm in ipairs(params.permissions) do
        if not perm.namespace_pattern or perm.namespace_pattern == "" then
            response.error = "Permission " .. i .. " missing namespace_pattern"
            return response
        end
        if not perm.permission_type or perm.permission_type == "" then
            response.error = "Permission " .. i .. " missing permission_type"
            return response
        end
        if perm.permission_type ~= "read" and perm.permission_type ~= "write" then
            response.error = "Permission " .. i .. " invalid permission_type: " .. perm.permission_type .. " (must be 'read' or 'write')"
            return response
        end
    end

    local actor = security.actor()
    if not actor then
        response.error = "Authentication required"
        return response
    end

    -- Create workspace first
    local result, err = writer.create_workspace(
        params.title,
        params.description,
        params.metadata
    )

    if err then
        response.error = "Failed to create workspace: " .. err
        return response
    end

    local workspace_id = result.results[1].workspace_id

    -- Create permissions for the workspace
    for _, perm in ipairs(params.permissions) do
        local perm_result, perm_err = writer.create_workspace_permission(
            workspace_id,
            perm.namespace_pattern,
            perm.permission_type
        )
        if perm_err then
            response.error = "Failed to create permission: " .. perm_err
            return response
        end
    end

    -- Auto-transition to active status after creation
    local status_result, status_err = writer.update_workspace(workspace_id, {status = "active"})
    if status_err then
        -- Log error but don't fail creation - status update is best effort
        -- Workspace is still created successfully
    end

    -- Set up control for automatic context and public meta
    local control = {
        context = {
            session = {
                set = {
                    workspace_id = workspace_id,
                    workspace_title = params.title
                }
            },
            public_meta = {
                set = {
                    {
                        id = "workspace_info",
                        title = params.title,
                        display_name = "Workspace: " .. params.title,
                        type = "workspace",
                        icon = "tabler:layers-difference",
                        url = nil,
                        workspace_id = workspace_id
                    }
                }
            }
        }
    }

    response.success = true
    response.workspace_id = workspace_id
    response.title = params.title
    response.permissions = params.permissions
    response.status = "active"  -- Always active after creation
    response.description = params.description
    response.created = true
    response.context_set = true
    response._control = control

    return response
end

return { handler = handler }