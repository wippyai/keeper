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

    local actor = security.actor()
    if not actor then
        response.error = "Authentication required"
        return response
    end

    local updates = {}
    if params.title then
        updates.title = params.title
    end
    if params.description then
        updates.description = params.description
    end
    if params.status then
        updates.status = params.status
    end
    if params.metadata then
        updates.metadata = params.metadata
    end

    if next(updates) == nil then
        response.error = "No valid fields to update"
        return response
    end

    local result, err = writer.update_workspace(params.workspace_id, updates)
    if err then
        response.error = "Failed to update workspace: " .. err
        return response
    end

    -- Update session context if title changed and this is the active workspace
    local control = nil
    if updates.title then
        control = {
            context = {
                session = {
                    set = {
                        workspace_title = updates.title
                    }
                },
                public_meta = {
                    update = {
                        {
                            id = "workspace_info",
                            title = updates.title,
                            display_name = "Workspace: " .. updates.title
                        }
                    }
                }
            }
        }
    end

    response.success = true
    response.changes_made = result.changes_made
    response.rows_affected = result.results and result.results[1] and result.results[1].rows_affected or 0
    response.updated_fields = updates
    response.message = "Workspace updated successfully"

    if control then
        response.context_updated = true
        response._control = control
    end

    return response
end

return { handler = handler }