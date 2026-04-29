-- keeper.task.phases:lifecycle
--
-- The single control-plane module for task phases. Merges what used to
-- live in task.service:orchestration + task.phases:flow + task.phases:spawner.
--
-- Public API:
--   M.start_cycle(task_id, body, actor_id)
--       Allocate a session changeset (if needed), record cycle_start, spawn
--       the DESIGN phase. Blocks on other active tasks (queue is serial).
--   M.spawn_phase(task_id, phase, opts)
--       Resume entry for start_cycle / respond / state-machine advance.
--       Verifies changeset compatibility, records phase-spawn baseline,
--       dispatches to the runner (agent or function), emits phase_started.
--   M.handle_exit(task_id, current_phase, result)
--       Called by keeper.task.tools:finish when an orchestrator exits.
--       Guards design empty-spec, routes ask_user/stuck to a pause,
--       applies bounce caps, records phase_exited + phase_transition,
--       spawns next phase.
--
-- Convenience API (same service layer, different entry points):
--   M.respond(task_id, body, actor_id)
--       Supersede active ask_user node, record user_response, spawn_phase
--       the current phase.
--   M.start_research(task_id, body) / M.sync_research(task_id)
--       Legacy standalone research dataflow helpers — pre-phase research
--       (the RESEARCH phase in the state machine is spawned via spawn_phase).

local agent_registry = require("agent_registry")
local changeset_client = require("changeset_client")
local changeset_consts = require("changeset_consts")
local changeset_repo = require("changeset_repo")
local context_builder = require("context")
local ctx = require("ctx")
local dataflow_flow = require("dataflow_flow")
local dataflow_repo = require("dataflow_repo")
local logger = require("logger")
local nodes_reader = require("nodes_reader")
local nodes_writer = require("nodes_writer")
local process = require("process")
local runners = require("runners")
local scope = require("scope")
local state_machine = require("state_machine")
local task_consts = require("task_consts")
local task_reader = require("task_reader")
local task_writer = require("task_writer")

local log = logger:named("keeper.task.lifecycle")

local M = {}

M.ERR = {
    BAD_REQUEST  = "bad_request",
    NOT_FOUND    = "not_found",
    FORBIDDEN    = "forbidden",
    UNAUTHORIZED = "unauthorized",
    CONFLICT     = "conflict",
    INTERNAL     = "internal",
}

local P = state_machine.PHASES
local S = state_machine.SIGNALS
local CS = changeset_consts.STATES
local PHASES = task_consts.PHASES
local STATUSES = task_consts.STATUSES

local BLOCKING_STATUSES = { "active", "waiting_for_user", "error" }

local CHANGESET_COMPATIBLE = {
    [P.DESIGN]    = { [CS.OPEN] = true, [CS.EDITING] = true, [CS.REVIEW] = true },
    [P.IMPLEMENT] = { [CS.OPEN] = true, [CS.EDITING] = true },
    [P.REVIEW]    = { [CS.OPEN] = true, [CS.EDITING] = true, [CS.REVIEW] = true, [CS.MERGED] = true },
}

local TERMINAL_SIGNAL = {
    [P.FINISH]    = S.APPROVED,
    [P.ABANDONED] = S.ABANDONED,
}

-- ============================================================================
-- Shared helpers
-- ============================================================================

local function fail(code, message, extra)
    local err = { code = code, message = message }
    if extra then for k, v in pairs(extra) do err[k] = v end end
    return nil, err
end

local function require_task_id(task_id)
    if not task_id or task_id == "" then
        return fail(M.ERR.BAD_REQUEST, "task id required")
    end
    return task_id
end

local function load_task(task_id)
    local task, err = task_reader.get_task(task_id)
    if err or not task then return fail(M.ERR.NOT_FOUND, "Task not found") end
    return task
end

local function emit_event(task_id, phase, discriminator, title, content, status, visibility)
    nodes_writer.record({
        task_id       = task_id,
        type          = "phase_event",
        discriminator = discriminator,
        title         = title,
        content       = content,
        status        = status or "passed",
        visibility    = visibility or "debug",
        metadata      = { phase = phase },
    })
end

-- ============================================================================
-- Changeset management
-- ============================================================================

local function find_or_create_changeset(task_id, task_title, actor_id)
    local existing = changeset_repo.list_changesets({ kind = changeset_consts.KINDS.SESSION })
    for _, cs in ipairs(existing or {}) do
        if cs.task_id == task_id
            and cs.state ~= changeset_consts.STATES.DROPPED
            and cs.state ~= changeset_consts.STATES.MERGED then
            return cs
        end
    end

    local ws, cerr = changeset_client.create({
        title    = "Task: " .. (task_title or task_id),
        kind     = changeset_consts.KINDS.SESSION,
        actor_id = actor_id,
        task_id  = task_id,
    })
    if cerr then return nil, "create changeset: " .. cerr end
    changeset_client.lock(ws.changeset_id, actor_id)
    local cs = changeset_repo.get_changeset(ws.changeset_id)
    if not cs then return nil, "changeset not found after create" end
    return cs
end

-- Auto-fork when the task has no live workspace (prior cs merged/dropped/rejected).
local function ensure_live_changeset_for_task(task_id, actor_id, phase)
    local cs = changeset_repo.active_for_task(task_id)
    if cs then return nil end

    local task = task_reader.get_task(task_id)
    local title = "Task: " .. ((task and task.title) or task_id)

    local ws, cerr = changeset_client.create({
        title    = title,
        kind     = changeset_consts.KINDS.SESSION,
        actor_id = actor_id or "orchestrator",
        task_id  = task_id,
    })
    if cerr then return "create fresh changeset: " .. cerr end

    changeset_client.lock(ws.changeset_id, actor_id or "orchestrator")
    emit_event(task_id, phase or P.IMPLEMENT, "auto_fork_changeset",
        "Auto-forked fresh changeset",
        "Prior workspace was merged, dropped, or rejected; opened " ..
            ws.changeset_id .. " (branch " .. ws.state_branch .. ") for " ..
            tostring(phase or P.IMPLEMENT) .. " re-entry.",
        "passed", "user")
    return nil
end

