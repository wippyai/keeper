local registry = require("registry")
local logger = require("logger")
local consts = require("consts")
local observers = require("observers")
local sync = require("sync")

local log = logger:named("gov.service.changeset")

local M = {}

function M.merge_options(base_options, override_options)
    local merged = {}
    if type(base_options) == "table" then
        for k, v in pairs(base_options) do merged[k] = v end
    end
    if type(override_options) == "table" then
        for k, v in pairs(override_options) do merged[k] = v end
    end
    return merged
end

function M.count_errors(issues)
    if type(issues) ~= "table" then return 0 end
    local n = 0
    for _, issue in ipairs(issues) do
        if issue.type == "error" then n = n + 1 end
    end
    return n
end

-- Pure shape validation for a changeset array. Returns a list of issue rows
-- (same shape as logger-bound validate_changeset emits).
function M.check_basic_shape(changeset)
    local issues = {}

    if type(changeset) ~= "table" or #changeset == 0 then
        table.insert(issues, {
            id = "changeset", type = "error",
            message = consts.ERRORS.NO_CHANGESET,
        })
        return issues
    end

    local managed_namespaces = consts.get_managed_namespaces()

    for i, item in ipairs(changeset) do
        local item_id = "item:" .. i

        if not item.kind or not item.entry then
            table.insert(issues, {
                id = item_id, type = "error",
                message = "Missing kind or entry field",
            })
        elseif item.kind ~= consts.REGISTRY_OPERATIONS.CREATE
            and item.kind ~= consts.REGISTRY_OPERATIONS.UPDATE
            and item.kind ~= consts.REGISTRY_OPERATIONS.DELETE then
            table.insert(issues, {
                id = item.entry.id or item_id, type = "error",
                message = consts.ERRORS.INVALID_OPERATION .. ": " .. tostring(item.kind),
            })
        elseif item.kind == consts.REGISTRY_OPERATIONS.DELETE and not item.entry.id then
            table.insert(issues, {
                id = item_id, type = "error",
                message = consts.ERRORS.MISSING_ENTRY_ID,
            })
        elseif item.entry.id then
            local namespace = item.entry.id:match("^([^:]+):")
            if namespace and not consts.is_namespace_managed(namespace) then
                table.insert(issues, {
                    id = item.entry.id, type = "error",
                    message = consts.ERRORS.UNMANAGED_NAMESPACE .. ": '" .. namespace ..
                        "'. Managed namespaces: " .. table.concat(managed_namespaces, ", "),
                })
            end
        end
    end

    return issues
end

local function validate_changeset(changeset, request_id, options, user_id)
    log:debug("Validating changeset", {
        count = changeset and #changeset or 0,
        request_id = request_id,
        original_options = options
    })

    local issues = M.check_basic_shape(changeset)

    if #issues == 1 and issues[1].id == "changeset" then
        return nil, consts.ERRORS.NO_CHANGESET, issues
    end

    local error_count = M.count_errors(issues)
    if error_count > 0 then
        log:error("Basic validation failed", {
            error_count = error_count,
            request_id = request_id
        })
        return nil, "Changeset validation failed", issues
    end

    log:info("Changeset validation completed successfully", {
        changeset_count = #changeset,
        issue_count = #issues,
        request_id = request_id
    })

    return changeset, nil, issues
end

local function validate_version_id(version_id)
    log:debug("Validating version ID", { version_id = version_id })

    local issues = {}

    if not version_id or type(version_id) ~= "string" then
        table.insert(issues, {
            id = "version:input",
            type = "error",
            message = consts.ERRORS.INVALID_VERSION_ID
        })
        return nil, consts.ERRORS.INVALID_VERSION_ID, issues
    end

    local history = registry.history()
    if not history then
        table.insert(issues, {
            id = "version:history",
            type = "error",
            message = consts.ERRORS.REGISTRY_HISTORY_UNAVAILABLE
        })
        return nil, consts.ERRORS.REGISTRY_HISTORY_UNAVAILABLE, issues
    end

    local version, err = history:get_version(tonumber(version_id) or 0)
    if not version then
        table.insert(issues, {
            id = "version:" .. version_id,
            type = "error",
            message = consts.ERRORS.VERSION_NOT_FOUND .. ": " .. version_id
        })
        return nil, consts.ERRORS.VERSION_NOT_FOUND .. ": " .. version_id, issues
    end

    return version_id, nil, issues
