local finish = require("finish")
local changeset_repo = require("changeset_repo")
local changeset_consts = require("changeset_consts")
local nodes_reader = require("nodes_reader")
local state_machine = require("state_machine")
local task_consts = require("task_consts")
local task_reader = require("task_reader")
local task_writer = require("task_writer")
local test = require("test")
local uuid = require("uuid")
local sql = require("sql")

local P = state_machine.PHASES
local S = state_machine.SIGNALS
local TASK_DB = "keeper.state:db"

-- Tracked IDs are purged in after_all so finish_test doesn't leave zombie
-- tasks in keeper_tasks / zombie rows in keeper_changesets that later block
-- start_cycle's "serial queue" guard.
local created_task_ids = {}
local created_changeset_ids = {}

local function must_db()
    local db, err = sql.get(TASK_DB)
    if err then error("db: " .. tostring(err)) end
    if not db then error("db unavailable") end
    return db
end

local function fresh_task(phase)
    local id = uuid.v7()
    local res, err = task_writer.create_task({
        task_id = id,
        title   = "finish_test " .. id:sub(1, 8),
    }):execute()
    if err then error("create_task: " .. tostring(err)) end
    task_writer.for_task(res.task_id):update_task({
        phase  = phase,
        status = "active",
    }):execute()
    table.insert(created_task_ids, res.task_id)
    return res.task_id
end

local function fresh_changeset(task_id)
    local cs_id = "fintest-" .. uuid.v7()
    local ws, err = changeset_repo.create_changeset({
        changeset_id     = cs_id,
        task_id          = task_id,
        title            = "finish_test cs",
        kind             = changeset_consts.KINDS.SESSION,
        actor_id         = "test.finish",
        state_branch     = changeset_consts.branch_for(cs_id),
        scratch_fs_path  = cs_id .. "/",
        baseline_version = "0",
        baseline_fs_hash = "",
    })
    if err then error(err) end
    table.insert(created_changeset_ids, ws.changeset_id)
    return ws
end

local function purge()
    local db = must_db()
    for _, id in ipairs(created_task_ids) do
        db:execute("DELETE FROM keeper_task_nodes WHERE task_id = ?", { id })
        db:execute("DELETE FROM keeper_tasks WHERE task_id = ?", { id })
        local rows = db:query(
            "SELECT changeset_id FROM keeper_changesets WHERE task_id = ?",
            { id }
        ) or {}
        for _, row in ipairs(rows) do
            table.insert(created_changeset_ids, row.changeset_id)
        end
    end
    for _, cs_id in ipairs(created_changeset_ids) do
        db:execute("DELETE FROM keeper_changeset_changes WHERE changeset_id = ?", { cs_id })
        db:execute("DELETE FROM keeper_changeset_fs_content WHERE changeset_id = ?", { cs_id })
        db:execute("DELETE FROM keeper_changeset_fs_deletes WHERE changeset_id = ?", { cs_id })
        db:execute("DELETE FROM keeper_changeset_baselines WHERE changeset_id = ?", { cs_id })
        db:execute("DELETE FROM keeper_changesets WHERE changeset_id = ?", { cs_id })
    end
    db:release()
    created_task_ids = {}
    created_changeset_ids = {}
end

local function seed_change(changeset_id)
    changeset_repo.record_change({
        changeset_id = changeset_id,
        category     = changeset_consts.CATEGORIES.REGISTRY,
        op           = changeset_consts.OPS.CREATE,
        target       = "test.finish:seeded",
        source       = changeset_consts.SOURCES.MATERIALIZED,
        status       = changeset_consts.CHANGE_STATUSES.PENDING,
    })
end

