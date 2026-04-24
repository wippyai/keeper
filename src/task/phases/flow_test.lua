local test = require("test")
local uuid = require("uuid")
local flow = require("lifecycle")
local state_machine = require("state_machine")
local task_writer = require("task_writer")
local task_reader = require("task_reader")
local nodes_writer = require("nodes_writer")
local changeset_repo = require("changeset_repo")
local changeset_consts = require("changeset_consts")
local sql = require("sql")
local task_consts = require("task_consts")

local function define_tests()
    describe("Phase flow advance", function()
        local P = state_machine.PHASES
        local S = state_machine.SIGNALS
        local created_ids = {}
        local created_changesets = {}

        after_all(function()
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
                for _, id in ipairs(created_changesets) do
                    cdb:execute("DELETE FROM keeper_changeset_changes WHERE changeset_id = ?", { id })
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

            it("forces finish once review->implement hits cap=1", function()
                local task_id = make_task("At review cap")
                local cap = state_machine.bounce_cap(P.REVIEW, P.IMPLEMENT)
                seed_bounces(task_id, P.REVIEW, P.IMPLEMENT, cap.cap)
                flow.handle_exit(task_id, P.REVIEW, { status = S.BUGS, summary = "still red" })
                local row = task_reader.get_task(task_id)
                test.eq(row.phase, P.FINISH,
                    "second review=bugs must force-finish (cap=1 regression: no indefinite review loops)")
                test.eq(row.status, "completed", "task should be completed")
            end)

            it("forces abandoned once implement->design hits cap", function()
                local task_id = make_task("At spec-rework cap")
                local cap = state_machine.bounce_cap(P.IMPLEMENT, P.DESIGN)
                seed_bounces(task_id, P.IMPLEMENT, P.DESIGN, cap.cap)
                flow.handle_exit(task_id, P.IMPLEMENT,
                    { status = S.SPEC_WRONG, summary = "spec still wrong" })
                local row = task_reader.get_task(task_id)
                test.eq(row.phase, P.ABANDONED, "phase should be abandoned")
                test.eq(row.status, "abandoned", "task should be abandoned")
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

        describe("auto-fork on implement re-spawn", function()
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

        describe("ask_user revert (implement phase)", function()
            local function seed_overlay_entry(branch, id, kind, created_at)
                local db = sql.get(task_consts.DATABASE.RESOURCE_ID)
                db:execute([[
                    INSERT INTO keeper_overlay_entries
                        (id, branch, kind, deleted, created_at, updated_at)
                    VALUES (?, ?, ?, 0, ?, ?)
                ]], { id, branch, kind, created_at, created_at })
                db:release()
            end

            local function count_entries(branch)
                local db = sql.get(task_consts.DATABASE.RESOURCE_ID)
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
