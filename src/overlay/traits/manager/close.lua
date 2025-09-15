local json = require("json")
local security = require("security")
local reader = require("reader")
local writer = require("writer")
local ctx = require("ctx")

local function handler(params)
    local response = {
        success = false,
        error = nil
    }

    local actor = security.actor()
    if not actor then
        response.error = "Authentication required"
        return response
    end

    if not params.confirm then
        response.error = "Confirmation required to close workspace context"
        return response
    end

    -- Get current workspace to check status for transition
    local workspace_id, ctx_err = ctx.get("workspace_id")
    if not ctx_err and workspace_id and workspace_id ~= "" then
        -- Get workspace status to determine transition
        local reader_instance, reader_err = reader.for_user(actor:id())
        if not reader_err then
            local workspace, workspace_err = reader_instance:with_workspaces(workspace_id):one()
            if not workspace_err and workspace and workspace.status == "active" then
                -- Transition active → archived
                local status_result, status_err = writer.update_workspace(workspace_id, {status = "archived"})
                if status_err then
                    -- Log error but don't fail close - status update is best effort
                end
            end
            -- Other statuses remain unchanged
        end
    end

    -- Set up control to clear workspace context and public meta
    local control = {
        context = {
            session = {
                delete = {
                    "workspace_id",
                    "workspace_title"
                }
            },
            public_meta = {
                clear = "workspace"  -- Clear all workspace type entries
            }
        }
    }

    response.success = true
    response.context_cleared = true
    response.message = "Workspace context cleared"
    response._control = control

    return response
end

return { handler = handler }