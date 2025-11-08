local sql = require("sql")
local json = require("json")
local uuid = require("uuid")
local time = require("time")
local consts = require("design_consts")
local design_ops = require("design_ops")

local design_writer = {}

design_writer._deps = {
    security = require("security")
}

local function get_db()
    local db, err = sql.get(consts.get_db_resource())
    if err then
        return nil, consts.ERROR.DB_CONNECTION_FAILED .. ": " .. err
    end
    return db, nil
end

local function get_user_id()
    local actor = design_writer._deps.security.actor()
    if not actor then
        return nil, "Authentication required"
    end
    return actor:id(), nil
end

local function get_next_position(workspace_id, parent_data_id)
    local db, err = get_db()
    if err then
        return 0
    end

    local query
    if parent_data_id then
        query = sql.builder.select("MAX(position) as max_pos")
            :from("design_workspace_data")
            :where("workspace_id = ?", workspace_id)
            :where("parent_data_id = ?", parent_data_id)
    else
        query = sql.builder.select("MAX(position) as max_pos")
            :from("design_workspace_data")
            :where("workspace_id = ?", workspace_id)
            :where("parent_data_id IS NULL")
    end

    local executor = query:run_with(db)
    local result, query_err = executor:query()
    db:release()

    if query_err or not result or #result == 0 then
        return 0
    end

    local max_pos = result[1].max_pos
    if max_pos == nil then
        return 0
    end

    return max_pos + 1
end

local node_builder_mt = {__index = {}}

local function create_node_builder(workspace_builder, node_id)
    local instance = {
        _workspace = workspace_builder,
        _node_id = node_id
    }
    return setmetatable(instance, node_builder_mt)
end

function node_builder_mt.__index:data(spec)
    if not spec.type then
        error("data spec must have 'type' field")
    end

    local data_id = uuid.v7()

    local position = spec.position
    if position == nil then
        position = get_next_position(self._workspace._workspace_id, self._node_id)
    end

    table.insert(self._workspace._commands, {
        type = consts.OPERATION_TYPE.CREATE_WORKSPACE_DATA,
        payload = {
            user_id = self._workspace._user_id,
            workspace_id = self._workspace._workspace_id,
            data_id = data_id,
            parent_data_id = self._node_id,
            type = spec.type,
            discriminator = spec.discriminator,
            content = spec.content,
            content_type = spec.content_type or consts.DEFAULTS.CONTENT_TYPE,
            status = spec.status,
            position = position,
            metadata = spec.metadata
        }
    })

    return create_node_builder(self._workspace, data_id)
end

function node_builder_mt.__index:update(updates)
    return self._workspace:update(updates)
end

function node_builder_mt.__index:delete()
    return self._workspace:delete()
end

function node_builder_mt.__index:update_data(data_id, updates)
    return self._workspace:update_data(data_id, updates)
end

function node_builder_mt.__index:delete_data(data_id)
    return self._workspace:delete_data(data_id)
end

function node_builder_mt.__index:execute()
    return self._workspace:execute()
end

function design_writer._send_process_message(target_process, topic, payload)
    process.send(target_process, topic, payload)
end

function design_writer._get_current_timestamp()
    return time.now():format(time.RFC3339NANO)
end

function design_writer.publish_updates(result)
    if not result or not result.changes_made or not result.results then
        return
    end

    local now_ts = design_writer._get_current_timestamp()

    for _, cmd_result in ipairs(result.results) do
        if not (cmd_result and cmd_result.changes_made and cmd_result.input) then
            goto continue
        end

        local cmd_type = cmd_result.input.type
        local payload = cmd_result.input.payload or {}
        local user_target = "user." .. (payload.user_id or "unknown")

        if cmd_type == consts.OPERATION_TYPE.CREATE_WORKSPACE then
            local workspace_id = cmd_result.workspace_id
            local topic = consts.TOPIC_PATTERNS.WORKSPACE_PREFIX .. workspace_id

            design_writer._send_process_message(user_target, topic, {
                type = "workspace_created",
                workspace_id = workspace_id,
                data = {
                    title = payload.title,
                    description = payload.description,
                    status = payload.status or consts.DEFAULTS.WORKSPACE_STATUS
                },
                timestamp = now_ts
            })
        elseif cmd_type == consts.OPERATION_TYPE.UPDATE_WORKSPACE then
            local workspace_id = payload.workspace_id
            local topic = consts.TOPIC_PATTERNS.WORKSPACE_PREFIX .. workspace_id

            design_writer._send_process_message(user_target, topic, {
                type = "workspace_updated",
                workspace_id = workspace_id,
                data = {
                    title = payload.title,
                    description = payload.description,
                    status = payload.status,
                    metadata = payload.metadata
                },
                timestamp = now_ts
            })
        elseif cmd_type == consts.OPERATION_TYPE.DELETE_WORKSPACE then
            local workspace_id = payload.workspace_id
            local topic = consts.TOPIC_PATTERNS.WORKSPACE_PREFIX .. workspace_id

            design_writer._send_process_message(user_target, topic, {
                type = "workspace_deleted",
                workspace_id = workspace_id,
                data = {},
                timestamp = now_ts
            })
        elseif cmd_type == consts.OPERATION_TYPE.CREATE_WORKSPACE_DATA then
            local workspace_id = cmd_result.workspace_id
            local topic = consts.TOPIC_PATTERNS.WORKSPACE_PREFIX .. workspace_id

            design_writer._send_process_message(user_target, topic, {
                type = "data_created",
                workspace_id = workspace_id,
                data = {
                    data_id = cmd_result.data_id,
                    type = payload.type,
                    discriminator = payload.discriminator,
                    path = cmd_result.path,
                    depth = cmd_result.depth
                },
                timestamp = now_ts
            })
        elseif cmd_type == consts.OPERATION_TYPE.UPDATE_WORKSPACE_DATA then
            local workspace_id = cmd_result.workspace_id
            if workspace_id then
                local topic = consts.TOPIC_PATTERNS.WORKSPACE_PREFIX .. workspace_id

                design_writer._send_process_message(user_target, topic, {
                    type = "data_updated",
                    workspace_id = workspace_id,
                    data = {
                        data_id = payload.data_id,
                        type = payload.type,
                        discriminator = payload.discriminator
                    },
                    timestamp = now_ts
                })
            end
        elseif cmd_type == consts.OPERATION_TYPE.DELETE_WORKSPACE_DATA then
            local workspace_id = cmd_result.workspace_id
            if workspace_id and cmd_result.deleted_items then
                local topic = consts.TOPIC_PATTERNS.WORKSPACE_PREFIX .. workspace_id

                for _, deleted_item in ipairs(cmd_result.deleted_items) do
                    design_writer._send_process_message(user_target, topic, {
                        type = "data_deleted",
                        workspace_id = workspace_id,
                        data = {
                            data_id = deleted_item.data_id,
                            type = deleted_item.type,
                            discriminator = deleted_item.discriminator,
                            path = deleted_item.path,
                            depth = deleted_item.depth
                        },
                        timestamp = now_ts
                    })
                end
            end
        end

        ::continue::
    end
