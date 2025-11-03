local json = require("json")
local flow = require("flow")

local function run(inputs)
    local branch_context = inputs.branch_context
    local branch_id = inputs.branch_id

    if not branch_context or branch_context == "" then
        return nil, "branch_context required"
    end

    if not branch_id then
        return nil, "branch_id required"
    end

    local assignments_schema = {
        type = "object",
        properties = {
            assignments = {
                type = "array",
                items = {
                    type = "object",
                    properties = {
                        agent_id = { type = "string" },
                        prompt = { type = "string" }
                    },
                    required = { "agent_id", "prompt" }
                }
            },
            reasoning = { type = "string" }
        },
        required = { "assignments", "reasoning" }
    }

    local result_schema = {
        type = "object",
        properties = {
            passed = { type = "boolean" },
            feedback = { type = { "string", "null" } }
        },
        required = { "passed" }
    }

    return flow.create()
        :with_title("Review Workflow")
        :with_input({ branch_context = branch_context })
        :to("decompose")

        :with_data(branch_context):as("context_data")
            :to("reviewers", "context")

        :agent("keeper.design.agents.review:decomposer", {
            input_transform = {
                branch_context = "input.branch_context"
            },
            arena = {
                prompt = "Select reviewers and create review prompts",
                max_iterations = 5,
                tool_calling = "any",
                exit_schema = assignments_schema
            },
            metadata = {
                title = "Decompose",
                icon = "tabler:route"
            }
        })
        :as("decompose")
        :to("@success", nil, "{passed: true, feedback: nil}"):when("len(output.assignments) == 0")
        :to("reviewers", "assignments", "output.assignments")

        :parallel({
            inputs = { required = { "assignments", "context" } },
            source_array_key = "assignments",
            iteration_input_key = "assignment",
            passthrough_keys = { "context" },
            batch_size = 5,
            on_error = "continue",
            filter = "all",
            unwrap = false,
            template = flow.template()
                :agent("", {
                    inputs = { required = { "assignment", "context" } },
                    input_transform = {
                        agent_id = "inputs.assignment.agent_id",
                        prompt = "inputs.assignment.prompt",
                        branch_context = "inputs.context"
                    },
                    arena = {
                        prompt = "Review design",
                        max_iterations = 10
                    }
                })
                :to("@success"),
            metadata = {
                title = "Execute Reviews",
                icon = "tabler:checklist"
            }
        })
        :as("reviewers")
        :to("consolidate", "results")

        :agent("keeper.design.agents.review:consolidator", {
            inputs = { required = { "results" } },
            input_transform = {
                results = "inputs.results"
            },
            arena = {
                prompt = "Consolidate feedback",
                max_iterations = 3,
                tool_calling = "any",
                exit_schema = result_schema
            },
            metadata = {
                title = "Consolidate",
                icon = "tabler:git-merge"
            }
        })
        :as("consolidate")
        :to("@success")
        :error_to("@fail")

        :run()
end

return { run = run }