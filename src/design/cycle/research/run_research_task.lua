local json = require("json")
local flow = require("flow")

local function run(input)
    local research_id = input.research_id
    local agent_id = input.agent_id
    local prompt = input.prompt
    local workspace_id = input.workspace_id
    local title = input.title

    if not research_id then
        return nil, "research_id required"
    end

    if not agent_id or agent_id == "" then
        return nil, "agent_id required"
    end

    if not workspace_id then
        return nil, "workspace_id required"
    end

    return flow.create()
        :with_title(title or "Research Task")
        :with_input({ prompt = prompt })
        :to("research_agent")

        :agent(agent_id, {
            input_transform = {
                prompt = "input.prompt"
            },
            arena = {
                prompt = "Gather research context based on the provided prompt.",
                max_iterations = 32
            },
            metadata = {
                icon = "tabler:search"
            }
        })
        :as("research_agent")
        :to("format_context", "content")

        :func("keeper.context:format_context", {
            inputs = { required = { "content" } },
            input_transform = {
                content = "inputs.content"
            }
        })
        :as("format_context")
        :to("store_result", "agent_result")
        :error_to("@fail")

        :func("keeper.design.cycle.research:store_research_result", {
            inputs = { required = { "agent_result" } },
            args = {
                research_id = research_id,
                workspace_id = workspace_id,
                title = title
            },
            input_transform = {
                agent_result = "inputs.agent_result"
            }
        })
        :as("store_result")
        :to("@success")
        :error_to("@fail")

        :run()
end

return { run = run }