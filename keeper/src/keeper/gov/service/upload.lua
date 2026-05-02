local registry = require("registry")
local loader = require("loader")
local logger = require("logger")
local consts = require("consts")
local fs_module = require("fs")

local log = logger:named("gov.service.upload")

local M = {}

M.OP = consts.REGISTRY_OPERATIONS
local OP = M.OP

type RegistryEntry = {
    id: string,
    kind: string,
    meta: {[string]: unknown}?,
    data: unknown?,
}

-- Pure: split entries into { filtered, skipped } using the supplied
-- is_managed(namespace) predicate. `skipped` rows carry {id, namespace}
-- with "unknown" fallbacks so callers can log them consistently.
function M.compute_managed_partition(entries, is_managed_fn)
    local filtered = {}
    local skipped = {}
    if type(entries) ~= "table" then return filtered, skipped end

    for _, entry in ipairs(entries) do
        local namespace = nil
        if entry.id then
            namespace = entry.id:match("^([^:]+):")
        end
        if namespace and is_managed_fn(namespace) then
            table.insert(filtered, entry)
        else
            table.insert(skipped, {
                id = entry.id or "unknown",
                namespace = namespace or "unknown"
            })
        end
    end

    return filtered, skipped
end

-- Pure: sort ops so CREATEs apply before UPDATEs before DELETEs.
-- registry.build_delta returns ops grouped by target entry, which can place
-- a DELETE ahead of an UPDATE that removes its incoming dependency. apply()
-- validates each op against the live graph, so the DELETE rejects. This
-- sort keeps relative order inside a kind (stable) and guarantees
-- dependency-removing UPDATEs land first.
local OP_ORDER = { [OP.CREATE] = 1, [OP.UPDATE] = 2, [OP.DELETE] = 3 }

function M.order_changeset(changeset)
    if type(changeset) ~= "table" then return changeset end
    local indexed = {}
    for i, op in ipairs(changeset) do indexed[i] = { i = i, op = op } end
    table.sort(indexed, function(a, b)
        local pa = OP_ORDER[a.op.kind] or 99
        local pb = OP_ORDER[b.op.kind] or 99
        if pa ~= pb then return pa < pb end
        return a.i < b.i
    end)
    local out = {}
    for i, entry in ipairs(indexed) do out[i] = entry.op end
    return out
end

-- Pure: tally entry.create / entry.update / entry.delete op counts from a changeset.
function M.compute_changeset_stats(changeset)
    local stats = { create = 0, update = 0, delete = 0 }
    if type(changeset) ~= "table" then return stats end
    for _, op in ipairs(changeset) do
        if op.kind == OP.CREATE then
            stats.create = stats.create + 1
        elseif op.kind == OP.UPDATE then
            stats.update = stats.update + 1
        elseif op.kind == OP.DELETE then
            stats.delete = stats.delete + 1
        end
    end
    return stats
end

function M.skipped_summary(skipped)
    local summary = { count = 0, namespaces = {}, sample = {} }
    if type(skipped) ~= "table" then return summary end

    local seen = {}
    for _, row in ipairs(skipped) do
        summary.count = summary.count + 1
        local ns = tostring(row.namespace or "unknown")
        if not seen[ns] then
            seen[ns] = true
            table.insert(summary.namespaces, ns)
        end
        if #summary.sample < 10 then
            table.insert(summary.sample, tostring(row.id or "unknown"))
        end
    end
    table.sort(summary.namespaces)
    return summary
end

local function add_skip_stats(stats, filesystem_skipped, registry_skipped, managed_namespaces)
    stats.skipped_unmanaged_source = #(filesystem_skipped or {})
    stats.skipped_unmanaged_registry = #(registry_skipped or {})
    stats.managed_namespaces = type(managed_namespaces) == "table" and #managed_namespaces or 0
    return stats
end

local function build_details(managed_namespaces, filesystem_skipped, registry_skipped)
    return {
        managed_namespaces = managed_namespaces or {},
        skipped_unmanaged = {
            filesystem = M.skipped_summary(filesystem_skipped),
            registry = M.skipped_summary(registry_skipped),
        },
    }
end

local function skipped_message_suffix(filesystem_skipped)
    local summary = M.skipped_summary(filesystem_skipped)
    if summary.count == 0 then return "" end
    return "; skipped unmanaged filesystem namespaces: " .. table.concat(summary.namespaces, ", ")
        .. ". Configure GOV_MANAGED_NAMESPACES or pass managed_namespaces for a one-shot app sync."
end

-- Filter entries to only include managed namespaces (including child namespaces)
local function filter_managed_entries(entries: {RegistryEntry}, options, label)
    local is_managed, managed_namespaces, filter_err = consts.namespace_filter(options)
    if not is_managed then
        return nil, nil, nil, filter_err
    end

    local filtered, skipped = M.compute_managed_partition(entries, is_managed)

    if #skipped > 0 then
        log:info("Skipped unmanaged namespace entries", {
            skipped_count = #skipped,
            managed_namespaces = managed_namespaces,
            source = label or "unknown",
        })
        for _, skip in ipairs(skipped) do
            log:debug("Skipped entry", skip)
        end
    end

    return filtered, skipped, managed_namespaces, nil
