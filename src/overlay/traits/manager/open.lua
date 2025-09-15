local json = require("json")
local security = require("security")
local reader = require("reader")
local writer = require("writer")

local function handler(params)
    local response = {
        success = false,
        workspace_id = params.workspace_id,
        error = nil
    }

    if not params.workspace_id or params.workspace_id == "" then
        response.error = "Workspace ID is required"
        return response
    end

    local actor = security.actor()
    if not actor then
        response.error = "Authentication required"
        return response
    end

    local user_id = actor:id()

    -- Get workspace using fluent reader API
    local reader_instance, err = reader.for_user(user_id)
    if err then
        response.error = "Failed to create reader: " .. err
        return response
    end

    local workspace, err = reader_instance:with_workspaces(params.workspace_id)
        :include_permissions()
        :one()
    if err then
        response.error = "Failed to get workspace: " .. err
        return response
    end

    if not workspace then
        response.error = "Workspace not found: " .. params.workspace_id
        return response
    end

    -- Force status to active when opening workspace
    local status_result, status_err = writer.update_workspace(params.workspace_id, {status = "active"})
    if status_err then
        -- Log error but don't fail open - status update is best effort
        -- Workspace can still be opened successfully
    end

    -- Build permissions summary for context
    local permissions_summary = {}
    if workspace.permissions and #workspace.permissions > 0 then
        for _, perm in ipairs(workspace.permissions) do
            table.insert(permissions_summary, perm.namespace_pattern .. ":" .. perm.permission_type)
        end
    end

    -- Set up control for workspace context and public meta
    local control = {
        context = {
            session = {
                set = {
                    workspace_id = workspace.workspace_id,
                    workspace_title = workspace.title
                }
            },
            public_meta = {
                set = {
                    {
                        id = "workspace_info",
                        title = workspace.title,
                        display_name = "Workspace: " .. workspace.title,
                        type = "workspace",
                        icon = "tabler:layers-difference",
                        url = nil,
                        workspace_id = workspace.workspace_id,
                        permissions_count = #workspace.permissions
                    }
                }
            }
        }
    }

    response.success = true
    response.title = workspace.title
    response.status = "active"  -- Always active after opening
    response.description = workspace.description
    response.permissions = workspace.permissions
    response.permissions_summary = permissions_summary
    response.opened = true
    response.context_set = true
    response._control = control

    return response
end

return { handler = handler }