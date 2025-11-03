local json = require("json")
local ctx = require("ctx")
local design_reader = require("design_reader")
local design_writer = require("design_writer")
local consts = require("consts")

local function get_active_workspace()
    local workspace_id, err = ctx.get("active_workspace_id")
    if not err and workspace_id and workspace_id ~= "" then
        return workspace_id, nil
    end
    return nil, "No active workspace (use workspace open first)"
end

local function create_operation(params)
    local workspace_id, err = get_active_workspace()
    if err then
        return nil, err
    end

    if not params.type or params.type == "" then
        return nil, "type required for create"
    end

    local data_spec = {
        parent_data_id = params.parent_data_id,
        type = params.type,
        discriminator = params.discriminator,
        content = params.content,
        content_type = params.content_type,
        status = params.status,
        position = params.position,
        metadata = params.metadata
    }

    local result, err = design_writer.create_workspace_data(workspace_id, data_spec)

    if err then
        return nil, err
    end

    if not result or not result.results or #result.results == 0 then
        return nil, "Create failed: no result"
    end

    local data = result.results[1]
    return {
        data_id = data.data_id,
        workspace_id = data.workspace_id,
        path = data.path,
        depth = data.depth,
        type = params.type,
        message = "Data created"
    }
end

local function update_operation(params)
    local workspace_id, err = get_active_workspace()
    if err then
        return nil, err
    end

    if not params.data_id or params.data_id == "" then
        return nil, "data_id required for update"
    end

    local updates = {}
    if params.type then updates.type = params.type end
    if params.discriminator ~= nil then updates.discriminator = params.discriminator end
    if params.content ~= nil then updates.content = params.content end
    if params.content_type then updates.content_type = params.content_type end
    if params.status ~= nil then updates.status = params.status end
    if params.position ~= nil then updates.position = params.position end
    if params.metadata then updates.metadata = params.metadata end

    if next(updates) == nil then
        return nil, "No fields to update"
    end

    local result, err = design_writer.update_workspace_data(params.data_id, updates)

    if err then
        return nil, err
    end

    return {
        data_id = params.data_id,
        changes_made = result.changes_made,
        message = "Data updated"
    }
end

local function delete_operation(params)
    local workspace_id, err = get_active_workspace()
    if err then
        return nil, err
    end

    if not params.data_id or params.data_id == "" then
        return nil, "data_id required for delete"
    end

    local result, err = design_writer.delete_workspace_data(params.data_id)

    if err then
        return nil, err
    end

    return {
        data_id = params.data_id,
        deleted = result.changes_made,
        message = "Data deleted"
    }
end

local function move_operation(params)
    local workspace_id, err = get_active_workspace()
    if err then
        return nil, err
    end

    if not params.data_id or params.data_id == "" then
        return nil, "data_id required for move"
    end

    local result, err = design_writer.move_workspace_data(
        params.data_id,
        params.parent_data_id
    )

    if err then
        return nil, err
    end

    return {
        data_id = params.data_id,
        parent_data_id = params.parent_data_id,
        message = "Data moved"
    }
end

local function list_operation(params)
    local workspace_id, err = get_active_workspace()
    if err then
        return nil, err
    end

    local reader, err = design_reader.for_workspace(workspace_id)
    if err then
        return nil, err
    end

    if params.types and #params.types > 0 then
        reader = reader:with_type(unpack(params.types))
    end

    if params.discriminators and #params.discriminators > 0 then
        reader = reader:with_discriminator(unpack(params.discriminators))
    end

    if params.parent_data_id then
        if params.parent_direct then
            reader = reader:with_parent_direct(params.parent_data_id)
        else
            reader = reader:with_parent(params.parent_data_id)
        end
    end

    if params.depth ~= nil then
        reader = reader:with_depth(params.depth)
    end

    if params.order_by == "path" then
        reader = reader:order_by_path()
    elseif params.order_by == "position" then
        reader = reader:order_by_position()
    end

    if params.limit and params.limit > 0 then
        reader = reader:limit(params.limit)
    end

    local data_list, err = reader:all()
    if err then
        return nil, err
    end

    local lines = {}
    table.insert(lines, "Workspace Data (" .. #data_list .. ")")
    table.insert(lines, "Workspace: " .. workspace_id)
    table.insert(lines, "")

    for _, data in ipairs(data_list) do
        local indent = string.rep("  ", data.depth)
        table.insert(lines, indent .. data.data_id)
        table.insert(lines, indent .. "  Type: " .. data.type)
        if data.discriminator and data.discriminator ~= "" then
            table.insert(lines, indent .. "  Discriminator: " .. data.discriminator)
        end
        table.insert(lines, indent .. "  Depth: " .. data.depth)
        if data.parent_data_id then
            table.insert(lines, indent .. "  Parent: " .. data.parent_data_id)
        end
        if data.content and data.content ~= "" then
            local preview = data.content:sub(1, 80)
            if #data.content > 80 then preview = preview .. "..." end
            table.insert(lines, indent .. "  Content: " .. preview)
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

local function get_operation(params)
    local workspace_id, err = get_active_workspace()
    if err then
        return nil, err
    end

    if not params.data_id or params.data_id == "" then
        return nil, "data_id required for get"
    end

    local reader, err = design_reader.for_workspace(workspace_id)
    if err then
        return nil, err
    end

    reader = reader:with_data(params.data_id)
    local data, err = reader:one()

    if err then
        return nil, err
    end

    if not data then
        return nil, "Data not found"
    end

    local lines = {}
    table.insert(lines, "Data: " .. data.data_id)
    table.insert(lines, "")
    table.insert(lines, "Workspace: " .. data.workspace_id)
    table.insert(lines, "Type: " .. data.type)
    if data.discriminator and data.discriminator ~= "" then
        table.insert(lines, "Discriminator: " .. data.discriminator)
    end
    table.insert(lines, "Depth: " .. data.depth)
    table.insert(lines, "Path: " .. data.path)
    if data.parent_data_id then
        table.insert(lines, "Parent: " .. data.parent_data_id)
    end
    table.insert(lines, "Position: " .. data.position)
    table.insert(lines, "Content Type: " .. data.content_type)
    if data.status and data.status ~= "" then
        table.insert(lines, "Status: " .. data.status)
    end
    if data.content and data.content ~= "" then
        table.insert(lines, "")
        table.insert(lines, "Content:")
        table.insert(lines, data.content)
    end

    if data.metadata and type(data.metadata) == "table" and next(data.metadata) then
        local meta_json, _ = json.encode(data.metadata)
        if meta_json then
            table.insert(lines, "")
            table.insert(lines, "Metadata: " .. meta_json)
        end
    end

    return table.concat(lines, "\n")
end

local function handler(params)
    if not params or not params.operation then
        return nil, "operation required (create, update, delete, move, list, get)"
    end

    local valid_ops = {
        create = true,
        update = true,
        delete = true,
        move = true,
        list = true,
        get = true
    }

    if not valid_ops[params.operation] then
        return nil, "Invalid operation: " .. params.operation
    end

    if params.operation == "create" then
        return create_operation(params)
    elseif params.operation == "update" then
        return update_operation(params)
    elseif params.operation == "delete" then
        return delete_operation(params)
    elseif params.operation == "move" then
        return move_operation(params)
    elseif params.operation == "list" then
        return list_operation(params)
    elseif params.operation == "get" then
        return get_operation(params)
    end
end

return { handler = handler }