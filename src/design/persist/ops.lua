local sql = require("sql")
local json = require("json")
local time = require("time")
local uuid = require("uuid")
local consts = require("design_consts")

local design_ops = {}

design_ops.OPERATION_TYPE = consts.OPERATION_TYPE

local function encode_metadata(metadata)
    if not metadata then
        return consts.DEFAULTS.METADATA
    end

    if type(metadata) == "string" then
        return metadata
    end

    if type(metadata) == "table" then
        local encoded, err = json.encode(metadata)
        if err then
            return nil, consts.ERROR.JSON_ENCODE_FAILED .. ": " .. err
        end
        return encoded
    end

    return consts.DEFAULTS.METADATA
end

local function validate_workspace_status(status)
    return not status or consts.VALID_VALUES.WORKSPACE_STATUS[status] == true
end

local function validate_content_type(content_type)
    return not content_type or consts.VALID_VALUES.CONTENT_TYPE[content_type] == true
end

local function create_audit_entry(tx, workspace_id, operation_type, user_id, operation_data)
    if not workspace_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id for audit"
    end

    if not operation_type then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "operation_type for audit"
    end

    if not user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id for audit"
    end

    local op_id = uuid.v7()
    local now_ts = time.now():format(time.RFC3339NANO)

    local encoded_data, encode_err = encode_metadata(operation_data)
    if encode_err then
        return nil, "Audit encoding failed: " .. encode_err
    end

    local audit_query = sql.builder.insert("design_workspace_ops")
        :set_map({
            op_id = op_id,
            workspace_id = workspace_id,
            user_id = user_id,
            operation_type = operation_type,
            operation_data = encoded_data,
            created_at = now_ts
        })

    local audit_executor = audit_query:run_with(tx)
    local audit_result, audit_err = audit_executor:exec()

    if audit_err then
        return nil, "Audit creation failed: " .. audit_err
    end

    return op_id
end

local function build_path(parent_path, data_id)
    if not parent_path or parent_path == "" then
        return data_id
    end
    return parent_path .. "." .. data_id
end

local function get_parent_info(tx, parent_data_id)
    if not parent_data_id then
        return nil, 0, nil, nil
    end

    local lookup_query = sql.builder.select("path", "depth", "workspace_id")
        :from("design_workspace_data")
        :where("data_id = ?", parent_data_id)

    local lookup_executor = lookup_query:run_with(tx)
    local lookup_result, lookup_err = lookup_executor:query()

    if lookup_err then
        return nil, nil, nil, lookup_err
    end

    if not lookup_result or #lookup_result == 0 then
        return nil, nil, nil, consts.ERROR.PARENT_NOT_FOUND
    end

    return lookup_result[1].path, lookup_result[1].depth, lookup_result[1].workspace_id, nil
end

local handlers = {}

