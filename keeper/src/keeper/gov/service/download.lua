local registry = require("registry")
local yaml = require("yaml")
local logger = require("logger")
local consts = require("consts")
local fs_module = require("fs")
local sync = require("sync")

local log = logger:named("gov.service.download")

local M = {}

local FIELD_ORDER: {string} = {
    "version", "namespace",
    "name", "kind", "contract",
    "meta", "type", "title", "comment", "group", "tags", "icon", "description", "order", "content_type",
    "prompt", "model", "temperature", "max_tokens", "tools", "memory", "delegate",
    "source", "modules", "imports", "method",
    "depends_on", "router", "set", "resources", "entries"
}

-- Filter entries to only include managed namespaces (including child namespaces)
local function filter_managed_entries(entries)
    local filtered = {}
    local skipped = {}

    for _, entry in ipairs(entries) do
        local namespace = nil
        if entry.id then
            namespace = entry.id:match("^([^:]+):")
        end
        if namespace and consts.is_namespace_managed(namespace) then
            table.insert(filtered, entry)
        else
            table.insert(skipped, {
                id = entry.id or "unknown",
                namespace = namespace or "unknown"
            })
        end
    end

    if #skipped > 0 then
        log:info("Skipped unmanaged namespace entries", {
            skipped_count = #skipped,
            managed_namespaces = consts.get_managed_namespaces()
        })
        for _, skip in ipairs(skipped) do
            log:debug("Skipped entry", skip)
        end
    end

    return filtered
end

-- Walk namespace-dot segments, ensuring each directory exists.
local function ensure_directory(fs, base_dir, path)
    local current_path = base_dir
    for part in string.gmatch(string.gsub(path, "%.", "/"), "([^/]+)") do
        current_path = current_path .. "/" .. part
        if not fs:exists(current_path) then
            log:debug("Creating directory", { path = current_path })
            fs:mkdir(current_path)
        end
    end
    return current_path
end

local function should_write_file(fs, file_path, content)
    if not fs:exists(file_path) then
        log:debug("File doesn't exist, writing new file", { path = file_path })
        return true
    end

    local current_content = fs:readfile(file_path)
    if current_content ~= content then
        log:debug("File content differs, updating file", { path = file_path })
        return true
    end

    log:debug("File content unchanged, skipping write", { path = file_path })
    return false
end

-- Pure: turn a { [path] = "create"|"update" } map into a stable list of
-- { path, op } rows sorted by path so callers can surface deterministic output.
function M.compute_file_ops(written_files)
    local file_ops = {}
    if type(written_files) ~= "table" then return file_ops end
    for path, op in pairs(written_files) do
        table.insert(file_ops, { path = path, op = op })
    end
    table.sort(file_ops, function(a, b) return a.path < b.path end)
    return file_ops
end

-- Track files that were written during this run (path -> "create"|"update")
local written_files = {}

