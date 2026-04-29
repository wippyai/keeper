local task_reader = require("task_reader")
local nodes_reader = require("nodes_reader")
local changeset_repo = require("changeset_repo")
local state_machine = require("state_machine")

local P = state_machine.PHASES
local M = {}

-- Latest phase exit (phase_exited + phase_transition pair) for the task.
-- Returns a synthesised artifact { from_phase, to_phase, signal, terminal,
-- content } so downstream rendering doesn't care which node type it came
-- from. The phase_exited node holds the signal + content; the matching
-- phase_transition holds from→to.
local function latest_phase_result(task_id)
    local exited = nodes_reader.latest_of_type(task_id, "phase_exited")
    if not exited then return nil end

    local transition = nodes_reader.latest_of_type(task_id, "phase_transition")
    local meta = exited.metadata or {}
    local t_meta = (transition and transition.metadata) or {}

    return {
        from_phase = meta.from_phase or t_meta.from_phase or exited.discriminator,
        to_phase   = meta.to_phase or t_meta.to_phase,
        signal     = meta.signal or t_meta.signal,
        terminal   = meta.terminal or t_meta.terminal or false,
        content    = exited.content,
    }
end

local function append(parts, line) table.insert(parts, line) end
local function blank(parts) table.insert(parts, "") end

local function section(parts, heading, body)
    if body == nil or body == "" then return end
    blank(parts)
    append(parts, "## " .. heading)
    append(parts, tostring(body))
end

-- Signals that mean "the prior phase did not succeed" — used to label the
-- prior phase block as a recovery vs forward handoff. Both paths still
-- inject the full phase_summary so the next orchestrator has the
-- predecessor's narrative regardless of signal.
local FAIL_SIGNALS = {
    fail = true, bugs = true, rollback = true, spec_wrong = true,
    stuck = true, abandoned = true, error = true,
}

local function retry_budget_reset_seq(task_id)
    return nodes_reader.latest_transition_seq(task_id, P.INTEGRATE, P.TEST) or 0
end

-- Inject the predecessor's phase_summary_<phase> finding. lifecycle.lua
-- emits one of these on every transition (line 483) and already bakes
-- failed-stage error_messages into its content on the integrate-fail
-- path. By always reading it here, every orchestrator on every spawn
-- gets the predecessor's full narrative — file paths, line numbers,
-- decisions, runtime tracebacks — instead of just the one-line
-- phase_exited.content elevator pitch.
local function inject_prior_phase_summary(parts, task_id, prior_phase)
    if not task_id or not prior_phase then return end
    local summary = nodes_reader.latest_of_type(task_id, "finding",
        { discriminator = "phase_summary_" .. prior_phase })
    if not summary then return end
    if not summary.content or summary.content == "" then return end

    blank(parts)
    append(parts, "## Prior Phase Summary (" .. tostring(prior_phase) .. ")")
    append(parts, summary.content)
end

-- Count how many times the cycle has previously bounced from prior_phase
-- back into the current_phase since the last successful integrate->test
-- boundary. Older history stays in the task log, but no longer consumes the
-- retry budget for post-publish test/UI recovery.
-- The retry budget block (inject_retry_budget) shows OUTBOUND caps from
-- the current phase; this function shows the INBOUND count from the
-- predecessor edge so the orchestrator immediately sees "this is the Nth
-- time I've been bounced here for this reason" without parsing budgets.
local function inject_bounce_history(parts, task_id, prior_phase, current_phase)
    if not task_id or not prior_phase or not current_phase then return end
    if prior_phase == current_phase then return end
    local count = nodes_reader.transition_count(task_id, prior_phase, current_phase,
        { after_seq = retry_budget_reset_seq(task_id) }) or 0
    if count <= 1 then return end -- a single transition isn't "history"

    blank(parts)
    append(parts, "## Bounce History")
    append(parts, string.format("- %s -> %s: %d times since the last successful integrate. Each prior attempt produced a phase_summary above (read it before delegating).",
        prior_phase, current_phase, count))
end

