local json = require("json")
local ctx = require("ctx")
local design_writer = require("design_writer")
local design_reader = require("design_reader")

local function run(inputs)
    local branch_id = inputs.branch_id
    local materialize_node_id = inputs.materialize_node_id
    local operation = inputs.operation or {}
    local has_integrated = inputs.has_integrated or false
    local has_tested = inputs.has_tested or false

    if not branch_id then
        return nil, "branch_id required"
    end

    if not materialize_node_id then
        return nil, "materialize_node_id required"
    end

    local workspace_id = ctx.get("active_workspace_id")
    if not workspace_id then
        return nil, "active_workspace_id not set"
    end

    local reader = design_reader.for_workspace(workspace_id)

    local existing_iterations = reader
        :with_type("materialize_reasoning")
        :with_parent_direct(materialize_node_id)
        :count()

    local iteration = (existing_iterations or 0) + 1

    local op_type = operation.operation
    local reasoning = operation.reasoning or ""

    print(string.format("\n=== IMPLEMENTATION ITERATION %d ===", iteration))
    print(string.format("Materialize Node: %s", materialize_node_id))
    print(string.format("Operation: %s", op_type))

    local ws = design_writer.existing_workspace(workspace_id)

    ws:data({
        type = "materialize_reasoning",
        parent_data_id = materialize_node_id,
        content = reasoning,
        content_type = "text/markdown",
        status = "completed",
        metadata = {
            iteration_number = iteration,
            operation = op_type
        }
    })

    if op_type == "implement" and operation.implementation_plan then
        ws:data({
            type = "materialize_plan",
            parent_data_id = materialize_node_id,
            content = json.encode(operation.implementation_plan),
            content_type = "application/json",
            status = "completed",
            metadata = {
                iteration_number = iteration
            }
        })
    elseif op_type == "test" and operation.test_plan then
        ws:data({
            type = "materialize_test_plan",
            parent_data_id = materialize_node_id,
            content = json.encode(operation.test_plan),
            content_type = "application/json",
            status = "completed",
            metadata = {
                iteration_number = iteration
            }
        })
    elseif op_type == "debug" and operation.debug_prompt then
        ws:data({
            type = "materialize_debug_prompt",
            parent_data_id = materialize_node_id,
            content = operation.debug_prompt,
            content_type = "text/plain",
            status = "completed",
            metadata = {
                iteration_number = iteration
            }
        })
    elseif op_type == "integrate" and operation.integration_prompt then
        ws:data({
            type = "materialize_integration_request",
            parent_data_id = materialize_node_id,
            content_type = "text/plain",
            status = "completed",
            metadata = {
                iteration_number = iteration
            }
        })
    end

    local exec_result, exec_err = ws:execute()
    if exec_err then
        return nil, "Failed to execute writes: " .. exec_err
    end

    local should_stop = false
    local final_status = "active"
    local new_has_integrated = has_integrated
    local new_has_tested = has_tested

    if op_type == "integrate" then
        new_has_integrated = true
    elseif op_type == "test" then
        new_has_tested = true
    elseif op_type == "debug" then
    elseif op_type == "finish" then
        local materialize_node = reader:with_data(materialize_node_id):one()
        local node_meta = materialize_node.metadata or {}
        local parent_branch_id = node_meta.parent_branch_id

        if parent_branch_id then
            node_meta.materialization_complete = true
            node_meta.last_iteration = iteration

            ws = design_writer.existing_workspace(workspace_id)
            ws:update_data(parent_branch_id, {
                status = "materialized"
            })
            ws:update_data(materialize_node_id, {
                status = "completed",
                metadata = node_meta
            })
            ws:execute()
        end

        should_stop = true
        final_status = "complete"
    end

    return {
        state = {
            branch_id = branch_id,
            materialize_node_id = materialize_node_id,
            iterations_run = iteration,
            has_integrated = new_has_integrated,
            has_tested = new_has_tested
        },
        result = {
            should_stop = should_stop,
            status = final_status,
            iterations_run = iteration,
            operation = op_type,
            reasoning = reasoning
        },
        continue = not should_stop
    }
end

return { run = run }