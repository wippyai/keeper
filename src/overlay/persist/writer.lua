local sql = require("sql")
local json = require("json")
local uuid = require("uuid")
local time = require("time")
local security = require("security")
local consts = require("consts")
local overlay_ops = require("overlay_ops")

local overlay_writer = {}

-- ============================================================================
-- CONTEXT READER FUNCTIONALITY (MISSING FROM ORIGINAL READER)
-- ============================================================================

local context_reader_methods = {}
local context_reader_mt = { __index = context_reader_methods }

---Initialize a new reader for workspace context
---@param workspace_id string
---@return table|nil, string|nil
function overlay_writer.for_context(workspace_id)
    if not workspace_id or workspace_id == "" then
        return nil, "Workspace ID is required"
    end

    local instance = {
        _workspace_id = workspace_id,
        _context_ids = nil,
        _labels = nil,
        _content_types = nil,
        _limit = nil,
        _mode = "context"
    }
    return setmetatable(instance, context_reader_mt), nil
end

---Create an immutable copy of a context reader
---@param self table
---@return table
function context_reader_methods:_copy()
    local new_instance = {}
    for k, v in pairs(self) do
        new_instance[k] = v
    end
    return setmetatable(new_instance, context_reader_mt)
end

---Filter by specific context IDs
---@param ... string
---@return table
function context_reader_methods:with_context_ids(...)
    local new_instance = self:_copy()
    new_instance._context_ids = { ... }
    return new_instance
end

---Filter by specific labels
---@param ... string
---@return table
function context_reader_methods:with_labels(...)
    local new_instance = self:_copy()
    new_instance._labels = { ... }
    return new_instance
end

---Filter by content types
---@param ... string
---@return table
function context_reader_methods:with_content_types(...)
    local new_instance = self:_copy()
    new_instance._content_types = { ... }
    return new_instance
end

---Limit the number of results
---@param count number
---@return table
function context_reader_methods:limit(count)
    if not count or type(count) ~= "number" or count <= 0 then
        return self
    end

    local new_instance = self:_copy()
    new_instance._limit = count
    return new_instance
end

---Create a simple IN clause for arrays
---@param field string
---@param values string[]
---@return table|nil
local function create_in_clause(field, values)
    if not values or #values == 0 then
        return nil
    end

    if #values == 1 then
        return { field .. " = ?", values[1] }
    end

    local placeholders = {}
    for i = 1, #values do
        table.insert(placeholders, "?")
    end

    return { field .. " IN (" .. table.concat(placeholders, ", ") .. ")", unpack(values) }
end

---Parse JSON metadata string into table
---@param metadata_str string|nil
---@return table
local function parse_json_metadata(metadata_str)
    if not metadata_str or type(metadata_str) ~= "string" then
        return {}
    end

    local parsed, err = json.decode(metadata_str)
    if err then
        return {}
    else
        return parsed
    end
end

---Build context query
---@return table|nil, string|nil
function context_reader_methods:_build_context_query()
    local select_fields = {
        "wc.context_id",
        "wc.workspace_id",
        "wc.label",
        "wc.content",
        "wc.content_type",
        "wc.metadata",
        "wc.created_at",
        "wc.updated_at"
    }

    local query_builder = sql.builder.select(unpack(select_fields))
        :from("overlay_registry_workspace_context wc")
        :where("wc.workspace_id = ?", self._workspace_id)

    -- Apply context filters
    if self._context_ids and #self._context_ids > 0 then
        local context_clause = create_in_clause("wc.context_id", self._context_ids)
        if context_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(context_clause)))
        end
    end

    if self._labels and #self._labels > 0 then
        local label_clause = create_in_clause("wc.label", self._labels)
        if label_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(label_clause)))
        end
    end

    if self._content_types and #self._content_types > 0 then
        local type_clause = create_in_clause("wc.content_type", self._content_types)
        if type_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(type_clause)))
        end
    end

    query_builder = query_builder:order_by("wc.created_at DESC")

    -- Apply limit if specified
    if self._limit then
        query_builder = query_builder:limit(self._limit)
    end

    return query_builder
end