-- Render a phase_result artifact into a prompt section so the next phase
-- resumes with explicit awareness of the prior outcome. The order matters:
-- header signal first, then phase_exited.content (one-liner), then the
-- full phase_summary_<phase> finding (file paths + tracebacks +
-- decisions), then bounce history if this isn't a first transition.
local function prior_phase_section(parts, artifact, current_phase, task_id)
    if not artifact then return end
    if artifact.from_phase == current_phase then return end -- self-resume, skip

    blank(parts)
    append(parts, "## Prior Phase Result")
    append(parts, "- Phase: " .. tostring(artifact.from_phase))
    append(parts, "- Signal: " .. tostring(artifact.signal))
    if FAIL_SIGNALS[tostring(artifact.signal)] then
        append(parts, "- Outcome: FAILED — read the Prior Phase Summary below for the actionable detail. When you delegate to a specialist, forward the relevant error verbatim; they cannot read the trail themselves.")
    end
    if artifact.terminal then
        append(parts, "- Terminal: yes (landed in " .. tostring(artifact.to_phase) .. ")")
    end
    if type(artifact.content) == "string" and artifact.content ~= "" then
        append(parts, "")
        append(parts, artifact.content)
    end

    inject_prior_phase_summary(parts, task_id, artifact.from_phase)
    inject_bounce_history(parts, task_id, artifact.from_phase, current_phase)
end

local function inject_prior_research(parts, task_id)
    local findings = nodes_reader.findings(task_id) or {}
    if #findings == 0 then return end
    blank(parts)
    append(parts, "## Prior Research Discoveries")
    for _, f in ipairs(findings) do
        local key = f.discriminator or "finding"
        local body = f.title or ""
        if f.content and f.content ~= "" then
            body = body .. ": " .. f.content
        end
        append(parts, "- " .. key .. " — " .. body)
    end
end

local STATUS_ICON = {
    pending    = "[ ]",
    active     = "[.]",
    blocked    = "[!]",
    completed  = "[x]",
    superseded = "[-]",
    failed     = "[X]",
}

