local json = require("json")
local flow = require("flow")
local ctx = require("ctx")
local agent_registry = require("agent_registry")

local function handler(args)
    local task = args.task

    if not task or task == "" then
        return nil, "Task required"
    end

    if not ctx.get("overlay_branch") then
        return nil, "Working branch not set."
    end

    local known_fields = {
        task = true,
        agent_id = true,
        agent_options = true,
        search_options = true,
        _ = true
    }

    local failed_deps = {}
    local step_contexts = {}

    for k, v in pairs(args) do
        if not known_fields[k] then
            if type(v) == "table" then
                if v.success == false then
                    table.insert(failed_deps, {
                        step = k,
                        message = v.output or "Unknown error"
                    })
                elseif v.output then
                    step_contexts[k] = v.output
                end
            elseif type(v) == "string" then
                step_contexts[k] = v
            end
        end
    end

    if #failed_deps > 0 then
        local error_summary = "Cannot proceed: dependency failed\n\n"
        for _, dep in ipairs(failed_deps) do
            error_summary = error_summary .. "Step '" .. dep.step .. "' failed: " .. dep.message .. "\n"
        end

        return {
            success = false,
            output = error_summary
        }
    end

    local enriched_task = task
    if next(step_contexts) then
        local context_parts = {}
        for k, v in pairs(step_contexts) do
            table.insert(context_parts, string.format("<%s>\n%s\n</%s>", k, v, k))
        end
        enriched_task = task .. "\n\n" .. table.concat(context_parts, "\n\n")
    end

    local agent_id = args.agent_id

    local agent_options = args.agent_options or {}
    local agent_max_iterations = agent_options.max_iterations or 32
    local agent_arena_prompt = agent_options.arena_prompt or
        [[Implement the task using the provided context.
        Follow established patterns from examples. When done, call finish to indicate completion status.
        Previous steps and overall context provided in <xml> tags.
        Only focus on your own task.

        Always prioritize infromation in design context over other gathered context, gathered context is helping you to fill the gaps, but you MUST follow your task as part of design context.
        ]]

    if type(agent_max_iterations) ~= "number" or agent_max_iterations < 1 or agent_max_iterations > 64 then
        return nil, "agent_options.max_iterations must be between 1 and 64"
    end

    local f = flow.create():with_title("Implement Task")

    f:with_data(enriched_task):as("task")
        :to("dev", "task")
        :to("prepare_context", "task")

    if agent_id and agent_id ~= "" then
        local agent, err = agent_registry.get_by_id(agent_id)
        if err then
            return nil, "Failed to get agent: " .. err
        end
        if not agent then
            return nil, "Agent not found: " .. agent_id
        end

        local meta = agent.meta or {}
        local agent_description = meta.title or agent.name or agent_id
        local agent_requirements = meta.requirements or "None"

        f:with_data({
            agent_id = agent_id,
            description = agent_description,
            requirements = agent_requirements
        }):as("routing_info")
            :to("prepare_context", "routing")
            :to("dev", "routing")
    else
        f:with_data(task):as("router_input")
            :to("router")

        f:agent("keeper.develop:router", {
            arena = {
                prompt =
                "Select the most appropriate development specialist for the task. Provide a clear description of what this agent does and why it was selected for this specific task. Include the agent's requirements field which describes what context they need.",
                max_iterations = 5,
                tool_calling = "any",
                exit_schema = {
                    type = "object",
                    properties = {
                        agent_id = { type = "string" },
                        description = { type = "string" },
                        requirements = { type = "string" }
                    },
                    required = { "agent_id", "description" }
                }
            },
            metadata = {
                title = "Select Specialist",
                icon = "tabler:route"
            }
        })
            :as("router")
            :to("prepare_context", "routing")
            :to("dev", "routing")
            :error_to("@fail")
    end

    f:func("keeper.develop.context:prepare_context", {
        inputs = { required = { "task", "routing" } },
        input_transform = {
            agent_id = "inputs.routing.agent_id",
            prompt = "inputs.task"
        },
        metadata = {
            title = "Prepare Context",
            icon = "tabler:file-search"
        }
    })
        :as("prepare_context")
        :to("dev", "gathered_context")
        :error_to("@fail")

    f:agent("", {
        inputs = { required = { "task", "gathered_context", "routing" } },
        input_transform = {
            agent_id = "inputs.routing.agent_id",
            task = "inputs.task",
            gathered_context = "inputs.gathered_context"
        },
        arena = {
            prompt = agent_arena_prompt,
            max_iterations = agent_max_iterations,
            tool_calling = "any",
            exit_schema = {
                type = "object",
                properties = {
                    success = {
                        type = "boolean",
                        description = "true if task completed successfully, false if unable to complete"
                    },
                    output = {
                        type = "string",
                        description =
                        "If success=true: summary of what was implemented. If success=false: detailed explanation of why task could not be completed"
                    }
                },
                required = { "success", "output" }
            }
        },
        metadata = {
            title = "Developer",
            icon = "tabler:code"
        }
    })
        :as("dev")
        :to("@success")
        :error_to("@fail")

    return f:run()
end

return { handler = handler }
