local json = require("json")
local flow = require("flow")

local function run(args)
    local query = args.query
    local design_spec = args.design_spec or ""

    if not query or query == "" then
        return nil, "query required"
    end

    local orchestrator_schema = {
        type = "object",
        properties = {
            assignments = {
                type = "array",
                items = {
                    type = "object",
                    properties = {
                        agent_id = { type = "string" },
                        task = { type = "string" }
                    },
                    required = { "agent_id", "task" }
                },
                minItems = 1
            },
            reasoning = { type = "string" }
        },
        required = { "assignments", "reasoning" }
    }

    return flow.create()
        :with_title("Debug Investigation")
        :with_input({
            query = query,
            design_spec = design_spec
        })
        :as("input")
        :to("orchestrator")
        :to("consolidator", "original")

        :agent("keeper.debug.agents:orchestrator", {
            input_transform = {
                query = "input.query",
                design_spec = "input.design_spec"
            },
            arena = {
                prompt = "Analyze debug query and assign to specialists",
                max_iterations = 10,
                tool_calling = "any",
                exit_schema = orchestrator_schema
            },
            metadata = {
                title = "Plan Investigation",
                icon = "tabler:brain"
            }
        })
        :as("orchestrator")
        :to("investigators", "assignments", "output.assignments")

        :parallel({
            source_array_key = "assignments",
            batch_size = 5,
            on_error = "continue",
            filter = "all",
            unwrap = false,
            template = flow.template()
                :agent("", {
                    input_transform = {
                        agent_id = "input.agent_id",
                        task = "input.task",
                        design_spec = "inputs.design_spec"
                    },
                    arena = {
                        prompt = "Investigate assigned aspect",
                        max_iterations = 20,
                        tool_calling = "auto"
                    }
                }),
            metadata = {
                title = "Investigate",
                icon = "tabler:search"
            }
        })
        :as("investigators")
        :to("consolidator", "findings")

        :func("keeper.debug:consolidate_findings", {
            inputs = { required = { "original", "findings" } },
            input_transform = {
                query = "inputs.original.query",
                results = "inputs.findings"
            },
            metadata = {
                title = "Synthesize",
                icon = "tabler:report"
            }
        })
        :as("consolidator")
        :to("@success")

        :run()
end

return { run = run }