local funcs = require("funcs")
local json = require("json")
local logger = require("logger")
local ctx = require("ctx")
local discovery = require("discovery")

local log = logger:named("keeper.lint")

-- Main handler function
local function handle(request)
    log:info("Starting linter pipeline execution")

    -- Validate input
    if not request then
        return {
            success = false,
            changeset = {},
            issues = { {
                level = "error",
                code = "INVALID_INPUT",
                message = "No request provided"
            } }
        }
    end

    local changeset = request.changeset or {}
    local options = request.options or {}

    log:info("Processing changeset", {
        changeset_count = #changeset,
        has_options = next(options) ~= nil
    })

    -- Get context values that might be useful for linters
    local request_id, _ = ctx.get("request_id")
    local workspace_id, _ = ctx.get("workspace_id")

    -- Determine linter selection criteria
    local level = options.level or 1
    local halt_on_error = options.halt_on_error ~= false -- Default true
    local halt_on_warning = options.halt_on_warning or false

    -- Find available linters
    local linters = discovery.find_linters({
        max_level = level -- Only run linters at or below requested level
    })

    if not linters or #linters == 0 then
        log:info("No linters found for level", { level = level })
        return {
            success = true,
            changeset = changeset,
            issues = {}
        }
    end

    log:info("Found linters", { count = #linters, level = level })

    -- Create function executor
    local executor = funcs.new()

    -- Initialize aggregated results
    local current_changeset = changeset
    local all_issues = {}
    local linters_executed = 0

    -- Execute linters in priority order
    for _, linter in ipairs(linters) do
        log:debug("Executing linter", {
            linter_id = linter.id,
            priority = linter.priority,
            level = linter.level
        })

        -- Prepare linter input following the pipeline contract
        local linter_input = {
            changeset = current_changeset,
            options = options
        }

        -- Execute the linter
        local result, err = executor:call(linter.id, linter_input)

        if err then
            log:error("Linter execution failed", {
                linter_id = linter.id,
                error = err
            })

            -- Add execution error as issue
            table.insert(all_issues, {
                level = "error",
                code = "LINTER_EXECUTION_ERROR",
                message = "Linter " .. linter.id .. " failed: " .. err,
                entry_id = nil
            })

            if halt_on_error then
                log:warn("Halting pipeline due to linter error", {
                    linter_id = linter.id
                })
                break
            end
        else
            linters_executed = linters_executed + 1

            -- Validate linter result format
            if not result or type(result) ~= "table" then
                log:error("Invalid linter result format", {
                    linter_id = linter.id,
                    result_type = type(result)
                })

                table.insert(all_issues, {
                    level = "error",
                    code = "INVALID_RESULT_FORMAT",
                    message = "Linter " .. linter.id .. " returned invalid result format"
                })

                if halt_on_error then
                    break
                end
            else
                -- Check if linter succeeded
                if not result.success then
                    log:warn("Linter reported failure", {
                        linter_id = linter.id,
                        message = result.message or "Unknown error"
                    })

                    -- Add linter failure as error issue
                    table.insert(all_issues, {
                        level = "error",
                        code = "LINTER_FAILURE",
                        message = "Linter " .. linter.id .. " failed: " .. (result.message or "Unknown error")
                    })

                    if halt_on_error then
                        break
                    end
                else
                    -- Linter succeeded, process results
                    -- Update changeset if linter modified it
                    if result.changeset then
                        current_changeset = result.changeset
                        log:debug("Changeset updated by linter", {
                            linter_id = linter.id,
                            new_count = #current_changeset
                        })
                    end

                    -- Aggregate issues
                    if result.issues and #result.issues > 0 then
                        for _, issue in ipairs(result.issues) do
                            table.insert(all_issues, issue)
                        end

                        -- Check for halt conditions
                        local has_errors = false
                        local has_warnings = false

                        for _, issue in ipairs(result.issues) do
                            if issue.level == "error" then
                                has_errors = true
                            elseif issue.level == "warning" then
                                has_warnings = true
                            end
                        end

                        if has_errors and halt_on_error then
                            log:warn("Halting pipeline due to error issues", {
                                linter_id = linter.id
                            })
                            break
                        end

                        if has_warnings and halt_on_warning then
                            log:warn("Halting pipeline due to warning issues", {
                                linter_id = linter.id
                            })
                            break
                        end
                    end
                end
            end
        end
    end

    -- Count issue types for logging
    local error_count = 0
    local warning_count = 0
    local info_count = 0

    for _, issue in ipairs(all_issues) do
        if issue.level == "error" then
            error_count = error_count + 1
        elseif issue.level == "warning" then
            warning_count = warning_count + 1
        elseif issue.level == "info" then
            info_count = info_count + 1
        end
    end

    log:info("Pipeline execution completed", {
        linters_executed = linters_executed,
        total_linters = #linters,
        changeset_final_count = #current_changeset,
        issues = {
            errors = error_count,
            warnings = warning_count,
            infos = info_count
        }
    })

    -- Determine overall success
    local success = error_count == 0

    return {
        success = success,
        changeset = current_changeset,
        issues = all_issues
    }
end

return { handle = handle }