local function check_changeset_compatible(task_id, next_phase)
    local cs = changeset_repo.active_for_task(task_id)
    if not cs then
        if next_phase == P.DESIGN or next_phase == P.IMPLEMENT then
            return false, "no active changeset for task; expected open workspace for phase " .. next_phase
        end
        return true, nil
    end
    local allowed = CHANGESET_COMPATIBLE[next_phase]
    if allowed and not allowed[cs.state] then
        return false, "changeset " .. cs.changeset_id .. " is in state '" .. tostring(cs.state) ..
            "'; not valid entry state for phase '" .. next_phase .. "'"
    end
    return true, nil
end

local function record_phase_spawn_baseline(task_id, phase)
    local cs = changeset_repo.active_for_task(task_id)
    if not cs or not cs.changeset_id then return end
    local registry_version = cs.head_version or cs.baseline_version or "0"
    local fs_tree_hash = cs.head_fs_hash or cs.baseline_fs_hash or ""
    changeset_repo.record_baseline({
        changeset_id     = cs.changeset_id,
        registry_version = registry_version,
        fs_tree_hash     = fs_tree_hash,
        reason           = changeset_consts.BASELINE_REASONS.PHASE_SPAWN,
    })
    emit_event(task_id, phase, "phase_spawn_baseline",
        phase .. " spawn baseline",
        "changeset " .. cs.changeset_id .. " registry_version=" .. registry_version,
        "passed", "debug")
end

-- ============================================================================
-- Runner dispatch
-- ============================================================================

local function orchestrator_context_chain(runner_id)
    local agent = agent_registry.get_by_id(runner_id)
    local meta = (agent and agent.meta) or {}
    local chain = meta.context_chain
    if type(chain) ~= "table" or #chain == 0 then return nil, meta end
    return chain, meta
end

local function phase_failure_node_options(phase_scope)
    -- Required input is intentional. In dataflow, optional-only func nodes may
    -- be runnable without upstream data, which would make this error sink fire
    -- as a root node. It must run only when an upstream :error_to emits "error".
    return {
        inputs = { required = { "error" } },
        input_transform = { error = "inputs.error" },
        context = phase_scope,
        metadata = { title = "Phase Failure Handler", icon = "tabler:alert-triangle" },
    }
end

local function spawn_agent(task_id, phase, runner, opts)
    local runner_id = type(runner.id) == "string" and runner.id or nil
    if not runner_id then
        return nil, "agent runner id missing for phase " .. tostring(phase)
    end

    local exit_schema = runners.exit_schema_for(phase)

    local prompt, context, _, task, err = context_builder.build(task_id, phase, opts)
    if err then return nil, err end

    local arena = {
        prompt         = prompt,
        max_iterations = opts.max_iterations or 60,
        tool_calling   = "any",
        exit_schema    = exit_schema,
        exit_func_id   = "keeper.task.tools:finish",
        context        = context,
    }

    local base_metadata = {
        type    = "task_phase",
        task_id = task_id,
        phase   = phase,
        source  = "keeper.task",
        runner  = "agent",
    }

    local phase_scope = scope.for_phase(task_id, phase)

    local chain, meta = orchestrator_context_chain(runner_id)
    if chain then
        -- Two-step flow: prepare_context (reads meta.context_chain, spawns context
        -- agents in parallel) feeds gathered_context into the orchestrator arena.
        local f = dataflow_flow.create()
            :with_title(phase .. ": " .. (task.title or task_id))
            :with_metadata(base_metadata)
            :with_input(phase_scope)

        f:with_data(prompt):as("phase_prompt")
            :to("prepare_context", "prompt")
            :to("orchestrator", "phase_prompt")

        f:with_data({
            agent_id     = runner_id,
            description  = meta.title or runner_id,
            requirements = meta.requirements or "None",
        }):as("routing"):to("prepare_context", "routing")

        f:func("keeper.develop.context:prepare_context", {
            inputs          = { required = { "prompt", "routing" } },
            input_transform = {
                agent_id = "inputs.routing.agent_id",
                prompt   = "inputs.prompt",
            },
            context  = phase_scope,
            metadata = { title = "Prepare Context", icon = "tabler:file-search" },
        })
            :as("prepare_context")
            :to("orchestrator", "gathered_context")
            :error_to("phase_failure", "error")

        f:agent(runner.id, {
            inputs          = { required = { "phase_prompt", "gathered_context" } },
            input_transform = {
                phase_prompt     = "inputs.phase_prompt",
                gathered_context = "inputs.gathered_context",
            },
            arena = arena,
        })
            :as("orchestrator")
            :to("@success")
            :error_to("phase_failure", "error")

        f:func("keeper.task.phases:phase_failure", phase_failure_node_options(phase_scope))
            :as("phase_failure")
            :to("@success")

        return f:start({ detached = opts.detached or false })
    end

    local f = dataflow_flow.create()
        :with_title(phase .. ": " .. (task.title or task_id))
        :with_metadata(base_metadata)
        :with_input(phase_scope)
        :agent(runner.id, { arena = arena })
        :as("orchestrator")
        :to("@success")
        :error_to("phase_failure", "error")

    f:func("keeper.task.phases:phase_failure", phase_failure_node_options(phase_scope))
        :as("phase_failure")
        :to("@success")

    return f:start({ detached = opts.detached or false })
end

local function spawn_function(task_id, phase, runner, opts)
    local phase_scope = scope.for_phase(task_id, phase, {
        changeset_id = opts.changeset_id,
        actor_id     = opts.actor_id,
    })

    local f = dataflow_flow.create()
        :with_title(phase .. ": task " .. task_id)
        :with_metadata({
            type    = "task_phase",
            task_id = task_id,
            phase   = phase,
            source  = "keeper.task",
            runner  = "function",
        })
        :with_input(phase_scope)
        :func(runner.id, {
            context  = phase_scope,
            metadata = {
                title = phase .. " runner",
                icon  = phase == P.ROLLBACK and "tabler:arrow-back-up" or "tabler:rocket",
            },
        })
        :as("runner")
        :to("@success")
        :error_to("phase_failure", "error")

    f:func("keeper.task.phases:phase_failure", phase_failure_node_options(phase_scope))
        :as("phase_failure")
        :to("@success")

    return f:start({ detached = opts.detached or false })
end

