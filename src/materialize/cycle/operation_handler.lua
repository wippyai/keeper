local json = require("json")
local flow = require("flow")
local ctx = require("ctx")
local design_writer = require("design_writer")
local design_reader = require("design_reader")

local function run(inputs)
    local collector_result = inputs.collector_result
    local operation = inputs.operation
    local design_context = inputs.design_context

    if not collector_result or not operation then
        return nil, "Missing required inputs"
    end

    local op_type = operation.operation
    local state = collector_result.state or {}
    local materialize_node_id = state.materialize_node_id

    if not materialize_node_id then
        return nil, "materialize_node_id not found in collector state"
    end

    if op_type == "finish" then
        return collector_result
    end

    if op_type == "integrate" then
        local integration_prompt = operation.integration_prompt or ""

        return flow.create()
            :with_title("Running Tests")
            :with_input({
                test_scenario = integration_prompt,
                materialize_node_id = materialize_node_id,
                state = state
            })
            :as("integration_input")
            :to("integration", "integration_input")
            :to("store_result", "integration_input")

            :func("keeper.integrate:integrate", {
                inputs = { required = { "integration_input" } },
                input_transform = {
                    test_scenario = "inputs.integration_input.test_scenario"
                },
                metadata = {
                    title = "Testing Changes",
                    icon = "tabler:rocket"
                }
            })
            :as("integration")
            :to("store_result", "integration_result")
            :error_to("store_result", "integration_result")

            :func("keeper.materialize.cycle:store_operation_result", {
                inputs = { required = { "integration_result", "integration_input" } },
                input_transform = {
                    materialize_node_id = "inputs.integration_input.materialize_node_id",
                    operation_type = '"integrate"',
                    result = "inputs.integration_result",
                    state = "inputs.integration_input.state"
                },
                metadata = {
                    title = "Recording Results",
                    icon = "tabler:database"
                }
            })
            :as("store_result")
            :to("@success")
            :error_to("@fail")

            :run()
    end

    if op_type == "implement_graph" then
        local plan = operation.implementation_plan
        if not plan or not plan.steps then
            return nil, "No implementation plan found"
        end

        local workspace_id = ctx.get("active_workspace_id")
        if not workspace_id then
            return nil, "active_workspace_id not set"
        end

        local reader = design_reader.for_workspace(workspace_id)
        local materialize_node = reader:with_data(materialize_node_id):one()
        if not materialize_node then
            return nil, "Materialize node not found"
        end

        local node_meta = materialize_node.metadata or {}
        local parent_branch_id = node_meta.parent_branch_id

        if not parent_branch_id then
            return nil, "parent_branch_id not found in materialize node metadata"
        end

        local branch = reader:with_data(parent_branch_id):one()
        if not branch then
            return nil, "Parent design branch not found"
        end

        return flow.create()
            :with_title("Building Features")
            :with_input({
                steps = plan.steps,
                max_iterations = 32,
                search_max_agents = 5,
                branch_id = parent_branch_id,
                materialize_node_id = materialize_node_id,
                state = state
            })
            :as("execution_input")
            :to("load_clean_context", "execution_input")
            :to("execute_steps", "execution_input")
            :to("store_result", "execution_input")

            :func("keeper.materialize.cycle:load_design_context", {
                inputs = { required = { "execution_input" } },
                input_transform = {
                    branch_id = "inputs.execution_input.branch_id"
                },
                metadata = {
                    title = "Loading Design Spec",
                    icon = "tabler:file-text"
                }
            })
            :as("load_clean_context")
            :to("execute_steps", "task_context")

            :func("keeper.develop:execute_steps", {
                inputs = { required = { "execution_input", "task_context" } },
                input_transform = {
                    steps = "inputs.execution_input.steps",
                    max_iterations = "inputs.execution_input.max_iterations",
                    search_max_agents = "inputs.execution_input.search_max_agents",
                    task_context = "inputs.task_context"
                },
                metadata = {
                    title = "Implementing Steps",
                    icon = "tabler:code"
                }
            })
            :as("execute_steps")
            :to("store_result", "execution_result")

            :func("keeper.materialize.cycle:store_operation_result", {
                inputs = { required = { "execution_result", "execution_input" } },
                input_transform = {
                    materialize_node_id = "inputs.execution_input.materialize_node_id",
                    operation_type = '"implement_graph"',
                    result = "inputs.execution_result",
                    state = "inputs.execution_input.state"
                },
                metadata = {
                    title = "Recording Results",
                    icon = "tabler:database"
                }
            })
            :as("store_result")
            :to("@success")
            :error_to("@fail")

            :run()
    end

    return nil, "Unknown operation type: " .. (op_type or "nil")
end

return { run = run }