end

local function execute_commands(commands)
    if #commands == 0 then
        return nil, "No commands to execute"
    end

    local db, err_db = get_db()
    if err_db then
        return nil, err_db
    end

    local tx, err_tx = db:begin()
    if err_tx then
        db:release()
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err_tx
    end

    local result, err_op = design_ops.execute(tx, commands)
    if err_op then
        tx:rollback()
        db:release()
        return nil, err_op
    end

    local success, err_commit = tx:commit()
    if err_commit then
        tx:rollback()
        db:release()
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err_commit
    end

    db:release()

    design_writer.publish_updates(result)

    return result, nil
end

local workspace_builder_mt = {__index = {}}

function design_writer.workspace(title, description, metadata)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    local workspace_id = uuid.v7()

    local instance = {
        _user_id = user_id,
        _workspace_id = workspace_id,
        _commands = {
            {
                type = consts.OPERATION_TYPE.CREATE_WORKSPACE,
                payload = {
                    user_id = user_id,
                    workspace_id = workspace_id,
                    title = title,
                    description = description,
                    metadata = metadata
                }
            }
        }
    }

    return setmetatable(instance, workspace_builder_mt)
end

function design_writer.existing_workspace(workspace_id)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    local instance = {
        _user_id = user_id,
        _workspace_id = workspace_id,
        _commands = {}
    }

    return setmetatable(instance, workspace_builder_mt)
end

function workspace_builder_mt.__index:data(spec)
    if not spec.type then
        error("data spec must have 'type' field")
    end

    local data_id = uuid.v7()

    local position = spec.position
    if position == nil then
        position = get_next_position(self._workspace_id, spec.parent_data_id)
    end

    table.insert(self._commands, {
        type = consts.OPERATION_TYPE.CREATE_WORKSPACE_DATA,
        payload = {
            user_id = self._user_id,
            workspace_id = self._workspace_id,
            data_id = data_id,
            parent_data_id = spec.parent_data_id,
            type = spec.type,
            discriminator = spec.discriminator,
            content = spec.content,
            content_type = spec.content_type or consts.DEFAULTS.CONTENT_TYPE,
            status = spec.status,
            position = position,
            metadata = spec.metadata
        }
    })

    return create_node_builder(self, data_id)
end

function workspace_builder_mt.__index:update(updates)
    if not updates or type(updates) ~= "table" or next(updates) == nil then
        error("update requires non-empty table of updates")
    end

    local payload = {
        user_id = self._user_id,
        workspace_id = self._workspace_id
    }

    for k, v in pairs(updates) do
        payload[k] = v
    end

    table.insert(self._commands, {
        type = consts.OPERATION_TYPE.UPDATE_WORKSPACE,
        payload = payload
    })

    return self
end

function workspace_builder_mt.__index:delete()
    table.insert(self._commands, {
        type = consts.OPERATION_TYPE.DELETE_WORKSPACE,
        payload = {
            user_id = self._user_id,
            workspace_id = self._workspace_id
        }
    })

    return self
end

function workspace_builder_mt.__index:update_data(data_id, updates)
    if not data_id then
        error("update_data requires data_id")
    end

    if not updates or type(updates) ~= "table" or next(updates) == nil then
        error("update_data requires non-empty table of updates")
    end

    local payload = {
        user_id = self._user_id,
        data_id = data_id
    }

    for k, v in pairs(updates) do
        payload[k] = v
    end

    table.insert(self._commands, {
        type = consts.OPERATION_TYPE.UPDATE_WORKSPACE_DATA,
        payload = payload
    })

    return self
end

function workspace_builder_mt.__index:delete_data(data_id)
    if not data_id then
        error("delete_data requires data_id")
    end

    table.insert(self._commands, {
        type = consts.OPERATION_TYPE.DELETE_WORKSPACE_DATA,
        payload = {
            user_id = self._user_id,
            data_id = data_id
        }
    })

    return self
end

function workspace_builder_mt.__index:execute()
    local result, err = execute_commands(self._commands)
    if err then
        return nil, err
    end

    return {
        workspace_id = self._workspace_id,
        results = result.results,
        changes_made = result.changes_made
    }, nil
end

return design_writer