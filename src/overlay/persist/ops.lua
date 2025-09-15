local sql = require("sql")
local json = require("json")
local time = require("time")
local uuid = require("uuid")
local consts = require("consts")

local overlay_ops = {}

overlay_ops.OPERATION_TYPE = consts.OPERATION_TYPE

-- ============================================================================
-- PRIVATE HELPERS
-- ============================================================================

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

local function validate_entry_operation_type(operation_type)
    return consts.VALID_VALUES.ENTRY_OPERATION_TYPE[operation_type] == true
end

local function validate_permission_type(permission_type)
    return consts.VALID_VALUES.PERMISSION_TYPE[permission_type] == true
end

local function validate_review_status(status)
    return not status or consts.VALID_VALUES.REVIEW_STATUS[status] == true
end

local function validate_content_type(content_type)
    return not content_type or consts.VALID_VALUES.CONTENT_TYPE[content_type] == true
end

local function validate_namespace_pattern(pattern)
    return pattern and type(pattern) == "string" and #pattern <= consts.LIMITS.MAX_NAMESPACE_PATTERN_LENGTH
end

-- Create audit entry - MUST succeed if called
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

    local audit_query = sql.builder.insert("overlay_registry_ops")
        :set_map({
            op_id = op_id,
            workspace_id = workspace_id,
            operation_type = operation_type,
            operation_data = encoded_data,
            user_id = user_id,
            created_at = now_ts
        })

    local audit_executor = audit_query:run_with(tx)
    local audit_result, audit_err = audit_executor:exec()

    if audit_err then
        return nil, "Audit creation failed: " .. audit_err
    end

    return op_id
end

-- ============================================================================
-- COMMAND HANDLERS
-- ============================================================================

local handlers = {}