local function dispatch_runner(task_id, phase, opts)
    local runner = runners.for_phase(phase)
    if not runner then
        return nil, "no runner registered for phase: " .. tostring(phase)
    end
    if runner.kind == "agent"    then return spawn_agent(task_id, phase, runner, opts) end
    if runner.kind == "function" then return spawn_function(task_id, phase, runner, opts) end
    return nil, "unknown runner kind '" .. tostring(runner.kind) .. "' for phase: " .. phase
end

-- ============================================================================
-- State-machine glue — transitions, guards, exit recording
-- ============================================================================

local function log_error(task_id, phase, title, content)
    emit_event(task_id, phase, "error", title, content, "failed", "user")
    task_writer.for_task(task_id):update_task({ status = "error" }):execute()
end

local function in_dataflow_context()
    local ok, session_context = pcall(function() return ctx.all() end)
    if not ok or type(session_context) ~= "table" then return false end
    return session_context.dataflow_id ~= nil and tostring(session_context.dataflow_id) ~= ""
end

local function phase_spawn_opts(opts)
    opts = opts or {}
    return {
        actor_id       = opts.actor_id or "orchestrator",
        changeset_id   = opts.changeset_id,
        user_response  = opts.user_response,
        auto_approve   = opts.auto_approve,
        max_iterations = opts.max_iterations,
    }
end

local function request_phase_spawn(task_id, phase, opts)
    local payload = {
        operation = "spawn_phase",
        task_id   = task_id,
        phase     = phase,
        opts      = phase_spawn_opts(opts),
    }

    local ok = process.send(
        task_consts.PROCESS_NAMES.SERVICE,
        task_consts.TOPICS.COMMANDS,
        payload
    )
    if not ok then
        return nil, "task phase service unavailable: " .. task_consts.PROCESS_NAMES.SERVICE
    end

    emit_event(task_id, phase, "phase_spawn_requested",
        "Requested " .. phase .. " phase spawn",
        "Deferred to " .. task_consts.PROCESS_NAMES.SERVICE,
        "passed", "debug")
    return true, nil
end

local function request_queue_pump(actor_id)
    local ok = process.send(
        task_consts.PROCESS_NAMES.SERVICE,
        task_consts.TOPICS.COMMANDS,
        {
            operation = "pump_queue",
            actor_id  = actor_id,
        }
    )
    if not ok then
        return nil, "task phase service unavailable: " .. task_consts.PROCESS_NAMES.SERVICE
    end
    return true, nil
end

M.request_queue_pump = request_queue_pump

local function stringify_failure(details)
    if details == nil then return "unknown error" end
    if type(details) ~= "table" then return tostring(details) end
    local preferred = details.error or details.message or details.summary or details.result_summary
    if preferred then return tostring(preferred) end
    local parts = {}
    for k, v in pairs(details) do
        table.insert(parts, tostring(k) .. "=" .. tostring(v))
    end
    table.sort(parts)
    if #parts == 0 then return "unknown error" end
    return table.concat(parts, ", ")
end

function M.handle_phase_failure(task_id, phase, details)
    if not task_id or task_id == "" then return nil, "phase_failure: task_id required" end
    phase = phase or P.DESIGN
    if not state_machine.is_valid_phase(phase) then
        return nil, "phase_failure: invalid phase '" .. tostring(phase) .. "'"
    end

    local message = stringify_failure(details)
    local summary = "Phase runner failed before calling finish: " .. message ..
        ". The task is paused so the next response can retry the same phase with this failure visible."

    local started = nodes_reader.latest_of_type(task_id, "phase_started", {
        status        = "running",
        discriminator = phase,
    })
    if started and started.node_id then
        nodes_writer.update(started.node_id, {
            status         = "failed",
            result_summary = "Phase runner failed before finish",
            error_message  = message,
        })
    end

    emit_event(task_id, phase, "phase_failure",
        "Phase runner failed before finish", message, "failed", "user")

    M.handle_exit(task_id, phase, {
        status  = S.ASK_USER,
        summary = summary,
    })

    return { ok = true, task_id = task_id, phase = phase, paused = true }
end

-- Map of step kinds → phase that handles them. Used for data-driven routing
-- after the static state-machine produces a next_phase — if the default
-- destination has no pending work matching its remit, redirect to the phase
-- that does.
local STEP_KIND_PHASE = {
    impl           = P.IMPLEMENT,
    migration      = P.IMPLEMENT,
    fs_write       = P.IMPLEMENT,
    test_create    = P.IMPLEMENT,
    research       = P.RESEARCH,
    test_run       = P.TEST,
    endpoint_probe = P.TEST,
    view_probe     = P.TEST,
    verify         = P.TEST,
}

local function pending_kind_counts(task_id)
    local plan = nodes_reader.latest_of_type(task_id, "plan", { status = "active" })
    if not plan then return {} end
    local steps, _ = nodes_reader.children(plan.node_id)
    if not steps then return {} end

    local counts = {}
    for _, s in ipairs(steps) do
        if s.status == "pending" or s.status == "in_progress" or s.status == "blocked" then
            local kind = (s.metadata and s.metadata.kind) or "?"
            counts[kind] = (counts[kind] or 0) + 1
        end
    end
    return counts
end

local function any_kind_for_phase(counts, phase)
    for kind, n in pairs(counts) do
        if n > 0 and STEP_KIND_PHASE[kind] == phase then return true end
    end
    return false
end

-- Decide the actual next phase based on remaining plan steps.
-- The override ONLY kicks in for specific phase transitions where the step
-- list changes the answer; otherwise we honour the static state machine.
--
-- integrate:ok — if impl-kind still pending, return to implement (partial
--   integrate); if no test-kind pending, skip test and finish.
-- test:approved — if impl-kind still pending, return to implement.
-- For everything else (including implement→review), honour static_next.
local function pick_next_phase_from_steps(task_id, from_phase, static_next, signal)
    local counts = pending_kind_counts(task_id)
    if not counts or next(counts) == nil then
        return static_next
    end

    if from_phase == P.INTEGRATE and signal == S.OK then
        if any_kind_for_phase(counts, P.IMPLEMENT) then
            return P.IMPLEMENT
        end
        if not any_kind_for_phase(counts, P.TEST) then
            return P.FINISH
        end
        return static_next
    end

    if from_phase == P.TEST and signal == S.APPROVED then
        if any_kind_for_phase(counts, P.IMPLEMENT) then
            return P.IMPLEMENT
        end
    end

    return static_next
