-- keeper.gov.service:sync
--
-- Writes registry entries from specified namespaces to filesystem as canonical YAML.
-- Called after successful changesets to keep disk in sync with live registry.
-- Unlike download.lua (which writes everything), this targets specific namespaces only.

local registry = require("registry")
local yaml = require("yaml")
local logger = require("logger")
local fs_module = require("fs")
local consts = require("consts")

local log = logger:named("gov.service.sync")

local M = {}

M.KIND_CONFIG = {
    ["function.lua"]   = { source_field = "source", extension = ".lua" },
    ["library.lua"]    = { source_field = "source", extension = ".lua" },
    ["process.lua"]    = { source_field = "source", extension = ".lua" },
    ["workflow.lua"]   = { source_field = "source", extension = ".lua" },
    ["template.jet"]   = { source_field = "source", extension = ".jet" },
    ["registry.entry"] = {
        types = {
            ["view.page"]   = { source_field = "source", extension = ".html" },
            ["module.spec"] = { source_field = "source", extension = ".md" },
            ["agent.gen1"]  = { source_field = "source", extension = ".yml" },
        }
    }
}

local FIELD_ORDER: string[] = {
    "version", "namespace",
    "name", "kind", "contract",
    "meta", "type", "title", "comment", "group", "tags", "icon", "description", "order", "content_type",
    "prompt", "model", "temperature", "max_tokens", "tools", "memory", "delegate",
    "source", "modules", "imports", "method",
    "depends_on", "router", "set", "resources", "entries"
}

-- Pure: resolve the effective { source_field, extension } config for a given
-- kind + optional meta.type. Returns nil when no mapping exists.
function M.pick_kind_config(kind, meta_type)
    local kind_config = M.KIND_CONFIG[kind]
    if not kind_config then return nil end
    if kind_config.types and meta_type and kind_config.types[meta_type] then
        return kind_config.types[meta_type]
    end
    if kind_config.source_field and kind_config.extension then
        return kind_config
    end
    return nil
end