-- Workspace Operations
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

    local insert_query = sql.builder.insert("overlay_registry_workspaces")
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

    -- Create audit entry - MUST succeed
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

    local update_query = sql.builder.update("overlay_registry_workspaces")
        :where("workspace_id = ?", payload.workspace_id)

    local has_update = false
    local updated_fields = {}

    if payload.title then
        update_query = update_query:set("title", payload.title)
        updated_fields.title = payload.title
        has_update = true
    end

    if payload.description then
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

    -- Create audit entry - MUST succeed
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

    local delete_query = sql.builder.delete("overlay_registry_workspaces")
        :where("workspace_id = ?", payload.workspace_id)

    local executor = delete_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    -- Create audit entry - MUST succeed
    local audit_data = {
        workspace_deleted = {
            workspace_id = payload.workspace_id,
            rows_affected = result.rows_affected
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, payload.workspace_id, consts.OPERATION_TYPE.DELETE_WORKSPACE, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        workspace_id = payload.workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected,
        deleted = true,
        user_id = payload.user_id
    }
end

-- Workspace Permission Operations
handlers[consts.OPERATION_TYPE.CREATE_WORKSPACE_PERMISSION] = function(tx, command)
    local payload = command.payload or {}

    if not payload.workspace_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not payload.namespace_pattern then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "namespace_pattern"
    end

    if not payload.permission_type then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "permission_type"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    if not validate_namespace_pattern(payload.namespace_pattern) then
        return nil, consts.ERROR.INVALID_NAMESPACE_PATTERN
    end

    if not validate_permission_type(payload.permission_type) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "permission_type"
    end

    local permission_id = uuid.v7()
    local now_ts = time.now():format(time.RFC3339NANO)

    local insert_query = sql.builder.insert("overlay_registry_workspace_permissions")
        :set_map({
            permission_id = permission_id,
            workspace_id = payload.workspace_id,
            namespace_pattern = payload.namespace_pattern,
            permission_type = payload.permission_type,
            created_at = now_ts
        })

    local executor = insert_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    -- Create audit entry - MUST succeed
    local audit_data = {
        permission_created = {
            permission_id = permission_id,
            workspace_id = payload.workspace_id,
            namespace_pattern = payload.namespace_pattern,
            permission_type = payload.permission_type
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, payload.workspace_id, consts.OPERATION_TYPE.CREATE_WORKSPACE_PERMISSION, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        permission_id = permission_id,
        workspace_id = payload.workspace_id,
        changes_made = true,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.DELETE_WORKSPACE_PERMISSION] = function(tx, command)
    local payload = command.payload or {}

    if not payload.permission_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "permission_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    -- Get workspace_id and other data BEFORE deleting - MUST succeed for audit
    local lookup_query = sql.builder.select("workspace_id", "namespace_pattern", "permission_type")
        :from("overlay_registry_workspace_permissions")
        :where("permission_id = ?", payload.permission_id)

    local lookup_executor = lookup_query:run_with(tx)
    local lookup_result, lookup_err = lookup_executor:query()

    if lookup_err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. lookup_err
    end

    if not lookup_result or #lookup_result == 0 then
        return nil, "Permission not found: " .. payload.permission_id
    end

    local workspace_id = lookup_result[1].workspace_id
    local namespace_pattern = lookup_result[1].namespace_pattern
    local permission_type = lookup_result[1].permission_type

    -- Create audit entry BEFORE deletion - MUST succeed
    local audit_data = {
        permission_deleted = {
            permission_id = payload.permission_id,
            workspace_id = workspace_id,
            namespace_pattern = namespace_pattern,
            permission_type = permission_type
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, workspace_id, consts.OPERATION_TYPE.DELETE_WORKSPACE_PERMISSION, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    -- Now perform the deletion
    local delete_query = sql.builder.delete("overlay_registry_workspace_permissions")
        :where("permission_id = ?", payload.permission_id)

    local executor = delete_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    return {
        permission_id = payload.permission_id,
        workspace_id = workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected,
        deleted = true,
        user_id = payload.user_id
    }
end

-- Workspace Entry Operations
handlers[consts.OPERATION_TYPE.CREATE_WORKSPACE_ENTRY] = function(tx, command)
    local payload = command.payload or {}

    if not payload.workspace_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not payload.entry_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "entry_id"
    end

    if not payload.operation_type then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "operation_type"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    -- Extract entry_kind from entry_data if not provided directly
    local entry_kind = payload.entry_kind
    if not entry_kind and payload.entry_data and type(payload.entry_data) == "table" then
        entry_kind = payload.entry_data.kind
    end

    if not entry_kind or entry_kind == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "entry_kind (must be provided or present in entry_data)"
    end

    if not validate_entry_operation_type(payload.operation_type) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "operation_type"
    end

    if payload.entry_id and #payload.entry_id > consts.LIMITS.MAX_ENTRY_ID_LENGTH then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "entry_id too long"
    end

    local workspace_entry_id = uuid.v7()
    local now_ts = time.now():format(time.RFC3339NANO)

    local entry_data, entry_data_err = encode_metadata(payload.entry_data)
    if entry_data_err then
        return nil, entry_data_err
    end

    local entry_meta, entry_meta_err = encode_metadata(payload.entry_meta)
    if entry_meta_err then
        return nil, entry_meta_err
    end

    local insert_query = sql.builder.insert("overlay_registry_workspace_entries")
        :set_map({
            workspace_entry_id = workspace_entry_id,
            workspace_id = payload.workspace_id,
            operation_type = payload.operation_type,
            entry_id = payload.entry_id,
            entry_kind = entry_kind,
            entry_data = entry_data,
            entry_meta = entry_meta,
            created_at = now_ts,
            updated_at = now_ts
        })

    local executor = insert_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    -- Create audit entry - MUST succeed
    local audit_data = {
        entry_created = {
            workspace_entry_id = workspace_entry_id,
            workspace_id = payload.workspace_id,
            entry_id = payload.entry_id,
            entry_kind = entry_kind,
            operation_type = payload.operation_type
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, payload.workspace_id, consts.OPERATION_TYPE.CREATE_WORKSPACE_ENTRY, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        workspace_entry_id = workspace_entry_id,
        workspace_id = payload.workspace_id,
        entry_id = payload.entry_id,
        changes_made = true,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.UPDATE_WORKSPACE_ENTRY] = function(tx, command)
    local payload = command.payload or {}

    if not payload.workspace_entry_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_entry_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    -- Get workspace_id BEFORE updating - MUST succeed for audit
    local lookup_query = sql.builder.select("workspace_id")
        :from("overlay_registry_workspace_entries")
        :where("workspace_entry_id = ?", payload.workspace_entry_id)

    local lookup_executor = lookup_query:run_with(tx)
    local lookup_result, lookup_err = lookup_executor:query()

    if lookup_err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. lookup_err
    end

    if not lookup_result or #lookup_result == 0 then
        return nil, "Workspace entry not found: " .. payload.workspace_entry_id
    end

    local workspace_id = lookup_result[1].workspace_id

    local update_query = sql.builder.update("overlay_registry_workspace_entries")
        :where("workspace_entry_id = ?", payload.workspace_entry_id)

    local has_update = false

    if payload.operation_type then
        if not validate_entry_operation_type(payload.operation_type) then
            return nil, consts.ERROR.INVALID_FIELD_VALUE .. "operation_type"
        end
        update_query = update_query:set("operation_type", payload.operation_type)
        has_update = true
    end

    if payload.entry_kind then
        update_query = update_query:set("entry_kind", payload.entry_kind)
        has_update = true
    end

    if payload.entry_data then
        local entry_data, entry_data_err = encode_metadata(payload.entry_data)
        if entry_data_err then
            return nil, entry_data_err
        end
        update_query = update_query:set("entry_data", entry_data)
        has_update = true
    end

    if payload.entry_meta then
        local entry_meta, entry_meta_err = encode_metadata(payload.entry_meta)
        if entry_meta_err then
            return nil, entry_meta_err
        end
        update_query = update_query:set("entry_meta", entry_meta)
        has_update = true
    end

    if not has_update then
        return {
            workspace_entry_id = payload.workspace_entry_id,
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

    -- Create audit entry - MUST succeed
    local audit_data = {
        entry_updated = {
            workspace_entry_id = payload.workspace_entry_id,
            rows_affected = result.rows_affected
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, workspace_id, consts.OPERATION_TYPE.UPDATE_WORKSPACE_ENTRY, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        workspace_entry_id = payload.workspace_entry_id,
        workspace_id = workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.DELETE_WORKSPACE_ENTRY] = function(tx, command)
    local payload = command.payload or {}

    if not payload.workspace_entry_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_entry_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    -- Get workspace_id and entry_id BEFORE deleting - MUST succeed for audit
    local lookup_query = sql.builder.select("workspace_id", "entry_id")
        :from("overlay_registry_workspace_entries")
        :where("workspace_entry_id = ?", payload.workspace_entry_id)

    local lookup_executor = lookup_query:run_with(tx)
    local lookup_result, lookup_err = lookup_executor:query()

    if lookup_err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. lookup_err
    end

    if not lookup_result or #lookup_result == 0 then
        return nil, "Workspace entry not found: " .. payload.workspace_entry_id
    end

    local workspace_id = lookup_result[1].workspace_id
    local entry_id = lookup_result[1].entry_id

    -- Create audit entry BEFORE deletion - MUST succeed
    local audit_data = {
        entry_deleted = {
            workspace_entry_id = payload.workspace_entry_id,
            entry_id = entry_id
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, workspace_id, consts.OPERATION_TYPE.DELETE_WORKSPACE_ENTRY, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    -- Now perform the deletion
    local delete_query = sql.builder.delete("overlay_registry_workspace_entries")
        :where("workspace_entry_id = ?", payload.workspace_entry_id)

    local executor = delete_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    return {
        workspace_entry_id = payload.workspace_entry_id,
        workspace_id = workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected,
        deleted = true,
        user_id = payload.user_id
    }
end

-- Workspace Review Operations
handlers[consts.OPERATION_TYPE.CREATE_WORKSPACE_REVIEW] = function(tx, command)
    local payload = command.payload or {}

    if not payload.workspace_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not payload.name then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "name"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    if payload.status and not validate_review_status(payload.status) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "status"
    end

    if payload.content_type and not validate_content_type(payload.content_type) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "content_type"
    end

    if payload.name and #payload.name > consts.LIMITS.MAX_REVIEW_NAME_LENGTH then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "name too long"
    end

    local review_id = uuid.v7()
    local now_ts = time.now():format(time.RFC3339NANO)

    local meta, meta_err = encode_metadata(payload.meta)
    if meta_err then
        return nil, meta_err
    end

    local insert_query = sql.builder.insert("overlay_registry_workspace_reviews")
        :set_map({
            review_id = review_id,
            workspace_id = payload.workspace_id,
            name = payload.name,
            content = payload.content,
            content_type = payload.content_type or consts.DEFAULTS.CONTENT_TYPE,
            meta = meta,
            status = payload.status or consts.DEFAULTS.REVIEW_STATUS,
            created_at = now_ts,
            updated_at = now_ts
        })

    local executor = insert_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    -- Create audit entry - MUST succeed
    local audit_data = {
        review_created = {
            review_id = review_id,
            workspace_id = payload.workspace_id,
            name = payload.name,
            content_type = payload.content_type or consts.DEFAULTS.CONTENT_TYPE,
            status = payload.status or consts.DEFAULTS.REVIEW_STATUS
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, payload.workspace_id, consts.OPERATION_TYPE.CREATE_WORKSPACE_REVIEW, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        review_id = review_id,
        workspace_id = payload.workspace_id,
        changes_made = true,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.UPDATE_WORKSPACE_REVIEW] = function(tx, command)
    local payload = command.payload or {}

    if not payload.review_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "review_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    if payload.status and not validate_review_status(payload.status) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "status"
    end

    if payload.content_type and not validate_content_type(payload.content_type) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "content_type"
    end

    -- Get workspace_id BEFORE updating - MUST succeed for audit
    local lookup_query = sql.builder.select("workspace_id")
        :from("overlay_registry_workspace_reviews")
        :where("review_id = ?", payload.review_id)

    local lookup_executor = lookup_query:run_with(tx)
    local lookup_result, lookup_err = lookup_executor:query()

    if lookup_err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. lookup_err
    end

    if not lookup_result or #lookup_result == 0 then
        return nil, "Review not found: " .. payload.review_id
    end

    local workspace_id = lookup_result[1].workspace_id

    local update_query = sql.builder.update("overlay_registry_workspace_reviews")
        :where("review_id = ?", payload.review_id)

    local has_update = false

    if payload.content then
        update_query = update_query:set("content", payload.content)
        has_update = true
    end

    if payload.content_type then
        update_query = update_query:set("content_type", payload.content_type)
        has_update = true
    end

    if payload.status then
        update_query = update_query:set("status", payload.status)
        has_update = true
    end

    if payload.meta then
        local meta, meta_err = encode_metadata(payload.meta)
        if meta_err then
            return nil, meta_err
        end
        update_query = update_query:set("meta", meta)
        has_update = true
    end

    if not has_update then
        return {
            review_id = payload.review_id,
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

    -- Create audit entry - MUST succeed
    local audit_data = {
        review_updated = {
            review_id = payload.review_id,
            rows_affected = result.rows_affected
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, workspace_id, consts.OPERATION_TYPE.UPDATE_WORKSPACE_REVIEW, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        review_id = payload.review_id,
        workspace_id = workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.DELETE_WORKSPACE_REVIEW] = function(tx, command)
    local payload = command.payload or {}

    if not payload.review_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "review_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    -- Get workspace_id and name BEFORE deleting - MUST succeed for audit
    local lookup_query = sql.builder.select("workspace_id", "name")
        :from("overlay_registry_workspace_reviews")
        :where("review_id = ?", payload.review_id)

    local lookup_executor = lookup_query:run_with(tx)
    local lookup_result, lookup_err = lookup_executor:query()

    if lookup_err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. lookup_err
    end

    if not lookup_result or #lookup_result == 0 then
        return nil, "Review not found: " .. payload.review_id
    end

    local workspace_id = lookup_result[1].workspace_id
    local name = lookup_result[1].name

    -- Create audit entry BEFORE deletion - MUST succeed
    local audit_data = {
        review_deleted = {
            review_id = payload.review_id,
            name = name
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, workspace_id, consts.OPERATION_TYPE.DELETE_WORKSPACE_REVIEW, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    -- Now perform the deletion
    local delete_query = sql.builder.delete("overlay_registry_workspace_reviews")
        :where("review_id = ?", payload.review_id)

    local executor = delete_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    return {
        review_id = payload.review_id,
        workspace_id = workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected,
        deleted = true,
        user_id = payload.user_id
    }
end

-- Workspace Context Operations
handlers[consts.OPERATION_TYPE.CREATE_WORKSPACE_CONTEXT] = function(tx, command)
    local payload = command.payload or {}

    if not payload.workspace_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not payload.label then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "label"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    if payload.content_type and not validate_content_type(payload.content_type) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "content_type"
    end

    local context_id = uuid.v7()
    local now_ts = time.now():format(time.RFC3339NANO)

    local metadata, metadata_err = encode_metadata(payload.metadata)
    if metadata_err then
        return nil, metadata_err
    end

    local insert_query = sql.builder.insert("overlay_registry_workspace_context")
        :set_map({
            context_id = context_id,
            workspace_id = payload.workspace_id,
            label = payload.label,
            content = payload.content,
            content_type = payload.content_type or consts.DEFAULTS.CONTENT_TYPE,
            metadata = metadata,
            created_at = now_ts,
            updated_at = now_ts
        })

    local executor = insert_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    -- Create audit entry - MUST succeed
    local audit_data = {
        context_created = {
            context_id = context_id,
            workspace_id = payload.workspace_id,
            label = payload.label,
            content_type = payload.content_type or consts.DEFAULTS.CONTENT_TYPE
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, payload.workspace_id, consts.OPERATION_TYPE.CREATE_WORKSPACE_CONTEXT, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        context_id = context_id,
        workspace_id = payload.workspace_id,
        changes_made = true,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.UPDATE_WORKSPACE_CONTEXT] = function(tx, command)
    local payload = command.payload or {}

    if not payload.context_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "context_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    if payload.content_type and not validate_content_type(payload.content_type) then
        return nil, consts.ERROR.INVALID_FIELD_VALUE .. "content_type"
    end

    -- Get workspace_id BEFORE updating - MUST succeed for audit
    local lookup_query = sql.builder.select("workspace_id")
        :from("overlay_registry_workspace_context")
        :where("context_id = ?", payload.context_id)

    local lookup_executor = lookup_query:run_with(tx)
    local lookup_result, lookup_err = lookup_executor:query()

    if lookup_err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. lookup_err
    end

    if not lookup_result or #lookup_result == 0 then
        return nil, "Context not found: " .. payload.context_id
    end

    local workspace_id = lookup_result[1].workspace_id

    local update_query = sql.builder.update("overlay_registry_workspace_context")
        :where("context_id = ?", payload.context_id)

    local has_update = false

    if payload.label then
        update_query = update_query:set("label", payload.label)
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
            context_id = payload.context_id,
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

    -- Create audit entry - MUST succeed
    local audit_data = {
        context_updated = {
            context_id = payload.context_id,
            rows_affected = result.rows_affected
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, workspace_id, consts.OPERATION_TYPE.UPDATE_WORKSPACE_CONTEXT, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    return {
        context_id = payload.context_id,
        workspace_id = workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected,
        user_id = payload.user_id
    }
end

handlers[consts.OPERATION_TYPE.DELETE_WORKSPACE_CONTEXT] = function(tx, command)
    local payload = command.payload or {}

    if not payload.context_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "context_id"
    end

    if not payload.user_id then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    -- Get workspace_id and label BEFORE deleting - MUST succeed for audit
    local lookup_query = sql.builder.select("workspace_id", "label")
        :from("overlay_registry_workspace_context")
        :where("context_id = ?", payload.context_id)

    local lookup_executor = lookup_query:run_with(tx)
    local lookup_result, lookup_err = lookup_executor:query()

    if lookup_err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. lookup_err
    end

    if not lookup_result or #lookup_result == 0 then
        return nil, "Context not found: " .. payload.context_id
    end

    local workspace_id = lookup_result[1].workspace_id
    local label = lookup_result[1].label

    -- Create audit entry BEFORE deletion - MUST succeed
    local audit_data = {
        context_deleted = {
            context_id = payload.context_id,
            label = label
        }
    }
    local audit_id, audit_err = create_audit_entry(tx, workspace_id, consts.OPERATION_TYPE.DELETE_WORKSPACE_CONTEXT, payload.user_id, audit_data)
    if audit_err then
        return nil, audit_err
    end

    -- Now perform the deletion
    local delete_query = sql.builder.delete("overlay_registry_workspace_context")
        :where("context_id = ?", payload.context_id)

    local executor = delete_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
    end

    return {
        context_id = payload.context_id,
        workspace_id = workspace_id,
        changes_made = result.rows_affected > 0,
        rows_affected = result.rows_affected,
        deleted = true,
        user_id = payload.user_id
    }
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function overlay_ops.execute(tx, commands)
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

return overlay_ops