---Get all matching context results
---@return table[]|nil, string|nil
function context_reader_methods:all()
    local db, err = sql.get(consts.get_db_resource())
    if err then
        return nil, "Failed to connect to database: " .. err
    end

    local query = self:_build_context_query()
    if not query then
        db:release()
        return nil, "Failed to build context query"
    end

    local executor = query:run_with(db)
    local results, exec_err = executor:query()
    db:release()

    if exec_err then
        return nil, "Failed to fetch context: " .. exec_err
    end

    -- Parse metadata for each result
    for i, row in ipairs(results) do
        if row.metadata then
            row.metadata = parse_json_metadata(row.metadata)
        else
            row.metadata = {}
        end
    end

    return results, nil
end

---Get a single context result
---@return table|nil, string|nil
function context_reader_methods:one()
    local results, err = self:all()
    if err then
        return nil, err
    end

    if #results == 0 then
        return nil, nil
    end

    return results[1], nil
end

-- ============================================================================
-- PRIVATE HELPERS
-- ============================================================================

local function get_db()
    local db, err = sql.get(consts.get_db_resource())
    if err then
        return nil, consts.ERROR.DB_CONNECTION_FAILED .. ": " .. err
    end
    return db, nil
end

local function get_user_id()
    local actor = security.actor()
    if not actor then
        return nil, "Authentication required"
    end
    return actor:id(), nil
end

function overlay_writer._send_process_message(target_process, topic, payload)
    process.send(target_process, topic, payload)
end

function overlay_writer._get_current_timestamp()
    return time.now():format(time.RFC3339NANO)
end

-- ============================================================================
-- REAL-TIME PUBLISHING FOR ALL OPERATIONS
-- ============================================================================

