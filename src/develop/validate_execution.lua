local json = require("json")

local function is_error_result(value)
    if type(value) ~= "table" then
        return false
    end

    if value._error or value.error or value.failed then
        return true
    end

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

    if error_result._error then
        return extract_error_message(error_result._error)
    end

    if error_result.message then
        return error_result.message
    end

    if error_result.error then
        return extract_error_message(error_result.error)
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

    for step_id, result in pairs(results) do
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

    local summary = {
        total_steps = total,
        succeeded = #successes,
        failed = #failures,
        success_rate = total > 0 and (#successes / total) or 0,
        successes = successes,
        failures = failures
    }

    if #failures > 0 then
        summary.has_failures = true
        summary.error_summary = string.format(
            "%d of %d steps failed",
            #failures,
            total
        )
    end

    return summary, nil
end

return { handler = handler }