end

-- Emit a short, structured phase-summary finding so the next phase sees
-- "what just happened" without re-reading the whole node tree. Contents
-- derive from already-recorded nodes; no LLM call involved.
local function emit_phase_summary(task_id, from_phase, signal, summary, to_phase)
    if not task_id or not from_phase then return end
    if signal == S.ASK_USER or signal == S.STUCK then return end

    local lines = {}
    table.insert(lines, string.format("Phase: %s — signal=%s", from_phase, signal or "?"))
    if summary and summary ~= "" then
        table.insert(lines, "Summary: " .. summary)
    end

    -- Count tool_calls recorded in this phase (grouped by tool name).
    local calls, _ = nodes_reader.by_type(task_id, "tool_call")
    if calls and #calls > 0 then
        local buckets, total_phase = {}, 0
        for _, c in ipairs(calls) do
            local meta = c.metadata or {}
            if meta.phase == from_phase then
                local tool = meta.tool or c.discriminator or "?"
                buckets[tool] = (buckets[tool] or 0) + 1
                total_phase = total_phase + 1
            end
        end
        if total_phase > 0 then
            local parts = {}
            for tool, n in pairs(buckets) do
                table.insert(parts, tool .. "=" .. n)
            end
            table.sort(parts)
            table.insert(lines, "Tool calls (" .. total_phase .. "): " .. table.concat(parts, ", "))
        end
    end

    -- Surface failing integrate-stage error_messages so the next implement
    -- phase sees exactly which handler failed and why. Without this the
    -- orchestrator reads `phase_summary_integrate` as "integrate failed"
    -- with no diagnostic and wastes a loop guessing which of migration /
    -- test / endpoint broke. The raw error_message column is populated by
    -- integrate/run.lua but only visible to SQL callers until it lands here.
    if from_phase == P.INTEGRATE and signal == S.FAIL then
        local stages, _ = nodes_reader.by_type(task_id, "integrate_stage",
            { status = "failed" })
        if stages and #stages > 0 then
            for _, st in ipairs(stages) do
                local msg = st.error_message
                if msg and msg ~= "" then
                    table.insert(lines, string.format("Stage %s failed: %s",
                        st.discriminator or "?", msg))
                end
            end
        end
    end

    -- Summarise plan step transitions during this phase, when a plan exists.
    local plan = nodes_reader.latest_of_type(task_id, "plan", { status = "active" })
    if plan then
        local steps, _ = nodes_reader.children(plan.node_id)
        if steps then
            local done_here, blocked_here, still_pending = {}, {}, 0
            for _, s in ipairs(steps) do
                if s.status == "pending" or s.status == "in_progress" then
                    still_pending = still_pending + 1
                elseif s.status == "done" then
                    table.insert(done_here, s.discriminator or "?")
                elseif s.status == "blocked" then
                    table.insert(blocked_here, s.discriminator or "?")
                end
            end
            if #done_here > 0 then
                table.insert(lines, "Steps done: " .. table.concat(done_here, ", "))
            end
            if #blocked_here > 0 then
                table.insert(lines, "Steps blocked: " .. table.concat(blocked_here, ", "))
            end
            if still_pending > 0 then
                table.insert(lines, "Steps still pending: " .. tostring(still_pending))
            end
        end
    end

    nodes_writer.record({
        task_id       = task_id,
        type          = "finding",
        discriminator = "phase_summary_" .. from_phase,
        title         = from_phase .. " summary",
        content       = table.concat(lines, "\n"),
        content_type  = "text/markdown",
        status        = "active",
        visibility    = "user",
        metadata      = { phase = from_phase, to_phase = to_phase, signal = signal, kind = "phase_summary" },
    })
end

-- Exposed for targeted regression tests. Not part of the public control-plane
-- API — call M.handle_exit instead for normal flow.
M._emit_phase_summary = emit_phase_summary

local function log_transition(task_id, from_phase, to_phase, signal, summary)
    nodes_writer.record({
        task_id        = task_id,
        type           = "phase_exited",
        discriminator  = from_phase,
        title          = from_phase .. " exited: " .. signal,
        content        = summary,
        content_type   = "text/markdown",
        status         = "passed",
        visibility     = "user",
        result_summary = "Transition: " .. signal,
        metadata       = { signal = signal, to_phase = to_phase },
    })
    nodes_writer.record({
        task_id       = task_id,
        type          = "phase_transition",
        discriminator = from_phase .. "->" .. to_phase,
        title         = from_phase .. " → " .. to_phase,
        content       = summary,
        status        = "active",
        visibility    = "user",
        metadata      = { signal = signal, from_phase = from_phase, to_phase = to_phase },
    })
end

-- Forward-declared so close_task can hand off to pump_queue. Body is
-- defined below close_task because pump_queue itself calls M.start_cycle.
local pump_queue

local function close_task(task_id, from_phase, next_phase, signal, summary)
    local is_completed = next_phase == P.FINISH
    local task_status  = is_completed and "completed" or "abandoned"

    task_writer.for_task(task_id)
        :update_task({ phase = next_phase, status = task_status })
        :execute()

    nodes_writer.record({
        task_id        = task_id,
        type           = "phase_exited",
        discriminator  = from_phase,
        title          = from_phase .. " exited: " .. signal,
        content        = summary,
        content_type   = "text/markdown",
        status         = "passed",
        visibility     = "user",
        result_summary = "Terminal: " .. signal,
        metadata       = { signal = signal, to_phase = next_phase, terminal = true },
    })
    nodes_writer.record({
        task_id       = task_id,
        type          = "phase_transition",
        discriminator = from_phase .. "->" .. next_phase,
        title         = from_phase .. " → " .. next_phase,
        content       = summary,
        status        = "active",
        visibility    = "user",
        metadata      = { signal = signal, from_phase = from_phase, to_phase = next_phase, terminal = true },
    })

    changeset_repo.set_task_lock(task_id, nil)

    -- Serial queue handoff: this task is no longer blocking, so the next
    -- waiting task can start. Phase finish runs inside a dataflow, and
    -- FlowBuilder:start intentionally rejects nested async starts. Defer the
    -- queue pump to the task process when we are still in that nested context.
    if in_dataflow_context() then
        local ok, err = request_queue_pump(nil)
        if not ok then
            emit_event(task_id, next_phase, "queue_pump_request_failed",
                "Failed to request queued task start", tostring(err), "failed", "debug")
        else
            emit_event(task_id, next_phase, "queue_pump_requested",
                "Requested queued task start",
                "Deferred to " .. task_consts.PROCESS_NAMES.SERVICE,
                "passed", "debug")
        end
    else
        pcall(pump_queue, nil)
    end