-- Download entries from registry to filesystem (managed namespaces only)
local function download(options: unknown)
    options = type(options) == "table" and options or {}
    written_files = {}

    log:info("Starting download from registry to filesystem")

    local fs_id: string = tostring(consts.FILESYSTEM.SOURCE_FS_ID)
    local base_dir = "."

    log:info("Using governance filesystem", {
        filesystem_id = fs_id,
        base_directory = base_dir
    })

    local fs = fs_module.get(fs_id)
    if not fs then
        log:error("Failed to get filesystem instance", { filesystem_id = fs_id })
        return {
            success = false,
            message = "Failed to get filesystem instance for '" .. fs_id .. "'"
        }
    end

    if not fs:exists(base_dir) then
        log:debug("Creating base directory", { path = base_dir })
        fs:mkdir(base_dir)
    end

    local snapshot, err = registry.snapshot()
    if not snapshot then
        log:error("Failed to get registry snapshot", { error = err })
        return {
            success = false,
            message = "Failed to get registry snapshot: " .. (err or "unknown error")
        }
    end

    local all_entries = snapshot:entries()
    local filtered_entries = filter_managed_entries(all_entries)

    log:info("Retrieved entries from registry", {
        total_count = #all_entries,
        managed_count = #filtered_entries
    })

    local namespaces = {}
    local stats = {
        namespaces = 0,
        entries = 0,
        files = 0,
        files_skipped = 0
    }

    for _, entry in ipairs(filtered_entries) do
        local ns, name = string.match(entry.id, "(.+):(.+)")
        if ns and name then
            if not namespaces[ns] then
                namespaces[ns] = {
                    entries = {},
                    referenced_files = {}
                }
                stats.namespaces = stats.namespaces + 1
                log:debug("Added new namespace", { namespace = ns })
            end

            local yaml_entry = {
                name = name,
                kind = entry.kind
            }

            if entry.meta then yaml_entry.meta = entry.meta end
            if entry.data then
                for k, v in pairs(entry.data) do
                    yaml_entry[k] = v
                end
            end

            local config = sync.pick_kind_config(entry.kind, entry.meta and entry.meta.type)

            if config and config.source_field and config.extension then
                local source_field = config.source_field
                local extension = config.extension
                local sv = yaml_entry[source_field]

                if sv and type(sv) == "string" and not sv:match("^file://") then
                    local dir_path = ensure_directory(fs, base_dir, ns)
                    local filename = sync.append_extension(name, extension)
                    local file_path = dir_path .. "/" .. filename
                    if should_write_file(fs, file_path, sv) then
                        local existed = fs:exists(file_path)
                        log:debug("Writing file", { path = file_path })
                        fs:write_file(file_path, tostring(sv))
                        written_files[file_path] = existed and "update" or "create"
                        stats.files = stats.files + 1
                    else
                        stats.files_skipped = stats.files_skipped + 1
                    end

                    yaml_entry[source_field] = "file://" .. filename
                    namespaces[ns].referenced_files[filename] = true
                    log:debug("Tracking referenced file", {namespace = ns, filename = filename})
                elseif sv and type(sv) == "string" and sv:match("^file://") then
                    local filename = sync.extract_filename(sv)
                    if filename then
                        namespaces[ns].referenced_files[filename] = true
                        log:debug("Tracking existing file reference", {namespace = ns, filename = filename})
                    end
                end
            end

            table.insert(namespaces[ns].entries, yaml_entry)
            stats.entries = stats.entries + 1
        else
            log:warn("Invalid ID format, skipping entry", { entry_id = entry.id })
        end
    end

    for ns, namespace_data in pairs(namespaces) do
        if #namespace_data.entries == 0 then
            log:info("Skipping empty namespace", { namespace = ns })
            goto continue
        end

        local dir_path = ensure_directory(fs, base_dir, ns)
        local index_filepath = dir_path .. "/" .. consts.FILESYSTEM.INDEX_FILENAME

        table.sort(namespace_data.entries, function(a, b)
            return a.name < b.name
        end)

        local header = {
            namespace = ns,
            version = "1.0"
        }

        if namespace_data.meta then
            header.meta = namespace_data.meta
        end

        local yaml_options: {field_order: {string}, sort_unordered: boolean} = {
            field_order = FIELD_ORDER,
            sort_unordered = true
        }

        local header_yaml, err = yaml.encode(header, yaml_options)
        if err or not header_yaml then
            log:error("Failed to encode YAML header", {namespace = ns, error = err})
            return {
                success = false,
                message = "Failed to encode YAML header: " .. (err or "unknown error")
            }
        end

        local content = header_yaml .. "\n" .. "entries:" .. "\n"

        for i, entry in ipairs(namespace_data.entries) do
            local entry_yaml, err = yaml.encode(entry, yaml_options)
            if err or not entry_yaml then
                log:error("Failed to encode entry", {namespace = ns, name = entry.name, error = err})
                return {
                    success = false,
                    message = "Failed to encode entry: " .. (err or "unknown error")
                }
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
            local existed = fs:exists(index_filepath)
            log:debug("Writing index file", { path = index_filepath })
            fs:write_file(index_filepath, content)
            written_files[index_filepath] = existed and "update" or "create"
        else
            log:debug("Index file unchanged, skipping write", { path = index_filepath })
        end

        ::continue::
    end

    local file_ops = M.compute_file_ops(written_files)

    log:info("Download completed", stats)
    return {
        success = true,
        message = "Registry successfully synchronized to filesystem",
        stats = stats,
        file_ops = file_ops
    }
end

local function run(args)
    log:info("Starting download process")

    if not args then
        log:error("No arguments provided")
        return {
            success = false,
            message = "No arguments provided",
            error = "Missing required arguments"
        }
    end

    local request_id = args.request_id or "unknown"
    local user_id = args.user_id

    log:info("Processing download request", {
        request_id = request_id,
        user_id = user_id
    })

    log:info("Performing download operation")
    local result = download(args.options or {})
    if not result then
        return {
            success = false,
            message = "Download returned no result",
            error = "Internal error"
        }
    end

    if result.success then
        log:info("Download operation completed successfully", {
            request_id = request_id,
            user_id = user_id,
            stats = result.stats
        })
    else
        log:error("Download operation failed", {
            error = result.message,
            request_id = request_id,
            user_id = user_id
        })
    end

    return result
end

M.run = run
return M
