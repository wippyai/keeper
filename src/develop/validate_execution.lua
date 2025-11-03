local json = require("json")

local function is_error_result(value)
    -- Check if value represents an error from dataflow
    if type(value) ~= "table" then
        return false
    end

    -- Common error indicators in dataflow results
    if value._error or value.error or value.failed then
        return true
    end

    -- Check for error-like structure
    if value.code and (value.code == "AGENT_EXEC_FAILED" or
            value.code == "CHILD_WORKFLOW_FAILED" or
            value.code:match("FAILED$")) then
        return true
    end

    return false
end

local function extract_error_message(error_result)
    if type(error_result) == "string" then
        return error_result
    end

    if type(error_result) ~= "table" then
        return "Unknown error"
    end

    -- Try various error message fields
    if error_result._error then
        return extract_error_message(error_result._error)
    end

    if error_result.message then
        return error_result.message
    end

    if error_result.error then
        return extract_error_message(error_result.error)
    end

    -- Fallback to JSON encoding
    local encoded, err = json.encode(error_result)
    if encoded then
        return encoded
    end

    return "Error details unavailable"
end

local function handler(results)
    if type(results) ~= "table" then
        return nil, "Invalid results format"
    end

    local successes = {}
    local failures = {}
    local total = 0

    -- Analyze each step result
    for step_id, result in pairs(results) do
        -- Skip internal dataflow fields
        if step_id ~= "_" and not step_id:match("^_") then
            total = total + 1

            if is_error_result(result) then
                table.insert(failures, {
                    step = step_id,
                    error = extract_error_message(result),
                    details = result
                })
            else
                table.insert(successes, {
                    step = step_id,
                    result = result
                })
            end
        end
    end

    -- Build execution summary
    local summary = {
        total_steps = total,
        succeeded = #successes,
        failed = #failures,
        success_rate = total > 0 and (#successes / total) or 0,
        successes = successes,
        failures = failures
    }

    -- If any step failed, fail the workflow but preserve all results
    if #failures > 0 then
        local error_message = string.format(
            "Execution failed: %d of %d steps failed",
            #failures,
            total
        )

        -- Append first failure details
        if failures[1] then
            error_message = error_message .. "\n\nFirst failure: " .. failures[1].step
            error_message = error_message .. "\nError: " .. failures[1].error
        end

        -- Return full summary in error for inspection
        return nil, error_message, summary
    end

    -- All steps succeeded
    return summary, nil
end

return { handler = handler }