end

local function execute_changeset(changeset, options, request_id, user_id)
    log:info("Executing changeset", {
        changeset_count = #changeset,
        options = options,
        request_id = request_id,
        user_id = user_id
    })

    local snapshot, err = registry.snapshot()
    if not snapshot then
        log:error("Failed to create registry snapshot", {
            error = err,
            request_id = request_id,
            user_id = user_id
        })
        return {
            success = false,
            message = "Failed to create registry snapshot",
            error = err or "Unknown error",
            request_id = request_id,
            user_id = user_id
        }
    end

    local changes = snapshot:changes()
    if not changes then
        log:error("Failed to get changes object", {
            request_id = request_id,
            user_id = user_id
        })
        return {
            success = false,
            message = "Failed to get changes object from snapshot",
            error = "Changes object not available",
            request_id = request_id,
            user_id = user_id
        }
    end

    for _, op in ipairs(changeset) do
        local kind = op.kind
        local entry = op.entry

        if kind == consts.REGISTRY_OPERATIONS.CREATE then
            log:debug("Creating entry", {
                id = entry.id or (entry.namespace and entry.name and (entry.namespace .. ":" .. entry.name)),
                request_id = request_id,
                user_id = user_id
            })
            changes:create(entry)
        elseif kind == consts.REGISTRY_OPERATIONS.UPDATE then
            log:debug("Updating entry", {
                id = entry.id or (entry.namespace and entry.name and (entry.namespace .. ":" .. entry.name)),
                request_id = request_id,
                user_id = user_id
            })
            changes:update(entry)
        elseif kind == consts.REGISTRY_OPERATIONS.DELETE then
            local id = entry.id or (entry.namespace and entry.name and (entry.namespace .. ":" .. entry.name))
            log:debug("Deleting entry", {
                id = id,
                request_id = request_id,
                user_id = user_id
            })
            changes:delete(id)
        end
    end

    local version, err = changes:apply()
    if not version then
        if err and tostring(err):find("no changes to apply") then
            log:info("No changes needed to be applied", {
                request_id = request_id,
                user_id = user_id
            })
            return {
                success = true,
                message = "No changes needed to be applied",
                request_id = request_id,
                user_id = user_id
            }
        else
            log:error("Failed to apply changes", {
                error = err,
                request_id = request_id,
                user_id = user_id
            })
            return {
                success = false,
                message = "Failed to apply changes to registry",
                error = err or "Unknown error",
                request_id = request_id,
                user_id = user_id
            }
        end
    end

    log:info("Successfully applied changeset", {
        version = version:id(),
        request_id = request_id,
        user_id = user_id
    })

    return {
        success = true,
        message = "Successfully applied changes to registry",
        version = version:id(),
        request_id = request_id,
        user_id = user_id
    }
end

local function execute_version(version_id, options, request_id, user_id)
    log:info("Executing version application", {
        version_id = version_id,
        options = options,
        request_id = request_id,
        user_id = user_id
    })

    local history = registry.history()
    if not history then
        return {
            success = false,
            message = "Registry history unavailable",
            error = "Failed to get registry history",
            request_id = request_id,
            user_id = user_id
        }
    end

    local version, ver_err = history:get_version(tonumber(version_id) or 0)
    if not version then
        log:error("Failed to get registry version", {
            version_id = version_id,
            error = ver_err,
            request_id = request_id,
            user_id = user_id
        })
        return {
            success = false,
            message = "Failed to get registry version: " .. version_id,
            error = ver_err or "Unknown error",
            request_id = request_id,
            user_id = user_id
        }
    end

    local success, err = registry.apply_version(version)
    if not success then
        log:error("Failed to apply registry version", {
            version_id = version_id,
            error = err,
            request_id = request_id,
            user_id = user_id
        })
        return {
            success = false,
            message = "Failed to apply registry version: " .. version_id,
            error = err or "Unknown error",
            request_id = request_id,
            user_id = user_id
        }
    end

    log:info("Successfully applied registry version", {
        version_id = version_id,
        request_id = request_id,
        user_id = user_id
    })

    return {
        success = true,
        message = "Successfully applied registry version: " .. version_id,
        version = version_id,
        request_id = request_id,
        user_id = user_id
    }