end

-- Auto-queue: when a task lands terminal (or is abandoned via the API),
-- the serial-execution invariant means the next `spec` task in the queue
-- can now start. start_cycle's own blocking-task check still gates against
-- a stale active row, so this is a fire-and-forget kick. Returns the
-- started task_id or nil if the queue is empty.
function pump_queue(actor_id)
    -- task_reader query path: phase='spec' AND archived=0, oldest first.
    -- New tasks land at status='active' phase='spec' (the queue line); they
    -- only leave 'spec' phase once start_cycle moves them to 'design'.
    -- Filtering on status='spec' was wrong — that status doesn't exist for
    -- the create_task default path.
    local tasks, err = task_reader.tasks()
        :with_phase("spec")
        :with_status("active")
        :with_archived(false)
        :order_by_created("asc")
        :limit(1)
        :all()
    if err or not tasks or #tasks == 0 then return nil end

    local next_task = tasks[1]
    if not next_task or not next_task.task_id then return nil end

    -- start_cycle re-checks BLOCKING_STATUSES against this task_id, so a
    -- concurrent spawn is still safe (the second caller gets CONFLICT).
    local _, serr = M.start_cycle(next_task.task_id, {}, actor_id or next_task.actor_id)
    if serr then return nil end
    return next_task.task_id
end

M._pump_queue = pump_queue

local function revert_phase_edits_on_ask_user(task_id, phase)
    if phase ~= P.IMPLEMENT then return end

    local cs = changeset_repo.active_for_task(task_id)
    if not cs or not cs.changeset_id or not cs.state_branch then return end

    local baseline = changeset_repo.latest_baseline_by_reason(
        cs.changeset_id, changeset_consts.BASELINE_REASONS.PHASE_SPAWN
    )
    if not baseline or not baseline.captured_at then return end

    local stats, err = changeset_repo.revert_to_phase_baseline(
        cs.changeset_id, cs.state_branch, baseline.captured_at
    )
    if err then
        emit_event(task_id, phase, "revert_failed",
            "Phase revert failed", "revert_to_phase_baseline: " .. tostring(err),
            "failed", "user")
        return
    end

    emit_event(task_id, phase, "revert",
        "Reverted " .. phase .. " edits on ask_user",
        "baseline " .. baseline.baseline_id ..
            " captured_at=" .. baseline.captured_at ..
            " entries=" .. tostring(stats.entries) ..
            " chunks=" .. tostring(stats.chunks) ..
            " edges=" .. tostring(stats.edges) ..
            " fs_content=" .. tostring(stats.fs_content) ..
            " fs_deletes=" .. tostring(stats.fs_deletes) ..
            " journal=" .. tostring(stats.journal),
        "passed", "user")
end

local function log_question(task_id, phase, summary)
    revert_phase_edits_on_ask_user(task_id, phase)

    task_writer.for_task(task_id)
        :update_task({ phase = phase, status = "waiting_for_user" })
        :execute()

    nodes_writer.record({
        task_id        = task_id,
        type           = "ask_user",
        discriminator  = phase,
        title          = "Asked: " .. summary:sub(1, 80),
        content        = summary,
        content_type   = "text/markdown",
        status         = "active",
        visibility     = "user",
        result_summary = "Waiting for user response",
        metadata       = { phase = phase },
    })
end

local function retry_budget_reset_seq(task_id)
    -- Once integrate publishes and hands off to post-publish tests, previous
    -- implement/review/integrate retries belong to the prior correction
    -- segment. Keep the history, but reset cap accounting for test-time fixes.
    return nodes_reader.latest_transition_seq(task_id, P.INTEGRATE, P.TEST) or 0
end

local function apply_bounce_guards(task_id, from_phase, to_phase, signal, summary)
    local cap = state_machine.bounce_cap(from_phase, to_phase)
    if not cap then return to_phase, signal, summary end

    local reset_seq = retry_budget_reset_seq(task_id)
    local n = nodes_reader.transition_count(task_id, from_phase, to_phase,
        { after_seq = reset_seq }) or 0
    if n < cap.cap then return to_phase, signal, summary end

    -- Sentinel terminal: instead of force-finish/abandon, pause the task for
    -- user input at the routed to_phase. handle_exit short-circuits the
    -- transition and records an ask_user node; respond resumes to_phase with
    -- the user's answer in context.
    if cap.terminal == "ask_user" then
        local reason = from_phase .. " -> " .. to_phase .. " bounced " .. n ..
            " times (cap=" .. cap.cap .. "). Pausing for user input. " ..
            "Last summary: " .. (summary or "")
        log:warn("bounce cap hit: pausing for user", {
            task_id      = task_id,
            from_phase   = from_phase,
            to_phase     = to_phase,
            cap          = cap.cap,
            count        = n,
            reset_seq    = reset_seq,
            orig_signal  = signal,
            new_signal   = S.ASK_USER,
        })
        return to_phase, S.ASK_USER, reason
    end

    local forced_signal = TERMINAL_SIGNAL[cap.terminal] or signal
    local reason = from_phase .. " -> " .. to_phase .. " bounced " .. n ..
        " times (cap=" .. cap.cap ..
        "). Forcing " .. cap.terminal .. ". Last summary: " .. (summary or "")
    -- v25 regression note: terminal=FINISH used to silently rewrite a `bugs`
    -- review exit to S.APPROVED via TERMINAL_SIGNAL[FINISH]=APPROVED, then
    -- close_task marked the task `completed` even though nothing landed on
    -- main. Post-fix: NO cap routes to FINISH (asserted by state_machine_test).
    -- This warn surfaces any future drift loudly in the logs.
    log:warn("bounce cap hit: forcing terminal", {
        task_id           = task_id,
        from_phase        = from_phase,
        to_phase          = to_phase,
        cap               = cap.cap,
        count             = n,
        reset_seq         = reset_seq,
        terminal          = cap.terminal,
        orig_signal       = signal,
        forced_signal     = forced_signal,
        signal_rewritten  = forced_signal ~= signal,
    })
    if cap.terminal == P.FINISH then
        log:error(
            "REGRESSION: cap.terminal=FINISH should never happen. "
            .. "Cap exhaustion is not a successful ship — task_status will be "
            .. "set to 'completed' falsely. See state_machine.BOUNCE_CAPS.",
            {
                task_id    = task_id,
                from_phase = from_phase,
                to_phase   = to_phase,
            })
    end
    return cap.terminal, forced_signal, reason
