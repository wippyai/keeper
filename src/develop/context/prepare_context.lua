local json = require("json")
local flow = require("flow")
local agent_registry = require("agent_registry")

local function format_conditional_list(conditional)
    local parts = {}
    for i, spec in ipairs(conditional) do
        table.insert(parts, string.format(
            "%d. agent_id: %s\n   instructions: %s\n   condition: %s",
            i, spec.agent_id, spec.instructions, spec.condition
        ))
    end
    return table.concat(parts, "\n\n")
end

local function handler(params)
    local agent_id = params.agent_id
    local prompt = params.prompt

    if not agent_id or agent_id == "" then
        return nil, "agent_id required"
    end

    if not prompt or prompt == "" then
        return nil, "prompt required"
    end

    local agent, err = agent_registry.get_by_id(agent_id)
    if err then
        return nil, "Failed to load agent: " .. err
    end

    if not agent then
        return nil, "Agent not found: " .. agent_id
    end

    local meta = agent.meta or {}
    local context_chain = meta.context_chain

    if not context_chain or #context_chain == 0 then
        return "", nil
    end

    local unconditional = {}
    local conditional = {}

    for _, entry in ipairs(context_chain) do
        if entry.agent_id then
            local spec = {
                agent_id = entry.agent_id,
                instructions = entry.instructions or ""
            }

            if entry.condition then
                spec.condition = entry.condition
                table.insert(conditional, spec)
            else
                table.insert(unconditional, spec)
            end
        end
    end

    if #unconditional == 0 and #conditional == 0 then
        return "", nil
    end

    if #conditional == 0 then
        return flow.create()
            :with_title("Execute Context Agents")

            :with_data(unconditional):as("specs")
                :to("executor", "specs")

            :with_data(prompt):as("task")
                :to("executor", "task")

            :parallel({
                inputs = { required = { "specs", "task" } },
                source_array_key = "specs",
                iteration_input_key = "spec",
                passthrough_keys = { "task" },
                batch_size = 10,
                on_error = "continue",
                filter = "successes",
                unwrap = true,
                template = flow.template()
                    :agent("", {
                        inputs = { required = { "spec", "task" } },
                        input_transform = {
                            agent_id = "inputs.spec.agent_id",
                            instructions = "inputs.spec.instructions",
                            task = "inputs.task"
                        },
                        arena = {
                            prompt = "Follow the provided instructions to gather context for the task. If you see target or example entries from design context, focus on loading them.",
                            max_iterations = 25,
                            tool_calling = "auto"
                        }
                    })
                    :to("@success"),
                metadata = {
                    title = "Query Context",
                    icon = "tabler:users"
                }
            })
            :as("executor")
                :to("formatter", "content", [[join(output, "\n\n---\n\n")]])
            :error_to("@fail")

            :func("keeper.context:format_context", {
                inputs = { required = { "content" } },
                input_transform = {
                    content = "inputs.content"
                },
                metadata = {
                    title = "Format Context",
                    icon = "tabler:file-text"
                }
            })
            :as("formatter")
                :to("@success")
            :error_to("@fail")

            :run()
    end

    local conditional_text = format_conditional_list(conditional)

    return flow.create()
        :with_title("Execute Context Agents with Routing")

        :with_data(prompt):as("task")
            :to("exec_unconditional", "task")
            :to("router", "task")
            :to("exec_conditional", "task")

        :with_data(unconditional):as("unconditional_specs")
            :to("exec_unconditional", "specs")

        :with_data(conditional):as("all_conditional_specs")
            :to("exec_conditional", "all_specs")

        :with_data(conditional_text):as("conditional_text")
            :to("router", "conditional_agents")

        :parallel({
            inputs = { required = { "specs", "task" } },
            source_array_key = "specs",
            iteration_input_key = "spec",
            passthrough_keys = { "task" },
            batch_size = 10,
            on_error = "continue",
            filter = "successes",
            unwrap = true,
            template = flow.template()
                :agent("", {
                    inputs = { required = { "spec", "task" } },
                    input_transform = {
                        agent_id = "inputs.spec.agent_id",
                        instructions = "inputs.spec.instructions",
                        task = "inputs.task"
                    },
                    arena = {
                        prompt = "Follow the provided instructions to gather context for the task.",
                        max_iterations = 25,
                        tool_calling = "auto"
                    }
                })
                :to("@success"),
            metadata = {
                title = "Find Context",
                icon = "tabler:database"
            }
        })
        :as("exec_unconditional")
            :to("router", "gathered_context", [[join(output, "\n\n---\n\n")]])
            :to("exec_conditional", "gathered_context", [[join(output, "\n\n---\n\n")]])
            :to("merger", "unconditional", [[join(output, "\n\n---\n\n")]])
        :error_to("@fail")

        :agent("keeper.develop.context:context_router", {
            inputs = { required = { "task", "conditional_agents", "gathered_context" } },
            arena = {
                prompt = "Evaluate which conditional context agents should run based on the task and conditions. Consider what has already been gathered in the unconditional context.",
                max_iterations = 5,
                tool_calling = "any",
                exit_schema = {
                    type = "object",
                    properties = {
                        selected = {
                            type = "array",
                            items = { type = "string" },
                            description = "Array of selected agent IDs"
                        },
                        reasoning = {
                            type = "string",
                            description = "Explanation of why each agent was selected or not"
                        }
                    },
                    required = { "selected", "reasoning" }
                }
            },
            metadata = {
                title = "Analyze Context Gaps",
                icon = "tabler:route"
            }
        })
        :as("router")
            :to("exec_conditional", "selected"):when("len(output.selected) > 0")
            :to("merger", "conditional", '""'):when("len(output.selected) == 0")
        :error_to("@fail")

        :parallel({
            inputs = { required = { "selected", "all_specs", "task", "gathered_context" } },
            input_transform = {
                specs = [[filter(inputs.all_specs, {#.agent_id in inputs.selected.selected})]],
                task = "inputs.task",
                gathered_context = "inputs.gathered_context"
            },
            source_array_key = "specs",
            iteration_input_key = "spec",
            passthrough_keys = { "task", "gathered_context" },
            batch_size = 10,
            on_error = "continue",
            filter = "successes",
            unwrap = true,
            template = flow.template()
                :agent("", {
                    inputs = { required = { "spec", "task", "gathered_context" } },
                    input_transform = {
                        agent_id = "inputs.spec.agent_id",
                        instructions = "inputs.spec.instructions",
                        task = "inputs.task",
                        gathered_context = "inputs.gathered_context"
                    },
                    arena = {
                        prompt = "Follow the provided instructions to gather context for the task. Context already gathered is provided for reference, do not duplicate it.",
                        max_iterations = 25,
                        tool_calling = "auto"
                    }
                })
                :to("@success"),
            metadata = {
                title = "Clarify Context Gaps",
                icon = "tabler:search"
            }
        })
        :as("exec_conditional")
            :to("merger", "conditional", [[join(output, "\n\n---\n\n")]])
        :error_to("@fail")

        :join({
            inputs = { required = { "unconditional", "conditional" } },
            metadata = {
                title = "Merge Results",
                icon = "tabler:transform"
            }
        })
        :as("merger")
            :to("formatter", "content", [[output.unconditional + "\n\n---\n\n" + output.conditional]])
        :error_to("@fail")

        :func("keeper.context:format_context", {
            inputs = { required = { "content" } },
            input_transform = {
                content = "inputs.content"
            },
            metadata = {
                title = "Format Context",
                icon = "tabler:file-text"
            }
        })
        :as("formatter")
            :to("@success")
        :error_to("@fail")

        :run()
end

return { handler = handler }