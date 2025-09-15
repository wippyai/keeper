-- Registry Virtual Filesystem with Fluent API
local rfs = {}

-- Dependencies (initialized with real deps, can be overridden in tests)
rfs._deps = {
    registry = require("registry"),
    snapshot = require("snapshot"),
    ns = require("ns"),
    consts = require("consts")
}

-- ============================================================================
-- INTERNAL PATH UTILITIES
-- ============================================================================

local function parse_path(vfs_path)
    if not vfs_path or type(vfs_path) ~= "string" then
        return nil, nil, rfs._deps.consts.RFS.RFS_ERROR.INVALID_PATH_FORMAT
    end

    local parts = {}
    for part in vfs_path:gmatch("[^" .. rfs._deps.consts.RFS.PATH.PATH_SEPARATOR .. "]+") do
        table.insert(parts, part)
    end

    if #parts < 2 then
        return nil, nil, rfs._deps.consts.RFS.RFS_ERROR.INVALID_PATH_FORMAT .. ": " .. vfs_path
    end

    local filename = parts[#parts]
    table.remove(parts, #parts)
    local namespace = table.concat(parts, rfs._deps.consts.RFS.PATH.NAMESPACE_SEPARATOR)

    return namespace, filename, nil
end

local function build_vfs_path(namespace, filename)
    return namespace:gsub(rfs._deps.consts.RFS.PATH.NAMESPACE_SEPARATOR, rfs._deps.consts.RFS.PATH.PATH_SEPARATOR) ..
           rfs._deps.consts.RFS.PATH.PATH_SEPARATOR .. filename
end

-- ============================================================================
-- HELPER FUNCTIONS (DEFINED EARLY FOR PROPER SCOPING)
-- ============================================================================

local function file_belongs_to_entry(filename, entry_name, entry_id, session)
    if filename == rfs._deps.consts.RFS.PATH.INDEX_FILENAME then
        return false -- _index.yaml doesn't belong to any single entry
    end

    -- Get entry to check its configuration
    local entry_data, err = session and session:get_workspace(entry_id) or rfs._deps.registry.get(entry_id)
    if not entry_data then
        return false
    end

    local config = rfs._deps.ns.get_file_config({kind = entry_data.kind, meta = entry_data.meta})
    if not config then
        return false
    end

    local expected_filename = rfs._deps.ns.generate_filename(entry_name, config)
    return expected_filename == filename
end

local function is_writable(status, session)
    if not session then
        return false -- registry-only mode = read-only
    end
    if status == rfs._deps.consts.RFS.FILE_STATUS.DELETED then
        return false -- can't edit deleted files
    end
    return true
end

local function read_file_content(namespace, filename, entries)
    -- Handle _index.yaml
    if filename == rfs._deps.consts.RFS.PATH.INDEX_FILENAME then
        local namespace_obj = rfs._deps.ns.new(namespace, entries)
        local content, err = namespace_obj:to_yaml()
        return content, nil -- no single entry owns _index.yaml
    end

    -- Handle source files - find owning entry
    for _, entry in ipairs(entries) do
        local config = rfs._deps.ns.get_file_config(entry)
        if config then
            local entry_ns, entry_name = entry.id:match("([^:]+):(.+)")
            if entry_name then
                local source_field = config.source_field
                local entry_filename = nil

                if entry.data and entry.data[source_field] then
                    local existing_filename = rfs._deps.ns.extract_filename_from_url(entry.data[source_field])
                    if existing_filename then
                        entry_filename = existing_filename
                    else
                        entry_filename = rfs._deps.ns.generate_filename(entry_name, config)
                    end
                end

                if entry_filename == filename then
                    local content, err = rfs._deps.ns.extract_source_content(entry)
                    return content, entry
                end
            end
        end
    end

    return nil, nil
end

-- ============================================================================
-- SNAPSHOT MANAGEMENT
-- ============================================================================

local function get_namespace_entries(namespace, session)
    if session then
        return rfs._deps.snapshot.get_namespace_snapshot(session, namespace)
    else
        local registry_snapshot, err = rfs._deps.registry.snapshot()
        if not registry_snapshot then
            return nil, err or rfs._deps.consts.ERROR.DB_CONNECTION_FAILED
        end

        local all_entries, err = registry_snapshot:entries()
        if err then
            return nil, rfs._deps.consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
        end

        local namespace_entries = {}
        for _, entry in ipairs(all_entries) do
            local entry_ns, _ = entry.id:match("([^:]+):(.+)")
            if entry_ns == namespace then
                table.insert(namespace_entries, entry)
            end
        end

        if #namespace_entries == 0 then
            return nil, rfs._deps.consts.RFS.RFS_ERROR.NAMESPACE_NOT_FOUND .. ": " .. namespace
        end

        return namespace_entries, nil
    end
end

local function get_file_status(namespace, filename, session)
    if not session then
        return rfs._deps.consts.RFS.FILE_STATUS.CLEAN
    end

    local dirty_entries, err = session:get_dirty_entries()
    if err or not dirty_entries then
        return rfs._deps.consts.RFS.FILE_STATUS.CLEAN
    end

    for _, dirty in ipairs(dirty_entries) do
        local entry_ns, entry_name = dirty.entry_id:match("([^:]+):(.+)")
        if entry_ns == namespace then
            -- Check if this file belongs to this entry
            if file_belongs_to_entry(filename, entry_name, dirty.entry_id, session) then
                if dirty.operation_type == rfs._deps.consts.ENTRY_OPERATION_TYPE.DELETE then
                    return rfs._deps.consts.RFS.FILE_STATUS.DELETED
                elseif dirty.operation_type == rfs._deps.consts.ENTRY_OPERATION_TYPE.CREATE then
                    return rfs._deps.consts.RFS.FILE_STATUS.NEW
                else
                    return rfs._deps.consts.RFS.FILE_STATUS.MODIFIED
                end
            end
        end
    end

    return rfs._deps.consts.RFS.FILE_STATUS.CLEAN
end

-- ============================================================================
-- EXECUTION IMPLEMENTATIONS
-- ============================================================================

local function execute_read_files(paths, session, options)
    local results = {}

    -- Group paths by namespace to minimize snapshot calls
    local namespace_groups = {}
    for _, path in ipairs(paths) do
        local namespace, filename, err = parse_path(path)
        if err then
            results[path] = {error = err}
        else
            if not namespace_groups[namespace] then
                namespace_groups[namespace] = {}
            end
            table.insert(namespace_groups[namespace], {path = path, filename = filename})
        end
    end

    -- Process each namespace once
    for namespace, files in pairs(namespace_groups) do
        local entries, err = get_namespace_entries(namespace, session)
        if err then
            for _, file_info in ipairs(files) do
                results[file_info.path] = {error = err}
            end
        else
            -- Process all files in this namespace using the same snapshot
            for _, file_info in ipairs(files) do
                local path = file_info.path
                local filename = file_info.filename

                local content, entry_data = read_file_content(namespace, filename, entries)

                if content then
                    local status = rfs._deps.consts.RFS.FILE_STATUS.CLEAN
                    if options.include_status then
                        status = get_file_status(namespace, filename, session)
                    end

                    results[path] = {
                        content = content,
                        status = status,
                        writable = is_writable(status, session),
                        entry_id = entry_data and entry_data.id or nil,
                        entry_kind = entry_data and entry_data.kind or nil,
                        entry_meta = options.include_meta and entry_data and entry_data.meta or {}
                    }
                else
                    results[path] = {error = rfs._deps.consts.RFS.RFS_ERROR.FILE_NOT_FOUND .. ": " .. filename}
                end
            end
        end
    end

    return results
end

local function execute_list_files(namespace, session, options)
    if not namespace or namespace == "" then
        return nil, "Namespace is required"
    end

    local entries, err = get_namespace_entries(namespace, session)
    if err then
        return nil, err
    end

    local namespace_obj = rfs._deps.ns.new(namespace, entries)
    local files = namespace_obj:list_files()

    local file_list = {
        namespace = namespace,
        files = {}
    }

    for _, filename in ipairs(files) do
        local file_entry = {name = filename}

        if options.include_status then
            file_entry.status = get_file_status(namespace, filename, session)
        end

        table.insert(file_list.files, file_entry)
    end

    return file_list
end

local function execute_get_tree(root_namespace, session)
    root_namespace = root_namespace or "."

    if session then
        local namespace_snapshots, err = rfs._deps.snapshot.get_full_snapshot(session)
        if err then
            return nil, err
        end

        local tree_data = {
            root = root_namespace,
            namespaces = {}
        }

        for ns, entries in pairs(namespace_snapshots) do
            local should_include = false

            if root_namespace == "." then
                should_include = true
            else
                should_include = (ns == root_namespace) or
                    (ns:match("^" .. root_namespace:gsub("%.", "%.") .. "%."))
            end

            if should_include and #entries > 0 then
                local namespace_obj = rfs._deps.ns.new(ns, entries)
                local files = namespace_obj:list_files()
                table.insert(tree_data.namespaces, {
                    namespace = ns,
                    entry_count = #entries,
                    files = files
                })
            end
        end

        table.sort(tree_data.namespaces, function(a, b)
            return a.namespace < b.namespace
        end)

        return tree_data, nil
    else
        -- Registry-only mode
        local registry_snapshot, err = rfs._deps.registry.snapshot()
        if not registry_snapshot then
            return nil, err or rfs._deps.consts.ERROR.DB_CONNECTION_FAILED
        end

        local all_entries, err = registry_snapshot:entries()
        if err then
            return nil, rfs._deps.consts.ERROR.DB_OPERATION_FAILED .. ": " .. err
        end

        -- Group by namespace
        local namespace_groups = {}
        for _, entry in ipairs(all_entries) do
            local entry_ns, _ = entry.id:match("([^:]+):(.+)")
            if entry_ns then
                if not namespace_groups[entry_ns] then
                    namespace_groups[entry_ns] = {}
                end
                table.insert(namespace_groups[entry_ns], entry)
            end
        end

        local tree_data = {
            root = root_namespace,
            namespaces = {}
        }

        for ns, entries in pairs(namespace_groups) do
            local should_include = false

            if root_namespace == "." then
                should_include = true
            else
                should_include = (ns == root_namespace) or
                    (ns:match("^" .. root_namespace:gsub("%.", "%.") .. "%."))
            end

            if should_include then
                local namespace_obj = rfs._deps.ns.new(ns, entries)
                local files = namespace_obj:list_files()
                table.insert(tree_data.namespaces, {
                    namespace = ns,
                    entry_count = #entries,
                    files = files
                })
            end
        end

        table.sort(tree_data.namespaces, function(a, b)
            return a.namespace < b.namespace
        end)

        return tree_data, nil
    end
end

local function execute_namespace_exists(namespace, session)
    local entries, err = get_namespace_entries(namespace, session)
    if err then
        return false, err
    end
    return entries and #entries > 0, nil
end

local function execute_file_exists(namespace, filename, session)
    local entries, err = get_namespace_entries(namespace, session)
    if err then
        return false, err
    end

    local namespace_obj = rfs._deps.ns.new(namespace, entries)
    return namespace_obj:file_exists(filename), nil
end

-- ============================================================================
-- FLUENT API READER
-- ============================================================================

local reader_methods = {}
local reader_mt = { __index = reader_methods }

function reader_methods:_copy()
    local new_reader = {}
    for k, v in pairs(self) do
        new_reader[k] = v
    end
    return setmetatable(new_reader, reader_mt)
end

function reader_methods:from_workspace(session)
    local new_reader = self:_copy()
    new_reader._session = session
    return new_reader
end

function reader_methods:from_registry()
    local new_reader = self:_copy()
    new_reader._session = nil
    return new_reader
end

function reader_methods:include_meta(enabled)
    local new_reader = self:_copy()
    new_reader._include_meta = enabled ~= false
    return new_reader
end

function reader_methods:include_status(enabled)
    local new_reader = self:_copy()
    new_reader._include_status = enabled ~= false
    return new_reader
end

-- ============================================================================
-- EXECUTION METHODS
-- ============================================================================

function reader_methods:read_files(paths)
    return execute_read_files(paths, self._session, {
        include_meta = self._include_meta,
        include_status = self._include_status
    })
end

function reader_methods:read_file(path)
    local results = self:read_files({path})
    return results[path]
end

function reader_methods:list_files(namespace)
    return execute_list_files(namespace, self._session, {
        include_status = self._include_status
    })
end

function reader_methods:get_tree(root_namespace)
    return execute_get_tree(root_namespace, self._session)
end

function reader_methods:namespace_exists(namespace)
    return execute_namespace_exists(namespace, self._session)
end

function reader_methods:file_exists(path)
    local namespace, filename, err = parse_path(path)
    if err then
        return false, err
    end
    return execute_file_exists(namespace, filename, self._session)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Create fluent reader
function rfs.reader()
    return setmetatable({
        _session = nil,
        _include_meta = true,
        _include_status = true
    }, reader_mt)
end

return rfs