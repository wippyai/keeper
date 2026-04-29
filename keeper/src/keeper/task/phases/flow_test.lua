local test = require("test")
local uuid = require("uuid")
local time = require("time")
local dataflow_flow = require("dataflow_flow")
local flow = require("lifecycle")
local state_machine = require("state_machine")
local phase_spawner = require("phase_spawner")
local task_writer = require("task_writer")
local task_reader = require("task_reader")
local nodes_reader = require("nodes_reader")
local nodes_writer = require("nodes_writer")
local changeset_repo = require("changeset_repo")
local changeset_consts = require("changeset_consts")
local sql = require("sql")
local task_consts = require("task_consts")

local DATAFLOW_DB = "app:db"

local function define_tests()
    describe("Phase flow advance", function()
        local P = state_machine.PHASES
        local S = state_machine.SIGNALS
        local created_ids = {}
        local created_changesets = {}
        local created_dataflows = {}

        local function must_db(resource_id)
            local db, err = sql.get(resource_id)
            if err then error("db: " .. tostring(err)) end
            if not db then error("db unavailable: " .. tostring(resource_id)) end
            return db
        end

        local function must_cap(from_phase, to_phase)
            local cap = state_machine.bounce_cap(from_phase, to_phase)
            if not cap then
                error("missing bounce cap for " .. tostring(from_phase) .. " -> " .. tostring(to_phase))
            end
            return cap
        end

        after_all(function()
            local df_db = sql.get(DATAFLOW_DB)
            if df_db then
                for _, dataflow_id in ipairs(created_dataflows) do
                    df_db:execute("DELETE FROM dataflow_data WHERE dataflow_id = ?", { dataflow_id })
                    df_db:execute("DELETE FROM dataflow_commits WHERE dataflow_id = ?", { dataflow_id })
                    df_db:execute("DELETE FROM dataflow_nodes WHERE dataflow_id = ?", { dataflow_id })
                    df_db:execute("DELETE FROM dataflows WHERE dataflow_id = ?", { dataflow_id })
                end
                df_db:release()
            end

            local db = sql.get(task_consts.DATABASE.RESOURCE_ID)
            if db then
                for _, id in ipairs(created_ids) do
                    db:execute("DELETE FROM keeper_task_nodes WHERE task_id = ?", { id })
                    db:execute("DELETE FROM keeper_tasks WHERE task_id = ?", { id })
                end
                db:release()
            end
            local cdb = sql.get(changeset_consts.DATABASE.RESOURCE_ID)
            if cdb then
                for _, task_id in ipairs(created_ids) do
                    local rows = cdb:query(
                        "SELECT changeset_id FROM keeper_changesets WHERE task_id = ?",
                        { task_id }
                    ) or {}
                    for _, row in ipairs(rows) do
                        table.insert(created_changesets, row.changeset_id)
                    end
                end
                for _, id in ipairs(created_changesets) do
                    cdb:execute("DELETE FROM keeper_changeset_changes WHERE changeset_id = ?", { id })
                    cdb:execute("DELETE FROM keeper_changeset_fs_content WHERE changeset_id = ?", { id })
                    cdb:execute("DELETE FROM keeper_changeset_fs_deletes WHERE changeset_id = ?", { id })
                    cdb:execute("DELETE FROM keeper_changeset_baselines WHERE changeset_id = ?", { id })
                    cdb:execute("DELETE FROM keeper_changesets WHERE changeset_id = ?", { id })
                end
                cdb:release()
            end
        end)

        local function make_task(title)
            local res, err = task_writer.create_task({
                title    = title,
                actor_id = "test.flow",
                spec     = "x",
            }):execute()
            if err then error(err) end
            table.insert(created_ids, res.task_id)
            return res.task_id
        end

        local function make_changeset_for(task_id, title)
            local cs_id = "flowtest-" .. uuid.v7()
            local ws, err = changeset_repo.create_changeset({
                changeset_id     = cs_id,
                task_id          = task_id,
                title            = title or "flow-test cs",
                kind             = changeset_consts.KINDS.SESSION,
                actor_id         = "test.flow",
                state_branch     = changeset_consts.branch_for(cs_id),
                scratch_fs_path  = cs_id .. "/",
                baseline_version = "0",
                baseline_fs_hash = "",
            })
            if err then error(err) end
            table.insert(created_changesets, ws.changeset_id)
            return ws
        end

        local function record_baseline(task_id, cs_id, baseline)
            nodes_writer.record({
                task_id       = task_id,
                type          = "phase_event",
                discriminator = "implement_baseline",
                title         = "implement baseline",
                content       = "changeset " .. cs_id .. " baseline=" .. baseline,
                status        = "passed",
                visibility    = "debug",
                metadata      = { phase = P.IMPLEMENT, baseline = baseline },
            })
        end

        local function seed_bounces(task_id, from_phase, to_phase, count)
            for _ = 1, count do
                nodes_writer.record({
                    task_id       = task_id,
                    type          = "phase_transition",
                    discriminator = from_phase .. "->" .. to_phase,
                    title         = from_phase .. " → " .. to_phase,
                    content       = "bounce",
                    status        = "active",
                    visibility    = "user",
                    metadata      = { from_phase = from_phase, to_phase = to_phase },
                })
            end
        end

        describe("bounce cap enforcement", function()
            it("routes review->implement on the first bounce", function()
                local task_id = make_task("First review bounce")
                -- No prior bounces seeded. cap=1 means the first bounce still routes normally.
                flow.handle_exit(task_id, P.REVIEW, { status = S.BUGS, summary = "retry" })
                local row = task_reader.get_task(task_id)
                test.eq(row.phase, P.IMPLEMENT, "phase should advance to implement on first bounce")
                test.is_true(row.status ~= "completed", "task should not be terminal yet")
            end)

            it("review->implement cap=1 exhaustion pauses for user (NOT completed, NOT abandoned)", function()
                local task_id = make_task("At review cap")
                local cap = must_cap(P.REVIEW, P.IMPLEMENT)
                seed_bounces(task_id, P.REVIEW, P.IMPLEMENT, cap.cap)
                flow.handle_exit(task_id, P.REVIEW, { status = S.BUGS, summary = "still red" })
                local row = task_reader.get_task(task_id)
                test.eq(row.status, "waiting_for_user",
                    "review-cap exhaustion must pause for user — the agents are stuck in ping-pong; the user can adjudicate. Pre-fix this was task_status='completed' (v25 regression).")
                test.is_true(row.status ~= "completed",
                    "completed means 'shipped to main' — never a force-finish from cap exhaustion")
                test.is_true(row.phase ~= P.FINISH,
                    "phase must NOT be FINISH on cap-fire; that label belongs to actual successful ship")
            end)

            it("v25 regression: cap-fired review-bugs after a prior integrate-fail still ask_user (not completed)", function()
                local task_id = make_task("Review cap after integrate fail")
                -- The exact v25 path: review#1 bounced once, review#2 approved,
                -- integrate#1 failed and re-spawned implement, review#3 returns
                -- bugs again. Cap=1 fires.
                seed_bounces(task_id, P.REVIEW, P.IMPLEMENT, 1)
                seed_bounces(task_id, P.REVIEW, P.INTEGRATE, 1)
                seed_bounces(task_id, P.INTEGRATE, P.IMPLEMENT, 1)
                flow.handle_exit(task_id, P.REVIEW,
                    { status = S.BUGS, summary = "structural review still failing post-integrate-recovery" })
                local row = task_reader.get_task(task_id)
                test.eq(row.status, "waiting_for_user",
                    "v25 mislabelled this as completed; ask_user is correct because partial work is in changeset and human can resume")
                test.is_true(row.status ~= "completed")
            end)

            it("test->implement cap=3 exhaustion pauses for user (runtime debugging needs human)", function()
                local task_id = make_task("Test cap exhaustion")
                local cap = must_cap(P.TEST, P.IMPLEMENT)
                seed_bounces(task_id, P.TEST, P.IMPLEMENT, cap.cap)
                flow.handle_exit(task_id, P.TEST, { status = S.BUGS, summary = "endpoints still red" })
                local row = task_reader.get_task(task_id)
                test.eq(row.status, "waiting_for_user")
            end)

            it("integrate->implement cap=3 exhaustion pauses for user (handler keeps failing)", function()
                local task_id = make_task("Integrate cap exhaustion")
                local cap = must_cap(P.INTEGRATE, P.IMPLEMENT)
                seed_bounces(task_id, P.INTEGRATE, P.IMPLEMENT, cap.cap)
                flow.handle_exit(task_id, P.INTEGRATE, { status = S.FAIL, summary = "handlers still red" })
                local row = task_reader.get_task(task_id)
                test.eq(row.status, "waiting_for_user")
            end)

            it("implement->design cap=3 exhaustion ABANDONS (agents say spec is infeasible)", function()
                local task_id = make_task("spec_wrong cap")
                local cap = must_cap(P.IMPLEMENT, P.DESIGN)
                seed_bounces(task_id, P.IMPLEMENT, P.DESIGN, cap.cap)
                flow.handle_exit(task_id, P.IMPLEMENT, { status = S.SPEC_WRONG, summary = "spec still wrong" })
                local row = task_reader.get_task(task_id)
                test.eq(row.status, "abandoned",
                    "implement->design cap is the only one that abandons — agents reporting design infeasibility, not ping-pong")
                test.is_true(row.status ~= "completed")
            end)

            it("BREAK-IT: phase NEVER lands on FINISH from a cap-exhausting bounce", function()
                -- Drive every capped edge to its limit and confirm none of them
                -- ever produces phase=FINISH or status=completed. The whole point
                -- of the v25 fix.
                local cases = {
                    { from = P.REVIEW,    to = P.IMPLEMENT, signal = S.BUGS,       desc = "review-bugs" },
                    { from = P.IMPLEMENT, to = P.REVIEW,    signal = S.PUSHED,     desc = "implement-push-loop" },
                    { from = P.TEST,      to = P.IMPLEMENT, signal = S.BUGS,       desc = "test-bugs" },
                    { from = P.INTEGRATE, to = P.IMPLEMENT, signal = S.FAIL,       desc = "integrate-fail" },
                }
                for _, c in ipairs(cases) do
                    local task_id = make_task("cap " .. c.desc)
                    local cap = must_cap(c.from, c.to)
                    seed_bounces(task_id, c.from, c.to, cap.cap)
                    flow.handle_exit(task_id, c.from, { status = c.signal, summary = c.desc .. " over cap" })
                    local row = task_reader.get_task(task_id)
                    test.is_true(row.phase ~= P.FINISH,
                        c.desc .. ": phase MUST NOT be FINISH on cap exhaustion; got " .. tostring(row.phase))
                    test.is_true(row.status ~= "completed",
                        c.desc .. ": status MUST NOT be 'completed' on cap exhaustion; got " .. tostring(row.status))
                end
            end)

            it("BREAK-IT: zero-bounce review-bugs is NOT cap-fired (regression: cap counts must be > 0 to fire)", function()
                local task_id = make_task("first review bounce")
                -- ZERO prior bounces seeded
                flow.handle_exit(task_id, P.REVIEW, { status = S.BUGS, summary = "first time" })
                local row = task_reader.get_task(task_id)
                test.eq(row.phase, P.IMPLEMENT,
                    "first review-bugs must route to implement, not fire the cap")
                test.is_true(row.status ~= "waiting_for_user",
                    "first bounce must NOT pause for user")
                test.is_true(row.status ~= "completed")
                test.is_true(row.status ~= "abandoned")
            end)

            it("BREAK-IT: a successful integrate transition counts toward implement->review (regression: only intended bounces should count)", function()
                -- Verify the cap counter only counts real bounce edges, not
                -- forward transitions. implement->review on staged should bump
                -- implement->review counter (intended). implement->review with
                -- a different signal (impossible per state machine) shouldn't.
                local task_id = make_task("count probe")
                seed_bounces(task_id, P.IMPLEMENT, P.REVIEW, 4)
                flow.handle_exit(task_id, P.IMPLEMENT,
                    { status = S.STAGED, summary = "5th push" })
                local row = task_reader.get_task(task_id)
                -- After 5 implement->review counts (4 seeded + 1 just fired)
                -- this hits cap=5; next implement-staged exit fires ask_user.
                -- But this exit lands BEFORE the cap (count after = 5, cap = 5).
                test.eq(row.phase, P.REVIEW,
                    "5th push lands at cap boundary but does not exceed; routes to review normally")
                seed_bounces(task_id, P.IMPLEMENT, P.REVIEW, 1) -- now 5 prior
                flow.handle_exit(task_id, P.IMPLEMENT,
                    { status = S.STAGED, summary = "6th push" })
                row = task_reader.get_task(task_id)
                test.eq(row.status, "waiting_for_user",
                    "6th push exceeds cap=5 and MUST ask_user")
            end)

            it("resets implement->review cap after successful integrate->test", function()
                local task_id = make_task("post-publish ui fix")
                local cap = must_cap(P.IMPLEMENT, P.REVIEW)
                seed_bounces(task_id, P.IMPLEMENT, P.REVIEW, cap.cap)
                seed_bounces(task_id, P.INTEGRATE, P.TEST, 1)

                flow.handle_exit(task_id, P.IMPLEMENT,
                    { status = S.STAGED, summary = "incremental UI fix after green integrate" })
                local row = task_reader.get_task(task_id)
                test.eq(row.phase, P.REVIEW,
                    "post-integrate fixes are a new retry segment and must be reviewable")
                test.is_true(row.status ~= "waiting_for_user",
                    "old pre-integrate implement->review attempts must not trip the post-test fix")
            end)

            it("forces abandoned once implement->design hits cap", function()
                local task_id = make_task("At spec-rework cap")
                local cap = must_cap(P.IMPLEMENT, P.DESIGN)
                seed_bounces(task_id, P.IMPLEMENT, P.DESIGN, cap.cap)
                flow.handle_exit(task_id, P.IMPLEMENT,
                    { status = S.SPEC_WRONG, summary = "spec still wrong" })
                local row = task_reader.get_task(task_id)
                test.eq(row.phase, P.ABANDONED, "phase should be abandoned")
                test.eq(row.status, "abandoned", "task should be abandoned")
            end)

            it("routes integrate->implement on the first fail (cap=3)", function()
                local task_id = make_task("First integrate fail")
                task_writer.for_task(task_id):update_task({ phase = P.INTEGRATE, status = "active" }):execute()
                flow.handle_exit(task_id, P.INTEGRATE,
                    { status = S.FAIL, summary = "handler bug, try once" })
                local row = task_reader.get_task(task_id)
                test.eq(row.phase, P.IMPLEMENT, "first integrate fail should bounce to implement")
                test.is_true(row.status ~= "waiting_for_user",
                    "first bounce must not trip ask_user")
            end)

            it("pauses for user once integrate->implement hits cap=3", function()
                -- Regression: without this cap, integrate that keeps failing
                -- loops implement→review→integrate→implement indefinitely.
                -- With it, the task halts in waiting_for_user so the operator
                -- can guide the agent instead of burning tokens forever.
                local task_id = make_task("At integrate cap")
                task_writer.for_task(task_id):update_task({ phase = P.INTEGRATE, status = "active" }):execute()
                local cap = must_cap(P.INTEGRATE, P.IMPLEMENT)
                test.not_nil(cap, "integrate->implement must have a bounce cap configured")
                test.eq(cap.terminal, "ask_user",
                    "integrate->implement cap must terminate with ask_user, not a phase")
                seed_bounces(task_id, P.INTEGRATE, P.IMPLEMENT, cap.cap)

                flow.handle_exit(task_id, P.INTEGRATE,
                    { status = S.FAIL, summary = "third integrate fail — same handler" })

                local row = task_reader.get_task(task_id)
                test.eq(row.status, "waiting_for_user",
                    "cap-hit must pause task for user input, not force-finish")
                test.eq(row.phase, P.IMPLEMENT,
                    "resume point must be the routed to_phase (implement) so user's answer flows into the next implement context")

                -- ask_user node must be recorded so /tasks API surfaces the question.
                local db = must_db(task_consts.DATABASE.RESOURCE_ID)
                local rows = db:query(
                    "SELECT content FROM keeper_task_nodes WHERE task_id=? AND type='ask_user' ORDER BY seq DESC LIMIT 1",
                    { task_id })
                db:release()
                test.eq(#rows, 1, "ask_user node must be recorded")
                test.is_true(rows[1].content:find("bounced", 1, true) ~= nil,
                    "ask_user content must explain the cap was hit")
            end)

            it("review cannot bounce to design — spec_wrong signal rejected (regression)", function()
                local task_id = make_task("Review spec_wrong rejected")
                -- The state machine no longer routes review -> design on any signal.
                -- flow.handle_exit on an invalid signal returns the task unchanged in REVIEW.
                local ok, err = pcall(function()
                    flow.handle_exit(task_id, P.REVIEW,
                        { status = S.SPEC_WRONG, summary = "spec wrong" })
                end)
                -- Either the call errors or the task stays in REVIEW — either way, the
                -- task must NOT end up in DESIGN.
                local row = task_reader.get_task(task_id)
                test.is_true(row.phase ~= P.DESIGN,
                    "review must never route to design — spec_wrong is not a valid review exit")
            end)

            it("recovery implement spec_wrong pauses instead of starting a new design+plan loop", function()
                local task_id = make_task("Recovery spec_wrong guard")
                seed_bounces(task_id, P.INTEGRATE, P.IMPLEMENT, 1)
                task_writer.for_task(task_id):update_task({ phase = P.IMPLEMENT, status = "active" }):execute()

                flow.handle_exit(task_id, P.IMPLEMENT,
                    { status = S.SPEC_WRONG, summary = "frontend architecture seems wrong" })

                local row = task_reader.get_task(task_id)
                test.eq(row.status, "waiting_for_user",
                    "after integrate/test/review recovery, spec_wrong must pause for the user")
                test.eq(row.phase, P.IMPLEMENT,
                    "resume point stays implement; redesign is not automatic recovery")
                test.is_true(row.phase ~= P.DESIGN,
                    "regression: this used to burn a full design+plan loop after integrate failure")

                local db = must_db(task_consts.DATABASE.RESOURCE_ID)
                local rows = db:query(
                    "SELECT content FROM keeper_task_nodes WHERE task_id=? AND type='ask_user' ORDER BY seq DESC LIMIT 1",
                    { task_id })
                db:release()
                test.eq(#rows, 1, "ask_user node must be recorded")
                test.is_true(rows[1].content:find("recovering from integrate -> implement", 1, true) ~= nil,
                    "question should identify the guarded recovery edge")
            end)

            it("first-pass implement spec_wrong can still return to design", function()
                local task_id = make_task("First pass spec_wrong still design")
                task_writer.for_task(task_id):update_task({ phase = P.IMPLEMENT, status = "active" }):execute()

                flow.handle_exit(task_id, P.IMPLEMENT,
                    { status = S.SPEC_WRONG, summary = "plan target cannot exist" })

                local row = task_reader.get_task(task_id)
                test.eq(row.phase, P.DESIGN,
                    "the guard is only for recovery implement; genuine first-pass infeasibility still redesigns")
                test.is_true(row.status ~= "waiting_for_user",
                    "first-pass spec_wrong should not be converted to ask_user")
            end)
        end)

        describe("ask_user", function()
            it("keeps task in current phase and sets waiting_for_user", function()
                local task_id = make_task("Ask user pauses cycle")
                flow.handle_exit(task_id, P.DESIGN,
                    { status = S.ASK_USER, summary = "please clarify X" })
                local row = task_reader.get_task(task_id)
                test.eq(row.status, "waiting_for_user", "task should pause waiting for user")
            end)
        end)

        describe("uncapped edges", function()
            it("routes design->plan without touching bounce cap", function()
                local task_id = make_task("Clean approve")
                flow.handle_exit(task_id, P.DESIGN,
                    { status = S.APPROVED, summary = "spec ready" })
                local row = task_reader.get_task(task_id)
                test.eq(row.phase, P.PLAN, "design->plan should advance on approved")
            end)

            it("routes plan->implement on planned", function()
                local task_id = make_task("Plan advance")
                task_writer.for_task(task_id):update_task({ phase = P.PLAN, status = "active" }):execute()
                flow.handle_exit(task_id, P.PLAN,
                    { status = S.PLANNED, summary = "3 steps" })
                local row = task_reader.get_task(task_id)
                test.eq(row.phase, P.IMPLEMENT, "plan->implement should advance on planned")
            end)
        end)

        -- Zero-edit detection moved to keeper.task.tools:finish.verify when
        -- implement-was-noop logic left flow.handle_exit. Coverage lives in
        -- keeper.task.tools:finish_test against real changeset counts.

        describe("phase-spawn baseline", function()
            it("records a phase_spawn baseline on the active changeset at spawn", function()
                local task_id = make_task("Phase spawn baseline")
                local ws      = make_changeset_for(task_id)

                flow.spawn_phase(task_id, P.DESIGN, { detached = true })

                local latest, err = changeset_repo.latest_baseline(ws.changeset_id)
                test.is_nil(err, "latest_baseline should succeed")
                test.eq(latest.reason, changeset_consts.BASELINE_REASONS.PHASE_SPAWN,
                    "latest baseline should be a phase_spawn row")
            end)
        end)

        describe("serial queue blocker predicate", function()
            it("does not let queued spec tasks block each other", function()
                local queued_a = {
                    task_id = "queued-a",
                    status  = task_consts.STATUSES.ACTIVE,
                    phase   = task_consts.PHASES.SPEC,
                }
                local queued_b = {
                    task_id = "queued-b",
                    status  = task_consts.STATUSES.ACTIVE,
                    phase   = task_consts.PHASES.SPEC,
                }
                local running = {
                    task_id = "running",
                    status  = task_consts.STATUSES.ACTIVE,
                    phase   = P.DESIGN,
                }

                test.is_false(flow._is_blocking_task(queued_a, queued_b.task_id),
                    "phase=spec rows are queued work and must not block queue promotion")
                test.is_false(flow._is_blocking_task(queued_b, queued_a.task_id))
                test.is_true(flow._is_blocking_task(running, queued_a.task_id),
                    "non-spec active phases still block the serial queue")
            end)

            it("only promotes active spec tasks from the serial queue", function()
                local task_id = make_task("Paused spec task must not auto-start")
                task_writer.for_task(task_id)
                    :update_task({ phase = task_consts.PHASES.SPEC, status = "waiting_for_user" })
                    :execute()

                local started = flow._pump_queue("test.flow")
                test.is_nil(started, "waiting_for_user spec rows are not queued work")

                local row = task_reader.get_task(task_id)
                test.eq(row.phase, task_consts.PHASES.SPEC)
                test.eq(row.status, "waiting_for_user")
                test.is_nil(changeset_repo.active_for_task(task_id),
                    "queue pump must not open a changeset for non-active spec rows")
            end)
        end)

        describe("phase spawner stale requests", function()
            it("classifies missing task lookups as skipped stale spawn requests", function()
                test.is_true(phase_spawner._is_missing_task_error(task_consts.ERRORS.NOT_FOUND))
                test.is_true(phase_spawner._is_missing_task_error("task not found: task-1"))
                test.is_false(phase_spawner._is_missing_task_error("db error: locked"))
            end)
        end)

        describe("auto-fork when a phase needs a live workspace", function()
            local function drop_changeset(cs_id)
                local cdb = sql.get(changeset_consts.DATABASE.RESOURCE_ID)
                if not cdb then return end
                cdb:execute(
                    "UPDATE keeper_changesets SET state = ? WHERE changeset_id = ?",
                    { changeset_consts.STATES.DROPPED, cs_id }
                )
                cdb:release()
            end

            it("opens a fresh changeset when implement spawns with no live workspace", function()
                local task_id = make_task("Auto-fork on implement re-entry")
                local ws      = make_changeset_for(task_id)
                drop_changeset(ws.changeset_id)

                test.is_nil(changeset_repo.active_for_task(task_id),
                    "pre-condition: no active changeset")

                flow.spawn_phase(task_id, P.IMPLEMENT, { detached = true, actor_id = "test.flow" })

                local fresh = changeset_repo.active_for_task(task_id)
                test.not_nil(fresh, "fresh changeset should be auto-forked")
                test.is_true(fresh.changeset_id ~= ws.changeset_id,
                    "fresh changeset must have a different id than the dropped one")
                test.eq(fresh.task_id, task_id, "fresh changeset should be tied to the task")
                table.insert(created_changesets, fresh.changeset_id)
            end)

            it("opens a fresh changeset when plan spawns with no live workspace", function()
                local task_id = make_task("Auto-fork on plan re-entry")
                local ws      = make_changeset_for(task_id)
                drop_changeset(ws.changeset_id)

                task_writer.for_task(task_id):update_task({ phase = P.PLAN, status = "active" }):execute()
                flow.spawn_phase(task_id, P.PLAN, { detached = true, actor_id = "test.flow" })

                local fresh = changeset_repo.active_for_task(task_id)
                test.not_nil(fresh, "plan phase should recover a fresh workspace")
                test.is_true(fresh.changeset_id ~= ws.changeset_id,
                    "fresh changeset must have a different id than the dropped one")
                test.eq(fresh.task_id, task_id)
                table.insert(created_changesets, fresh.changeset_id)
            end)

            it("does not fork when a live changeset already exists", function()
                local task_id = make_task("No fork when live changeset present")
                local ws      = make_changeset_for(task_id)

                flow.spawn_phase(task_id, P.IMPLEMENT, { detached = true, actor_id = "test.flow" })

                local active = changeset_repo.active_for_task(task_id)
                test.not_nil(active, "changeset should remain")
                test.eq(active.changeset_id, ws.changeset_id,
                    "existing changeset should be reused; no fork")
            end)
        end)

        describe("phase runner failure sink", function()
            local function wait_for_flow(dataflow_id)
                local db = must_db(DATAFLOW_DB)
                local status = nil
                for _ = 1, 40 do
                    local rows = db:query("SELECT status FROM dataflows WHERE dataflow_id = ?", { dataflow_id }) or {}
                    status = rows[1] and rows[1].status
                    if status == "completed" or status == "failed" then break end
                    time.sleep("50ms")
                end
                db:release()
                return status
            end

            it("does not schedule the failure sink as a root node on successful phase flow", function()
                local task_id = make_task("Failure sink waits for error input")
                task_writer.for_task(task_id):update_task({ phase = P.TEST, status = "active" }):execute()

                local phase_scope = { task_id = task_id, phase = P.TEST }
                local f = dataflow_flow.create()
                    :with_title("phase failure sink input contract")
                    :with_metadata({
                        type    = "task_phase_failure_regression",
                        task_id = task_id,
                        phase   = P.TEST,
                    })
                    :with_input({ message = "ok", delay_ms = 0 })
                    :func("userspace.dataflow.node.func:test_func", {
                        metadata = { title = "Successful Phase Runner" },
                    })
                    :as("runner")
                    :to("@success")
                    :error_to("phase_failure", "error")

                f:func("keeper.task.phases:phase_failure", {
                    inputs = { required = { "error" } },
                    input_transform = { error = "inputs.error" },
                    context = phase_scope,
                    metadata = { title = "Phase Failure Handler", icon = "tabler:alert-triangle" },
                })
                    :as("phase_failure")
                    :to("@success")

                local dataflow_id, err = f:start({ detached = true })
                test.is_nil(err)
                test.not_nil(dataflow_id)
                table.insert(created_dataflows, dataflow_id)

                local status = wait_for_flow(dataflow_id)
                test.eq(status, "completed")

                local db = must_db(DATAFLOW_DB)
                local failed = db:query([[
                    SELECT COUNT(*) AS c
                    FROM dataflow_nodes
                    WHERE dataflow_id = ?
                      AND metadata LIKE '%Phase Failure Handler%'
                      AND status = 'failed'
                      AND metadata LIKE '%NO_INPUT_DATA%'
                ]], { dataflow_id }) or {}
                db:release()

                test.eq(tonumber(failed[1] and failed[1].c or 0), 0,
                    "phase failure handler must wait for an error input; it must not run as a root with NO_INPUT_DATA")
            end)

            it("defers next phase spawn when finish runs inside a dataflow", function()
                local task_id = make_task("Nested finish defers spawn")
                make_changeset_for(task_id)
                -- Keep the row inactive so the service receives the request
                -- but skips the actual planner spawn; this pins the nested
                -- start regression without launching an LLM phase in tests.
                task_writer.for_task(task_id):update_task({ phase = P.DESIGN, status = "waiting_for_user" }):execute()

                local f = dataflow_flow.create()
                    :with_title("nested finish defers phase spawn")
                    :with_metadata({
                        type    = "task_phase_nested_finish_regression",
                        task_id = task_id,
                    })
                    :with_input({
                        task_id = task_id,
                        phase   = P.DESIGN,
                        result  = {
                            status  = S.APPROVED,
                            summary = "nested design approved",
                        },
                    })
                    :func("keeper.task.phases:nested_exit_probe", {
                        metadata = { title = "Nested finish probe" },
                    })
                    :as("probe")
                    :to("@success")

                local dataflow_id, err = f:start({ detached = true })
                test.is_nil(err)
                test.not_nil(dataflow_id)
                table.insert(created_dataflows, dataflow_id)

                local status = wait_for_flow(dataflow_id)
                test.eq(status, "completed",
                    "finish must not call FlowBuilder:start from nested context")

                local task_row = task_reader.get_task(task_id)
                test.eq(task_row.phase, P.PLAN)
                test.eq(task_row.status, "waiting_for_user")

                local requested = nodes_reader.latest_of_type(task_id, "phase_event", {
                    discriminator = "phase_spawn_requested",
                })
                test.not_nil(requested, "next phase spawn should be handed to the task service")
            end)

            it("pauses instead of leaving an active task when a phase dataflow fails before finish", function()
                local task_id = make_task("Phase runner failed before finish")
                make_changeset_for(task_id)
                task_writer.for_task(task_id):update_task({ phase = P.PLAN, status = "active" }):execute()

                local started = nodes_writer.record({
                    task_id       = task_id,
                    type          = "phase_started",
                    discriminator = P.PLAN,
                    title         = "Started plan phase",
                    status        = "running",
                    visibility    = "user",
                    metadata      = { phase = P.PLAN },
                })
                test.not_nil(started)

                local out, err = flow.handle_phase_failure(task_id, P.PLAN, { error = "planner exploded" })
                test.is_nil(err)
                test.is_true(out.paused)

                local task_row = task_reader.get_task(task_id)
                test.eq(task_row.phase, P.PLAN)
                test.eq(task_row.status, "waiting_for_user")

                local db = must_db(task_consts.DATABASE.RESOURCE_ID)
                local phase_rows = db:query(
                    "SELECT status, error_message FROM keeper_task_nodes WHERE node_id = ?",
                    { started.node_id }
                )
                local asks = db:query([[
                    SELECT content FROM keeper_task_nodes
                    WHERE task_id = ? AND type = 'ask_user' AND status = 'active'
                    ORDER BY seq DESC LIMIT 1
                ]], { task_id })
                db:release()

                test.eq(phase_rows[1].status, "failed")
                test.eq(phase_rows[1].error_message, "planner exploded")
                test.is_true((asks[1].content or ""):find("planner exploded", 1, true) ~= nil,
                    "ask_user content should carry the phase failure")
            end)
        end)

        describe("ask_user revert (implement phase)", function()
            local function seed_overlay_entry(branch, id, kind, created_at)
                local db = must_db(task_consts.DATABASE.RESOURCE_ID)
                db:execute([[
                    INSERT INTO keeper_overlay_entries
                        (id, branch, kind, deleted, created_at, updated_at)
                    VALUES (?, ?, ?, 0, ?, ?)
                ]], { id, branch, kind, created_at, created_at })
                db:release()
            end

            local function count_entries(branch)
                local db = must_db(task_consts.DATABASE.RESOURCE_ID)
                local rows = db:query(
                    "SELECT COUNT(*) AS n FROM keeper_overlay_entries WHERE branch = ?",
                    { branch }
                )
                db:release()
                return (rows and rows[1] and tonumber(rows[1].n)) or 0
            end

            it("deletes post-baseline overlay entries on implement ask_user", function()
                local task_id = make_task("Implement ask_user revert")
                local ws      = make_changeset_for(task_id)
                record_baseline(task_id, ws.changeset_id, 0)

                -- Seed one entry that existed *before* the phase-spawn baseline.
                seed_overlay_entry(ws.state_branch, "kept:pre", "function.lua", "2000-01-01T00:00:00Z")

                -- Record the phase-spawn baseline now (simulates implement spawn).
                changeset_repo.record_baseline({
                    changeset_id     = ws.changeset_id,
                    registry_version = ws.baseline_version,
                    fs_tree_hash     = ws.baseline_fs_hash,
                    reason           = changeset_consts.BASELINE_REASONS.PHASE_SPAWN,
                })

                -- Simulate an entry created *during* the phase (after baseline).
                seed_overlay_entry(ws.state_branch, "phase:new", "function.lua", "2099-12-31T23:59:59Z")

                test.eq(count_entries(ws.state_branch), 2,
                    "pre-condition: both pre and in-phase entries present")

                flow.handle_exit(task_id, P.IMPLEMENT,
                    { status = S.ASK_USER, summary = "need clarification" })

                test.eq(count_entries(ws.state_branch), 1,
                    "in-phase overlay entry should be reverted; pre-phase entry retained")

                local row = task_reader.get_task(task_id)
                test.eq(row.status, "waiting_for_user",
                    "task should still be paused for user input")
            end)

            it("leaves composition alone when design phase asks user", function()
                local task_id = make_task("Design ask_user no revert")
                local ws      = make_changeset_for(task_id)

                changeset_repo.record_baseline({
                    changeset_id     = ws.changeset_id,
                    registry_version = ws.baseline_version,
                    fs_tree_hash     = ws.baseline_fs_hash,
                    reason           = changeset_consts.BASELINE_REASONS.PHASE_SPAWN,
                })

                seed_overlay_entry(ws.state_branch, "design:untouched", "function.lua",
                    "2099-12-31T23:59:59Z")
                test.eq(count_entries(ws.state_branch), 1)

                flow.handle_exit(task_id, P.DESIGN,
                    { status = S.ASK_USER, summary = "clarify spec" })

                test.eq(count_entries(ws.state_branch), 1,
                    "design ask_user must not revert composition — design has no edit tools")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
