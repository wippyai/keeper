local json = require("json")
local security = require("security")
local ctx = require("ctx")
local writer = require("writer")

local function handler(params)
    if not params.namespace_pattern or params.namespace_pattern == "" then
        return nil, "Namespace pattern is required"
    end

    if not params.permission_type or params.permission_type == "" then
        return nil, "Permission type is required"
    end

    if params.permission_type ~= "read" and params.permission_type ~= "write" then
        return nil, "Invalid permission type: " .. params.permission_type .. " (must be 'read' or 'write')"
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

    local result, err = writer.create_workspace_permission(
        workspace_id,
        params.namespace_pattern,
        params.permission_type
    )

    if err then
        return nil, "Failed to create permission: " .. err
    end

    local output = {}
    table.insert(output, "=== PERMISSION ADDED ===")
    table.insert(output, "Workspace: " .. workspace_id)
    table.insert(output, "Pattern: " .. params.namespace_pattern)
    table.insert(output, "Type: " .. params.permission_type)
    table.insert(output, "Permission ID: " .. result.results[1].permission_id)
    table.insert(output, "")
    table.insert(output, "Permission added successfully to current workspace")

    return table.concat(output, "\n"), nil
end

return { handler = handler }