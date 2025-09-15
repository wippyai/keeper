local json = require("json")
local security = require("security")
local ctx = require("ctx")
local writer = require("writer")

local function handler(params)
    if not params.permission_id or params.permission_id == "" then
        return nil, "Permission ID is required"
    end

    if not params.confirm then
        return nil, "Confirmation required to delete permission (confirm=true)"
    end

    local actor = security.actor()
    if not actor then
        return nil, "Authentication required"
    end

    -- Get workspace from context automatically (CONTEXT-LOCKED)
    local workspace_id, err = ctx.get("workspace_id")
    if err then
        return nil, "Cannot access workspace context: " .. err
    end

    if not workspace_id or workspace_id == "" then
        return nil, "No active workspace. Use workspace manager to open one first"
    end

    local result, err = writer.delete_workspace_permission(params.permission_id)
    if err then
        return nil, "Failed to delete permission: " .. err
    end

    local output = {}
    table.insert(output, "=== PERMISSION REMOVED ===")
    table.insert(output, "Workspace: " .. workspace_id)
    table.insert(output, "Permission ID: " .. params.permission_id)
    table.insert(output, "Rows affected: " .. (result.results[1].rows_affected or 0))
    table.insert(output, "")
    table.insert(output, "Permission removed successfully from current workspace")

    return table.concat(output, "\n"), nil
end

return { handler = handler }