end

local function active_unmerged_changeset_change_count(task_id)
    local cs = changeset_repo.active_for_task(task_id)
    if not cs or not cs.changeset_id then return 0, nil end
    return changeset_repo.count_changes(cs.changeset_id) or 0, cs
end

-- `already_done` is valid for discovery phases when the requested target
-- already exists on main. It is not valid as a terminal shortcut when the
-- task owns a live changeset with unmerged edits: in that case "done" means
-- "done on the overlay", and the work still needs review + integrate.
local function guard_already_done_with_unmerged_changes(task_id, from_phase, to_phase, signal, summary)
    if signal ~= S.ALREADY_DONE or to_phase ~= P.FINISH then return to_phase, signal, summary end
    if from_phase ~= P.DESIGN and from_phase ~= P.PLAN and from_phase ~= P.IMPLEMENT then
        return to_phase, signal, summary
    end

    local change_count, cs = active_unmerged_changeset_change_count(task_id)
    if change_count <= 0 then return to_phase, signal, summary end

    local reason = "already_done would finish the task, but active changeset " ..
        tostring(cs and cs.changeset_id or "?") .. " still has " ..
        tostring(change_count) .. " unmerged change(s). Routing to review so integrate can publish them."

    emit_event(task_id, from_phase, "already_done_unmerged_guard",
        "already_done kept on review path", reason, "passed", "user")

    local new_summary = summary and summary ~= "" and (summary .. "\n\n" .. reason) or reason
    return P.REVIEW, signal, new_summary
end

local MAX_EMPTY_SPEC_CORRECTIONS = 2

-- Block a design-approved exit when no spec is on file. Checks both the
-- legacy keeper_tasks.spec column and the new keeper_task_nodes type=spec
-- (active) row — either is proof a spec exists. First N occurrences fall
-- through to ASK_USER with a diagnostic prompt; once the cap is hit, abandon.
local function guard_empty_spec(task_id, current_phase, signal)
    if current_phase ~= P.DESIGN or signal ~= S.APPROVED then return nil end

    local task = task_reader.get_task(task_id)
    if task and task.spec and task.spec ~= "" then return nil end

    local spec_node = nodes_reader.latest_of_type(task_id, "spec", { status = "active" })
    if spec_node and spec_node.content and spec_node.content ~= "" then return nil end

    local prior_rows = nodes_reader.by_type(task_id, "phase_event",
        { discriminator = "empty_spec_guard" }) or {}
    local prior = #prior_rows

    emit_event(task_id, P.DESIGN, "empty_spec_guard",
        "Design empty-spec guard",
        "Design exited status=approved but no active spec node is on file. "
            .. "Orchestrator must call write_spec before approving.",
        "failed", "user")

    if prior + 1 >= MAX_EMPTY_SPEC_CORRECTIONS then
        return {
            terminal = true,
            signal   = S.ABANDONED,
            summary  = "Design approved twice without writing a spec. Abandoning to prevent loop. "
                .. "Fix the design orchestrator prompt or supply a spec manually.",
        }
    end

    return {
        signal  = S.ASK_USER,
        summary = "Approval rejected: no spec on file. Call write_spec with the full implementation plan, "
            .. "then exit status='approved' again.",
    }
end

local RECOVERY_IMPLEMENT_PREDECESSORS = {
    [P.REVIEW]    = true,
    [P.INTEGRATE] = true,
    [P.TEST]      = true,
    [P.ROLLBACK]  = true,
}

-- First-pass implement may legitimately reject an impossible plan. Recovery
-- implement is different: review/integrate/test already produced concrete
-- failure evidence, so routing back to design hides that failure and burns a
-- full design+plan cycle. In recovery, make spec_wrong an ask_user pause.
local function guard_recovery_spec_wrong(task_id, current_phase, signal, summary)
    if current_phase ~= P.IMPLEMENT or signal ~= S.SPEC_WRONG then return nil end

    local transition = nodes_reader.latest_of_type(task_id, "phase_transition")
    if not transition then return nil end

    local meta = transition.metadata or {}
    local from_phase = meta.from_phase
    local to_phase = meta.to_phase
    if to_phase ~= P.IMPLEMENT then return nil end
    if not RECOVERY_IMPLEMENT_PREDECESSORS[from_phase] then return nil end

    local reason = "Implement emitted spec_wrong while recovering from " ..
        tostring(from_phase) .. " -> implement. That would restart design/plan " ..
        "instead of resolving the concrete prior failure. Pausing for user " ..
        "rather than redesigning automatically. Last implement summary: " ..
        (summary or "")

    emit_event(task_id, current_phase, "recovery_spec_wrong_guard",
        "Blocked recovery spec_wrong", reason, "failed", "user")

    return {
        signal  = S.ASK_USER,
        summary = reason,
    }
end

-- ============================================================================
-- Public API
-- ============================================================================

