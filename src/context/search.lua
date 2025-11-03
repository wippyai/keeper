local json = require("json")
local flow = require("flow")
local ctx = require("ctx")

local function handler(params)
    local prompt = params.prompt
    if not prompt or prompt == "" then
        return nil, "prompt is required"
    end

    local classes = params.classes or {}
    local system_instructions = params.system_instructions or ""
    local max_agents = params.max_agents or 5

    local router_schema = {
        type = "object",
        properties = {
            assignments = {
                type = "array",
                items = {
                    type = "object",
                    properties = {
                        agent_id = { type = "string" },
                        prompt = { type = "string" },
                    },
                    required = { "agent_id", "prompt" }
                },
                minItems = 1
            },
            reasoning = { type = "string" }
        },
        required = { "assignments", "reasoning" }
    }

    return flow.create()
        :with_title("Context Search")
        :with_input({
            prompt = prompt,
            classes = classes,
            system_instructions = system_instructions,
            max_agents = max_agents
        })
        :as("input")
        :to("router")
        :to("summarizer", "original")

        :agent("keeper.context.agents:router_agent", {
            input_transform = {
                prompt = "input.prompt",
                classes = "input.classes",
                system_instructions = "input.system_instructions",
                count = "input.max_agents"
            },
            arena = {
                prompt = "Select agents and create specific prompts for each.",
                max_iterations = 5,
                tool_calling = "any",
                exit_schema = router_schema
            },
            metadata = {
                title = "Plan Search",
                icon = "tabler:route"
            }
        })
        :as("router")
        :to("gather", "assignments", "output.assignments")

        :parallel({
            source_array_key = "assignments",
            batch_size = max_agents,
            on_error = "continue",
            filter = "successes",
            template = flow.template()
                :agent("keeper.context.traits:context_gatherer", {
                    input_transform = {
                        agent_id = "input.agent_id",
                        prompt = "input.prompt"
                    },
                    arena = {
                        prompt = "Gather context based on the specific request provided.",
                        max_iterations = 25,
                        tool_calling = "auto"
                    }
                }),
            metadata = {
                title = "Gather Context",
                icon = "tabler:search"
            }
        })
        :as("gather")
        :to("format", "content")

        :func("keeper.context:format_context", {
            inputs = { required = { "content" } },
            metadata = {
                title = "Format Output",
                icon = "tabler:file-text"
            }
        })
        :as("format")
        :to("summarizer", "gathered")

        :agent("keeper.context.agents:summarizer", {
            inputs = { required = { "original", "gathered" } },
            input_transform = {
                original_prompt = "inputs.original.prompt",
                gathered_results = "inputs.gathered"
            },
            arena = {
                prompt = "Remove redundancies and compress context to answer original query.",
                max_iterations = 3
            },
            metadata = {
                title = "Compress",
                icon = "tabler:filter"
            }
        })
        :as("summarizer")
        :to("@success")

        :run()
end

return { handler = handler }