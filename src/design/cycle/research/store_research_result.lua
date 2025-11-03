local json = require("json")
local design_writer = require("design_writer")

local function run(inputs)
    local agent_result = inputs.agent_result
    local research_id = inputs.research_id
    local workspace_id = inputs.workspace_id
    local title = inputs.title or "Research"

    if not research_id then
        return nil, "research_id required"
    end

    if not workspace_id then
        return nil, "workspace_id required"
    end

    if not agent_result then
        print(string.format("  → Marking as failed: %s", title))

        local ws = design_writer.existing_workspace(workspace_id)
        ws:update_data(research_id, {
            status = "failed",
            content = "Agent returned no result"
        })

        local exec_result, exec_err = ws:execute()
        if exec_err then
            return nil, "Failed to mark research as failed: " .. exec_err
        end

        return {
            success = false,
            research_id = research_id,
            message = "Research marked as failed"
        }
    end

    local result_content = agent_result
    if type(result_content) == "table" then
        result_content = json.encode(result_content)
    elseif type(result_content) ~= "string" then
        result_content = tostring(result_content or "")
    end

    print(string.format("  → Storing result for: %s", title))

    local ws = design_writer.existing_workspace(workspace_id)
    ws:update_data(research_id, {
        content = result_content,
        status = "completed"
    })

    local exec_result, exec_err = ws:execute()
    if exec_err then
        return nil, "Failed to store research result: " .. exec_err
    end

    return {
        success = true,
        research_id = research_id,
        message = "Research result stored"
    }
end

return { run = run }