-- Pure: append the extension if the filename doesn't already end with it.
function M.append_extension(filename, extension)
    if not filename or not extension then return filename end
    if filename:sub(-#extension) == extension then return filename end
    return filename .. extension
end

-- Pure: "a.b.c" → "<base>/a/b/c"
function M.namespace_dir(base_dir, namespace)
    local current = base_dir
    for part in string.gmatch(string.gsub(namespace, "%.", "/"), "([^/]+)") do
        current = current .. "/" .. part
    end
    return current
end

-- Walk `namespace_dir` parts, ensuring each segment exists on disk.
local function ensure_directory(fs, base_dir, path)
    local current_path = base_dir
    for part in string.gmatch(string.gsub(path, "%.", "/"), "([^/]+)") do
        current_path = current_path .. "/" .. part
        if not fs:exists(current_path) then
            fs:mkdir(current_path)
        end
    end
    return current_path
end

local function should_write_file(fs, file_path, content)
    if not fs:exists(file_path) then return true end
    return fs:readfile(file_path) ~= content
end

-- Pure: pull the path out of a "file://..." URL. Returns nil for non-matching input.
function M.extract_filename(file_url)
    if not file_url or type(file_url) ~= "string" then return nil end
    return file_url:match("^file://(.+)$")
end

-- Pure: collect distinct namespaces referenced by a changeset's ops.
function M.changeset_namespaces(changeset)
    local seen = {}
    local list = {}
    for _, op in ipairs(changeset or {}) do
        local entry = op.entry
        local id = entry and entry.id
        if id then
            local ns = id:match("^([^:]+):")
            if ns and not seen[ns] then
                seen[ns] = true
                table.insert(list, ns)
            end
        end
    end
    return list
end

-- Pure: collect distinct valid entry IDs named directly by a changeset, map
-- each id to its last operation kind, and remember IDs created at any point in
-- the changeset so a surviving create/update lifecycle can be written to disk.
function M.changeset_entry_ops(changeset)
    local seen = {}
    local ids = {}
    local ops = {}
    local created = {}
    for _, op in ipairs(changeset or {}) do
        local entry = op.entry
        local id = entry and entry.id
        if type(id) == "string" and id:match("^([^:]+):(.+)$") then
            if not seen[id] then
                seen[id] = true
                table.insert(ids, id)
            end
            ops[id] = op.kind
            if op.kind == consts.REGISTRY_OPERATIONS.CREATE then
                created[id] = true
            end
        end
    end
    return ids, ops, created
end

-- Pure: reduce an entry's changeset lifecycle to the decisions shared by
-- registry collection, index patching, and source-file cleanup.
function M.entry_sync_decision(entry_id, entry_kind, ops_by_id, created_by_id)
    ops_by_id = ops_by_id or {}
    created_by_id = created_by_id or {}
    return {
        delete = ops_by_id[entry_id] == consts.REGISTRY_OPERATIONS.DELETE,
        guarded_missing = entry_kind == "ns.dependency" and not created_by_id[entry_id],
    }
end

-- Get current entries for a set of namespaces from the registry
local function collect_namespace_entries(ns_set)
    local snapshot, err = registry.snapshot()
    if not snapshot then
        return nil, "Failed to get registry snapshot: " .. (err or "unknown")
    end

    local all = snapshot:entries()
    local filtered = {}
    for _, entry in ipairs(all or {}) do
        local ns = entry.id and entry.id:match("^([^:]+):")
        if ns and ns_set[ns] then
            table.insert(filtered, entry)
        end
    end
    return filtered
end

local function collect_entries_by_id(id_set)
    local snapshot, err = registry.snapshot()
    if not snapshot then
        return nil, "Failed to get registry snapshot: " .. (err or "unknown")
    end

    local all = snapshot:entries()
    local filtered = {}
    for _, entry in ipairs(all or {}) do
        if entry.id and id_set[entry.id] then
            table.insert(filtered, entry)
        end
    end
    return filtered
end

local function yaml_entry_for(entry)
    if type(entry.id) ~= "string" then return nil, nil, nil end
    local ns, name = string.match(entry.id, "(.+):(.+)")
    if not ns or not name then return nil, nil, nil end

    local yaml_entry = { name = name, kind = entry.kind }
    if entry.meta then yaml_entry.meta = entry.meta end
    if entry.data then
        for k, v in pairs(entry.data) do
            yaml_entry[k] = v
        end
    end
    return ns, name, yaml_entry
end

function M.render_index_entry(namespace, entry)
    local entry_yaml, entry_err = yaml.encode(entry, {
        field_order = FIELD_ORDER,
        sort_unordered = true,
    })
    if entry_err or not entry_yaml then
        return nil, entry_err or "unknown"
    end

    local label = namespace .. ":" .. tostring(entry.name or "")
    entry_yaml = "  # " .. label .. "\n" .. "  - " .. entry_yaml:gsub("\n", "\n    ")
    return entry_yaml:gsub("[\n\r]+$", "")
end

local function split_lines(content)
    local lines = {}
    if type(content) ~= "string" or content == "" then return lines end
    for line in (content .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(lines, line)
    end
    return lines
end

local function scalar_value(raw)
    if not raw or raw == "" then return nil end
    return raw:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
end

-- Locate the entry name without assuming which field the YAML encoder emits
-- first. Sequence-item fields use four-space indentation after the initial
-- `  - ` line; nested `name` fields are therefore deliberately ignored.
-- Canonical identity comments are a fallback for unusual hand-written blocks.
local function block_name(lines, start_line, entry_line, finish, namespace)
    for line_number = entry_line, finish do
        local raw = lines[line_number] or ""
        local value
        if line_number == entry_line then
            value = raw:match("^  %- name:%s*(.-)%s*$")
        else
            value = raw:match("^    name:%s*(.-)%s*$")
        end
        local name = scalar_value(value)
        if name then return name end
    end

    local marker = (lines[start_line] or ""):match("^  #%s*(.-)%s*$")
    local prefix = tostring(namespace) .. ":"
    if marker and marker:sub(1, #prefix) == prefix then
        return scalar_value(marker:sub(#prefix + 1))
    end
    return nil
end

local function append_block_lines(out, block)
    for _, line in ipairs(split_lines(block)) do
        table.insert(out, line)
    end
end

local function sorted_names(map)
    local out = {}
    for name in pairs(map or {}) do table.insert(out, name) end
    table.sort(out)
    return out
end

-- Pure: patch one namespace _index.yaml at entry-block granularity. Existing
-- unrelated blocks are copied as bytes/lines from the input; only named
-- replacement/deletion blocks are touched. `guarded_missing[name]` prevents
-- appending a block that was not already present, used for non-create
-- ns.dependency syncs from throwaway registries.
function M.patch_index_content(existing, namespace, replacements, deletes, guarded_missing)
    replacements = replacements or {}
    deletes = deletes or {}
    guarded_missing = guarded_missing or {}

    local has_existing = type(existing) == "string" and existing ~= ""
    if not has_existing then
        local body = {}
        for _, name in ipairs(sorted_names(replacements)) do
            if not guarded_missing[name] then
                append_block_lines(body, replacements[name])
            end
        end
        if #body == 0 then return nil, false end

        local header, enc_err = yaml.encode({ namespace = namespace, version = "1.0" }, {
            field_order = FIELD_ORDER,
            sort_unordered = true,
        })
        if enc_err or not header then return nil, false, enc_err or "unknown" end

        return header .. "\nentries:\n" .. table.concat(body, "\n"), true
    end

    local lines = split_lines(existing)
    local entries_idx = nil
    for i, line in ipairs(lines) do
        if line:match("^entries:%s*$") then
            entries_idx = i
            break
        end
    end
    if not entries_idx then
        return M.patch_index_content(nil, namespace, replacements, deletes, guarded_missing)
    end

    local out = {}
    for i = 1, entries_idx do table.insert(out, lines[i]) end

    local found = {}
    local replaced = {}
    local i = entries_idx + 1
    while i <= #lines do
        local start = i
        local entry_line = nil

        if lines[i]:match("^  #") and lines[i + 1] and lines[i + 1]:match("^  %- ") then
            entry_line = i + 1
        elseif lines[i]:match("^  %- ") then
            entry_line = i
        end

        if not entry_line then
            table.insert(out, lines[i])
            i = i + 1
        else
            local next_start = entry_line + 1
            while next_start <= #lines do
                if lines[next_start]:match("^  %- ") then
                    break
                end
                if lines[next_start]:match("^  #") and lines[next_start + 1] and lines[next_start + 1]:match("^  %- ") then
                    break
                end
                next_start = next_start + 1
            end
            local finish = next_start - 1
            local name = block_name(lines, start, entry_line, finish, namespace)

            if name then found[name] = true end
            if name and deletes[name] then
                -- drop the block
            elseif name and replacements[name] then
                if not replaced[name] then
                    append_block_lines(out, replacements[name])
                    replaced[name] = true
                end
            else
                for j = start, finish do table.insert(out, lines[j]) end
            end
            i = next_start
        end
    end

    for _, name in ipairs(sorted_names(replacements)) do
        if not found[name] and not guarded_missing[name] then
            append_block_lines(out, replacements[name])
        end
    end

    -- A namespace document without an entry block is not a valid Wippy source.
    -- Returning nil tells the filesystem writer to remove the index instead of
    -- persisting an unbootable `entries:` document.
    local has_entries = false
    for _, line in ipairs(out) do
        if line:match("^  %- ") then
            has_entries = true
            break
        end
    end
    if not has_entries then return nil, true end

    local patched = table.concat(out, "\n")
    return patched, patched ~= existing
end

-- Write entries to filesystem grouped by namespace. One _index.yaml per namespace.
local function write_entries_to_fs(entries, options)
    options = options or {}
    local fs_id: string = tostring(consts.FILESYSTEM.SOURCE_FS_ID)
    local base_dir = "."

    local fs = fs_module.get(fs_id)
    if not fs then
        return nil, "Failed to get filesystem instance for '" .. fs_id .. "'"
    end

    if not fs:exists(base_dir) then
        fs:mkdir(base_dir)
    end

    local namespaces = {}
    local stats = { namespaces = 0, entries = 0, files = 0, files_skipped = 0 }

    for _, entry in ipairs(entries) do
        local ns, name = string.match(entry.id, "(.+):(.+)")
        if ns and name then
            if not namespaces[ns] then
                namespaces[ns] = { entries = {}, referenced_files = {} }
                stats.namespaces = stats.namespaces + 1
            end

            local yaml_entry = { name = name, kind = entry.kind }
            if entry.meta then yaml_entry.meta = entry.meta end
            if entry.data then
                for k, v in pairs(entry.data) do
                    yaml_entry[k] = v
                end
            end

            local config = M.pick_kind_config(entry.kind, entry.meta and entry.meta.type)

            if config and config.source_field and config.extension then
                local source_field = config.source_field
                local extension = config.extension
                local sv = yaml_entry[source_field]

                if sv and type(sv) == "string" and not sv:match("^file://") then
                    local dir_path = ensure_directory(fs, base_dir, ns)
                    local filename = M.append_extension(name, extension)
                    local file_path = dir_path .. "/" .. filename
                    if should_write_file(fs, file_path, sv) then
                        fs:write_file(file_path, tostring(sv))
                        stats.files = stats.files + 1
                    else
                        stats.files_skipped = stats.files_skipped + 1
                    end
                    yaml_entry[source_field] = "file://" .. filename
                    namespaces[ns].referenced_files[filename] = true
                elseif sv and type(sv) == "string" and sv:match("^file://") then
                    local filename = M.extract_filename(sv)
                    if filename then
                        namespaces[ns].referenced_files[filename] = true
                    end
                end
            end

            table.insert(namespaces[ns].entries, yaml_entry)
            stats.entries = stats.entries + 1
        end
    end

    for ns, namespace_data in pairs(namespaces) do
        if #namespace_data.entries > 0 then
            local dir_path = ensure_directory(fs, base_dir, ns)
            local index_filepath = dir_path .. "/" .. consts.FILESYSTEM.INDEX_FILENAME

            table.sort(namespace_data.entries, function(a, b) return a.name < b.name end)

            local header = { namespace = ns, version = "1.0" }
            local yaml_options: {field_order: string[], sort_unordered: boolean} =
                { field_order = FIELD_ORDER, sort_unordered = true }

            local header_yaml, enc_err = yaml.encode(header, yaml_options)
            if enc_err or not header_yaml then
                return nil, "Failed to encode YAML header for " .. ns .. ": " .. (enc_err or "unknown")
            end

            local content = header_yaml .. "\n" .. "entries:" .. "\n"
            for i, entry in ipairs(namespace_data.entries) do
                local entry_yaml, entry_err = yaml.encode(entry, yaml_options)
                if entry_err or not entry_yaml then
                    return nil, "Failed to encode entry " .. ns .. ":" .. entry.name .. ": " .. (entry_err or "unknown")
                end
                local label = ns .. ":" .. entry.name
                entry_yaml = "  # " .. label .. "\n" .. "  - " .. entry_yaml:gsub("\n", "\n    ")
                entry_yaml = entry_yaml:gsub("[\n\r]+$", "")
                content = content .. entry_yaml
                if i < #namespace_data.entries then
                    content = content .. "\n"
                end
            end

            if should_write_file(fs, index_filepath, content) then
                fs:write_file(index_filepath, content)
            end
        end
    end

    return stats
end

local function write_changeset_entries_to_fs(entries, changeset, ops_by_id, created_by_id)
    local fs_id: string = tostring(consts.FILESYSTEM.SOURCE_FS_ID)
    local base_dir = "."

    local fs = fs_module.get(fs_id)
    if not fs then
        return nil, "Failed to get filesystem instance for '" .. fs_id .. "'"
    end

    if not fs:exists(base_dir) then
        fs:mkdir(base_dir)
    end

    local stats = { namespaces = 0, entries = 0, files = 0, files_skipped = 0, index_files = 0 }
    local namespaces = {}

    local function ns_group(ns)
        if not namespaces[ns] then
            namespaces[ns] = { replacements = {}, deletes = {}, guarded_missing = {} }
            stats.namespaces = stats.namespaces + 1
        end
        return namespaces[ns]
    end

    for _, entry in ipairs(entries or {}) do
        local ns, name, yaml_entry = yaml_entry_for(entry)
        if ns and name and consts.is_namespace_managed(ns) then
            local group = ns_group(ns)
            local config = M.pick_kind_config(entry.kind, entry.meta and entry.meta.type)

            if config and config.source_field and config.extension then
                local source_field = config.source_field
                local extension = config.extension
                local sv = yaml_entry[source_field]

                if sv and type(sv) == "string" and not sv:match("^file://") then
                    local dir_path = ensure_directory(fs, base_dir, ns)
                    local filename = M.append_extension(name, extension)
                    local file_path = dir_path .. "/" .. filename
                    if should_write_file(fs, file_path, sv) then
                        fs:write_file(file_path, tostring(sv))
                        stats.files = stats.files + 1
                    else
                        stats.files_skipped = stats.files_skipped + 1
                    end
                    yaml_entry[source_field] = "file://" .. filename
                end
            end

            local block, block_err = M.render_index_entry(ns, yaml_entry)
            if not block then
                return nil, "Failed to encode entry " .. entry.id .. ": " .. tostring(block_err)
            end

            group.replacements[name] = block
            local decision = M.entry_sync_decision(
                entry.id, entry.kind, ops_by_id, created_by_id)
            if decision.guarded_missing then
                group.guarded_missing[name] = true
            end
            stats.entries = stats.entries + 1
        end
    end

    for _, op in ipairs(changeset or {}) do
        if op.kind == consts.REGISTRY_OPERATIONS.DELETE and op.entry and op.entry.id then
            local decision = M.entry_sync_decision(
                op.entry.id, op.entry.kind, ops_by_id, created_by_id)
            local ns, name = op.entry.id:match("^([^:]+):(.+)$")
            if decision.delete and ns and name and consts.is_namespace_managed(ns) then
                ns_group(ns).deletes[name] = true
            end
        end
    end

    for ns, namespace_data in pairs(namespaces) do
        local dir_path = M.namespace_dir(base_dir, ns)
        local index_filepath = dir_path .. "/" .. consts.FILESYSTEM.INDEX_FILENAME
        local existing = nil
        if fs:exists(index_filepath) then
            existing = fs:readfile(index_filepath)
        end

        local patched, changed, patch_err = M.patch_index_content(
            existing, ns, namespace_data.replacements,
            namespace_data.deletes, namespace_data.guarded_missing)
        if patch_err then
            return nil, "Failed to patch index for " .. ns .. ": " .. tostring(patch_err)
        end
        if changed then
            if patched then
                ensure_directory(fs, base_dir, ns)
                fs:write_file(index_filepath, patched)
                stats.index_files = stats.index_files + 1
            elseif existing then
                local removed, remove_err = fs:remove(index_filepath)
                if not removed then
                    return nil, "Failed to remove empty index for " .. ns .. ": " .. tostring(remove_err)
                end
                stats.index_files_removed = (stats.index_files_removed or 0) + 1
            end
        end
    end

    return stats
end

-- Delete _index.yaml for namespaces that no longer have any entries in the registry
local function prune_empty_namespaces(requested_namespaces, entries)
    local have_entries = {}
    for _, entry in ipairs(entries or {}) do
        local ns = entry.id and entry.id:match("^([^:]+):")
        if ns then have_entries[ns] = true end
    end

    local pruned = {}
    local fs_id: string = tostring(consts.FILESYSTEM.SOURCE_FS_ID)
    local fs = fs_module.get(fs_id)
    if not fs then return pruned end

    for _, ns in ipairs(requested_namespaces) do
        if not have_entries[ns] then
            local dir = M.namespace_dir(".", ns)
            local index_path = dir .. "/" .. consts.FILESYSTEM.INDEX_FILENAME
            if fs:exists(index_path) then
                local ok = fs:remove(index_path)
                if ok then
                    log:info("Pruned stale _index.yaml for empty namespace", { namespace = ns, path = index_path })
                    table.insert(pruned, ns)
                else
                    log:warn("Failed to prune stale _index.yaml", { namespace = ns, path = index_path })
                end
            end
        end
    end
    return pruned
end

-- Public: write specific namespaces from registry to filesystem
function M.sync_namespaces(namespace_list)
    if not namespace_list or #namespace_list == 0 then
        return { namespaces = 0, entries = 0, files = 0, files_skipped = 0, pruned = 0 }
    end

    local ns_set = {}
    local managed_only = {}
    for _, ns in ipairs(namespace_list) do
        if consts.is_namespace_managed(ns) then
            ns_set[ns] = true
            table.insert(managed_only, ns)
        else
            log:warn("Skipping unmanaged namespace for sync", { namespace = ns })
        end
    end

    if #managed_only == 0 then
        return { namespaces = 0, entries = 0, files = 0, files_skipped = 0, pruned = 0 }
    end

    log:info("Syncing namespaces to filesystem", { namespaces = managed_only })

    local entries, err = collect_namespace_entries(ns_set)
    if not entries then
        log:error("Failed to collect entries", { error = err })
        return nil, err
    end

    local stats, write_err = write_entries_to_fs(entries)
    if not stats then
        log:error("Failed to write entries", { error = write_err })
        return nil, write_err
    end

    local pruned = prune_empty_namespaces(managed_only, entries)
    stats.pruned = #pruned
    if #pruned > 0 then
        stats.pruned_namespaces = pruned
    end

    log:info("Namespace sync completed", stats)
    return stats
end

-- Pure: compute the on-disk file path for an entry. Returns nil when the
-- entry's kind has no canonical file mapping.
function M.entry_file_path(entry)
    if not entry or type(entry.id) ~= "string" then return nil end
    local ns, name = string.match(entry.id, "(.+):(.+)")
    if not ns or not name then return nil end

    local config = M.pick_kind_config(entry.kind, entry.meta and entry.meta.type)
    if not config or not config.extension then return nil end

    return M.namespace_dir(".", ns) .. "/" .. M.append_extension(name, config.extension)
end

-- Remove on-disk source files for entries deleted in this changeset.
local function remove_deleted_files(changeset, ops_by_id, created_by_id)
    local fs = fs_module.get(tostring(consts.FILESYSTEM.SOURCE_FS_ID))
    if not fs then return 0 end

    local removed = 0
    for _, op in ipairs(changeset or {}) do
        if op.kind == consts.REGISTRY_OPERATIONS.DELETE and op.entry and op.entry.id then
            local decision = M.entry_sync_decision(
                op.entry.id, op.entry.kind, ops_by_id, created_by_id)
            local ns = op.entry.id:match("^([^:]+):")
            if decision.delete and ns and consts.is_namespace_managed(ns) then
                local path = M.entry_file_path(op.entry)
                if path and fs:exists(path) then
                    if fs:remove(path) then
                        log:info("Removed source file for deleted entry", {
                            entry_id = op.entry.id, path = path,
                        })
                        removed = removed + 1
                    else
                        log:warn("Failed to remove source file", {
                            entry_id = op.entry.id, path = path,
                        })
                    end
                end
            end
        end
    end
    return removed
end

-- Public: sync namespaces affected by a changeset
function M.sync_changeset(changeset)
    local ids, ops_by_id, created_by_id = M.changeset_entry_ops(changeset)
    if #ids == 0 then
        return { namespaces = 0, entries = 0, files = 0, files_skipped = 0, pruned = 0 }
    end

    local id_set = {}
    for _, id in ipairs(ids) do
        local decision = M.entry_sync_decision(id, nil, ops_by_id, created_by_id)
        if not decision.delete then
            id_set[id] = true
        end
    end

    local entries, err = collect_entries_by_id(id_set)
    if not entries then return nil, err end

    local stats, write_err = write_changeset_entries_to_fs(
        entries, changeset, (ops_by_id :: any), (created_by_id :: any))
    if not stats then return nil, write_err end

    local removed = remove_deleted_files(
        changeset, (ops_by_id :: any), (created_by_id :: any))
    if removed > 0 then
        stats.files_removed = removed
    end
    return stats
end

return M
