local json = require("json")
local ctx = require("ctx")
local design_writer = require("design_writer")
local design_reader = require("design_reader")

local function run(inputs)
    local materialize_node_id = inputs.materialize_node_id
    local operation_type = inputs.operation_type
    local result = inputs.result
    local state = inputs.state

    if not materialize_node_id then
        return nil, "materialize_node_id required"
    end

    if not operation_type then
        return nil, "operation_type required"
    end

    if not result then
        return nil, "result required"
    end

    local workspace_id = ctx.get("active_workspace_id")
    if not workspace_id then
        return nil, "active_workspace_id not set"
    end

    local reader = design_reader.for_workspace(workspace_id)

    local existing_iterations = reader
        :with_type("materialize_iteration")
        :with_parent_direct(materialize_node_id)
        :count()

    local iteration = (existing_iterations or 0) + 1

    local ws = design_writer.existing_workspace(workspace_id)

    local result_status = "completed"

    if operation_type == "implement_graph" then
        if result.failures and #result.failures > 0 then
            result_status = "failed"
        end

        ws:data({
            type = "materialize_iteration",
            discriminator = "implementation_result",
            parent_data_id = materialize_node_id,
            content = json.encode(result),
            content_type = "application/json",
            status = result_status,
            position = iteration,
            metadata = {
                iteration_number = iteration,
                operation = operation_type,
                entry_type = "execution_result"
            }
        })

    elseif operation_type == "integrate" then
        if result.success ~= true then
            result_status = "failed"
        end

        ws:data({
            type = "materialize_iteration",
            discriminator = "integration_result",
            parent_data_id = materialize_node_id,
            content = json.encode(result),
            content_type = "application/json",
            status = result_status,
            position = iteration,
            metadata = {
                iteration_number = iteration,
                operation = operation_type,
                entry_type = "integration_result"
            }
        })
    end

    local exec_result, exec_err = ws:execute()
    if exec_err then
        return nil, "Failed to store operation result: " .. exec_err
    end

    return {
        state = state,
        result = result,
        continue = true,
        stored = true,
        iteration = iteration,
        status = result_status
    }
end

return { run = run }