local function define_tests()
    describe("keeper.task.tools:finish", function()

        after_all(purge)

        describe("signal validation", function()
            it("rejects empty signal", function()
                local id = fresh_task(P.DESIGN)
                local _, err = finish.handle(id, P.DESIGN, { status = "", summary = "x" })
                test.not_nil(err)
                test.is_true(err:find("signal.+required") ~= nil)
            end)

            it("rejects nil result", function()
                local id = fresh_task(P.DESIGN)
                local _, err = finish.handle(id, P.DESIGN, nil)
                test.not_nil(err)
                test.is_true(err:find("result table required") ~= nil)
            end)

            it("rejects signal not in the phase's allowed set", function()
                local id = fresh_task(P.REVIEW)
                local _, err = finish.handle(id, P.REVIEW, { status = "spec_wrong", summary = "x" })
                test.not_nil(err)
                test.is_true(err:find("not allowed for phase 'review'") ~= nil,
                    "review must not accept spec_wrong; err was: " .. tostring(err))
            end)

            it("rejects signal for unknown phase", function()
                local id = fresh_task(P.DESIGN)
                local _, err = finish.handle(id, "bogus_phase", { status = "approved", summary = "x" })
                test.not_nil(err)
                test.is_true(err:find("invalid phase") ~= nil)
            end)

            it("rejects missing task_id", function()
                local _, err = finish.handle(nil, P.DESIGN, { status = "approved", summary = "x" })
                test.not_nil(err)
                test.is_true(err:find("task_id missing") ~= nil)
            end)
        end)

        describe("happy path — emits phase_exited via flow.advance", function()
            it("design->abandoned closes the task and emits phase_exited node", function()
                local id = fresh_task(P.DESIGN)
                finish.handle(id, P.DESIGN, { status = "abandoned", summary = "not feasible" })

                local exited = nodes_reader.latest_of_type(id, "phase_exited")
                test.not_nil(exited, "expected phase_exited node after finish")
                test.eq(exited.discriminator, P.DESIGN)
                test.eq(exited.status, "passed")

                local transition = nodes_reader.latest_of_type(id, "phase_transition")
                test.not_nil(transition, "expected phase_transition node")
                test.eq(transition.discriminator, P.DESIGN .. "->" .. P.ABANDONED)
            end)

            it("ask_user is a valid signal for every phase (self-loop)", function()
                for _, phase in ipairs({ P.DESIGN, P.IMPLEMENT, P.REVIEW }) do
                    local id = fresh_task(phase)
                    local _, err = finish.handle(id, phase, { status = "ask_user", summary = "q?" })
                    test.is_nil(err, "ask_user must be accepted on " .. phase .. " (got err: " .. tostring(err) .. ")")
                end
            end)
        end)

        describe("verification — implement:staged zero-edit", function()
            it("rewrites staged to stuck when changeset has no changes and pauses for user", function()
                local id = fresh_task(P.IMPLEMENT)
                fresh_changeset(id)

                finish.handle(id, P.IMPLEMENT, { status = S.STAGED, summary = "claimed done" })

                local row = task_reader.get_task(id)
                test.eq(row.phase, P.IMPLEMENT,
                    "zero-edit staged is rewritten to stuck → implement pauses for user (PLAN.md §Step 4: implement.stuck→ask_user)")
                test.eq(row.status, "waiting_for_user",
                    "stuck must park the task in waiting_for_user, not auto-advance")

                local override = nodes_reader.latest_of_type(id, "override")
                test.not_nil(override, "verification rewrite must emit an override node")
                test.eq(override.discriminator, S.STAGED)
                test.eq(override.metadata.new_signal, S.STUCK)

                local ask = nodes_reader.latest_of_type(id, "ask_user", { status = "active" })
                test.not_nil(ask, "stuck must record an ask_user node for the UI banner")
            end)

            it("completes zero-edit staged recovery after a prior merged changeset", function()
                local id = fresh_task(P.IMPLEMENT)
                local merged = fresh_changeset(id)
                changeset_repo.update_state(merged.changeset_id, changeset_consts.STATES.MERGED, "test")
                fresh_changeset(id)

                finish.handle(id, P.IMPLEMENT, { status = S.STAGED, summary = "nothing left to change" })

                local row = task_reader.get_task(id)
                test.eq(row.status, "completed",
                    "post-merge zero-edit recovery must finish instead of entering an empty review/integrate loop")
                test.eq(row.phase, P.FINISH)

                local override = nodes_reader.latest_of_type(id, "override")
                test.not_nil(override, "verification rewrite must emit an override node")
                test.eq(override.metadata.new_signal, S.ALREADY_DONE)
            end)

            it("keeps staged routing when changeset has ≥1 recorded change", function()
                local id = fresh_task(P.IMPLEMENT)
                local ws = fresh_changeset(id)
                seed_change(ws.changeset_id)

                finish.handle(id, P.IMPLEMENT, { status = S.STAGED, summary = "real change" })

                local row = task_reader.get_task(id)
                test.eq(row.phase, P.REVIEW,
                    "staged with real changes must advance to review without override")

                local override = nodes_reader.latest_of_type(id, "override")
                test.is_nil(override,
                    "no override node expected when verification trusts the signal")
            end)

            it("pushed signal gets the same zero-edit rewrite as staged", function()
                local id = fresh_task(P.IMPLEMENT)
                fresh_changeset(id)

                finish.handle(id, P.IMPLEMENT, { status = S.PUSHED, summary = "claimed done" })

                local row = task_reader.get_task(id)
                test.eq(row.phase, P.IMPLEMENT,
                    "legacy pushed alias triggers the same stuck-pause verification")
                test.eq(row.status, "waiting_for_user")
            end)

            it("rewrites implement already_done with zero changes and no merge to stuck", function()
                local id = fresh_task(P.IMPLEMENT)
                fresh_changeset(id)

                finish.handle(id, P.IMPLEMENT, { status = S.ALREADY_DONE, summary = "already exists" })

                local row = task_reader.get_task(id)
                test.eq(row.phase, P.IMPLEMENT)
                test.eq(row.status, "waiting_for_user",
                    "implement cannot close a task as already_done without either edits or a prior merge")

                local override = nodes_reader.latest_of_type(id, "override")
                test.not_nil(override)
                test.eq(override.metadata.new_signal, S.STUCK)
            end)

            it("routes implement already_done with active edits to review", function()
                local id = fresh_task(P.IMPLEMENT)
                local ws = fresh_changeset(id)
                seed_change(ws.changeset_id)

                finish.handle(id, P.IMPLEMENT, { status = S.ALREADY_DONE, summary = "overlay already satisfies spec" })

                local row = task_reader.get_task(id)
                test.eq(row.status, "active")
                test.eq(row.phase, P.REVIEW,
                    "already_done must not hide active unmerged changes")

                local guard = nodes_reader.latest_of_type(id, "phase_event",
                    { discriminator = "already_done_unmerged_guard" })
                test.not_nil(guard, "guard should leave an auditable node")
            end)
        end)

        describe("verification — review:approved requires non-rejected changeset", function()
            it("rewrites approved to bugs when active changeset is rejected", function()
                local id = fresh_task(P.REVIEW)
                local ws = fresh_changeset(id)
                changeset_repo.update_state(ws.changeset_id, "rejected", "test")

                finish.handle(id, P.REVIEW, { status = S.APPROVED, summary = "lgtm" })

                local row = task_reader.get_task(id)
                test.eq(row.phase, P.IMPLEMENT,
                    "approved on rejected changeset must bounce back to implement")

                local override = nodes_reader.latest_of_type(id, "override")
                test.not_nil(override)
                test.eq(override.metadata.new_signal, S.BUGS)
            end)
        end)

        describe("verification — already_done must not hide unmerged work", function()
            it("routes design already_done to review when the task has unmerged changes", function()
                local id = fresh_task(P.DESIGN)
                local ws = fresh_changeset(id)
                seed_change(ws.changeset_id)

                finish.handle(id, P.DESIGN, { status = S.ALREADY_DONE, summary = "overlay already matches spec" })

                local row = task_reader.get_task(id)
                test.eq(row.status, "active",
                    "already_done with unmerged overlay changes must not close the task as completed")
                test.eq(row.phase, P.REVIEW,
                    "unmerged overlay changes still need review/integrate")

                local transition = nodes_reader.latest_of_type(id, "phase_transition")
                test.not_nil(transition)
                test.eq(transition.discriminator, P.DESIGN .. "->" .. P.REVIEW)
                test.eq(transition.metadata.signal, S.ALREADY_DONE)

                local guard = nodes_reader.latest_of_type(id, "phase_event",
                    { discriminator = "already_done_unmerged_guard" })
                test.not_nil(guard, "guard should leave an auditable node")
            end)

            it("routes plan already_done to review when the task has unmerged changes", function()
                local id = fresh_task(P.PLAN)
                local ws = fresh_changeset(id)
                seed_change(ws.changeset_id)

                finish.handle(id, P.PLAN, { status = S.ALREADY_DONE, summary = "planned work already staged" })

                local row = task_reader.get_task(id)
                test.eq(row.status, "active")
                test.eq(row.phase, P.REVIEW)
            end)
        end)

    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
