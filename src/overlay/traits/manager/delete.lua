local json = require("json")
local security = require("security")
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

    if not params.confirm then
        response.error = "Deletion requires explicit confirmation (confirm=true)"
        return response
    end

    local actor = security.actor()
    if not actor then
        response.error = "Authentication required"
        return response
    end

    local result, err = writer.delete_workspace(params.workspace_id)
    if err then
        response.error = "Failed to delete workspace: " .. err
        return response
    end

    -- Set up control to flush all workspace-related context and public meta
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
    response.deleted = result.changes_made
    response.rows_affected = result.results and result.results[1] and result.results[1].rows_affected or 0
    response.message = "Workspace permanently deleted and context flushed"
    response._control = control

    return response
end

return { handler = handler }