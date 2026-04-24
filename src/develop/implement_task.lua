-- Develop tool. Orchestrator calls this once per step with {task, agent_id,
-- agent_options, <prior_step_outputs>}. Inside, it:
--   1. Enriches the task with any named prior-step outputs passed in as extra args.
--   2. Runs keeper.develop.context:prepare_context(agent_id, enriched_task) which
--      reads the specialist's meta.context_chain, spawns the context agents in
--      parallel, and returns a formatted blob of real registry + KB patterns.
--   3. Spawns the specialist with `task` + `gathered_context` + `routing` as
--      arena inputs. The gathered_context lands in the specialist's system prompt
--      so Anthropic prompt caching kicks in automatically across calls.
--
-- Ported from /home/wolfy-j/wippy/keeper/src/develop/implement_task.lua with
-- the keeper.develop:router branch removed — agent_id is required here. Add
-- the router back once the specialists are registered.

local json = require("json")
local flow = require("flow")
local ctx = require("ctx")
local agent_registry = require("agent_registry")
local audit = require("audit")
local changeset_repo = require("changeset_repo")

local function do_handler(args)
    local task = args.task
    if not task or task == "" then return nil, "task required" end

    local agent_id = args.agent_id
    if not agent_id or agent_id == "" then
        return nil, "agent_id required (specialist to delegate to)"
    end

    -- Always resolve the live branch + changeset from the task record, not
    -- from ctx. A prior phase may have had its workspace dropped and the
    -- lifecycle auto-forked a fresh one — ctx may still hold the stale
    -- branch. Specialists must always target the task's active changeset.
    local task_id = ctx.get("task_id")
    if not task_id or task_id == "" then
        return nil, "task_id not set in ctx — call from inside a task phase"
    end
    local live_cs = changeset_repo.active_for_task(task_id)
    if not live_cs or not live_cs.state_branch then
        return nil, "task has no live changeset — implement phase cannot stage work"
    end
    local live_branch       = live_cs.state_branch
    local live_changeset_id = live_cs.changeset_id

    -- Collect named prior-step outputs (anything that isn't a known field becomes
    -- a <step_name>content</step_name> block prepended to the task). Matches the
    -- old keeper's pattern for decomposer-driven multi-step flows.
    local known_fields = {
        task = true, agent_id = true, agent_options = true, search_options = true, _ = true,
    }
    local failed_deps, step_contexts = {}, {}
    for k, v in pairs(args) do
        if not known_fields[k] then
            if type(v) == "table" then
                if v.success == false then
                    table.insert(failed_deps, { step = k, message = v.output or "unknown error" })
                elseif v.output then
                    step_contexts[k] = v.output
                end
            elseif type(v) == "string" then
                step_contexts[k] = v
            end
        end
    end

    if #failed_deps > 0 then
        local msg = "Cannot proceed — dependency failed:\n"
        for _, d in ipairs(failed_deps) do
            msg = msg .. "  step " .. d.step .. ": " .. d.message .. "\n"
        end
        return { success = false, output = msg }
    end

    -- Anchor the specialist to the original user ask. Orchestrator-authored
    -- `task` is a slice the orchestrator chose to forward; the TASK row holds
    -- the literal description the user typed. Prepend it as <original_task>
    -- so specialists can cross-check the slice against ground truth.
    local original_description = ctx.get("task_description")
    local original_title       = ctx.get("task_title")
    local anchor_parts = {}
    if original_title and original_title ~= "" then
        table.insert(anchor_parts, string.format("<task_title>\n%s\n</task_title>", original_title))
    end
    if original_description and original_description ~= "" then
        table.insert(anchor_parts, string.format("<task_description>\n%s\n</task_description>", original_description))
    end

    local enriched_task = task
    if #anchor_parts > 0 then
        enriched_task = table.concat(anchor_parts, "\n\n") .. "\n\n" .. enriched_task
    end
    if next(step_contexts) then
        local parts = {}
        for k, v in pairs(step_contexts) do
            table.insert(parts, string.format("<%s>\n%s\n</%s>", k, v, k))
        end
        enriched_task = enriched_task .. "\n\n" .. table.concat(parts, "\n\n")
    end

    local agent_options = args.agent_options or {}
    local max_iter = agent_options.max_iterations or 32
    if type(max_iter) ~= "number" or max_iter < 1 or max_iter > 64 then
        return nil, "agent_options.max_iterations must be 1..64"
    end
    local arena_prompt = agent_options.arena_prompt or [[
Implement the task using the provided context.

`<gathered_context>` holds real, live registry + KB patterns gathered by
context agents. Follow those patterns exactly — do not invent shapes from
memory. When done, exit with `success=true` and a summary of what you
implemented. Exit `success=false` with a concrete reason if you can't proceed.]]

    -- Resolve agent metadata for routing (description + requirements).
    local agent, err = agent_registry.get_by_id(agent_id)
    if err then return nil, "Failed to load specialist agent: " .. err end
    if not agent then return nil, "Specialist agent not found: " .. agent_id end
    local meta = agent.meta or {}

    local f = flow.create():with_title("Implement Task (" .. agent_id .. ")")

    f:with_data(enriched_task):as("task")
        :to("dev", "task")
        :to("prepare_context", "task")

    f:with_data({
        agent_id     = agent_id,
        description  = meta.title or agent.name or agent_id,
        requirements = meta.requirements or "None",
    }):as("routing")
        :to("prepare_context", "routing")
        :to("dev", "routing")

    f:func("keeper.develop.context:prepare_context", {
        inputs          = { required = { "task", "routing" } },
        input_transform = {
            agent_id = "inputs.routing.agent_id",
            prompt   = "inputs.task",
        },
        metadata = { title = "Prepare Context", icon = "tabler:file-search" },
    })
        :as("prepare_context")
        :to("dev", "gathered_context")
        :error_to("@fail")

    f:agent("", {
        inputs          = { required = { "task", "gathered_context", "routing" } },
        input_transform = {
            agent_id         = "inputs.routing.agent_id",
            task             = "inputs.task",
            gathered_context = "inputs.gathered_context",
        },
        arena = {
            prompt         = arena_prompt,
            max_iterations = max_iter,
            tool_calling   = "any",
            context        = {
                task_id        = task_id,
                overlay_branch = live_branch,
                changeset_id   = live_changeset_id,
            },
            exit_schema    = {
                type = "object",
                properties = {
                    success = { type = "boolean",
                        description = "true if task completed, false if could not" },
                    output  = { type = "string",
                        description = "summary on success; explanation on failure" },
                },
                required = { "success", "output" },
            },
        },
        metadata = { title = "Specialist", icon = "tabler:code" },
    })
        :as("dev")
        :to("@success")
        :error_to("@fail")

    return f:run()
end

local function handler(args)
    args = args or {}
    return audit.wrap({
        tool          = "implement_task",
        discriminator = "implement_task",
        target        = args.agent_id,
        params        = { agent_id = args.agent_id, task = args.task and args.task:sub(1, 400) or nil },
        summarise = function(result, err)
            if err then return "implement_task failed: " .. tostring(err) end
            if type(result) == "table" and result.success ~= nil then
                return "implement_task " .. (result.success and "ok" or "failed")
            end
            return "implement_task done"
        end,
    }, function()
        return do_handler(args)
    end)
end

return { handler = handler }
