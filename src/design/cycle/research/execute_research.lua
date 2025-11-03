local json = require("json")
local flow = require("flow")
local ctx = require("ctx")
local design_reader = require("design_reader")

local function run(inputs)
    local branch_id = inputs.branch_id

    if not branch_id then
        return nil, "branch_id required"
    end

    local workspace_id = ctx.get("active_workspace_id")
    if not workspace_id then
        return nil, "active_workspace_id not set"
    end

    local reader = design_reader.for_workspace(workspace_id)

    local pending_research = reader
        :with_type("research")
        :with_parent_direct(branch_id)
        :with_statuses("pending")
        :order_by_position()
        :all()

    if not pending_research or #pending_research == 0 then
        return {
            executed_count = 0,
            message = "No pending research"
        }
    end

    local namespace_research = {}
    local other_research = {}

    for _, r in ipairs(pending_research) do
        local meta = r.metadata or {}
        local agent_id = meta.agent_id or r.discriminator
        if agent_id and agent_id:match("namespace_structure_specialist") then
            table.insert(namespace_research, r)
        else
            table.insert(other_research, r)
        end
    end

    local sorted_research = {}
    for _, r in ipairs(namespace_research) do
        table.insert(sorted_research, r)
    end
    for _, r in ipairs(other_research) do
        table.insert(sorted_research, r)
    end

    print(string.format("\n=== EXECUTING RESEARCH ==="))
    print(string.format("Branch: %s", branch_id))
    print(string.format("Pending research: %d (%d namespace, %d other)",
        #sorted_research, #namespace_research, #other_research))

    local f = flow.create()
        :with_title("Execute Research Agents")
        :with_input({})

    for i = 1, #sorted_research do
        f = f:to("research_" .. i, "_")
    end

    local leaf_nodes = {}
    for i, research in ipairs(sorted_research) do
        local node_id = "research_" .. i
        local meta = research.metadata or {}
        local agent_id = meta.agent_id or research.discriminator
        local title = meta.title or ("Research " .. i)

        print(string.format("  [%d] %s (Agent: %s)", i, title, agent_id))

        f = f:func("keeper.design.cycle.research:run_research_task", {
            args = {
                research_id = research.data_id,
                agent_id = agent_id,
                prompt = research.content or meta.query or "",
                workspace_id = workspace_id,
                title = title
            },
            metadata = {
                title = title,
                icon = "tabler:search"
            }
        })
        :as(node_id)
        :to("collect_results", node_id)
        :error_to("collect_results", node_id)

        table.insert(leaf_nodes, node_id)
    end

    f = f:join({
        inputs = {required = leaf_nodes},
        metadata = {
            title = "Collect Results"
        }
    })
    :as("collect_results")
    :to("@success")

    return f:run()
end

return { run = run }