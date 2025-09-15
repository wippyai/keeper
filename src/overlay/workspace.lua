local json = require("json")
local consts = require("consts")

-- Dependencies (for mocking in tests)
local deps = {
    registry = require("registry"),
    reader = require("reader"),
    writer = require("writer")
}

local workspace = {}
local session_methods = {}
local session_mt = { __index = session_methods }

-- ============================================================================
-- PRIVATE HELPERS
-- ============================================================================

local function validate_namespace_access(entry_id, permissions)
    if not permissions or #permissions == 0 then
        return false, consts.ERROR.INSUFFICIENT_PERMISSIONS .. ": no permissions defined"
    end

    -- Extract namespace from entry ID (same as snapshot.lua)
    local function extract_namespace_from_entry_id(entry_id)
        if not entry_id or type(entry_id) ~= "string" then
            return nil
        end
        local namespace, _ = entry_id:match("([^:]+):(.+)")
        return namespace
    end

    local matching_permissions = {}

    for _, perm in ipairs(permissions) do
        if perm.namespace_pattern then
            local pattern = perm.namespace_pattern
            local matches = false

            -- Handle .* patterns (hierarchical namespace matching)
            if pattern:sub(-2) == ".*" then
                local target_namespace = pattern:sub(1, -3) -- Remove ".*"
                local entry_namespace = extract_namespace_from_entry_id(entry_id)
                if entry_namespace then
                    -- Exact match or hierarchical match with proper dot boundary
                    if entry_namespace == target_namespace or
                        (entry_namespace:sub(1, #target_namespace) == target_namespace and
                            entry_namespace:sub(#target_namespace + 1, #target_namespace + 1) == ".") then
                        matches = true
                    end
                end
            end

            -- Handle exact matches
            if not pattern:find("*", 1, true) then
                local entry_namespace = extract_namespace_from_entry_id(entry_id)
                if entry_namespace == pattern then
                    matches = true
                end
            end

            -- Handle other wildcard patterns
            if pattern:find("*", 1, true) and pattern:sub(-2) ~= ".*" then
                local lua_pattern = pattern:gsub("%*", ".*")
                lua_pattern = "^" .. lua_pattern .. "$"
                if entry_id:match(lua_pattern) then
                    matches = true
                end
            end

            -- Collect matching permission
            if matches then
                table.insert(matching_permissions, perm.permission_type)
            end
        end
    end

    -- No matches found
    if #matching_permissions == 0 then
        return false, consts.ERROR.INSUFFICIENT_PERMISSIONS .. ": entry outside workspace namespace patterns"
    end

    -- Prioritize write over read (return highest permission level)
    for _, perm_type in ipairs(matching_permissions) do
        if perm_type == consts.PERMISSION_TYPE.WRITE then
            return true, consts.PERMISSION_TYPE.WRITE
        end
    end

    -- Return read if no write found
    for _, perm_type in ipairs(matching_permissions) do
        if perm_type == consts.PERMISSION_TYPE.READ then
            return true, consts.PERMISSION_TYPE.READ
        end
    end

    -- Fallback (shouldn't reach here)
    return true, matching_permissions[1]
end

-- ============================================================================
-- SESSION INITIALIZATION
-- ============================================================================

-- Create a new workspace session
function workspace.open(workspace_id, user_id)
    if not workspace_id or workspace_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_id"
    end

    if not user_id or user_id == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "user_id"
    end

    local instance = {
        workspace_id = workspace_id,
        user_id = user_id,
        _workspace_info = nil, -- Lazy loaded
        _entry_cache = {},     -- Cache for workspace entries
        _dirty = false         -- Track if session has changes
    }

    return setmetatable(instance, session_mt), nil
end

-- ============================================================================
-- PRIVATE SESSION METHODS
-- ============================================================================

-- Lazy load workspace information with permissions
function session_methods:_ensure_workspace_info()
    if self._workspace_info then
        return self._workspace_info, nil
    end

    local reader, reader_err = deps.reader.for_user(self.user_id)
    if reader_err then
        return nil, reader_err
    end

    local workspace, err = reader:with_workspaces(self.workspace_id)
        :include_permissions()
        :one()
    if err then
        return nil, err
    end

    if not workspace then
        return nil, consts.ERROR.WORKSPACE_NOT_FOUND
    end

    -- Check access permissions
    if workspace.user_id ~= self.user_id then
        return nil, consts.ERROR.WORKSPACE_ACCESS_DENIED
    end

    self._workspace_info = workspace
    return workspace, nil
end

-- Load workspace entry from cache or database
function session_methods:_get_workspace_entry(entry_id)
    -- Check cache first
    if self._entry_cache[entry_id] then
        return self._entry_cache[entry_id]
    end

    -- Load from database
    local reader, reader_err = deps.reader.for_workspace(self.workspace_id)
    if reader_err then
        return nil
    end

    local entries, err = reader:with_entries(entry_id):all()
    if err or not entries or #entries == 0 then
        return nil
    end

    local workspace_entry = entries[1]

    -- Cache the entry
    self._entry_cache[entry_id] = workspace_entry

    return workspace_entry
end

-- Validate entry access based on workspace permissions
function session_methods:_validate_entry_access(entry_id)
    local workspace, err = self:_ensure_workspace_info()
    if err then
        return false, err
    end

    local has_access, permission_type = validate_namespace_access(entry_id, workspace.permissions)
    if not has_access then
        return false, permission_type -- permission_type contains error message when access denied
    end

    return true, permission_type
end

-- Check if entry access requires write permission
function session_methods:_validate_write_access(entry_id)
    local has_access, permission_type = self:_validate_entry_access(entry_id)
    if not has_access then
        return false, permission_type
    end

    if permission_type ~= consts.PERMISSION_TYPE.WRITE then
        return false, consts.ERROR.INSUFFICIENT_PERMISSIONS .. ": write access required"
    end

    return true, nil
end

-- ============================================================================
-- CORE ENTRY OPERATIONS
-- ============================================================================

-- Get entry (merged workspace + main registry view)
function session_methods:get(entry_id)
    if not entry_id or entry_id == "" then
        return nil, consts.ERROR.ENTRY_ID_REQUIRED
    end

    local valid, err = self:_validate_entry_access(entry_id)
    if not valid then
        return nil, err
    end

    -- Check workspace first
    local workspace_entry = self:_get_workspace_entry(entry_id)
    if workspace_entry then
        if workspace_entry.operation_type == consts.ENTRY_OPERATION_TYPE.DELETE then
            return nil, nil -- Entry is deleted in workspace
        elseif workspace_entry.operation_type == consts.ENTRY_OPERATION_TYPE.CREATE or
            workspace_entry.operation_type == consts.ENTRY_OPERATION_TYPE.UPDATE then
            return workspace_entry.entry_data, nil
        end
    end

    -- Fallback to main registry
    local registry_entry, registry_err = deps.registry.get(entry_id)
    return registry_entry, registry_err
end

-- Get original entry from main registry only
function session_methods:get_original(entry_id)
    if not entry_id or entry_id == "" then
        return nil, consts.ERROR.ENTRY_ID_REQUIRED
    end

    local valid, err = self:_validate_entry_access(entry_id)
    if not valid then
        return nil, err
    end

    return deps.registry.get(entry_id)
end

-- Get workspace override only (nil if no override) - returns clean DTO {id, kind, meta, data}
function session_methods:get_workspace(entry_id)
    if not entry_id or entry_id == "" then
        return nil, consts.ERROR.ENTRY_ID_REQUIRED
    end

    local valid, err = self:_validate_entry_access(entry_id)
    if not valid then
        return nil, err
    end

    local workspace_entry = self:_get_workspace_entry(entry_id)
    if not workspace_entry then
        return nil, nil
    end

    if workspace_entry.operation_type == consts.ENTRY_OPERATION_TYPE.DELETE then
        return { _deleted = true }, nil
    else
        -- Return clean DTO format
        return {
            id = entry_id,
            kind = workspace_entry.entry_kind,
            meta = workspace_entry.entry_meta or {},
            data = workspace_entry.entry_data or {}
        }, nil
    end
end

-- Check if entry has workspace override
function session_methods:has_override(entry_id)
    if not entry_id or entry_id == "" then
        return false
    end

    local valid, err = self:_validate_entry_access(entry_id)
    if not valid then
        return false
    end

    local workspace_entry = self:_get_workspace_entry(entry_id)
    return workspace_entry ~= nil
end

-- Update entry in workspace - FIXED to handle new format from edit.lua
function session_methods:upsert_entry(entry_id, entry_info)
    if not entry_id or entry_id == "" then
        return nil, consts.ERROR.ENTRY_ID_REQUIRED
    end

    if not entry_info or type(entry_info) ~= "table" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "entry_info"
    end

    -- Validate write access
    local valid, err = self:_validate_write_access(entry_id)
    if not valid then
        return nil, err
    end

    -- Determine operation type
    local operation_type = consts.ENTRY_OPERATION_TYPE.UPDATE
    local original_entry, _ = deps.registry.get(entry_id)
    if not original_entry then
        operation_type = consts.ENTRY_OPERATION_TYPE.CREATE
    end

    -- Extract components from entry_info - support both old and new formats
    local entry_kind, entry_data, entry_meta

    if entry_info.kind and entry_info.data then
        -- New format from edit.lua: {kind, data, meta}
        entry_kind = entry_info.kind
        entry_data = entry_info.data
        entry_meta = entry_info.meta
    else
        -- Old format: all fields flattened in entry_info
        -- Extract entry_meta if provided
        entry_meta = entry_info.entry_meta

        -- Extract entry_kind if provided
        entry_kind = entry_info.entry_kind or entry_info.kind

        -- Clean entry_data by removing meta and kind fields
        entry_data = {}
        for k, v in pairs(entry_info) do
            if k ~= "entry_meta" and k ~= "entry_kind" and k ~= "kind" and k ~= "meta" then
                entry_data[k] = v
            end
        end

        -- If meta was provided directly (not as entry_meta), use it
        if not entry_meta and entry_info.meta then
            entry_meta = entry_info.meta
        end
    end

    -- Validate that we have the required entry_kind
    if not entry_kind or entry_kind == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "entry_kind"
    end

    -- Create/update workspace entry
    local result, write_err
    local workspace_entry = self:_get_workspace_entry(entry_id)

    if workspace_entry then
        -- Update existing workspace entry
        result, write_err = deps.writer.update_workspace_entry(workspace_entry.workspace_entry_id, {
            operation_type = operation_type,
            entry_kind = entry_kind,
            entry_data = entry_data,
            entry_meta = entry_meta
        })
    else
        -- Create new workspace entry
        result, write_err = deps.writer.create_workspace_entry(
            self.workspace_id,
            entry_id,
            operation_type,
            entry_data,
            entry_meta,
            entry_kind
        )
    end

    if write_err then
        return nil, write_err
    end

    -- Update cache
    self._entry_cache[entry_id] = {
        workspace_entry_id = result.results[1].workspace_entry_id,
        workspace_id = self.workspace_id,
        entry_id = entry_id,
        operation_type = operation_type,
        entry_data = entry_data,
        entry_meta = entry_meta,
        entry_kind = entry_kind
    }

    -- Mark session as dirty
    self._dirty = true

    return result, nil
end

-- Delete entry in workspace (mark as deleted)
function session_methods:delete_entry(entry_id)
    if not entry_id or entry_id == "" then
        return nil, consts.ERROR.ENTRY_ID_REQUIRED
    end

    -- Validate write access
    local valid, err = self:_validate_write_access(entry_id)
    if not valid then
        return nil, err
    end

    -- Get entry_kind for DELETE operation (required by ops.lua)
    local entry_kind = nil
    local workspace_entry = self:_get_workspace_entry(entry_id)

    if workspace_entry then
        entry_kind = workspace_entry.entry_kind
    else
        -- Get kind from registry entry
        local registry_entry, reg_err = deps.registry.get(entry_id)
        if registry_entry then
            entry_kind = registry_entry.kind
        end
    end

    if not entry_kind then
        return nil, "Cannot delete entry: unable to determine entry kind for " .. entry_id
    end

    -- Create/update workspace entry as DELETE operation
    local result, write_err

    if workspace_entry then
        -- Update existing workspace entry to DELETE
        result, write_err = deps.writer.update_workspace_entry(workspace_entry.workspace_entry_id, {
            operation_type = consts.ENTRY_OPERATION_TYPE.DELETE,
            entry_data = nil,
            entry_meta = nil
        })
    else
        -- Create new DELETE workspace entry
        result, write_err = deps.writer.create_workspace_entry(
            self.workspace_id,
            entry_id,
            consts.ENTRY_OPERATION_TYPE.DELETE,
            nil,       -- no entry data for delete
            nil,       -- no entry meta for delete
            entry_kind -- required entry_kind parameter
        )
    end

    if write_err then
        return nil, write_err
    end

    -- Update cache
    self._entry_cache[entry_id] = {
        workspace_entry_id = result.results[1].workspace_entry_id,
        workspace_id = self.workspace_id,
        entry_id = entry_id,
        operation_type = consts.ENTRY_OPERATION_TYPE.DELETE,
        entry_data = nil,
        entry_meta = nil,
        entry_kind = entry_kind
    }

    -- Mark session as dirty
    self._dirty = true

    return result, nil
end

-- Reset entry (remove workspace override)
function session_methods:reset_entry(entry_id)
    if not entry_id or entry_id == "" then
        return nil, consts.ERROR.ENTRY_ID_REQUIRED
    end

    -- Validate write access
    local valid, err = self:_validate_write_access(entry_id)
    if not valid then
        return nil, err
    end

    local workspace_entry = self:_get_workspace_entry(entry_id)
    if not workspace_entry then
        return nil, nil -- No override to reset
    end

    -- Delete the workspace entry
    local result, write_err = deps.writer.delete_workspace_entry(workspace_entry.workspace_entry_id)
    if write_err then
        return nil, write_err
    end

    -- Clear from cache
    self._entry_cache[entry_id] = nil

    -- Mark session as dirty
    self._dirty = true

    return result, nil
end

-- ============================================================================
-- WORKSPACE METADATA MANAGEMENT
-- ============================================================================

-- Set workspace metadata
function session_methods:set_meta(key, value)
    if not key or key == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "key"
    end

    local workspace, err = self:_ensure_workspace_info()
    if err then
        return nil, err
    end

    -- Get current metadata
    local current_meta = workspace.metadata or {}
    local old_value = current_meta[key]

    -- Update the key
    current_meta[key] = value

    -- Save to database
    local result, write_err = deps.writer.update_workspace(self.workspace_id, {
        metadata = current_meta
    })

    if write_err then
        return nil, write_err
    end

    -- Update cached workspace info
    workspace.metadata = current_meta

    -- Mark session as dirty
    self._dirty = true

    return result, nil
end

-- Get workspace metadata value
function session_methods:get_meta(key)
    if not key or key == "" then
        return nil
    end

    local workspace, err = self:_ensure_workspace_info()
    if err then
        return nil
    end

    local metadata = workspace.metadata or {}
    return metadata[key]
end

-- Get all workspace metadata
function session_methods:get_all_meta()
    local workspace, err = self:_ensure_workspace_info()
    if err then
        return {}
    end

    return workspace.metadata or {}
end

-- Remove workspace metadata key
function session_methods:remove_meta(key)
    if not key or key == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "key"
    end

    local workspace, err = self:_ensure_workspace_info()
    if err then
        return nil, err
    end

    local current_meta = workspace.metadata or {}
    local old_value = current_meta[key]
    current_meta[key] = nil

    local result, write_err = deps.writer.update_workspace(self.workspace_id, {
        metadata = current_meta
    })

    if write_err then
        return nil, write_err
    end

    workspace.metadata = current_meta

    -- Mark session as dirty
    self._dirty = true

    return result, nil
end

-- ============================================================================
-- WORKSPACE FIELD UPDATES
-- ============================================================================

-- Update workspace fields (title, description, status)
function session_methods:update_workspace(updates)
    if not updates or type(updates) ~= "table" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "updates"
    end

    local workspace, err = self:_ensure_workspace_info()
    if err then
        return nil, err
    end

    -- Track what fields are being changed
    local changed_fields = {}
    local old_values = {}

    for field, new_value in pairs(updates) do
        if field == "title" or field == "description" or field == "status" then
            if workspace[field] ~= new_value then
                changed_fields[field] = new_value
                old_values[field] = workspace[field]
            end
        end
    end

    -- Only proceed if there are actual changes
    if next(changed_fields) == nil then
        return { changes_made = false }, nil
    end

    -- Save to database
    local result, write_err = deps.writer.update_workspace(self.workspace_id, changed_fields)

    if write_err then
        return nil, write_err
    end

    -- Update cached workspace info
    for field, new_value in pairs(changed_fields) do
        workspace[field] = new_value
    end

    -- Mark session as dirty
    self._dirty = true

    return result, nil
end

-- ============================================================================
-- STATE INSPECTION
-- ============================================================================

-- Get list of entries with workspace overrides
function session_methods:get_dirty_entries()
    local reader, reader_err = deps.reader.for_workspace(self.workspace_id)
    if reader_err then
        return {}, reader_err
    end

    local entries, err = reader:all()
    if err then
        return {}, err
    end

    local dirty_entries = {}
    for _, entry in ipairs(entries) do
        table.insert(dirty_entries, {
            entry_id = entry.entry_id,
            operation_type = entry.operation_type,
            entry_kind = entry.entry_kind,
            entry_meta = entry.entry_meta,
            entry_data = entry.entry_data,
        })
    end

    return dirty_entries, nil
end

-- Get workspace statistics
function session_methods:get_workspace_stats()
    local workspace, err = self:_ensure_workspace_info()
    if err then
        return nil, err
    end

    local reader, reader_err = deps.reader.for_workspace(self.workspace_id)
    if reader_err then
        return nil, reader_err
    end

    local total_count, count_err = reader:count()
    if count_err then
        return nil, count_err
    end

    local create_count, create_err = reader:with_operations(consts.ENTRY_OPERATION_TYPE.CREATE):count()
    if create_err then
        create_count = 0
    end

    local update_count, update_err = reader:with_operations(consts.ENTRY_OPERATION_TYPE.UPDATE):count()
    if update_err then
        update_count = 0
    end

    local delete_count, delete_err = reader:with_operations(consts.ENTRY_OPERATION_TYPE.DELETE):count()
    if delete_err then
        delete_count = 0
    end

    -- Build permissions summary
    local permissions_summary = {}
    if workspace.permissions and #workspace.permissions > 0 then
        for _, perm in ipairs(workspace.permissions) do
            table.insert(permissions_summary, perm.namespace_pattern .. ":" .. perm.permission_type)
        end
    end

    return {
        workspace_id = self.workspace_id,
        status = workspace.status,
        permissions = permissions_summary,
        total_entries = total_count,
        creates = create_count,
        updates = update_count,
        deletes = delete_count,
        is_dirty = self._dirty
    }, nil
end

-- Check if session is dirty
function session_methods:is_dirty()
    return self._dirty
end

-- Get workspace info
function session_methods:get_workspace_info()
    return self:_ensure_workspace_info()
end

-- Get workspace context entries
function session_methods:get_workspace_context()
    local workspace, err = self:_ensure_workspace_info()
    if err then
        return {}, err
    end

    local reader, reader_err = deps.reader.for_context(self.workspace_id)
    if reader_err then
        return {}, reader_err
    end

    local contexts, contexts_err = reader:all()
    if contexts_err then
        return {}, contexts_err
    end

    return contexts or {}, nil
end

workspace._deps = deps

return workspace
