local json = require("json")
local flow = require("flow")
local ctx = require("ctx")
local design_reader = require("design_reader")

local function handler(args)
    local branch_id = args.branch_id
    local max_iterations = args.max_iterations or 10

    if not branch_id then
        local workspace_id = ctx.get("active_workspace_id")
        if not workspace_id then
            return nil, "active_workspace_id not set and branch_id not provided"
        end

        local reader = design_reader.for_workspace(workspace_id)
        local root, err = reader
            :with_type("design")
            :with_discriminator("root")
            :with_depth(0)
            :one()

        if err or not root then
            return nil, "Root branch not found: " .. (err or "not found")
        end

        branch_id = root.data_id
    end

    return flow.create()
        :with_title("Design Iteration")
        :with_input({
            branch_id = branch_id
        })
        :as("input")

        :cycle({
            func_id = "keeper.design.cycle:design_cycle",
            max_iterations = max_iterations,
            initial_state = {
                branch_id = branch_id,
                iterations_run = 0
            },
            metadata = {
                title = "Design Cycle",
                icon = "tabler:repeat"
            }
        })
        :as("cycle")
        :to("@success")
        :error_to("@fail")

        :run()
end

return { handler = handler }