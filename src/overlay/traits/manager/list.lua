local json = require("json")
local security = require("security")
local reader = require("reader")

local function handler(params)
    local response = {
        success = false,
        workspaces = {},
        error = nil
    }

    local actor = security.actor()
    if not actor then
        response.error = "Authentication required"
        return response
    end

    local user_id = actor:id()
    params = params or {}

    local workspace_reader, err = reader.for_user(user_id)
    if err then
        response.error = "Failed to create reader: " .. err
        return response
    end

    if params.status then
        workspace_reader = workspace_reader:with_statuses(params.status)
    end

    if params.limit then
        workspace_reader = workspace_reader:limit(params.limit)
    end

    local workspaces, err = workspace_reader:all()
    if err then
        response.error = "Failed to fetch workspaces: " .. err
        return response
    end

    response.success = true
    response.workspaces = workspaces or {}
    response.count = #response.workspaces
    response.filters = {
        status = params.status,
        limit = params.limit
    }

    -- Add summary info
    local total_permissions = 0
    local total_entries = 0
    for _, ws in ipairs(response.workspaces) do
        if ws.permissions then
            total_permissions = total_permissions + #ws.permissions
        end
        if ws.entries then
            total_entries = total_entries + #ws.entries
        end
    end

    response.summary = {
        total_permissions = total_permissions,
        total_entries = total_entries
    }

    return response
end

return { handler = handler }