-- opts: { user_response?, auto_approve?, max_iterations?, detached?, actor_id?, changeset_id? }
-- Returns: dataflow_id, error
function M.spawn_phase(task_id, phase, opts)
    opts = opts or {}

    if phase == P.DESIGN or phase == P.PLAN or phase == P.IMPLEMENT then
        local fork_err = ensure_live_changeset_for_task(
            task_id, opts.actor_id or "orchestrator", phase
        )
        if fork_err then
            log_error(task_id, phase, "Failed to auto-fork changeset", fork_err)
            return nil, fork_err
        end
    end

    local ok, reason = check_changeset_compatible(task_id, phase)
    if not ok then
        log_error(task_id, phase, "Changeset incompatible with phase", reason)
        return nil, reason
    end

    record_phase_spawn_baseline(task_id, phase)

    if phase == P.IMPLEMENT then
        changeset_repo.set_task_lock(task_id, opts.actor_id or "orchestrator")
    end

    local dataflow_id, spawn_err = dispatch_runner(task_id, phase, opts)
    if spawn_err then
        log_error(task_id, phase, "Failed to spawn " .. phase, spawn_err)
        return nil, spawn_err
    end

    nodes_writer.record({
        task_id       = task_id,
        type          = "phase_started",
        discriminator = phase,
        title         = "Started " .. phase .. " phase",
        content       = dataflow_id and ("Dataflow: " .. tostring(dataflow_id)) or nil,
        status        = "running",
        visibility    = "user",
        dataflow_id   = dataflow_id,
        metadata      = { phase = phase },
    })

    return dataflow_id, nil
end

local function spawn_next_phase(task_id, phase, opts)
    if in_dataflow_context() then
        return request_phase_spawn(task_id, phase, opts)
    end
    return M.spawn_phase(task_id, phase, opts)
end

-- Entry point called from keeper.task.tools:finish.
-- Returns the original result so the flow's output isn't swallowed.
function M.handle_exit(task_id, current_phase, result)
    if not task_id or task_id == "" then return result end
    current_phase = current_phase or P.DESIGN
    result = result or {}

    local signal  = result.status or S.ASK_USER
    local summary = result.summary or ""

    local guard = guard_empty_spec(task_id, current_phase, signal)
    if guard then
        if guard.terminal then
            close_task(task_id, current_phase, P.ABANDONED, guard.signal, guard.summary)
            return result
        end
        signal  = guard.signal
        summary = guard.summary
    end

    guard = guard_recovery_spec_wrong(task_id, current_phase, signal, summary)
    if guard then
        signal  = guard.signal
        summary = guard.summary
    end

    -- ask_user and stuck both pause for user input; stuck carries an
    -- "implement gave up" reason. Either signal releases the changeset
    -- lock and records a question node — no phase transition.
    if signal == S.ASK_USER or signal == S.STUCK then
        changeset_repo.set_task_lock(task_id, nil)
        local question = summary
        if signal == S.STUCK then
            question = "Implement exited stuck: " .. (summary or "") ..
                " — retries did not converge. Clarify spec or let implement retry with guidance."
        end
        log_question(task_id, current_phase, question)
        return result
    end

    local next_phase, route_err = state_machine.route(current_phase, signal)
    if route_err then
        log_error(task_id, current_phase, "Invalid phase transition",
            route_err .. " (status=" .. tostring(signal) .. ")")
        return result
    end

    next_phase, signal, summary = apply_bounce_guards(task_id, current_phase, next_phase, signal, summary)
    next_phase, signal, summary = guard_already_done_with_unmerged_changes(
        task_id, current_phase, next_phase, signal, summary
    )

    -- Cap-enforced ask_user: bounce budget exhausted, pause for user at the
    -- routed next_phase instead of force-finishing. revert_phase_edits_on_ask_user
    -- (called from log_question) handles overlay rollback when next_phase is
    -- implement.
    if signal == S.ASK_USER then
        emit_phase_summary(task_id, current_phase, S.FAIL, summary, next_phase)
        task_writer.for_task(task_id):update_task({ phase = next_phase }):execute()
        changeset_repo.set_task_lock(task_id, nil)
        log_question(task_id, next_phase, summary)
        return result
    end

    -- Data-driven override: when the default route would take us to a phase
    -- that no longer has pending work matching its remit, redirect to the
    -- phase whose step kinds are still open. Keeps the task moving forward
    -- based on the deterministic plan, not the static transition table.
    if not state_machine.is_terminal(next_phase) then
        local override = pick_next_phase_from_steps(task_id, current_phase, next_phase, signal)
        if override and override ~= next_phase then
            next_phase = override
        end
    end

    -- Phase summary finding — records what happened in the phase we are
    -- leaving, annotated with the resolved destination. Flows into next
    -- phase's prompt automatically via inject_prior_research.
    emit_phase_summary(task_id, current_phase, signal, summary, next_phase)

    if state_machine.is_terminal(next_phase) then
        close_task(task_id, current_phase, next_phase, signal, summary)
        return result
    end

    log_transition(task_id, current_phase, next_phase, signal, summary)

    task_writer.for_task(task_id):update_task({ phase = next_phase }):execute()

    local _, spawn_err = spawn_next_phase(task_id, next_phase, { detached = true })
    if spawn_err then
        log_error(task_id, next_phase, "Failed to spawn " .. next_phase, spawn_err)
    end

    return result
end

-- ============================================================================
-- Business flows (service-layer entry points — kept alongside the phase
-- control plane for a single task-pipeline module).
-- ============================================================================

local function find_blocking_task(self_task_id)
    for _, s in ipairs(BLOCKING_STATUSES) do
        local tasks, err = task_reader.tasks():with_status(s):with_archived(false):limit(50):all()
        if err then return nil, err end
        for _, t in ipairs(tasks or {}) do
            if M._is_blocking_task(t, self_task_id) then
                return t
            end
        end
    end
    return nil
end

-- New tasks sit in `status=active, phase=spec` until the serial queue
-- promotes them. They are queue entries, not running work. Treating them as
-- blockers means two queued tasks deadlock each other when the current task
-- finishes.
function M._is_blocking_task(task, self_task_id)
    if not task or task.task_id == self_task_id then return false end
    if task.phase == task_consts.PHASES.SPEC then return false end
    return true
end

