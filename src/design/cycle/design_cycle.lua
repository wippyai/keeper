local json = require("json")
local flow = require("flow")

local function run(cycle_context)
    local iteration = cycle_context.iteration
    local state = cycle_context.state
    local last_result = cycle_context.last_result

    if iteration == 1 then
        state.branch_id = cycle_context.input.branch_id
        state.iterations_run = 0
    end

    if last_result and last_result.should_stop then
        return {
            state = state,
            result = last_result,
            continue = false
        }
    end

    local branch_id = state.branch_id

    return flow.create()
        :with_title("Design Agent Execution")
        :with_input({
            branch_id = branch_id
        })
        :as("cycle_input")
        :to("research", "cycle_input")
        :to("context_loader", "cycle_input")
        :to("agent", "cycle_input")
        :to("collector", "cycle_input")

        :func("keeper.design.cycle.research:execute_research", {
            inputs = {
                required = { "cycle_input" }
            },
            input_transform = {
                branch_id = "inputs.cycle_input.branch_id"
            },
            metadata = {
                title = "Execute Research",
                icon = "tabler:search"
            }
        })
        :as("research")
        :to("context_loader", "research_result")
        :error_to("@fail")

        :func("keeper.design.cycle:load_branch_context", {
            inputs = {
                required = { "cycle_input", "research_result" }
            },
            input_transform = {
                branch_id = "inputs.cycle_input.branch_id"
            },
            metadata = {
                title = "Load Context",
                icon = "tabler:book"
            }
        })
        :as("context_loader")
        :to("agent", "design_context")
        :error_to("@fail")

        :agent("keeper.design.agents:design_agent", {
            inputs = {
                required = { "cycle_input", "design_context" }
            },
            arena = {
                prompt = "Review context and decide actions",
                max_iterations = 15,
                tool_calling = "any",
                exit_func_id = "keeper.design.cycle:validate_operations",
                exit_schema = {
                    type = "object",
                    properties = {
                        reasoning = {
                            type = "string",
                            description = "Current thinking and why taking these actions"
                        },
                        operations = {
                            type = "array",
                            description = "Scheduled operations",
                            items = {
                                type = "object",
                                properties = {
                                    op_type = {
                                        type = "string",
                                        enum = { "research", "context", "question", "design_spec" },
                                        description = "Operation type"
                                    },
                                    agent_id = {
                                        type = "string",
                                        description = "Required for: research"
                                    },
                                    prompt = {
                                        type = "string",
                                        description = "Required for: research"
                                    },
                                    title = {
                                        type = "string",
                                        description = "Required for: research, context"
                                    },
                                    question_id = {
                                        type = "string",
                                        description = "Required for: answer"
                                    },
                                    content = {
                                        type = "string",
                                        description = "Required for: question, context, design_spec"
                                    },
                                    blocking = {
                                        type = "boolean",
                                        description = "Required for: question"
                                    },
                                    is_final = {
                                        type = "boolean",
                                        description = "Optional for: design_spec (default false)"
                                    },
                                    comment = {
                                        type = "string",
                                        description = "Optional for all operations"
                                    },
                                    key = {
                                        type = "string",
                                        description = "Short key for context item (i.e. http_endpoints, example_of_xxx_pattern), only for contexts"
                                    }
                                },
                                required = { "op_type" }
                            }
                        }
                    },
                    required = { "reasoning", "operations" }
                }
            },
            metadata = {
                title = "Design Agent",
                icon = "tabler:brain",
                iteration = iteration
            }
        })
        :as("agent")
        :to("collector", "agent_output")
        :error_to("@fail")

        :func("keeper.design.cycle:iteration_collector", {
            inputs = {
                required = { "cycle_input", "agent_output" }
            },
            input_transform = {
                branch_id = "inputs.cycle_input.branch_id",
                agent_output = "inputs.agent_output"
            },
            metadata = {
                title = "Collector",
                icon = "tabler:database"
            }
        })
        :as("collector")
        :to("review"):when("output.result.marked_final")
        :to("@success"):when("!output.result.marked_final")
        :error_to("@fail")

        :func("keeper.design.cycle.review:execute_review", {
            inputs = {
                required = { "collector" }
            },
            input_transform = {
                branch_id = "inputs.collector.state.branch_id",
                collector_output = "inputs.collector"
            },
            metadata = {
                title = "Review",
                icon = "tabler:checklist"
            }
        })
        :as("review")
        :to("@success")
        :error_to("@fail")

        :run()
end

return { run = run }