end

-- Get current registry entries (filtered to managed namespaces)
local function get_registry_entries(options)
    log:debug("Getting current registry entries")

    local snapshot, err = registry.snapshot()
    if not snapshot then
        return nil, nil, nil, "Failed to get registry snapshot: " .. tostring(err)
    end

    local all_entries = snapshot:entries()
    local filtered_entries, skipped, managed_namespaces, filter_err =
        filter_managed_entries(all_entries :: {RegistryEntry}, options, "registry")
    if not filtered_entries then
        return nil, nil, nil, filter_err
    end

    log:info("Retrieved registry entries", {
        total_count = #all_entries,
        managed_count = #filtered_entries
    })

    return filtered_entries, skipped, managed_namespaces
end

-- Get filesystem entries (filtered to managed namespaces)
local function get_filesystem_entries(options)
    log:debug("Getting filesystem entries", options)

    -- Use governance filesystem
    local fs_id: string = tostring(consts.FILESYSTEM.SOURCE_FS_ID)

    -- Create a loader instance for the governance filesystem
    local loader_instance, err = loader.new(fs_id)
    if not loader_instance then
        return nil, nil, nil, "Failed to create loader for filesystem '" .. fs_id .. "': " .. tostring(err)
    end

    -- Get source directory from governance filesystem
    local fs = fs_module.get(fs_id)
    if not fs then
        return nil, nil, nil, "Failed to get filesystem instance: " .. fs_id
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
        return nil, nil, nil, "Failed to load entries from directory '" .. directory .. "': " .. tostring(err)
    end

    local filtered_entries, skipped, managed_namespaces, filter_err =
        filter_managed_entries(all_entries :: {RegistryEntry}, options, "filesystem")
    if not filtered_entries then
        return nil, nil, nil, filter_err
    end

    log:info("Retrieved filesystem entries", {
        total_count = #all_entries,
        managed_count = #filtered_entries
    })

    return filtered_entries, skipped, managed_namespaces
end

-- Compare registry entries with filesystem entries
local function compare_entries(currentEntries: {RegistryEntry}, targetEntries: {RegistryEntry})
    log:debug("Comparing registry and filesystem entries", {
        registry_count = #(currentEntries or {}),
        filesystem_count = #(targetEntries or {})
    })

    -- registry.build_delta accepts entry arrays at runtime and in
    -- registry/spec.md; the runtime type metadata currently labels these
    -- parameters as registry.Version.
    local changeset, err = registry.build_delta(
        currentEntries :: registry.Version,
        targetEntries :: registry.Version
    )
    if not changeset then
        return nil, "Failed to build delta: " .. tostring(err)
    end

    changeset = M.order_changeset(changeset)

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
    local currentEntries, registry_skipped, managed_namespaces, err = get_registry_entries(options)
    if not currentEntries then
        return {
            success = false,
            message = err
        }
    end

    -- Get filesystem entries (managed namespaces only)
    local filesystemEntries, filesystem_skipped, _, err = get_filesystem_entries(options)
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
        count = comparison.count,
        details = build_details(managed_namespaces, filesystem_skipped, registry_skipped),
    }
end

-- Upload entries from filesystem to registry - builds and returns the changeset
local function upload(options)
    log:info("Starting upload operation")

    -- Get current registry entries (managed namespaces only)
    local currentEntries, registry_skipped, managed_namespaces, err = get_registry_entries(options)
    if not currentEntries then
        return {
            success = false,
            message = err
        }
    end

    -- Get filesystem entries (managed namespaces only)
    local filesystemEntries, filesystem_skipped, _, err = get_filesystem_entries(options)
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
            message = "No changes needed, managed filesystem and registry are in sync"
                .. skipped_message_suffix(filesystem_skipped),
            changeset = {},
            count = 0,
            stats = add_skip_stats({
                create = 0,
                update = 0,
                delete = 0
            }, filesystem_skipped, registry_skipped, managed_namespaces),
            details = build_details(managed_namespaces, filesystem_skipped, registry_skipped),
        }
    end

    local stats = add_skip_stats(
        M.compute_changeset_stats(comparison.changeset),
        filesystem_skipped,
        registry_skipped,
        managed_namespaces
    )

    log:info("Upload operation completed", {
        changeset_size = comparison.count,
        stats = stats
    })

    -- Return the changeset without applying it
    return {
        success = true,
        message = "Successfully built changeset from managed filesystem" .. skipped_message_suffix(filesystem_skipped),
        changeset = comparison.changeset,
        count = comparison.count,
        stats = stats,
        details = build_details(managed_namespaces, filesystem_skipped, registry_skipped),
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
                details = result.details,
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

M.run = run
return M