local function inject_plan_steps(parts, task_id, opts)
    opts = opts or {}
    local plan = nodes_reader.latest_of_type(task_id, "plan", { status = "active" })
    if not plan then return end
    local steps, _ = nodes_reader.children(plan.node_id)
    if not steps or #steps == 0 then return end

    -- Filter to the kinds this phase cares about, if caller asked.
    local kind_filter = opts.kinds
    local filter_active = kind_filter and next(kind_filter) ~= nil

    local rendered = {}
    local done_count, pending_count = 0, 0
    for _, s in ipairs(steps) do
        local meta = s.metadata or {}
        local kind = meta.kind or "?"
        if (not filter_active) or kind_filter[kind] then
            table.insert(rendered, { step = s, kind = kind, meta = meta })
        end
        if s.status == "completed" or s.status == "superseded" or s.status == "failed" then
            done_count = done_count + 1
        else
            pending_count = pending_count + 1
        end
    end
    if #rendered == 0 then return end

    blank(parts)
    append(parts, string.format("## Tasks (plan rev %s — %d done, %d pending%s)",
        plan.discriminator or "?", done_count, pending_count,
        filter_active and (", showing " .. #rendered .. " matching") or ""))

    for _, r in ipairs(rendered) do
        local s = r.step
        local icon = STATUS_ICON[s.status] or "?"
        local needs = (type(r.meta.needs) == "table" and #r.meta.needs > 0)
            and (" (needs: " .. table.concat(r.meta.needs, ",") .. ")") or ""
        local target = r.meta.target and (" — " .. r.meta.target) or ""
        local line = string.format("- %s %s [%s] %s%s%s",
            icon, s.discriminator or "?", r.kind, s.title or "", target, needs)
        append(parts, line)
        if s.status == "completed" and s.result_summary and s.result_summary ~= "" then
            append(parts, "  result: " .. s.result_summary)
        elseif s.status == "blocked" and s.error_message and s.error_message ~= "" then
            append(parts, "  blocked: " .. s.error_message)
        else
            if r.meta.acceptance and r.meta.acceptance ~= "" then
                append(parts, "  acceptance: " .. r.meta.acceptance)
            end
            if r.meta.verification_tool and r.meta.verification_tool ~= "" then
                append(parts, "  verify with: " .. r.meta.verification_tool)
            end
        end
    end
end

-- Surface every bounce cap with a from-edge out of `phase` so the
-- orchestrator sees current counts and remaining budget before picking a
-- signal. Counts derive from keeper_task_nodes (type=phase_transition),
-- not from the old trail.
local function inject_retry_budget(parts, task_id, phase)
    local lines = {}
    for to_phase, cap in state_machine.outbound_caps(phase) do
        local count = nodes_reader.transition_count(task_id, phase, to_phase,
            { after_seq = retry_budget_reset_seq(task_id) }) or 0
        local remaining = cap.cap - count
        if remaining < 0 then remaining = 0 end
        table.insert(lines, string.format(
            "- %s -> %s: %d/%d used (%d left). %s",
            phase, to_phase, count, cap.cap, remaining, cap.note
        ))
    end
    if #lines == 0 then return end
    table.sort(lines)
    blank(parts)
    append(parts, "## Retry Budget")
    for _, l in ipairs(lines) do append(parts, l) end
end

local function research_prompt(task, cs, opts, prior)
    local parts = {
        "# Research Phase",
        "",
        "Gather the precedents and references the design phase needs. You do not write a spec",
        "and you do not write code. Save findings via save_context so design can read_context them.",
        "",
        "## Task",
        "Title: " .. (task.title or ""),
    }
    section(parts, "Task description", task.description)
    section(parts, "Acceptance Criteria", task.acceptance)
    inject_prior_research(parts, task.task_id)
    inject_retry_budget(parts, task.task_id, P.RESEARCH)
    prior_phase_section(parts, prior, P.RESEARCH, task.task_id)
    section(parts, "User Response", opts.user_response)

    blank(parts)
    append(parts, "## Workflow")
    append(parts, "1. search_knowledge for existing findings on this topic")
    append(parts, "2. explore_state / get_entries for real precedents; fetch_docs for platform APIs")
    append(parts, "3. save_context one row per concrete finding (cite entry_ids or KB node_ids)")
    append(parts, "4. Exit one of:")
    append(parts, "   - status='done' — findings saved, design can proceed")
    append(parts, "   - status='ask_user' — task description is too ambiguous to research")
    append(parts, "   - status='abandoned' — task is infeasible on this platform")
    return table.concat(parts, "\n")
end

local function design_prompt(task, cs, opts, prior)
    local parts = {
        "# Design Phase",
        "",
        "You produce an implementation plan. You do not write code.",
        "",
        "## Task",
        "Title: " .. (task.title or ""),
    }
    section(parts, "Task description", task.description)
    section(parts, "Existing Spec (revise or keep)", task.spec)
    section(parts, "Acceptance Criteria", task.acceptance)
    inject_prior_research(parts, task.task_id)
    inject_retry_budget(parts, task.task_id, P.DESIGN)
    prior_phase_section(parts, prior, P.DESIGN, task.task_id)
    section(parts, "User Response", opts.user_response)

    blank(parts)
    append(parts, "## Workflow")
    append(parts, "1. read_context for prior research. explore / kb_read / fetch_docs to fill gaps.")
    append(parts, "2. Save every concrete finding with save_context")
    append(parts, "3. write_spec with every entry ID, kind, and dependency")
    append(parts, "4. Exit one of:")
    append(parts, "   - status='approved' — spec is final, hand off to implement")
    append(parts, "   - status='needs_research' — research gaps block the spec; the research phase")
    append(parts, "     will run and then route back to design with saved findings")
    append(parts, "   - status='ask_user' — you need clarification from the user")
    append(parts, "   - status='abandoned' — task is not feasible")

    if opts.auto_approve then
        blank(parts)
        append(parts, "## AUTO-APPROVE MODE")
        append(parts, "Skip ask_user. Write the spec and exit with status='approved'.")
    end
    return table.concat(parts, "\n")
end

local function plan_prompt(task, cs, opts, prior)
    local parts = {
        "# Plan Phase",
        "",
        "Design finished. Decompose the approved spec into a deterministic",
        "step list and persist it via write_plan. You produce the plan of",
        "record that implement/test orchestrators execute.",
        "",
        "## Task",
        "Title: " .. (task.title or ""),
    }
    section(parts, "Task description", task.description)
    section(parts, "Approved Spec", task.spec or "(missing)")
    section(parts, "Acceptance Criteria", task.acceptance)
    inject_prior_research(parts, task.task_id)
    inject_retry_budget(parts, task.task_id, P.PLAN)
    prior_phase_section(parts, prior, P.PLAN, task.task_id)
    section(parts, "User Response", opts.user_response)

    blank(parts)
    append(parts, "## Workflow")
    append(parts, "1. read_context — load prior findings; if the spec is clear, skip further research.")
    append(parts, "2. Only if the spec references entries you are unsure exist — explore / get_entries.")
    append(parts, "3. write_plan with the full step list in ONE call.")
    append(parts, "4. Exit one of:")
    append(parts, "   - status='planned' — plan saved, hand off to implement")
    append(parts, "   - status='needs_research' — spec is missing concrete details; back to design")
    append(parts, "   - status='ask_user' — need clarification before planning")
    append(parts, "   - status='abandoned' — task is not feasible")
    return table.concat(parts, "\n")
end

local function implement_prompt(task, cs, opts, prior)
    local parts = {
        "# Implement Phase",
        "",
        "The spec is approved. Stage the work on the overlay branch, then exit. You do NOT publish —",
        "the integrate function runs after review.approved and owns publish + migrations + fs flush +",
        "build + tests + endpoint probes. You have no push, no submit(commit), no integrate tool.",
        "If the spec contradicts reality, exit status='spec_wrong'.",
        "",
        "## Task",
        "Title: " .. (task.title or ""),
    }
    section(parts, "Task description", task.description)
    section(parts, "Approved Spec", task.spec or "(missing)")
    section(parts, "Acceptance Criteria", task.acceptance)
    if cs and cs.state_branch then
        section(parts, "Overlay Branch", cs.state_branch)
    end

    inject_plan_steps(parts, task.task_id, {
        kinds = { impl = true, migration = true, fs_write = true, test_create = true, research = true },
    })
    inject_prior_research(parts, task.task_id)
    inject_retry_budget(parts, task.task_id, P.IMPLEMENT)

    prior_phase_section(parts, prior, P.IMPLEMENT, task.task_id)
    section(parts, "User Response", opts.user_response)

    blank(parts)
    append(parts, "## Workflow")
    append(parts, "1. Delegate to implement_task — specialists create entries on the branch")
    append(parts, "2. lint the branch, delegate fixes until clean")
    append(parts, "3. compare once to verify only spec-scoped targets changed")
    append(parts, "4. Exit one of:")
    append(parts, "   - status='staged' — all required changes live on the overlay, hand off to review")
    append(parts, "   - status='spec_wrong' — spec cannot be realised, kick back to design")
    append(parts, "   - status='stuck' — retries not converging, need human input")
    append(parts, "   - status='ask_user' — targeted question before continuing")
    return table.concat(parts, "\n")
end

local function inject_staged_artifacts(parts, task_id)
    local rows, _ = changeset_repo.list_staged_for_task(task_id)
    if not rows or #rows == 0 then return end

    local registry, filesystem = {}, {}
    for _, r in ipairs(rows) do
        if r.category == "registry" then
            table.insert(registry, string.format("- %s %s", r.op, r.target))
        elseif r.category == "filesystem" then
            table.insert(filesystem, string.format("- %s %s", r.op, r.target))
        end
    end

    blank(parts)
    append(parts, "## Staged Artifacts")
    append(parts, "Implement put these on the overlay branch; nothing is live yet. Review checks")
    append(parts, "structural match against the spec. Integrate publishes + runs handlers after.")
    if #registry > 0 then
        blank(parts)
        append(parts, "### Registry entries (get_entries to confirm kind/meta)")
        for _, line in ipairs(registry) do append(parts, line) end
    end
    if #filesystem > 0 then
        blank(parts)
        append(parts, "### Filesystem files (fs view to confirm content)")
        for _, line in ipairs(filesystem) do append(parts, line) end
    end
end

local function inject_merged_artifacts(parts, task_id)
    local rows, _ = changeset_repo.list_applied_for_task(task_id)
    if not rows or #rows == 0 then return end

    local registry, filesystem = {}, {}
    for _, r in ipairs(rows) do
        if r.category == "registry" then
            table.insert(registry, string.format("- %s %s", r.op, r.target))
        elseif r.category == "filesystem" then
            table.insert(filesystem, string.format("- %s %s", r.op, r.target))
        end
    end

    blank(parts)
    append(parts, "## Merged Artifacts")
    append(parts, "Integrate published the following changes to main. Probe each entry/file at")
    append(parts, "runtime (live HTTP / run_test / screenshot_ui).")
    if #registry > 0 then
        blank(parts)
        append(parts, "### Registry entries (get_entries + test_endpoint + run_test)")
        for _, line in ipairs(registry) do append(parts, line) end
    end
    if #filesystem > 0 then
        blank(parts)
        append(parts, "### Filesystem files (fs view + screenshot_ui)")
        for _, line in ipairs(filesystem) do append(parts, line) end
    end
end

local function review_prompt(task, cs, opts, prior)
    local parts = {
        "# Review Phase",
        "",
        "Implement staged changes on the overlay branch. Integrate has NOT run yet —",
        "nothing is live. Do a fast structural sanity check: does the branch match the",
        "spec? No runtime probes, no HTTP, no run_test — those belong to the test phase",
        "after integrate publishes. If bugs exist, hand back to implement.",
        "",
        "## Task",
        "Title: " .. (task.title or ""),
    }
    section(parts, "Task description", task.description)
    section(parts, "Spec", task.spec)
    section(parts, "Acceptance Criteria", task.acceptance)
    inject_staged_artifacts(parts, task.task_id)
    inject_plan_steps(parts, task.task_id, {})
    inject_prior_research(parts, task.task_id)
    inject_retry_budget(parts, task.task_id, P.REVIEW)
    prior_phase_section(parts, prior, P.REVIEW, task.task_id)
    section(parts, "User Response", opts.user_response)

    blank(parts)
    append(parts, "## Workflow")
    append(parts, "1. Read the spec + Staged Artifacts — that is the structural input.")
    append(parts, "2. For each registry target: get_entries to confirm kind/meta match.")
    append(parts, "3. For each fs target: fs view to confirm content matches the spec.")
    append(parts, "4. compare once — only spec-scoped targets may appear in the diff.")
    append(parts, "5. Exit one of:")
    append(parts, "   - status='approved' — branch matches spec, hand off to integrate")
    append(parts, "   - status='bugs' — concrete mismatch; list spec-says vs branch-has per target")
    append(parts, "   - status='ask_user' — need clarification on the spec itself")
    return table.concat(parts, "\n")
end

local function test_prompt(task, cs, opts, prior)
    local parts = {
        "# Test Phase",
        "",
        "Integrate published the changeset and ran the handler chain (migrations, fs flush,",
        "build, tests, endpoint probes). Now do post-publish runtime verification against",
        "live main. If a probe fails, emit 'bugs' back to implement. If the integration",
        "broke main so badly the registry must be restored, emit 'rollback'.",
        "",
        "## Task",
        "Title: " .. (task.title or ""),
    }
    section(parts, "Task description", task.description)
    section(parts, "Spec", task.spec)
    section(parts, "Acceptance Criteria", task.acceptance)
    inject_merged_artifacts(parts, task.task_id)
    inject_plan_steps(parts, task.task_id, {
        kinds = { test_run = true, endpoint_probe = true, view_probe = true, verify = true, test_create = true },
    })
    inject_prior_research(parts, task.task_id)
    inject_retry_budget(parts, task.task_id, P.TEST)
    prior_phase_section(parts, prior, P.TEST, task.task_id)
    section(parts, "User Response", opts.user_response)

    blank(parts)
    append(parts, "## Workflow")
    append(parts, "1. Read Merged Artifacts above — that is the authoritative list.")
    append(parts, "2. For registry entries: get_entries (meta); delegate verify_api with the")
    append(parts, "   http.endpoint + meta.type=test ids.")
    append(parts, "3. For fs routes (page.vue / ui.view): delegate review_ui with the routes.")
    append(parts, "4. Exit one of:")
    append(parts, "   - status='approved' — all delegates green, runtime behaviour matches spec")
    append(parts, "   - status='bugs' — concrete probe failure; list observed vs expected")
    append(parts, "   - status='rollback' — integration broke main; trigger rollback function runner")
    append(parts, "   - status='ask_user' — need clarification on acceptance criteria")
    return table.concat(parts, "\n")
end

local BUILDERS = {
    [P.RESEARCH]  = research_prompt,
    [P.DESIGN]    = design_prompt,
    [P.PLAN]      = plan_prompt,
    [P.IMPLEMENT] = implement_prompt,
    [P.REVIEW]    = review_prompt,
    [P.TEST]      = test_prompt,
}

-- Build prompt + arena context for a phase.
-- opts: { user_response?, auto_approve? }
-- Returns: prompt_string, context_table, changeset_row_or_nil, task_row, error
function M.build(task_id, phase, opts)
    opts = opts or {}
    if not state_machine.is_valid_phase(phase) then
        return nil, nil, nil, nil, "invalid phase: " .. tostring(phase)
    end

    local task, err = task_reader.get_task(task_id)
    if err or not task then
        return nil, nil, nil, nil, "task not found: " .. tostring(err)
    end

    local cs = changeset_repo.active_for_task(task_id)
    local prior = latest_phase_result(task_id)

    local build_fn = BUILDERS[phase]
    if not build_fn then
        return nil, nil, nil, nil, "no prompt builder for phase: " .. tostring(phase)
    end
    local prompt = build_fn(task, cs, opts, prior)

    local context = {
        task_id          = task_id,
        phase            = phase,
        trail_step       = phase,
        task_title       = task.title,
        task_description = task.description,
        task_acceptance  = task.acceptance,
    }
    if cs then
        context.overlay_branch = cs.state_branch
        context.changeset_id   = cs.changeset_id
    end

    return prompt, context, cs, task, nil
end

return M