end

local function run_post_processing(changeset, result, request_id, user_id)
    if not result.success then
        log:debug("Skipping post-processing for failed operation", {
            request_id = request_id,
            user_id = user_id
        })
        return
    end

    log:info("Running post-processing", {
        request_id = request_id,
        user_id = user_id,
        has_changeset = changeset ~= nil
    })

    observers.run_observers(changeset or {}, result, request_id, user_id)
end

local function run(args)
    log:info("Starting changeset process")

    if not args then
        log:error("No arguments provided")
        return {
            success = false,
            message = consts.ERRORS.INVALID_ARGUMENTS,
            error = "Missing required arguments"
        }
    end

    local request_id = args.request_id
    local user_id = args.user_id

    if not request_id then
        log:warn("No request_id provided")
        request_id = "unknown"
    end

    log:info("Processing request", {
        request_id = request_id,
        user_id = user_id,
        has_changeset = args.changeset ~= nil,
        has_version_id = args.version_id ~= nil,
        options = args.options
    })

    local result
    local changeset = args.changeset
    local validation_details = {}

    if args.changeset then
        local validated_changeset, err, issues = validate_changeset(args.changeset, request_id, args.options or {}, user_id)

        validation_details = issues or {}

        if not validated_changeset then
            log:error("Changeset validation failed", {
                error = err,
                request_id = request_id,
                user_id = user_id,
                issue_count = #validation_details
            })
            return {
                success = false,
                message = "Changeset validation failed",
                error = err,
                details = validation_details,
                options = args.options,
                user_id = user_id,
                request_id = request_id
            }
        end

        result = execute_changeset(validated_changeset, args.options or {}, request_id, user_id)
        changeset = validated_changeset

    elseif args.version_id then
        local validated_version, err, issues = validate_version_id(tostring(args.version_id))

        validation_details = issues or {}

        if not validated_version then
            log:error("Version validation failed", {
                error = err,
                request_id = request_id,
                user_id = user_id
            })
            return {
                success = false,
                message = "Version validation failed",
                error = err,
                details = validation_details,
                options = args.options,
                user_id = user_id,
                request_id = request_id
            }
        end

        result = execute_version(validated_version, args.options or {}, request_id, user_id)

    else
        log:error("Invalid arguments - requires changeset or version_id", {
            request_id = request_id,
            user_id = user_id
        })
        return {
            success = false,
            message = consts.ERRORS.INVALID_ARGUMENTS,
            error = "Must provide either changeset or version_id",
            details = {},
            request_id = request_id,
            user_id = user_id
        }
    end

    result.details = validation_details
    result.changeset = changeset

    -- Auto-sync affected namespaces to filesystem after successful apply.
    -- Default true; opt out with options.sync = false (used by upload/download workflows).
    local should_sync = result.success
        and changeset
        and #changeset > 0
        and (args.options == nil or args.options.sync ~= false)

    if should_sync then
        local sync_stats, sync_err = sync.sync_changeset(changeset)
        if sync_err then
            log:error("Auto-sync to filesystem failed", {
                error = sync_err,
                request_id = request_id,
                user_id = user_id,
            })
            result.sync_error = sync_err
        else
            result.sync_stats = sync_stats
            log:info("Auto-synced changeset to filesystem", sync_stats or {})
        end
    end

    run_post_processing(changeset, result, request_id, user_id)

    log:info("Completed changeset process", {
        success = result.success,
        request_id = request_id,
        user_id = user_id
    })

    return result
end

M.run = run
return M