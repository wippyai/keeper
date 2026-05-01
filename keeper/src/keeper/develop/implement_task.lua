-- Develop tool. Orchestrator calls this once per step with {task, agent_id,
-- agent_options, <prior_step_outputs>}. Inside, it:
--   1. Enriches the task with any named prior-step outputs passed in as extra args.
--   2. Runs keeper.develop.context:prepare_context(agent_id, enriched_task) which
--      reads the specialist's meta.context_chain, spawns the context agents in
--      parallel, and returns a formatted blob of real registry/filesystem patterns.
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
local branch_ctx = require("branch_ctx")
local scope = require("scope")

local function do_handler(args)
    local task = args.task
    if not task or task == "" then return nil, "task required" end

    local agent_id = args.agent_id
    if not agent_id or agent_id == "" then
        return nil, "agent_id required (specialist to delegate to)"
    end

    -- Resolve the active branch + changeset. Inside a task phase, prefer the
    -- task's live changeset (handles auto-fork when a prior workspace was
    -- dropped). Outside a task phase (direct MCP call from chat), fall back
    -- to ctx.overlay_branch set by set_branch — matches old keeper behavior
    -- (module-keeper/src/develop/implement_task.lua:13-15).
    local task_id           = ctx.get("task_id")
    if task_id == "" then task_id = nil end
    local live_branch, live_changeset_id
    if task_id then
        local live_cs = changeset_repo.active_for_task(task_id)
        if not live_cs or not live_cs.state_branch then
            return nil, "task has no live changeset — implement phase cannot stage work"
        end
        live_branch       = live_cs.state_branch
        live_changeset_id = live_cs.changeset_id
    else
        local overlay_branch, _ = ctx.get("overlay_branch")
        if not overlay_branch or overlay_branch == "" or overlay_branch == "main" then
            return nil, "no task_id in ctx and no overlay_branch set — call set_branch first"
        end
        local cs_id, cs_err = branch_ctx.resolve_changeset_id(overlay_branch)
        if cs_err then
            return nil, "cannot resolve changeset for branch '" .. overlay_branch .. "': " .. cs_err
        end
        live_branch       = overlay_branch
        live_changeset_id = cs_id
    end

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

`<gathered_context>` holds real, live registry/filesystem patterns gathered by
context agents. KB/docs research is separate: delegate to the task researcher
when a concrete docs or convention gap remains. Follow gathered patterns
exactly — do not invent shapes from memory. When done, exit with `success=true`
and a summary of what you implemented. Exit `success=false` with a concrete
reason if you can't proceed.]]

    -- Resolve agent metadata for routing (description + requirements).
    local agent, err = agent_registry.get_by_id(agent_id)
    if err then return nil, "Failed to load specialist agent: " .. err end
    if not agent then return nil, "Specialist agent not found: " .. agent_id end
    local meta = agent.meta or {}

    local parent_phase = ctx.get("phase")
    if parent_phase == "" then parent_phase = nil end
    local phase_scope = scope.for_phase(task_id, parent_phase, {
        changeset_id = live_changeset_id,
    })
    -- live_branch resolved from ctx may differ from active_for_task (e.g.
    -- direct-from-chat invocation while another task is active); pin it.
    phase_scope.overlay_branch = live_branch

    local f = flow.create()
        :with_title("Implement Task (" .. agent_id .. ")")
        :with_input(phase_scope)

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
        context  = phase_scope,
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
            context        = phase_scope,
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

-- Prepend a fresh live-branch banner to the specialist's output so the
-- orchestrator observing this tool result can't conflate it with a prior
-- cycle's branch. Only cosmetic for orchestrator reasoning — the structural
-- routing already uses live ctx (see do_handler above). Banner is cheap
-- and lands once per implement_task call.
local function banner_for_task(task_id)
    if not task_id or task_id == "" then return nil end
    local cs = changeset_repo.active_for_task(task_id)
    if not cs or not cs.changeset_id then return nil end
    return string.format("[active_branch=%s changeset_id=%s]",
        tostring(cs.state_branch or "?"), cs.changeset_id)
end

local function handler(args)
    args = args or {}
    return audit.wrap({
        tool          = "implement_task",
        discriminator = "implement_task",
        target        = args.agent_id,
        params        = { agent_id = args.agent_id, task = args.task },
        summarise = function(result, err)
            if err then return "implement_task failed: " .. tostring(err) end
            if type(result) == "table" and result.success ~= nil then
                return "implement_task " .. (result.success and "ok" or "failed")
            end
            return "implement_task done"
        end,
    }, function()
        local result, err = do_handler(args)
        if err then return result, err end
        if type(result) == "table" and type(result.output) == "string" then
            local banner = banner_for_task(ctx.get("task_id"))
            if banner then
                result.output = banner .. "\n" .. result.output
            end
        end
        return result, err
    end)
end

return { handler = handler }
