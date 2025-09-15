local registry = require("registry")
local json = require("json")
local time = require("time")
local logger = require("logger")
local contract = require("contract")
local consts = require("consts")
local observers = require("observers")

-- Create a named logger for this process
local log = logger:named("gov.service.changeset")

---------------------------
-- Helper Functions
---------------------------

-- Merge options tables, with override taking precedence
local function merge_options(base_options, override_options)
    local merged = {}

    -- Copy base options
    if base_options then
        for k, v in pairs(base_options) do
            merged[k] = v
        end
    end

    -- Override with new options
    if override_options then
        for k, v in pairs(override_options) do
            merged[k] = v
        end
    end

    return merged
end

---------------------------
-- Validation Functions
---------------------------

-- Validate changeset using namespace restrictions and linters
local function validate_changeset(changeset, request_id, options, user_id)
    log:debug("Validating changeset", {
        count = #changeset,
        request_id = request_id,
        original_options = options
    })

    local issues = {}
    local managed_namespaces = consts.get_managed_namespaces()

    if not changeset or #changeset == 0 then
        table.insert(issues, {
            id = "changeset",
            type = "error",
            message = consts.ERRORS.NO_CHANGESET
        })
        return nil, consts.ERRORS.NO_CHANGESET, issues
    end

    -- Validate each entry and check namespace management
    for i, item in ipairs(changeset) do
        local item_id = "item:" .. i

        -- Basic structure validation
        if not item.kind or not item.entry then
            table.insert(issues, {
                id = item_id,
                type = "error",
                message = "Missing kind or entry field"
            })
            goto continue
        end

        -- Validate operation kind
        if item.kind ~= consts.REGISTRY_OPERATIONS.CREATE and
           item.kind ~= consts.REGISTRY_OPERATIONS.UPDATE and
           item.kind ~= consts.REGISTRY_OPERATIONS.DELETE then
            table.insert(issues, {
                id = item.entry.id or item_id,
                type = "error",
                message = consts.ERRORS.INVALID_OPERATION .. ": " .. tostring(item.kind)
            })
            goto continue
        end

        -- Validate entry ID exists for delete operations
        if item.kind == consts.REGISTRY_OPERATIONS.DELETE and not item.entry.id then
            table.insert(issues, {
                id = item_id,
                type = "error",
                message = consts.ERRORS.MISSING_ENTRY_ID
            })
            goto continue
        end

        -- Check namespace management
        if item.entry.id then
            local namespace = item.entry.id:match("^([^:]+):")
            if namespace and not consts.is_namespace_managed(namespace) then
                table.insert(issues, {
                    id = item.entry.id,
                    type = "error",
                    message = consts.ERRORS.UNMANAGED_NAMESPACE .. ": '" .. namespace ..
                             "'. Managed namespaces: " .. table.concat(managed_namespaces, ", ")
                })
            end
        end

        ::continue::
    end

    -- If we have errors from basic validation, return early
    local error_count = 0
    for _, issue in ipairs(issues) do
        if issue.type == "error" then
            error_count = error_count + 1
        end
    end

    if error_count > 0 then
        log:error("Basic validation failed", {
            error_count = error_count,
            request_id = request_id
        })
        return nil, "Changeset validation failed", issues
    end

    -- Run linters pipeline
    local pipeline_contract, err = contract.get("keeper.linters:pipeline")
    if err then
        log:error("Failed to get linters pipeline contract", { error = err })
        table.insert(issues, {
            id = "linters",
            type = "error",
            message = consts.ERRORS.LINTER_PIPELINE_UNAVAILABLE .. ": " .. err
        })
        return nil, consts.ERRORS.LINTER_PIPELINE_UNAVAILABLE, issues
    end

    -- Open pipeline instance
    local pipeline_instance, err = pipeline_contract:open()
    if err then
        log:error("Failed to open linting pipeline", { error = err })
        table.insert(issues, {
            id = "linters",
            type = "error",
            message = "Failed to initialize linting pipeline: " .. err
        })
        return nil, "Linting pipeline initialization failed", issues
    end

    -- Merge original options with linting-specific overrides
    -- Force level to 100 and preserve all other original options
    local lint_options = merge_options(options, {
        level = 100,                 -- Force level 100 as requested
        halt_on_error = false,       -- Get all issues
        halt_on_warning = false      -- Get all issues
    })

    -- Execute linting
    local lint_request = {
        changeset = changeset,
        options = lint_options
    }

    log:debug("Executing linting pipeline", {
        original_options = options,
        merged_options = lint_options,
        request_id = request_id
    })

    local lint_result, err = pipeline_instance:lint(lint_request)
    if err then
        log:error("Linting execution failed", {
            error = err,
            request_id = request_id
        })
        table.insert(issues, {
            id = "linters",
            type = "error",
            message = consts.ERRORS.LINTER_EXECUTION_FAILED .. ": " .. err
        })
        return nil, consts.ERRORS.LINTER_EXECUTION_FAILED, issues
    end

    -- Convert linter issues to our format (maintain compatibility)
    if lint_result.issues then
        for _, lint_issue in ipairs(lint_result.issues) do
            table.insert(issues, {
                id = lint_issue.entry_id or "unknown",
                type = lint_issue.level, -- error, warning, info
                message = lint_issue.message
            })
        end
    end

    -- Check if linting succeeded (no errors)
    if not lint_result.success then
        log:error("Linting validation failed", {
            request_id = request_id,
            lint_message = lint_result.message
        })
        return nil, consts.ERRORS.LINTING_VALIDATION_FAILED, issues
    end

    -- Count errors to ensure we never pass with errors
    local final_error_count = 0
    for _, issue in ipairs(issues) do
        if issue.type == "error" then
            final_error_count = final_error_count + 1
        end
    end

    if final_error_count > 0 then
        log:error("Validation completed with errors", {
            error_count = final_error_count,
            request_id = request_id
        })
        return nil, "Validation failed with " .. final_error_count .. " errors", issues
    end

    log:info("Changeset validation completed successfully", {
        changeset_count = #changeset,
        final_changeset_count = lint_result.changeset and #lint_result.changeset or #changeset,
        issue_count = #issues,
        request_id = request_id
    })

    -- Return the potentially modified changeset from linters
    return lint_result.changeset or changeset, nil, issues
