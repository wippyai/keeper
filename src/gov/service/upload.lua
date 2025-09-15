local registry = require("registry")
local json = require("json")
local loader = require("loader")
local logger = require("logger")
local consts = require("consts")
local fs_module = require("fs")

local log = logger:named("gov.service.upload")

-- Operation types
local OP = {
    CREATE = "entry.create",
    UPDATE = "entry.update",
    DELETE = "entry.delete"
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

-- Get current registry entries (filtered to managed namespaces)
local function get_registry_entries()
    log:debug("Getting current registry entries")

    local snapshot, err = registry.snapshot()
    if not snapshot then
        return nil, "Failed to get registry snapshot: " .. tostring(err)
    end

    local all_entries = snapshot:entries()
    local filtered_entries = filter_managed_entries(all_entries)

    log:info("Retrieved registry entries", {
        total_count = #all_entries,
        managed_count = #filtered_entries
    })

    return filtered_entries
end

-- Get filesystem entries (filtered to managed namespaces)
local function get_filesystem_entries(options)
    log:debug("Getting filesystem entries", options)

    -- Use governance filesystem
    local fs_id = consts.FILESYSTEM.SOURCE_FS_ID

    -- Create a loader instance for the governance filesystem
    local loader_instance, err = loader.new(fs_id)
    if not loader_instance then
        return nil, "Failed to create loader for filesystem '" .. fs_id .. "': " .. tostring(err)
    end

    -- Get source directory from governance filesystem
    local fs = fs_module.get(fs_id)
    if not fs then
        return nil, "Failed to get filesystem instance: " .. fs_id
    end

    -- Use root directory of governance filesystem
    local directory = "."

    log:debug("Loading entries from filesystem", {
        filesystem = fs_id,
        directory = directory
    })

    -- Load entries from the governance source directory
    local all_entries, err = loader_instance:load_directory(directory, {})
    if not all_entries then
        return nil, "Failed to load entries from directory '" .. directory .. "': " .. tostring(err)
    end

    -- Filter to only managed namespaces (including child namespaces)
    local filtered_entries = filter_managed_entries(all_entries)

    log:info("Retrieved filesystem entries", {
        total_count = #all_entries,
        managed_count = #filtered_entries
    })

    return filtered_entries
end

-- Compare registry entries with filesystem entries
local function compare_entries(currentEntries, targetEntries)
    log:debug("Comparing registry and filesystem entries", {
        registry_count = #currentEntries,
        filesystem_count = #targetEntries
    })

    local changeset, err = registry.build_delta(currentEntries, targetEntries)
    if not changeset then
        return nil, "Failed to build delta: " .. tostring(err)
    end

    log:info("Built changeset", {
        operations_count = #changeset
    })

    return {
        changeset = changeset,
        count = #changeset,
        has_changes = #changeset > 0
    }
end

-- Check if there are differences between registry and filesystem
local function has_changes(options)
    log:info("Checking for changes between registry and filesystem")

    -- Get current registry entries (managed namespaces only)
    local currentEntries, err = get_registry_entries()
    if not currentEntries then
        return {
            success = false,
            message = err
        }
    end

    -- Get filesystem entries (managed namespaces only)
    local filesystemEntries, err = get_filesystem_entries(options)
    if not filesystemEntries then
        return {
            success = false,
            message = err
        }
    end

    -- Build delta between current registry entries and filesystem entries
    local comparison, err = compare_entries(currentEntries, filesystemEntries)
    if not comparison then
        return {
            success = false,
            message = err
        }
    end

    log:info("Change detection completed", {
        has_changes = comparison.has_changes,
        operations_count = comparison.count
    })

    return {
        success = true,
        has_changes = comparison.has_changes,
        count = comparison.count
    }
end

-- Upload entries from filesystem to registry - builds and returns the changeset
local function upload(options)
    log:info("Starting upload operation")

    -- Get current registry entries (managed namespaces only)
    local currentEntries, err = get_registry_entries()
    if not currentEntries then
        return {
            success = false,
            message = err
        }
    end

    -- Get filesystem entries (managed namespaces only)
    local filesystemEntries, err = get_filesystem_entries(options)
    if not filesystemEntries then
        return {
            success = false,
            message = err
        }
    end

    -- Build delta between current registry entries and filesystem entries
    local comparison, err = compare_entries(currentEntries, filesystemEntries)
    if not comparison then
        return {
            success = false,
            message = err
        }
    end

    -- If no changes needed, return early
    if not comparison.has_changes then
        log:info("No changes needed - filesystem and registry are in sync")
        return {
            success = true,
            message = "No changes needed, filesystem and registry are in sync",
            changeset = {},
            count = 0,
            stats = {
                create = 0,
                update = 0,
                delete = 0
            }
        }
    end

    -- Calculate operation stats for reporting
    local stats = {
        create = 0,
        update = 0,
        delete = 0
    }

    for _, op in ipairs(comparison.changeset) do
        if op.kind == OP.CREATE then
            stats.create = stats.create + 1
        elseif op.kind == OP.UPDATE then
            stats.update = stats.update + 1
        elseif op.kind == OP.DELETE then
            stats.delete = stats.delete + 1
        end
    end

    log:info("Upload operation completed", {
        changeset_size = comparison.count,
        stats = stats
    })

    -- Return the changeset without applying it
    return {
        success = true,
        message = "Successfully built changeset from filesystem",
        changeset = comparison.changeset,
        count = comparison.count,
        stats = stats
    }
end

-- Main run function
local function run(args)
    log:info("Starting upload process")

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

    log:info("Processing upload request", {
        request_id = request_id,
        user_id = user_id,
        check_only = args.check_only or false
    })

    -- Check if we need to check for changes or actually upload
    if args.check_only then
        log:info("Checking for changes only")
        local result = has_changes(args.options or {})
        return result
    else
        log:info("Performing upload operation - building changeset")
        local result = upload(args.options or {})

        -- Return the changeset for the governance process to handle
        if result.success then
            log:info("Successfully built changeset from filesystem", {
                request_id = request_id,
                user_id = user_id,
                changeset_count = result.count
            })

            return {
                success = true,
                message = result.message,
                changeset = result.changeset,
                count = result.count,
                stats = result.stats,
                request_id = request_id,
                user_id = user_id
            }
        else
            log:error("Upload operation failed", {
                error = result.message,
                request_id = request_id,
                user_id = user_id
            })
            return result
        end
    end
end

-- Export the run function
return { run = run }