handlers[consts.OPERATION_TYPE.CREATE_WORKSPACE] = function(tx, command)
    local payload = command.payload or {}

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    if payload.status and not validate_workspace_status(payload.status) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "status"
    end

    if payload.title and #payload.title > consts.LIMITS.MAX_WORKSPACE_TITLE_LENGTH then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "title too long"
    end

    if payload.description and #payload.description > consts.LIMITS.MAX_WORKSPACE_DESCRIPTION_LENGTH then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "description too long"
    end

    local workspace_id = payload.workspace_id or uuid.v7()
    local now_ts = time.now():format(time.RFC3339NANO)

    local metadata, metadata_err = encode_metadata(payload.metadata)
    if metadata_err then
        return nil, metadata_err
    end

    local insert_query = sql.builder.insert("design_workspaces")
        :set_map({
            workspace_id = workspace_id,
            user_id = payload.user_id,
            status = payload.status or consts.DEFAULTS.WORKSPACE_STATUS,
            title = payload.title,
            description = payload.description,
            metadata = metadata,
            created_at = now_ts,
            updated_at = now_ts
        })

    local executor = insert_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    local audit_data = {
        workspace_created = {
            workspace_id = workspace_id,
            title = payload.title,
            status = payload.status or consts.DEFAULTS.WORKSPACE_STATUS
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, workspace_id, consts.OPERATION_TYPE.CREATE_WORKSPACE, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        workspace_id = workspace_id,
        changes_made = true,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.UPDATE_WORKSPACE] = function(tx, command)
    local payload = command.payload or {}

    if not payload.workspace_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    if payload.status and not validate_workspace_status(payload.status) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "status"
    end

    if payload.title and #payload.title > consts.LIMITS.MAX_WORKSPACE_TITLE_LENGTH then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "title too long"
    end

    if payload.description and #payload.description > consts.LIMITS.MAX_WORKSPACE_DESCRIPTION_LENGTH then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "description too long"
    end

    local update_query = sql.builder.update("design_workspaces")
        :where("workspace_id = ?", payload.workspace_id)

    local has_update = false
    local updated_fields = {}

    if payload.title ~= nil then
        update_query = update_query:set("title", payload.title)
        updated_fields.title = payload.title
        has_update = true
    end

    if payload.description ~= nil then
        update_query = update_query:set("description", payload.description)
        updated_fields.description = payload.description
        has_update = true
    end

    if payload.status then
        update_query = update_query:set("status", payload.status)
        updated_fields.status = payload.status
        has_update = true
    end

    if payload.metadata then
        local metadata, metadata_err = encode_metadata(payload.metadata)
        if metadata_err then
            return nil, metadata_err
        end
        update_query = update_query:set("metadata", metadata)
        updated_fields.metadata = true
        has_update = true
    end

    if not has_update then
        return {
            workspace_id = payload.workspace_id,
            changes_made = false,
            message = consts.ERROR.NO_FIELDS_TO_UPDATE
        }
    end

    local now_ts = time.now():format(time.RFC3339NANO)
    update_query = update_query:set("updated_at", now_ts)

    local executor = update_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    local audit_data = {
        workspace_updated = {
            workspace_id = payload.workspace_id,
            fields_updated = updated_fields,
            rows_affected = result.rows_affected
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, payload.workspace_id, consts.OPERATION_TYPE.UPDATE_WORKSPACE, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        workspace_id = payload.workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.DELETE_WORKSPACE] = function(tx, command)
    local payload = command.payload or {}

    if not payload.workspace_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    local delete_query = sql.builder.delete("design_workspaces")
        :where("workspace_id = ?", payload.workspace_id)

    local executor = delete_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    return {
        workspace_id = payload.workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected,
        deleted = true,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.CREATE_WORKSPACE_DATA] = function(tx, command)
    local payload = command.payload or {}

    if not payload.workspace_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    if not payload.type then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "type"
    end

    if payload.content_type and not validate_content_type(payload.content_type) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "content_type"
    end

    local parent_path, parent_depth, parent_workspace_id, parent_err = get_parent_info(tx, payload.parent_data_id)
    if parent_err then
        return nil, parent_err
    end

    if payload.parent_data_id and parent_workspace_id ~= payload.workspace_id then
        return nil, "Parent data belongs to different workspace"
    end

    local data_id = payload.data_id or uuid.v7()
    local path = build_path(parent_path, data_id)
    local depth = parent_path and (parent_depth + 1) or 0
    local now_ts = time.now():format(time.RFC3339NANO)

    local metadata, metadata_err = encode_metadata(payload.metadata)
    if metadata_err then
        return nil, metadata_err
    end

    local insert_query = sql.builder.insert("design_workspace_data")
        :set_map({
            data_id = data_id,
            workspace_id = payload.workspace_id,
            user_id = payload.user_id,
            parent_data_id = payload.parent_data_id,
            path = path,
            depth = depth,
            position = payload.position or 0,
            type = payload.type,
            discriminator = payload.discriminator,
            content = payload.content,
            content_type = payload.content_type or consts.DEFAULTS.CONTENT_TYPE,
            status = payload.status,
            metadata = metadata,
            created_at = now_ts,
            updated_at = now_ts
        })

    local executor = insert_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    local audit_data = {
        data_created = {
            data_id = data_id,
            workspace_id = payload.workspace_id,
            type = payload.type,
            discriminator = payload.discriminator,
            path = path,
            depth = depth
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, payload.workspace_id, consts.OPERATION_TYPE.CREATE_WORKSPACE_DATA, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        data_id = data_id,
        workspace_id = payload.workspace_id,
        path = path,
        depth = depth,
        changes_made = true,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.UPDATE_WORKSPACE_DATA] = function(tx, command)
    local payload = command.payload or {}

    if not payload.data_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "data_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    if payload.content_type and not validate_content_type(payload.content_type) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "content_type"
    end

    local lookup_query = sql.builder.select("workspace_id")
        :from("design_workspace_data")
        :where("data_id = ?", payload.data_id)

    local lookup_executor = lookup_query:run_with(tx)
    local lookup_result, lookup_err = lookup_executor:query()

    if lookup_err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. lookup_err
    end

    if not lookup_result or #lookup_result == 0 then
        return nil, consts.ERROR.DATA_NOT_FOUND
    end

    local workspace_id = lookup_result[1].workspace_id

    local update_query = sql.builder.update("design_workspace_data")
        :where("data_id = ?", payload.data_id)

    local has_update = false

    if payload.type then
        update_query = update_query:set("type", payload.type)
        has_update = true
    end

    if payload.discriminator ~= nil then
        update_query = update_query:set("discriminator", payload.discriminator)
        has_update = true
    end

    if payload.content ~= nil then
        update_query = update_query:set("content", payload.content)
        has_update = true
    end

    if payload.content_type then
        update_query = update_query:set("content_type", payload.content_type)
        has_update = true
    end

    if payload.status ~= nil then
        update_query = update_query:set("status", payload.status)
        has_update = true
    end

    if payload.position ~= nil then
        update_query = update_query:set("position", payload.position)
        has_update = true
    end

    if payload.metadata then
        local metadata, metadata_err = encode_metadata(payload.metadata)
        if metadata_err then
            return nil, metadata_err
        end
        update_query = update_query:set("metadata", metadata)
        has_update = true
    end

    if not has_update then
        return {
            data_id = payload.data_id,
            changes_made = false,
            message = consts.ERROR.NO_FIELDS_TO_UPDATE
        }
    end

    local now_ts = time.now():format(time.RFC3339NANO)
    update_query = update_query:set("updated_at", now_ts)

    local executor = update_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    local audit_data = {
        data_updated = {
            data_id = payload.data_id,
            rows_affected = result.rows_affected
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, workspace_id, consts.OPERATION_TYPE.UPDATE_WORKSPACE_DATA, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        data_id = payload.data_id,
        workspace_id = workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.DELETE_WORKSPACE_DATA] = function(tx, command)
    local payload = command.payload or {}

    if not payload.data_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "data_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    local lookup_query = sql.builder.select("workspace_id", "parent_data_id", "path", "depth",
        "position", "type", "discriminator", "content", "content_type", "status", "metadata")
        :from("design_workspace_data")
        :where("data_id = ?", payload.data_id)

    local lookup_executor = lookup_query:run_with(tx)
    local lookup_result, lookup_err = lookup_executor:query()

    if lookup_err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. lookup_err
    end

    if not lookup_result or #lookup_result == 0 then
        return nil, consts.ERROR.DATA_NOT_FOUND
    end

    local parent_snapshot = lookup_result[1]
    local workspace_id = parent_snapshot.workspace_id
    local parent_path = parent_snapshot.path

    local descendants_query = sql.builder.select("data_id", "parent_data_id", "path", "depth",
        "position", "type", "discriminator", "content", "content_type", "status", "metadata")
        :from("design_workspace_data")
        :where("path LIKE ?", parent_path .. ".%")
        :order_by("depth DESC")

    local desc_executor = descendants_query:run_with(tx)
    local descendants, desc_err = desc_executor:query()

    if desc_err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. desc_err
    end

    local all_deleted = {}

    if descendants and #descendants > 0 then
        for _, child in ipairs(descendants) do
            local child_audit_data = {
                data_deleted = {
                    data_id = child.data_id,
                    parent_data_id = child.parent_data_id,
                    path = child.path,
                    depth = child.depth,
                    position = child.position,
                    type = child.type,
                    discriminator = child.discriminator,
                    content = child.content,
                    content_type = child.content_type,
                    status = child.status,
                    metadata = child.metadata
                }
            }

            local child_audit_id, child_audit_err = create_audit_entry(tx, workspace_id,
                consts.OPERATION_TYPE.DELETE_WORKSPACE_DATA, payload.user_id, child_audit_data)

            if child_audit_err then
                return nil, child_audit_err
            end

            local delete_child_query = sql.builder.delete("design_workspace_data")
                :where("data_id = ?", child.data_id)

            local delete_child_exec = delete_child_query:run_with(tx)
            local delete_child_result, delete_child_err = delete_child_exec:exec()

            if delete_child_err then
                return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. delete_child_err
            end

            table.insert(all_deleted, {
                data_id = child.data_id,
                type = child.type,
                discriminator = child.discriminator,
                path = child.path,
                depth = child.depth
            })
        end
    end

    local parent_audit_data = {
        data_deleted = {
            data_id = payload.data_id,
            parent_data_id = parent_snapshot.parent_data_id,
            path = parent_snapshot.path,
            depth = parent_snapshot.depth,
            position = parent_snapshot.position,
            type = parent_snapshot.type,
            discriminator = parent_snapshot.discriminator,
            content = parent_snapshot.content,
            content_type = parent_snapshot.content_type,
            status = parent_snapshot.status,
            metadata = parent_snapshot.metadata
        }
    }

    local parent_audit_id, parent_audit_err = create_audit_entry(tx, workspace_id,
        consts.OPERATION_TYPE.DELETE_WORKSPACE_DATA, payload.user_id, parent_audit_data)

    if parent_audit_err then
        return nil, parent_audit_err
    end

    local delete_query = sql.builder.delete("design_workspace_data")
        :where("data_id = ?", payload.data_id)

    local executor = delete_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    table.insert(all_deleted, {
        data_id = payload.data_id,
        type = parent_snapshot.type,
        discriminator = parent_snapshot.discriminator,
        path = parent_snapshot.path,
        depth = parent_snapshot.depth
    })

    return {
        data_id = payload.data_id,
        workspace_id = workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected + #descendants,
        deleted = true,
        deleted_items = all_deleted,
        user_id = payload.user_id
    }
end

function design_ops.execute(tx, commands)
    if not tx then
        return nil, consts.ERROR.TRANSACTION_REQUIRED
    end

    if not commands or type(commands) ~= "table" then
        return nil, consts.ERROR.COMMANDS_REQUIRED
    end

    local command_array = {}
    if commands.type then
        table.insert(command_array, commands)
    else
        command_array = commands
    end

    if #command_array == 0 then
        return nil, consts.ERROR.COMMANDS_EMPTY
    end

    local changes_made = false
    local results = {}

    for i, command in ipairs(command_array) do
        local handler = handlers[command.type]

        if not handler then
            return nil, consts.ERROR.UNKNOWN_COMMAND_TYPE .. (command.type or "nil") .. " at index " .. i
        end

        local result, err = handler(tx, command)

        if err then
            return nil, "Error executing command at index " .. i .. ": " .. err
        end

        if result and result.changes_made then
            changes_made = true
            result.input = command
        end

        table.insert(results, result)
    end

    return {
        results = results,
        changes_made = changes_made
    }, nil
end

return design_ops