local json = require("json")
local flow = require("flow")

-- Special context keys that must be passed to all implementation steps
local CONTEXT_KEYS = {
    DESIGN_CONTEXT = "design_context",  -- Primary design specification (always first after task)
    TASK_CONTEXT = "task_context",      -- Alias for design_context in input
}

local function topological_sort(steps)
    local in_degree = {}
    local sorted = {}

    for _, step in ipairs(steps) do
        in_degree[step.id] = 0
    end

    for _, step in ipairs(steps) do
        local needs = step.needs or {}
        in_degree[step.id] = #needs
    end

    local queue = {}
    for _, step in ipairs(steps) do
        if in_degree[step.id] == 0 then
            table.insert(queue, step.id)
        end
    end

    while #queue > 0 do
        local current_id = table.remove(queue, 1)
        table.insert(sorted, current_id)

        for _, step in ipairs(steps) do
            local needs = step.needs or {}
            for _, dep_id in ipairs(needs) do
                if dep_id == current_id then
                    in_degree[step.id] = in_degree[step.id] - 1
                    if in_degree[step.id] == 0 then
                        table.insert(queue, step.id)
                    end
                end
            end
        end
    end

    return sorted
end

local function find_leaves(steps)
    local leaves = {}

    for _, step in ipairs(steps) do
        local is_needed = false

        for _, other in ipairs(steps) do
            local needs = other.needs or {}
            for _, dep_id in ipairs(needs) do
                if dep_id == step.id then
                    is_needed = true
                    break
                end
            end
            if is_needed then break end
        end

        if not is_needed then
            table.insert(leaves, step.id)
        end
    end

    return leaves
end

local function run(input)
    local steps = input.steps
    local max_iterations = input.max_iterations or 32
    local search_max_agents = input.search_max_agents or 5
    local task_context = input.task_context

    if not steps or #steps == 0 then
        return nil, "No steps to execute"
    end

    local step_map = {}
    for _, step in ipairs(steps) do
        step_map[step.id] = step
    end

    local sorted_ids = topological_sort(steps)
    local leaf_ids = find_leaves(steps)

    local f = flow.create():with_input({})

    for _, step_id in ipairs(sorted_ids) do
        local needs = step_map[step_id].needs or {}
        if #needs == 0 then
            f = f:to(step_id, "_")
        end
    end

    for _, step_id in ipairs(sorted_ids) do
        local step = step_map[step_id]
        local needs = step.needs or {}
        local agent_id = step.agent_id
        local produces_prompt = step.produces_prompt or "Output what you created."

        local arena_prompt =
        "CRITICAL: The <design_context> contains the authoritative specification. You MUST follow it exactly - do not deviate from specified field names, types, or structure.\n\n" ..
        "Implement the task using the provided context. Follow established patterns from examples.\n\n" ..
        "After completing implementation: " ..
        produces_prompt ..
        "\n\nExit when done. Only implement what is asked, do not handle scope of work you were not asked to handle, you are one of many agents working on this task."

        -- ROOT NODES (no dependencies) - design_context passed directly in args
        if #needs == 0 then
            f = f:func("keeper.develop:implement_task", {
                    args = {
                        task = step.task,
                        -- CRITICAL: design_context must be first context arg for all steps
                        design_context = task_context,
                        agent_id = agent_id,
                        search_options = {
                            max_agents = search_max_agents,
                            with_patterns = true
                        },
                        agent_options = {
                            max_iterations = max_iterations,
                            arena_prompt = arena_prompt
                        }
                    },
                    metadata = { title = step.title }
                })
                :as(step_id)
        -- DEPENDENT NODES - design_context passed via inputs + args
        else
            f = f:func("keeper.develop:implement_task", {
                    inputs = { required = needs },
                    args = {
                        task = step.task,
                        design_context = task_context,
                        agent_id = agent_id,
                        search_options = {
                            max_agents = search_max_agents,
                            with_patterns = true
                        },
                        agent_options = {
                            max_iterations = max_iterations,
                            arena_prompt = arena_prompt
                        }
                    },
                    metadata = { title = step.title }
                })
                :as(step_id)
        end

        for _, other in ipairs(steps) do
            local other_needs = other.needs or {}
            for _, dep_id in ipairs(other_needs) do
                if dep_id == step_id then
                    f = f:to(other.id, step_id)
                end
            end
        end

        f = f:to("exit_join", step_id)
        f = f:error_to("exit_join", step_id)
    end

    f = f:join({
            inputs = { required = leaf_ids },
            output_mode = "object",
            metadata = { title = "Collect Results" }
        })
        :as("exit_join")
        :func("keeper.develop:validate_execution", {
            metadata = {
                title = "Validate Execution",
                icon = "tabler:check"
            }
        })
        :to("@success")
        :error_to("@fail")

    return f:run()
end

return { run = run }