function overlay_writer.publish_updates(result)
    if not result or not result.changes_made or not result.results then
        return
    end

    local now_ts = overlay_writer._get_current_timestamp()

    for _, cmd_result in ipairs(result.results) do
        if not (cmd_result and cmd_result.changes_made and cmd_result.input) then
            goto continue
        end

        local cmd_type = cmd_result.input.type
        local payload = cmd_result.input.payload or {}
        local user_target = "user." .. (payload.user_id or "unknown")

        -- Workspace operations
        if cmd_type == consts.OPERATION_TYPE.CREATE_WORKSPACE then
            local workspace_id = cmd_result.workspace_id
            local topic = "workspace:" .. workspace_id

            overlay_writer._send_process_message(user_target, topic, {
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
            local topic = "workspace:" .. workspace_id

            overlay_writer._send_process_message(user_target, topic, {
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
            local topic = "workspace:" .. workspace_id

            overlay_writer._send_process_message(user_target, topic, {
                type = "workspace_deleted",
                workspace_id = workspace_id,
                data = {},
                timestamp = now_ts
            })

        -- Permission operations
        elseif cmd_type == consts.OPERATION_TYPE.CREATE_WORKSPACE_PERMISSION then
            local workspace_id = cmd_result.workspace_id
            local topic = "workspace:" .. workspace_id

            overlay_writer._send_process_message(user_target, topic, {
                type = "permission_created",
                workspace_id = workspace_id,
                data = {
                    permission_id = cmd_result.permission_id,
                    namespace_pattern = payload.namespace_pattern,
                    permission_type = payload.permission_type
                },
                timestamp = now_ts
            })

        elseif cmd_type == consts.OPERATION_TYPE.DELETE_WORKSPACE_PERMISSION then
            local workspace_id = cmd_result.workspace_id
            if workspace_id then
                local topic = "workspace:" .. workspace_id

                overlay_writer._send_process_message(user_target, topic, {
                    type = "permission_deleted",
                    workspace_id = workspace_id,
                    data = {
                        permission_id = payload.permission_id
                    },
                    timestamp = now_ts
                })
            end

        -- Entry operations
        elseif cmd_type == consts.OPERATION_TYPE.CREATE_WORKSPACE_ENTRY then
            local workspace_id = cmd_result.workspace_id
            local topic = "workspace:" .. workspace_id

            overlay_writer._send_process_message(user_target, topic, {
                type = "entry_created",
                workspace_id = workspace_id,
                data = {
                    workspace_entry_id = cmd_result.workspace_entry_id,
                    entry_id = payload.entry_id,
                    entry_kind = payload.entry_kind,
                    operation_type = payload.operation_type
                },
                timestamp = now_ts
            })

        elseif cmd_type == consts.OPERATION_TYPE.UPDATE_WORKSPACE_ENTRY then
            local workspace_id = cmd_result.workspace_id
            if workspace_id then
                local topic = "workspace:" .. workspace_id

                overlay_writer._send_process_message(user_target, topic, {
                    type = "entry_updated",
                    workspace_id = workspace_id,
                    data = {
                        workspace_entry_id = payload.workspace_entry_id,
                        entry_id = payload.entry_id,
                        entry_kind = payload.entry_kind,
                        operation_type = payload.operation_type
                    },
                    timestamp = now_ts
                })
            end

        elseif cmd_type == consts.OPERATION_TYPE.DELETE_WORKSPACE_ENTRY then
            local workspace_id = cmd_result.workspace_id
            if workspace_id then
                local topic = "workspace:" .. workspace_id

                overlay_writer._send_process_message(user_target, topic, {
                    type = "entry_deleted",
                    workspace_id = workspace_id,
                    data = {
                        workspace_entry_id = payload.workspace_entry_id,
                        entry_id = cmd_result.entry_id
                    },
                    timestamp = now_ts
                })
            end

        -- Review operations
        elseif cmd_type == consts.OPERATION_TYPE.CREATE_WORKSPACE_REVIEW then
            local workspace_id = cmd_result.workspace_id
            local topic = "workspace:" .. workspace_id

            overlay_writer._send_process_message(user_target, topic, {
                type = "review_created",
                workspace_id = workspace_id,
                data = {
                    review_id = cmd_result.review_id,
                    name = payload.name,
                    content_type = payload.content_type or consts.DEFAULTS.CONTENT_TYPE,
                    status = payload.status or consts.DEFAULTS.REVIEW_STATUS
                },
                timestamp = now_ts
            })

        elseif cmd_type == consts.OPERATION_TYPE.UPDATE_WORKSPACE_REVIEW then
            local workspace_id = cmd_result.workspace_id
            if workspace_id then
                local topic = "workspace:" .. workspace_id

                overlay_writer._send_process_message(user_target, topic, {
                    type = "review_updated",
                    workspace_id = workspace_id,
                    data = {
                        review_id = payload.review_id,
                        name = payload.name,
                        content_type = payload.content_type,
                        status = payload.status
                    },
                    timestamp = now_ts
                })
            end

        elseif cmd_type == consts.OPERATION_TYPE.DELETE_WORKSPACE_REVIEW then
            local workspace_id = cmd_result.workspace_id
            if workspace_id then
                local topic = "workspace:" .. workspace_id

                overlay_writer._send_process_message(user_target, topic, {
                    type = "review_deleted",
                    workspace_id = workspace_id,
                    data = {
                        review_id = payload.review_id,
                        name = cmd_result.name
                    }
                })
            end

        -- Context operations
        elseif cmd_type == consts.OPERATION_TYPE.CREATE_WORKSPACE_CONTEXT then
            local workspace_id = cmd_result.workspace_id
            local topic = "workspace:" .. workspace_id

            overlay_writer._send_process_message(user_target, topic, {
                type = "context_created",
                workspace_id = workspace_id,
                data = {
                    context_id = cmd_result.context_id,
                    label = payload.label,
                    content_type = payload.content_type or consts.DEFAULTS.CONTENT_TYPE
                },
                timestamp = now_ts
            })

        elseif cmd_type == consts.OPERATION_TYPE.UPDATE_WORKSPACE_CONTEXT then
            local workspace_id = cmd_result.workspace_id
            if workspace_id then
                local topic = "workspace:" .. workspace_id

                overlay_writer._send_process_message(user_target, topic, {
                    type = "context_updated",
                    workspace_id = workspace_id,
                    data = {
                        context_id = payload.context_id,
                        label = payload.label,
                        content_type = payload.content_type
                    },
                    timestamp = now_ts
                })
            end

        elseif cmd_type == consts.OPERATION_TYPE.DELETE_WORKSPACE_CONTEXT then
            local workspace_id = cmd_result.workspace_id
            if workspace_id then
                local topic = "workspace:" .. workspace_id

                overlay_writer._send_process_message(user_target, topic, {
                    type = "context_deleted",
                    workspace_id = workspace_id,
                    data = {
                        context_id = payload.context_id,
                        label = cmd_result.label
                    },
                    timestamp = now_ts
                })
            end
        end

        ::continue::
    end
end

-- ============================================================================
-- TRANSACTION MANAGEMENT (SIMPLIFIED)
-- ============================================================================

function overlay_writer.tx_execute(tx, commands, options)
    if not tx then
        return nil, consts.ERROR.TRANSACTION_REQUIRED
    end

    if not commands or type(commands) ~= "table" or #commands == 0 then
        return nil, consts.ERROR.COMMANDS_EMPTY
    end

    options = options or {}

    -- Execute operations (audit is now handled inside ops)
    local result, err = overlay_ops.execute(tx, commands)
    if err then
        return nil, err
    end

    -- Handle publishing if enabled (default is true)
    if options.publish ~= false then
        overlay_writer.publish_updates(result)
    end

    return result, nil
end

function overlay_writer.execute(commands, options)
    if not commands then
        return nil, consts.ERROR.COMMANDS_REQUIRED
    end

    if type(commands) ~= "table" then
        return nil, consts.ERROR.COMMANDS_REQUIRED
    end

    if #commands == 0 then
        return nil, consts.ERROR.COMMANDS_EMPTY
    end

    options = options or {}

    local db, err_db = get_db()
    if err_db then
        return nil, err_db
    end

    local tx, err_tx = db:begin()
    if err_tx then
        db:release()
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err_tx
    end

    local result, err_op = overlay_writer.tx_execute(tx, commands, { publish = false })

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

    if options.publish ~= false then
        overlay_writer.publish_updates(result)
    end

    return result, nil
end

-- ============================================================================
-- CONVENIENCE METHODS (ORIGINAL API - GET USER_ID INTERNALLY)
-- ============================================================================

-- Workspace operations
function overlay_writer.create_workspace(title, description, metadata)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    local command = {
        type = consts.OPERATION_TYPE.CREATE_WORKSPACE,
        payload = {
            user_id = user_id,
            title = title,
            description = description,
            metadata = metadata
        }
    }

    return overlay_writer.execute({ command })
end

function overlay_writer.update_workspace(workspace_id, updates)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not workspace_id or workspace_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not updates or type(updates) ~= "table" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "updates"
    end

    local payload = {
        user_id = user_id,
        workspace_id = workspace_id
    }
    for k, v in pairs(updates) do
        payload[k] = v
    end

    local command = {
        type = consts.OPERATION_TYPE.UPDATE_WORKSPACE,
        payload = payload
    }

    return overlay_writer.execute({ command })
end

function overlay_writer.delete_workspace(workspace_id)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not workspace_id or workspace_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    local command = {
        type = consts.OPERATION_TYPE.DELETE_WORKSPACE,
        payload = {
            user_id = user_id,
            workspace_id = workspace_id
        }
    }

    return overlay_writer.execute({ command })
end

-- Permission operations
function overlay_writer.create_workspace_permission(workspace_id, namespace_pattern, permission_type)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not workspace_id or workspace_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not namespace_pattern or namespace_pattern == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "namespace_pattern"
    end

    if not permission_type or permission_type == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "permission_type"
    end

    local command = {
        type = consts.OPERATION_TYPE.CREATE_WORKSPACE_PERMISSION,
        payload = {
            user_id = user_id,
            workspace_id = workspace_id,
            namespace_pattern = namespace_pattern,
            permission_type = permission_type
        }
    }

    return overlay_writer.execute({ command })
end

function overlay_writer.delete_workspace_permission(permission_id)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not permission_id or permission_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "permission_id"
    end

    local command = {
        type = consts.OPERATION_TYPE.DELETE_WORKSPACE_PERMISSION,
        payload = {
            user_id = user_id,
            permission_id = permission_id
        }
    }

    return overlay_writer.execute({ command })
end

-- Entry operations
function overlay_writer.create_workspace_entry(workspace_id, entry_id, operation_type, entry_data, entry_meta, entry_kind)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not workspace_id or workspace_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not entry_id or entry_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "entry_id"
    end

    if not operation_type or operation_type == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "operation_type"
    end

    local command = {
        type = consts.OPERATION_TYPE.CREATE_WORKSPACE_ENTRY,
        payload = {
            user_id = user_id,
            workspace_id = workspace_id,
            entry_id = entry_id,
            operation_type = operation_type,
            entry_data = entry_data,
            entry_meta = entry_meta,
            entry_kind = entry_kind
        }
    }

    return overlay_writer.execute({ command })
end

function overlay_writer.update_workspace_entry(workspace_entry_id, updates)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not workspace_entry_id or workspace_entry_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_entry_id"
    end

    if not updates or type(updates) ~= "table" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "updates"
    end

    local payload = {
        user_id = user_id,
        workspace_entry_id = workspace_entry_id
    }
    for k, v in pairs(updates) do
        payload[k] = v
    end

    local command = {
        type = consts.OPERATION_TYPE.UPDATE_WORKSPACE_ENTRY,
        payload = payload
    }

    return overlay_writer.execute({ command })
end

function overlay_writer.delete_workspace_entry(workspace_entry_id)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not workspace_entry_id or workspace_entry_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_entry_id"
    end

    local command = {
        type = consts.OPERATION_TYPE.DELETE_WORKSPACE_ENTRY,
        payload = {
            user_id = user_id,
            workspace_entry_id = workspace_entry_id
        }
    }

    return overlay_writer.execute({ command })
end

-- Review operations
function overlay_writer.create_workspace_review(workspace_id, name, content, content_type, meta, status)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not workspace_id or workspace_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not name or name == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "name"
    end

    local command = {
        type = consts.OPERATION_TYPE.CREATE_WORKSPACE_REVIEW,
        payload = {
            user_id = user_id,
            workspace_id = workspace_id,
            name = name,
            content = content,
            content_type = content_type,
            meta = meta,
            status = status
        }
    }

    return overlay_writer.execute({ command })
end

function overlay_writer.update_workspace_review(review_id, updates)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not review_id or review_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "review_id"
    end

    if not updates or type(updates) ~= "table" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "updates"
    end

    local payload = {
        user_id = user_id,
        review_id = review_id
    }
    for k, v in pairs(updates) do
        payload[k] = v
    end

    local command = {
        type = consts.OPERATION_TYPE.UPDATE_WORKSPACE_REVIEW,
        payload = payload
    }

    return overlay_writer.execute({ command })
end

function overlay_writer.delete_workspace_review(review_id)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not review_id or review_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "review_id"
    end

    local command = {
        type = consts.OPERATION_TYPE.DELETE_WORKSPACE_REVIEW,
        payload = {
            user_id = user_id,
            review_id = review_id
        }
    }

    return overlay_writer.execute({ command })
end

-- Context operations
function overlay_writer.create_workspace_context(workspace_id, label, content, content_type, metadata)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not workspace_id or workspace_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not label or label == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "label"
    end

    local command = {
        type = consts.OPERATION_TYPE.CREATE_WORKSPACE_CONTEXT,
        payload = {
            user_id = user_id,
            workspace_id = workspace_id,
            label = label,
            content = content,
            content_type = content_type,
            metadata = metadata
        }
    }

    return overlay_writer.execute({ command })
end

function overlay_writer.update_workspace_context(context_id, updates)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not context_id or context_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "context_id"
    end

    if not updates or type(updates) ~= "table" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "updates"
    end

    local payload = {
        user_id = user_id,
        context_id = context_id
    }
    for k, v in pairs(updates) do
        payload[k] = v
    end

    local command = {
        type = consts.OPERATION_TYPE.UPDATE_WORKSPACE_CONTEXT,
        payload = payload
    }

    return overlay_writer.execute({ command })
end

function overlay_writer.delete_workspace_context(context_id)
    local user_id, err = get_user_id()
    if err then
        return nil, err
    end

    if not context_id or context_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "context_id"
    end

    local command = {
        type = consts.OPERATION_TYPE.DELETE_WORKSPACE_CONTEXT,
        payload = {
            user_id = user_id,
            context_id = context_id
        }
    }

    return overlay_writer.execute({ command })
end

return overlay_writer