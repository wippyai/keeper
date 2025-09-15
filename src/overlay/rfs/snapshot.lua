local consts = require("consts")

-- Workspace-aware registry snapshot builder
local snapshot = {}

-- Dependencies (initialized with real deps, can be overridden in tests)
snapshot._deps = {
    registry = require("registry")
}

-- Helper function to count table entries
local function count_table(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- ============================================================================
-- PATTERN MATCHING
-- ============================================================================

-- Extract namespace from entry ID
local function extract_namespace_from_entry_id(entry_id)
    if not entry_id or type(entry_id) ~= "string" then
        return nil
    end

    local namespace, _ = entry_id:match("([^:]+):(.+)")
    return namespace
end

-- Check if a namespace matches a pattern with precise boundary checking
local function matches_namespace_pattern(namespace, pattern)
    if not namespace or not pattern then
        return false
    end

    -- Handle :* patterns (exact namespace match)
    if pattern:sub(-2) == ":*" then
        local target_namespace = pattern:sub(1, -3) -- Remove ":*"
        return namespace == target_namespace
    end

    -- Handle .* patterns (hierarchical namespace match)
    if pattern:sub(-2) == ".*" then
        local target_namespace = pattern:sub(1, -3) -- Remove ".*"
        return namespace == target_namespace or
               (namespace:sub(1, #target_namespace) == target_namespace and
                namespace:sub(#target_namespace + 1, #target_namespace + 1) == ".")
    end

    -- Handle exact matches (no wildcards)
    if not pattern:find("*", 1, true) then
        return namespace == pattern
    end

    -- Handle other wildcard patterns (convert * to Lua pattern)
    local lua_pattern = pattern:gsub("%*", ".*")
    lua_pattern = "^" .. lua_pattern .. "$"
    return namespace:match(lua_pattern) ~= nil
end

-- Check if entry ID matches any workspace permission with precise boundary checking
local function entry_matches_workspace_permissions(entry_id, permissions)
    if not permissions or #permissions == 0 then
        return false
    end

    for _, perm in ipairs(permissions) do
        if perm.namespace_pattern then
            local pattern = perm.namespace_pattern

            -- Handle :* patterns (entry ID should start with pattern prefix)
            if pattern:sub(-2) == ":*" then
                local prefix = pattern:sub(1, -3) .. ":" -- Remove ":*" and add ":"
                if entry_id:sub(1, #prefix) == prefix then
                    return true
                end
            end

            -- Handle .* patterns (hierarchical namespace matching)
            if pattern:sub(-2) == ".*" then
                local target_namespace = pattern:sub(1, -3) -- Remove ".*"
                local entry_namespace = extract_namespace_from_entry_id(entry_id)
                if entry_namespace then
                    -- Exact match or hierarchical match with proper dot boundary
                    if entry_namespace == target_namespace or
                       (entry_namespace:sub(1, #target_namespace) == target_namespace and
                        entry_namespace:sub(#target_namespace + 1, #target_namespace + 1) == ".") then
                        return true
                    end
                end
            end

            -- Handle exact matches
            if not pattern:find("*", 1, true) then
                local entry_namespace = extract_namespace_from_entry_id(entry_id)
                if entry_namespace == pattern then
                    return true
                end
            end

            -- Handle other wildcard patterns
            if pattern:find("*", 1, true) and pattern:sub(-2) ~= ":*" and pattern:sub(-2) ~= ".*" then
                local lua_pattern = pattern:gsub("%*", ".*")
                lua_pattern = "^" .. lua_pattern .. "$"
                if entry_id:match(lua_pattern) then
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================================================
-- CORE SNAPSHOT OPERATIONS
-- ============================================================================

-- Get workspace-aware snapshot for specific namespace
function snapshot.get_namespace_snapshot(workspace_session, target_namespace)
    if not workspace_session then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_session"
    end

    if not target_namespace or target_namespace == "" then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "target_namespace"
    end

    -- Get workspace info for permission matching
    local workspace_info, err = workspace_session:get_workspace_info()
    if err then
        return nil, "Failed to get workspace info: " .. err
    end

    -- Get base registry entries for this namespace
    local registry_snapshot, err = snapshot._deps.registry.snapshot()
    if not registry_snapshot then
        return nil, "Failed to get registry snapshot: " .. (err or "unknown error")
    end

    local all_registry_entries, err = registry_snapshot:entries()
    if err then
        return nil, "Failed to get registry entries: " .. err
    end

    -- Filter to target namespace and workspace permissions
    local base_entries = {}

    for _, entry in ipairs(all_registry_entries) do
        local entry_ns = extract_namespace_from_entry_id(entry.id)
        if entry_ns == target_namespace and
           entry_matches_workspace_permissions(entry.id, workspace_info.permissions) then
            base_entries[entry.id] = entry
        end
    end

    -- Get workspace overrides for this namespace
    local dirty_entries, err = workspace_session:get_dirty_entries()
    if err then
        return nil, "Failed to get workspace overrides: " .. err
    end

    -- Apply workspace overlays
    for _, dirty_entry in ipairs(dirty_entries) do
        local entry_ns = extract_namespace_from_entry_id(dirty_entry.entry_id)

        -- Only process entries in target namespace
        if entry_ns == target_namespace then
            if dirty_entry.operation_type == consts.ENTRY_OPERATION_TYPE.DELETE then
                -- Remove from base entries
                base_entries[dirty_entry.entry_id] = nil

            elseif dirty_entry.operation_type == consts.ENTRY_OPERATION_TYPE.CREATE or
                   dirty_entry.operation_type == consts.ENTRY_OPERATION_TYPE.UPDATE then

                -- Get full workspace entry data (now returns clean DTO: {id, kind, meta, data})
                local workspace_entry_data, ws_err = workspace_session:get_workspace(dirty_entry.entry_id)

                -- Check for errors from get_workspace
                if ws_err then
                    return nil, "Failed to get workspace entry " .. dirty_entry.entry_id .. ": " .. ws_err
                end

                -- If workspace entry exists and is not deleted, use it completely (replaces registry entry)
                if workspace_entry_data then
                    if workspace_entry_data._deleted then
                        -- Entry is marked as deleted in workspace
                        base_entries[dirty_entry.entry_id] = nil
                    else
                        -- workspace_entry_data is now clean DTO: {id, kind, meta, data}
                        local registry_entry = {
                            id = workspace_entry_data.id,
                            kind = workspace_entry_data.kind,
                            meta = workspace_entry_data.meta or {},
                            data = workspace_entry_data.data or {}
                        }

                        base_entries[dirty_entry.entry_id] = registry_entry
                    end
                end
            end
        end
    end

    -- Convert map back to array
    local final_entries = {}
    for entry_id, entry in pairs(base_entries) do
        table.insert(final_entries, entry)
    end

    -- Sort by entry ID for consistent ordering
    table.sort(final_entries, function(a, b)
        return a.id < b.id
    end)

    return final_entries, nil
end

-- Get workspace-aware snapshot for all accessible namespaces
function snapshot.get_full_snapshot(workspace_session)
    if not workspace_session then
        return nil, consts.ERROR.MISSING_REQUIRED_FIELD .. "workspace_session"
    end

    -- Get workspace info for permission matching
    local workspace_info, err = workspace_session:get_workspace_info()
    if err then
        return nil, "Failed to get workspace info: " .. err
    end

    -- Get base registry entries
    local registry_snapshot, err = snapshot._deps.registry.snapshot()
    if not registry_snapshot then
        return nil, "Failed to get registry snapshot: " .. (err or "unknown error")
    end

    local all_registry_entries, err = registry_snapshot:entries()
    if err then
        return nil, "Failed to get registry entries: " .. err
    end

    -- Filter to workspace accessible entries using permissions array
    local base_entries = {}
    local namespaces = {}

    for _, entry in ipairs(all_registry_entries) do
        if entry_matches_workspace_permissions(entry.id, workspace_info.permissions) then
            base_entries[entry.id] = entry

            local entry_ns = extract_namespace_from_entry_id(entry.id)
            if entry_ns then
                namespaces[entry_ns] = true
            end
        end
    end

    -- Get workspace overrides
    local dirty_entries, err = workspace_session:get_dirty_entries()
    if err then
        return nil, "Failed to get workspace overrides: " .. err
    end

    -- Apply workspace overlays
    for _, dirty_entry in ipairs(dirty_entries) do
        if dirty_entry.operation_type == consts.ENTRY_OPERATION_TYPE.DELETE then
            -- Remove from base entries
            base_entries[dirty_entry.entry_id] = nil

        elseif dirty_entry.operation_type == consts.ENTRY_OPERATION_TYPE.CREATE or
               dirty_entry.operation_type == consts.ENTRY_OPERATION_TYPE.UPDATE then

            -- Get full workspace entry data (now returns clean DTO: {id, kind, meta, data})
            local workspace_entry_data, ws_err = workspace_session:get_workspace(dirty_entry.entry_id)

            -- Check for errors from get_workspace
            if ws_err then
                return nil, "Failed to get workspace entry " .. dirty_entry.entry_id .. ": " .. ws_err
            end

            -- If workspace entry exists and is not deleted, use it completely (replaces registry entry)
            if workspace_entry_data then
                if workspace_entry_data._deleted then
                    -- Entry is marked as deleted in workspace
                    base_entries[dirty_entry.entry_id] = nil
                else
                    -- workspace_entry_data is now clean DTO: {id, kind, meta, data}
                    local registry_entry = {
                        id = workspace_entry_data.id,
                        kind = workspace_entry_data.kind,
                        meta = workspace_entry_data.meta or {},
                        data = workspace_entry_data.data or {}
                    }

                    base_entries[dirty_entry.entry_id] = registry_entry

                    -- Track namespace for new entries
                    local entry_ns = extract_namespace_from_entry_id(dirty_entry.entry_id)
                    if entry_ns then
                        namespaces[entry_ns] = true
                    end
                end
            end
        end
    end

    -- Group entries by namespace
    local namespace_snapshots = {}
    for namespace, _ in pairs(namespaces) do
        local ns_entries = {}
        for entry_id, entry in pairs(base_entries) do
            local entry_ns = extract_namespace_from_entry_id(entry.id)
            if entry_ns == namespace then
                table.insert(ns_entries, entry)
            end
        end

        -- Sort entries by ID for consistent ordering
        table.sort(ns_entries, function(a, b)
            return a.id < b.id
        end)

        namespace_snapshots[namespace] = ns_entries
    end

    return namespace_snapshots, nil
end

-- Get single entry with workspace overlay applied
function snapshot.get_entry_snapshot(workspace_session, entry_id)
    if not workspace_session or not entry_id then
        return nil, "Workspace session and entry ID required"
    end

    -- Get workspace info for permission validation
    local workspace_info, err = workspace_session:get_workspace_info()
    if err then
        return nil, "Failed to get workspace info: " .. err
    end

    -- Check if entry is accessible via workspace permissions
    if not entry_matches_workspace_permissions(entry_id, workspace_info.permissions) then
        return nil, "Entry not accessible in workspace"
    end

    -- Check workspace first by looking at dirty entries
    local dirty_entries, err = workspace_session:get_dirty_entries()
    if err then
        return nil, "Failed to get dirty entries: " .. err
    end

    -- Find this entry in dirty entries
    for _, dirty_entry in ipairs(dirty_entries) do
        if dirty_entry.entry_id == entry_id then
            if dirty_entry.operation_type == consts.ENTRY_OPERATION_TYPE.DELETE then
                return nil, nil -- Entry deleted in workspace
            else
                -- Get workspace entry data (now returns clean DTO: {id, kind, meta, data})
                local workspace_entry_data, ws_err = workspace_session:get_workspace(entry_id)
                if ws_err then
                    return nil, "Failed to get workspace entry: " .. ws_err
                end

                if workspace_entry_data then
                    if workspace_entry_data._deleted then
                        return nil, nil -- Entry deleted in workspace
                    else
                        -- workspace_entry_data is already in registry format
                        return workspace_entry_data, nil
                    end
                end
            end
        end
    end

    -- Fallback to registry
    local registry_entry, err = snapshot._deps.registry.get(entry_id)
    if err then
        return nil, "Failed to get registry entry: " .. err
    end

    return registry_entry, nil
end

-- Check if entry exists in workspace-aware view
function snapshot.entry_exists(workspace_session, entry_id)
    if not workspace_session or not entry_id then
        return false
    end

    -- Check workspace first
    local workspace_entry, err = workspace_session:get_workspace(entry_id)
    if workspace_entry then
        return not workspace_entry._deleted
    end

    -- Check if entry matches workspace permissions
    local workspace_info, err = workspace_session:get_workspace_info()
    if err then
        return false
    end

    if not entry_matches_workspace_permissions(entry_id, workspace_info.permissions) then
        return false
    end

    -- Check base registry
    local registry_entry, err = snapshot._deps.registry.get(entry_id)
    return registry_entry ~= nil
end

-- Check if namespace exists in workspace view
function snapshot.namespace_exists(workspace_session, namespace)
    if not workspace_session or not namespace then
        return false
    end

    local entries, err = snapshot.get_namespace_snapshot(workspace_session, namespace)
    if err then
        return false
    end

    return entries and #entries > 0
end

return snapshot