function M.start_cycle(task_id, body, actor_id)
    local id, idErr = require_task_id(task_id)
    if idErr then return nil, idErr end

    local task, tErr = load_task(id)
    if tErr then return nil, tErr end

    local blocker, berr = find_blocking_task(id)
    if berr then return fail(M.ERR.INTERNAL, "Failed to check running tasks: " .. berr) end
    if blocker then
        return fail(M.ERR.CONFLICT,
            "Another task is holding the queue: " .. (blocker.title or blocker.task_id) ..
            " (status: " .. blocker.status .. "). Tasks run serially so each merge becomes the baseline for the next.",
            { blocking_task = {
                task_id = blocker.task_id,
                title   = blocker.title,
                status  = blocker.status,
                phase   = blocker.phase,
            } })
    end

    local cs, ce = find_or_create_changeset(id, task.title, actor_id)
    if ce then return fail(M.ERR.INTERNAL, ce) end

    body = body or {}

    nodes_writer.record({
        task_id       = id,
        type          = "cycle_start",
        discriminator = cs.changeset_id,
        title         = "Task started",
        content       = "Changeset: " .. cs.changeset_id .. "\nBranch: " .. cs.state_branch,
        status        = "passed",
        visibility    = "user",
        changeset_id  = cs.changeset_id,
    })
    task_writer.for_task(id):update_task({ phase = P.DESIGN }):execute()

    local dataflow_id, err = M.spawn_phase(id, P.DESIGN, {
        auto_approve   = body.auto_approve or false,
        max_iterations = body.max_iterations,
    })
    if err then return fail(M.ERR.INTERNAL, "Failed to start: " .. err) end

    return {
        dataflow_id  = dataflow_id,
        changeset_id = cs.changeset_id,
        task_id      = id,
        branch       = cs.state_branch,
        phase        = P.DESIGN,
    }
end

function M.respond(task_id, body, actor_id)
    local id, idErr = require_task_id(task_id)
    if idErr then return nil, idErr end

    if not body or not body.response or body.response == "" then
        return fail(M.ERR.BAD_REQUEST, "response text required")
    end

    local task, tErr = load_task(id)
    if tErr then return nil, tErr end

    local current_phase = task.phase or P.DESIGN
    if not state_machine.is_valid_phase(current_phase) then
        return fail(M.ERR.BAD_REQUEST, "task phase is terminal or invalid: " .. tostring(current_phase))
    end

    task_writer.for_task(id):update_task({ status = STATUSES.ACTIVE }):execute()

    local active_ask = nodes_reader.latest_of_type(id, "ask_user", { status = "active" })
    if active_ask then
        nodes_writer.update(active_ask.node_id, {
            status         = "passed",
            result_summary = "User responded",
        })
    end

    nodes_writer.record({
        task_id        = id,
        type           = "user_response",
        discriminator  = current_phase,
        title          = "User: " .. body.response:sub(1, 80),
        content        = body.response,
        content_type   = "text/markdown",
        status         = "passed",
        visibility     = "user",
        agent_id       = actor_id,
        result_summary = "User responded, resuming " .. current_phase,
        metadata       = { phase = current_phase },
    })

    local dataflow_id, err = M.spawn_phase(id, current_phase, {
        actor_id      = "orchestrator",
        user_response = body.response,
    })
    if err then return fail(M.ERR.INTERNAL, "Failed to resume: " .. err) end

    local cs = changeset_repo.active_for_task(id)

    return {
        task_id     = id,
        dataflow_id = dataflow_id,
        phase       = current_phase,
        branch      = cs and cs.state_branch or nil,
    }
end

function M.start_research(task_id, body)
    local id, idErr = require_task_id(task_id)
    if idErr then return nil, idErr end

    local task, tErr = load_task(id)
    if tErr then return nil, tErr end

    body = body or {}
    local prompt = body.prompt
    if not prompt or prompt == "" then
        prompt = "Research the following task and provide findings:\n\n" ..
            "Title: " .. (task.title or "") .. "\n" ..
            "Spec: " .. (task.spec or "") .. "\n" ..
            "Acceptance: " .. (task.acceptance or "") .. "\n\n" ..
            "Explore the registry, search the knowledge base, and report:\n" ..
            "1. Relevant existing entries and patterns\n" ..
            "2. Dependencies and integration points\n" ..
            "3. Potential approaches and trade-offs"
    end

    local title = body.title or ("Research: " .. (task.title or ""):sub(1, 40))

    local f = dataflow_flow.create()
        :with_title(title)
        :with_metadata({
            type    = "design_research",
            task_id = id,
            source  = "keeper.task",
        })
        :with_input({ prompt = prompt, task_id = id })

    f:agent("keeper.agents:researcher", {
        arena = {
            prompt         = prompt,
            max_iterations = body.max_iterations or 15,
        },
    })

    local dataflow_id, err = f:start()
    if err then return fail(M.ERR.INTERNAL, "Failed to start research: " .. err) end

    nodes_writer.record({
        task_id       = id,
        type          = "research_task",
        discriminator = dataflow_id,
        title         = title,
        content       = "Dataflow started: " .. dataflow_id,
        status        = "active",
        visibility    = "user",
        agent_id      = "keeper.agents:researcher",
        dataflow_id   = dataflow_id,
        metadata      = { phase = task.phase or PHASES.RESEARCH },
    })

    task_writer.for_task(id):update_task({ phase = PHASES.RESEARCH }):execute()

    return { dataflow_id = dataflow_id, task_id = id, title = title }
end

function M.sync_research(task_id)
    local id, idErr = require_task_id(task_id)
    if idErr then return nil, idErr end

    local nodes, nerr = nodes_reader.by_type(id, "research_task", { status = "active" })
    if nerr then return fail(M.ERR.INTERNAL, nerr) end
    if not nodes or #nodes == 0 then return { synced = 0 } end

    local synced = 0
    for _, node in ipairs(nodes) do
        local dataflow_id = node.dataflow_id or node.discriminator
        if dataflow_id then
            local flow, ferr = dataflow_repo.get(dataflow_id)
            if flow and not ferr and (flow.status == "completed" or flow.status == "failed") then
                local flow_meta = flow.metadata or {}
                local err_msg = flow_meta.error

                nodes_writer.update(node.node_id, {
                    status         = flow.status == "completed" and "passed" or "failed",
                    result_summary = err_msg and ("Research failed: " .. err_msg)
                        or "Dataflow " .. dataflow_id .. " completed",
                })

                if flow.status == "completed" then
                    nodes_writer.record({
                        task_id        = id,
                        parent_node_id = node.node_id,
                        type           = "research_result",
                        discriminator  = dataflow_id,
                        title          = "Research Complete",
                        content        = "Dataflow " .. dataflow_id ..
                            " completed. Results written to knowledge base.",
                        status         = "passed",
                        visibility     = "user",
                        agent_id       = node.agent_id,
                        dataflow_id    = dataflow_id,
                    })
                end

                synced = synced + 1
            end
        end
    end

    return { synced = synced }
end

return M
