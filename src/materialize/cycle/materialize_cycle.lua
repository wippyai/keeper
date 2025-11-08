local json = require("json")
local flow = require("flow")

local function run(cycle_context)
    local iteration = cycle_context.iteration
    local state = cycle_context.state
    local last_result = cycle_context.last_result

    if iteration == 1 then
        state.branch_id = cycle_context.input.branch_id
        state.materialize_node_id = cycle_context.input.materialize_node_id
        state.iterations_run = 0
        state.has_integrated = false
        state.has_tested = false
    end

    if last_result and last_result.should_stop then
        return {
            state = state,
            result = last_result,
            continue = false
        }
    end

    local branch_id = state.branch_id
    local materialize_node_id = state.materialize_node_id
    local has_integrated = state.has_integrated or false
    local has_tested = state.has_tested or false

    return flow.create()
        :with_title("Working on Your Design")
        :with_input({
            branch_id = branch_id,
            materialize_node_id = materialize_node_id,
            has_integrated = has_integrated,
            has_tested = has_tested
        })
        :as("cycle_input")
        :to("context_loader", "cycle_input")
        :to("orchestrator", "cycle_input")
        :to("collector", "cycle_input")

        :func("keeper.materialize.cycle:load_implementation_context", {
            inputs = {
                required = { "cycle_input" }
            },
            input_transform = {
                branch_id = "inputs.cycle_input.branch_id",
                materialize_node_id = "inputs.cycle_input.materialize_node_id"
            },
            metadata = {
                title = "Loading Design",
                icon = "tabler:book"
            }
        })
        :as("context_loader")
        :to("orchestrator", "design_context")
        :to("handler", "design_context")
        :error_to("@fail")

        :agent("keeper.materialize.agents:orchestrator", {
            inputs = {
                required = { "cycle_input", "design_context" }
            },
            arena = {
                prompt = "Review design and decide next operation",
                max_iterations = 15,
                tool_calling = "any",
                exit_func_id = "keeper.materialize.cycle:validate_operation",
                exit_schema = {
                    type = "object",
                    properties = {
                        operation = {
                            type = "string",
                            enum = { "implement", "integrate", "test", "debug", "finish" },
                            description = "Next operation"
                        },
                        reasoning = {
                            type = "string",
                            description = "Why this operation"
                        },
                        implementation_plan = {
                            type = "object",
                            properties = {
                                steps = {
                                    type = "array",
                                    items = {
                                        type = "object",
                                        properties = {
                                            id = { type = "string" },
                                            agent_id = { type = "string" },
                                            title = { type = "string" },
                                            task = { type = "string" },
                                            produces_prompt = { type = "string" },
                                            needs = {
                                                type = "array",
                                                items = { type = "string" }
                                            }
                                        },
                                        required = { "id", "agent_id", "title", "task", "produces_prompt" }
                                    }
                                }
                            }
                        },
                        debug_prompt = {
                            type = "string"
                        }
                    },
                    required = { "operation", "reasoning" }
                }
            },
            metadata = {
                title = "Planning Next Steps",
                icon = "tabler:brain",
                iteration = iteration
            }
        })
        :as("orchestrator")
        :to("collector", "orchestrator_output")
        :to("handler", "operation")
        :error_to("@fail")

        :func("keeper.materialize.cycle:implementation_collector", {
            inputs = {
                required = { "cycle_input", "orchestrator_output" }
            },
            input_transform = {
                branch_id = "inputs.cycle_input.branch_id",
                materialize_node_id = "inputs.cycle_input.materialize_node_id",
                operation = "inputs.orchestrator_output",
                has_integrated = "inputs.cycle_input.has_integrated",
                has_tested = "inputs.cycle_input.has_tested"
            },
            metadata = {
                title = "Saving Progress",
                icon = "tabler:database"
            }
        })
        :as("collector")
        :to("handler", "collector_result")
        :error_to("@fail")

        :func("keeper.materialize.cycle:operation_handler", {
            inputs = {
                required = { "collector_result", "operation", "design_context" }
            },
            metadata = {
                title = "Executing Plan",
                icon = "tabler:player-play"
            }
        })
        :as("handler")
        :to("@success")
        :error_to("@fail")

        :run()
end

return { run = run }