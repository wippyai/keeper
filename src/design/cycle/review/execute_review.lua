local json = require("json")
local ctx = require("ctx")
local flow = require("flow")

local function run(inputs)
    local branch_id = inputs.branch_id
    local collector_output = inputs.collector_output

    if not branch_id then
        return nil, "branch_id required"
    end

    if not collector_output then
        return nil, "collector_output required"
    end

    local workspace_id = ctx.get("active_workspace_id")
    if not workspace_id then
        return nil, "active_workspace_id not set"
    end

    print(string.format("\n=== DESIGN REVIEW ==="))
    print(string.format("Branch: %s", branch_id))

    return flow.create()
        :with_title("Design Review")
        :with_input({branch_id = branch_id})
        :to("load_context")

        :func("keeper.design.cycle:load_branch_context", {
            input_transform = {
                branch_id = "input.branch_id"
            },
            metadata = {
                title = "Load Context",
                icon = "tabler:book"
            }
        })
        :as("load_context")
        :to("workflow", "branch_context")

        :func("keeper.design.cycle.review:workflow", {
            args = {
                branch_id = branch_id
            },
            input_transform = {
                branch_context = "inputs.branch_context"
            },
            metadata = {
                title = "Review Workflow",
                icon = "tabler:checklist"
            }
        })
        :as("workflow")
        :to("finalize")

        :func("keeper.design.cycle.review:finalize", {
            args = {
                branch_id = branch_id,
                collector_output = collector_output,
                workspace_id = workspace_id
            },
            input_transform = {
                passed = "inputs.workflow.passed",
                feedback = "inputs.workflow.feedback"
            },
            metadata = {
                title = "Finalize",
                icon = "tabler:check"
            }
        })
        :as("finalize")
        :to("@success")
        :error_to("@fail")

        :run()
end

return {run = run}