end

-- Validate version ID
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

    -- Check if the version exists in the registry
    local history = registry.history()
    if not history then
        table.insert(issues, {
            id = "version:history",
            type = "error",
            message = consts.ERRORS.REGISTRY_HISTORY_UNAVAILABLE
        })
        return nil, consts.ERRORS.REGISTRY_HISTORY_UNAVAILABLE, issues
    end

    local version, err = history:get_version(version_id)
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

---------------------------
-- Execution Functions
---------------------------

-- Apply changeset to registry
local function execute_changeset(changeset, options, request_id, user_id)
    log:info("Executing changeset", {
        changeset_count = #changeset,
        options = options,
        request_id = request_id,
        user_id = user_id
    })

    -- Create a snapshot for applying changes
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

    -- Get changes object for the snapshot
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

    -- Apply changeset to the changes object
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

    -- Apply the changes to create a new registry version
    local version, err = changes:apply()
    if not version then
        -- Handle "no changes to apply" case
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
            -- Actual error case
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

-- Apply a specific registry version
local function execute_version(version_id, options, request_id, user_id)
    log:info("Executing version application", {
        version_id = version_id,
        options = options,
        request_id = request_id,
        user_id = user_id
    })

    -- Get the specified version using the history object
    local history = registry.history()
    local version, err = history:get_version(version_id)
    if not version then
        log:error("Failed to get registry version", {
            version_id = version_id,
            error = err,
            request_id = request_id,
            user_id = user_id
        })
        return {
            success = false,
            message = "Failed to get registry version: " .. version_id,
            error = err or "Unknown error",
            request_id = request_id,
            user_id = user_id
        }
    end

    -- Apply the version
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

---------------------------
-- Post-Processing Functions
---------------------------

-- Run observers for successful operations
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

    -- Run observers if we have a changeset
    if changeset then
        observers.run_observers(changeset, result, request_id, user_id)
    end
end

---------------------------
-- Main Process Function
---------------------------

-- Main run function that executes the appropriate operation
local function run(args)
    log:info("Starting changeset process")

    -- Validate arguments
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

    -- Determine and execute the appropriate operation
    if args.changeset then
        -- Validate changeset (this now properly merges options)
        local validated_changeset, err, issues = validate_changeset(args.changeset, request_id, args.options or {}, user_id)

        -- Store validation details
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

        -- Execute changeset
        result = execute_changeset(validated_changeset, args.options or {}, request_id, user_id)
        changeset = validated_changeset

    elseif args.version_id then
        -- Validate version ID
        local validated_version, err, issues = validate_version_id(args.version_id)

        -- Store validation details
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

        -- Execute version application
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

    -- Add validation details to result
    result.details = validation_details
    result.changeset = changeset

    -- Run post-processing (observers)
    run_post_processing(changeset, result, request_id, user_id)

    log:info("Completed changeset process", {
        success = result.success,
        request_id = request_id,
        user_id = user_id
    })

    return result
end

-- Export the run function
return { run = run }