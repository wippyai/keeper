local registry = require("registry")
local json = require("json")
local yaml = require("yaml")
local logger = require("logger")
local consts = require("consts")
local fs_module = require("fs")

local log = logger:named("gov.service.download")

-- Define file mapping configurations by kind
local KIND_CONFIG = {
    ["function.lua"] = {
        source_field = "source",
        extension = ".lua"
    },
    ["library.lua"] = {
        source_field = "source",
        extension = ".lua"
    },
    ["process.lua"] = {
        source_field = "source",
        extension = ".lua"
    },
    ["template.jet"] = {
        source_field = "source",
        extension = ".jet"
    },
    ["registry.entry"] = {
        -- Type-specific configurations
        types = {
            ["view.page"] = {
                source_field = "source",
                extension = ".html"
            },
            ["module.spec"] = {
                source_field = "source",
                extension = ".md"
            },
            ["agent.gen1"] = {
                source_field = "source",
                extension = ".yml"
            }
        }
    }
}

-- Define field order priority for YAML output
local FIELD_ORDER = {
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
        local namespace = entry.namespace or (entry.id and entry.id:match("^([^:]+):"))
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

-- Helper function to ensure directory exists
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

-- Extract filename from file:// URL
local function extract_filename(file_url)
    if not file_url or type(file_url) ~= "string" then
        return nil
    end
    return file_url:match("^file://(.+)$")
end

-- Compare file content to avoid unnecessary writes
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

-- Track files that were written during this run
local written_files = {}

-- Download entries from registry to filesystem (managed namespaces only)
local function download(options)
    options = options or {}
    written_files = {} -- Reset tracking of written files

    log:info("Starting download from registry to filesystem")

    -- Use governance filesystem
    local fs_id = consts.FILESYSTEM.SOURCE_FS_ID
    local base_dir = "." -- Root of governance filesystem

    log:info("Using governance filesystem", {
        filesystem_id = fs_id,
        base_directory = base_dir
    })

    -- Get filesystem instance
    local fs = fs_module.get(fs_id)
    if not fs then
        log:error("Failed to get filesystem instance", { filesystem_id = fs_id })
        return {
            success = false,
            message = "Failed to get filesystem instance for '" .. fs_id .. "'"
        }
    end

    -- Ensure base directory exists
    if not fs:exists(base_dir) then
        log:debug("Creating base directory", { path = base_dir })
        fs:mkdir(base_dir)
    end

    -- Get registry snapshot
    local snapshot, err = registry.snapshot()
    if not snapshot then
        log:error("Failed to get registry snapshot", { error = err })
        return {
            success = false,
            message = "Failed to get registry snapshot: " .. (err or "unknown error")
        }
    end

    -- Get all entries and filter to managed namespaces only
    local all_entries = snapshot:entries()
    local filtered_entries = filter_managed_entries(all_entries)

    log:info("Retrieved entries from registry", {
        total_count = #all_entries,
        managed_count = #filtered_entries
    })

    -- Track namespaces and group entries by namespace
    local namespaces = {}
    local stats = {
        namespaces = 0,
        entries = 0,
        files = 0,
        files_skipped = 0
    }

    -- Group entries by namespace
    for _, entry in ipairs(filtered_entries) do
        -- Parse ID to extract namespace and name
        local ns, name = string.match(entry.id, "(.+):(.+)")
        if ns and name then
            -- Initialize namespace entry if not exists
            if not namespaces[ns] then
                namespaces[ns] = {
                    entries = {},
                    referenced_files = {} -- Track referenced files
                }
                stats.namespaces = stats.namespaces + 1
                log:debug("Added new namespace", { namespace = ns })
            end

            -- Create entry structure (preserving original structure)
            local yaml_entry = {
                name = name,
                kind = entry.kind
            }

            -- Preserve meta as a nested structure
            if entry.meta then
                yaml_entry.meta = entry.meta
            end

            -- Copy all data fields to yaml_entry
            if entry.data then
                for k, v in pairs(entry.data) do
                    yaml_entry[k] = v
                end
            end

            -- Get config for this kind
            local kind_config = KIND_CONFIG[entry.kind]
            local config = nil

            -- Check if we have a direct kind config or need to check meta.type
            if kind_config then
                if kind_config.types and entry.meta and entry.meta.type and
                    kind_config.types[entry.meta.type] then
                    -- Use type-specific config
                    config = kind_config.types[entry.meta.type]
                else
                    -- Use direct kind config
                    config = kind_config
                end
            end

            -- Handle file materialization if we have a config
            if config and config.source_field and config.extension then
                local source_field = config.source_field
                local extension = config.extension

                -- Check if the source field exists and isn't already a file:// URL
                if yaml_entry[source_field] and type(yaml_entry[source_field]) == "string" and
                    not yaml_entry[source_field]:match("^file://") then
                    -- Prepare directory path
                    local dir_path = ensure_directory(fs, base_dir, ns)

                    -- Determine filename
                    local filename = name
                    if not filename:match(extension .. "$") then
                        filename = filename .. extension
                    end

                    -- Write file only if content differs or file doesn't exist
                    local file_path = dir_path .. "/" .. filename
                    if should_write_file(fs, file_path, yaml_entry[source_field]) then
                        log:debug("Writing file", { path = file_path })
                        fs:write_file(file_path, yaml_entry[source_field])
                        written_files[file_path] = true
                        stats.files = stats.files + 1
                    else
                        stats.files_skipped = stats.files_skipped + 1
                    end

                    -- Update to file reference and track the reference
                    yaml_entry[source_field] = "file://" .. filename
                    namespaces[ns].referenced_files[filename] = true
                    log:debug("Tracking referenced file", {namespace = ns, filename = filename})
                elseif yaml_entry[source_field] and type(yaml_entry[source_field]) == "string" and
                    yaml_entry[source_field]:match("^file://") then
                    -- Extract the filename and track it as referenced
                    local filename = extract_filename(yaml_entry[source_field])
                    if filename then
                        namespaces[ns].referenced_files[filename] = true
                        log:debug("Tracking existing file reference", {namespace = ns, filename = filename})
                    end
                end
            end

            -- Add to namespace entries
            table.insert(namespaces[ns].entries, yaml_entry)
            stats.entries = stats.entries + 1
        else
            log:warn("Invalid ID format, skipping entry", { entry_id = entry.id })
        end
    end

    -- Write namespace files
    for ns, namespace_data in pairs(namespaces) do
        -- Skip empty namespaces (no entries)
        if #namespace_data.entries == 0 then
            log:info("Skipping empty namespace", { namespace = ns })
            goto continue
        end

        -- Prepare directory path
        local dir_path = ensure_directory(fs, base_dir, ns)

        -- Generate only _index.yaml file
        local index_filepath = dir_path .. "/" .. consts.FILESYSTEM.INDEX_FILENAME

        -- Sort entries by name
        table.sort(namespace_data.entries, function(a, b)
            return a.name < b.name
        end)

        -- Generate the header content (namespace, version, meta)
        local header = {
            namespace = ns,
            version = "1.0"
        }

        -- Add meta section if it exists
        if namespace_data.meta then
            header.meta = namespace_data.meta
        end

        -- Define yaml options according to spec
        local yaml_options = {
            indent = 2,                -- 2-space indentation
            field_order = FIELD_ORDER, -- Field order according to our priority list
            sort_unordered = true      -- Sort remaining fields alphabetically
        }

        -- Generate YAML for header
        local header_yaml, err = yaml.encode(header, yaml_options)
        if err then
            log:error("Failed to encode YAML header", {namespace = ns, error = err})
            return {
                success = false,
                message = "Failed to encode YAML header: " .. err
            }
        end

        -- Start with the header content
        local content = header_yaml

        -- Add blank line and entries section header
        content = content .. "\n" .. "entries:" .. "\n"

        -- Process each entry individually
        for i, entry in ipairs(namespace_data.entries) do
            -- Generate YAML for a single entry
            local entry_yaml, err = yaml.encode(entry, yaml_options)
            if err then
                log:error("Failed to encode entry", {namespace = ns, name = entry.name, error = err})
                return {
                    success = false,
                    message = "Failed to encode entry: " .. err
                }
            end

            local label = ns .. ":" .. entry.name

            -- Format the entry with proper indentation
            -- The entry is currently formatted without the leading "- ", so add it
            entry_yaml = "  # " .. label .. "\n" .. "  - " .. entry_yaml:gsub("\n", "\n    ")

            -- Trim any trailing newlines
            entry_yaml = entry_yaml:gsub("[\n\r]+$", "")

            -- Add the entry to the content
            content = content .. entry_yaml

            -- Add blank line between entries (except after the last one)
            if i < #namespace_data.entries then
                content = content .. "\n"
            end
        end

        -- Write the file if content differs or file doesn't exist
        if should_write_file(fs, index_filepath, content) then
            log:debug("Writing index file", { path = index_filepath })
            fs:write_file(index_filepath, content)
            written_files[index_filepath] = true
        else
            log:debug("Index file unchanged, skipping write", { path = index_filepath })
        end

        ::continue::
    end

    log:info("Download completed", stats)
    return {
        success = true,
        message = "Registry successfully synchronized to filesystem",
        stats = stats
    }
end

-- Main run function
local function run(args)
    log:info("Starting download process")

    -- Validate arguments
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

    -- Perform download operation
    log:info("Performing download operation")
    local result = download(args.options or {})

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

-- Export the run function
return { run = run }