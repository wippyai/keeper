local json = require("json")
local ctx = require("ctx")
local design_reader = require("design_reader")
local design_writer = require("design_writer")
local consts = require("consts")

local function get_active_workspace()
    local workspace_id, err = ctx.get("active_workspace_id")
    if not err and workspace_id and workspace_id ~= "" then
        return workspace_id
    end
    return nil
end

local function open_operation(params)
    if not params.workspace_id or params.workspace_id == "" then
        return nil, "workspace_id required for open"
    end

    local reader, err = design_reader.for_user()
    if err then
        return nil, err
    end

    reader = reader:with_workspaces(params.workspace_id)
    local workspace, err = reader:one()

    if err then
        return nil, err
    end

    if not workspace then
        return nil, "Workspace not found"
    end

    local control = {
        context = {
            session = {
                set = {
                    active_workspace_id = params.workspace_id
                }
            },
            public_meta = {
                set = {
                    {
                        id = "workspace_info",
                        title = workspace.title or params.workspace_id,
                        display_name = "Workspace: " .. (workspace.title or params.workspace_id),
                        type = "workspace",
                        icon = "tabler:layout-dashboard",
                        url = nil,
                        workspace_id = params.workspace_id
                    }
                }
            }
        }
    }

    return {
        workspace_id = params.workspace_id,
        title = workspace.title,
        status = workspace.status,
        message = "Workspace opened",
        _control = control
    }
end

local function close_operation()
    local control = {
        context = {
            session = {
                delete = {"active_workspace_id"}
            },
            public_meta = {
                clear = "workspace"
            }
        }
    }

    return {
        message = "Workspace closed",
        _control = control
    }
end

local function create_operation(params)
    if not params.title or params.title == "" then
        return nil, "title required for create"
    end

    local ws = design_writer.workspace(
        params.title,
        params.description,
        nil
    )

    local result, err = ws:execute()
    if err then
        return nil, "Failed to create workspace: " .. err
    end

    return {
        workspace_id = result.workspace_id,
        title = params.title,
        description = params.description,
        status = "draft",
        message = "Workspace created (use open to activate)"
    }
end

local function delete_operation(params)
    if not params.workspace_id or params.workspace_id == "" then
        return nil, "workspace_id required for delete"
    end

    local active_workspace = get_active_workspace()
    if active_workspace == params.workspace_id then
        return nil, "Cannot delete active workspace (close first)"
    end

    local ws = design_writer.existing_workspace(params.workspace_id)
    ws:delete()

    local result, err = ws:execute()
    if err then
        return nil, "Failed to delete workspace: " .. err
    end

    return {
        workspace_id = params.workspace_id,
        deleted = result.changes_made,
        message = "Workspace deleted"
    }
end

local function list_operation(params)
    local reader, err = design_reader.for_user()
    if err then
        return nil, err
    end

    if params.status then
        reader = reader:with_statuses(params.status)
    end

    if params.limit and params.limit > 0 then
        reader = reader:limit(params.limit)
    end

    local workspaces, err = reader:all()
    if err then
        return nil, err
    end

    local active_workspace = get_active_workspace()

    local lines = {}
    table.insert(lines, "Workspaces (" .. #workspaces .. ")")
    if active_workspace then
        table.insert(lines, "Active: " .. active_workspace)
    end
    table.insert(lines, "")

    for _, ws in ipairs(workspaces) do
        local marker = ws.workspace_id == active_workspace and "* " or "  "
        table.insert(lines, marker .. ws.workspace_id)
        table.insert(lines, "    Title: " .. (ws.title or ""))
        table.insert(lines, "    Status: " .. ws.status)
        if ws.description and ws.description ~= "" then
            table.insert(lines, "    Description: " .. ws.description)
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

local function update_operation(params)
    if not params.workspace_id or params.workspace_id == "" then
        return nil, "workspace_id required for update"
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

    if not next(updates) then
        return nil, "At least one field to update required (title, description, status, metadata)"
    end

    local ws = design_writer.existing_workspace(params.workspace_id)
    ws:update(updates)

    local result, err = ws:execute()
    if err then
        return nil, "Failed to update workspace: " .. err
    end

    return {
        workspace_id = params.workspace_id,
        updated = result.changes_made,
        message = "Workspace updated"
    }
end

local function get_operation(params)
    if not params.workspace_id or params.workspace_id == "" then
        return nil, "workspace_id required for get"
    end

    local reader, err = design_reader.for_user()
    if err then
        return nil, err
    end

    reader = reader:with_workspaces(params.workspace_id)
    local workspace, err = reader:one()

    if err then
        return nil, err
    end

    if not workspace then
        return nil, "Workspace not found"
    end

    local lines = {}
    table.insert(lines, "Workspace: " .. workspace.workspace_id)
    table.insert(lines, "")
    table.insert(lines, "Title: " .. (workspace.title or ""))
    table.insert(lines, "Status: " .. workspace.status)
    if workspace.description and workspace.description ~= "" then
        table.insert(lines, "Description: " .. workspace.description)
    end
    table.insert(lines, "Created: " .. workspace.created_at)
    table.insert(lines, "Updated: " .. workspace.updated_at)

    if workspace.metadata and type(workspace.metadata) == "table" and next(workspace.metadata) then
        local meta_json, _ = json.encode(workspace.metadata)
        if meta_json then
            table.insert(lines, "Metadata: " .. meta_json)
        end
    end

    return table.concat(lines, "\n")
end

local function handler(params)
    if not params or not params.operation then
        return nil, "operation required (open, close, create, update, delete, list, get)"
    end

    local valid_ops = {
        open = true,
        close = true,
        create = true,
        update = true,
        delete = true,
        list = true,
        get = true
    }

    if not valid_ops[params.operation] then
        return nil, "Invalid operation: " .. params.operation
    end

    if params.operation == "open" then
        return open_operation(params)
    elseif params.operation == "close" then
        return close_operation()
    elseif params.operation == "create" then
        return create_operation(params)
    elseif params.operation == "update" then
        return update_operation(params)
    elseif params.operation == "delete" then
        return delete_operation(params)
    elseif params.operation == "list" then
        return list_operation(params)
    elseif params.operation == "get" then
        return get_operation(params)
    end
end

return { handler = handler }