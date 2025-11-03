local json = require("json")
local flow = require("flow")
local ctx = require("ctx")

local function handler(args)
    local task = args.task

    if not task or task == "" then
        return nil, "Task required"
    end

    if not ctx.get("overlay_branch") then
        return nil, "Working branch not set"
    end

    local max_iterations = args.max_iterations or 32
    local search_max_agents = args.search_max_agents or 5

    return flow.create()
        :with_title("Implement Multi-Step Task")

        :with_input(task)
            :to("decomposer")
            :to("executor", "task_context")

        :with_data({
            max_iterations = max_iterations,
            search_max_agents = search_max_agents
        }):as("options")
            :to("executor", "options")

        :agent("keeper.develop.agents:decomposer_agent", {
            arena = {
                prompt = "Decompose the task into minimal sequential steps. Select appropriate agent for each step. Do not add details not in the original task.",
                max_iterations = 8,
                tool_calling = "any",
                exit_schema = {
                    type = "object",
                    properties = {
                        steps = {
                            type = "array",
                            items = {
                                type = "object",
                                properties = {
                                    id = { type = "string" },
                                    agent_id = { type = "string" },
                                    title = { type = "string", description = "For non technical users" },
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
                    },
                    required = { "steps" }
                }
            },
            metadata = {
                title = "Decompose",
                icon = "tabler:list-tree"
            }
        })
        :as("decomposer")
        :to("executor", "plan")

        :func("keeper.develop:execute_steps", {
            inputs = { required = { "plan", "options", "task_context" } },
            input_transform = {
                steps = "inputs.plan.steps",
                max_iterations = "inputs.options.max_iterations",
                search_max_agents = "inputs.options.search_max_agents",
                task_context = "inputs.task_context"
            },
            metadata = {
                title = "Implement",
                icon = "tabler:code"
            }
        })
        :as("executor")
        :to("@success")
        :error_to("@fail")

        :run()
end

return { handler = handler }