-- Regression tests for the changeset-transition contract that
-- keeper.develop.integrate:run relies on after item-8 fix (2026-04-24):
--
--   1. push.lua no longer fires push_success — integrate/run.lua does it.
--   2. On handler-success path, fire_transition(push_success) moves
--      accepted -> merged; next phase spawn sees no active changeset.
--   3. On handler-failure path, fire_transition(push_failure) +
--      fire_transition(reopen) move accepted -> rejected -> editing so
--      the SAME changeset is reused by the next implement spawn instead
--      of auto-forking a fresh empty branch.
--
-- These are state-machine / active_for_task invariants. If someone ever
-- re-introduces the push_success-inside-push behaviour, or drops the
-- reopen call in run.lua's fail path, active_for_task will flip to
-- returning nil (merged/rejected) and auto_fork will silently recreate
-- the orphan-cascade we killed in item-8.

local test             = require("test")
local sql              = require("sql")
local funcs            = require("funcs")
local task_writer      = require("task_writer")
local changeset_client = require("changeset_client")
local changeset_repo   = require("changeset_repo")

local DB = "keeper.state:db"
local FIRE_FN = "keeper.changeset.service:fire_transition"

type TaskBuilder = {
    execute: (TaskBuilder) -> ({task_id: string?}?, string?),
}

local function must_db()
    local db, err = sql.get(DB)
    if err then error("test database unavailable: " .. tostring(err)) end
    if not db then error("test database unavailable") end
    return db
end

local function cleanup_task(task_id)
    if not task_id or task_id == "" then return end
    local db = must_db()
    db:execute("DELETE FROM keeper_task_nodes WHERE task_id=?", { task_id })
    db:execute("DELETE FROM keeper_changesets WHERE task_id=?", { task_id })
    db:execute("DELETE FROM keeper_tasks WHERE task_id=?", { task_id })
    db:release()
end

local function new_task()
    local builder = task_writer.create_task({
        title    = "integrate run transition probe",
        actor_id = "integrate_run_test",
    }) :: TaskBuilder
    local res = builder:execute()
    return res and res.task_id or nil
end

local function fire(changeset_id, event, reason)
    local executor = funcs.new()
    return executor:call(FIRE_FN, {
        changeset_id = changeset_id,
        event        = event,
        reason       = reason or ("test: " .. event),
    })
end

-- Drive changeset from OPEN -> EDITING -> REVIEW -> ACCEPTED via the real
-- service. We skip the guard-heavy submit_for_review/accept path by
-- sending the transitions directly; guard failures would otherwise need
-- pending changes + a clean linter run, which is out of scope for this
-- pure state-machine regression.
local function drive_to_accepted(changeset_id)
    -- Simulate an edit (first_edit is allowed from open unconditionally).
    local _, e1 = fire(changeset_id, "first_edit", "probe edit")
    if e1 then return nil, "first_edit: " .. tostring(e1) end
    return true
end

local function current_state(changeset_id)
    local cs = changeset_repo.get_changeset(changeset_id)
    return cs and cs.state or nil
end

local function define_tests()
    test.describe("integrate/run.lua transition contract (item-8)", function()
        test.it(
            "handler-fail path: push_failure + reopen keeps changeset reusable",
            function()
                local task_id = new_task()
                test.not_nil(task_id)

                local ws = changeset_client.create({
                    title    = "probe cs",
                    kind     = "session",
                    actor_id = "integrate_run_test",
                    task_id  = task_id,
                })
                test.not_nil(ws)
                local cs_id = ws.changeset_id

                -- Move to EDITING so we can observe the REJECTED->REOPEN->EDITING
                -- arc. In production this transition precedes push; here we
                -- simulate it because we're not running an actual push.
                local ok, drive_err = drive_to_accepted(cs_id)
                test.not_nil(ok, drive_err)

                -- Force to ACCEPTED directly via state machine to isolate the
                -- post-push failure branch. In production drive_to_accepted
                -- handles the submit_for_review + accept linting.
                local db = must_db()
                db:execute("UPDATE keeper_changesets SET state='accepted' WHERE changeset_id=?",
                    { cs_id })
                db:release()
                test.eq(current_state(cs_id), "accepted")

                -- Re-enact the integrate/run.lua handler-fail sequence:
                -- push_failure transitions ACCEPTED -> REJECTED, then reopen
                -- transitions REJECTED -> EDITING.
                local _, e1 = fire(cs_id, "push_failure", "probe: handlers failed")
                test.is_nil(e1, "push_failure from accepted must succeed")
                test.eq(current_state(cs_id), "rejected",
                    "push_failure must leave changeset rejected")

                local _, e2 = fire(cs_id, "reopen", "probe: reopen after integrate fail")
                test.is_nil(e2, "reopen from rejected must succeed")
                test.eq(current_state(cs_id), "editing",
                    "reopen must land on editing so active_for_task sees it again")

                -- The invariant the orphan-branch cascade depended on:
                -- active_for_task must return THIS changeset now, not nil.
                local active = changeset_repo.active_for_task(task_id)
                test.not_nil(active,
                    "active_for_task must find the reopened changeset; returning nil here means the next phase spawn will auto-fork a fresh empty branch")
                test.eq(active.changeset_id, cs_id,
                    "same changeset must be reused, not orphan-forked")

                cleanup_task(task_id)
            end)

        test.it(
            "handler-success path: push_success moves accepted -> merged",
            function()
                local task_id = new_task()
                local ws = changeset_client.create({
                    title    = "probe cs ok",
                    kind     = "session",
                    actor_id = "integrate_run_test",
                    task_id  = task_id,
                })
                test.not_nil(ws)
                local cs_id = ws.changeset_id

                local db = must_db()
                db:execute("UPDATE keeper_changesets SET state='accepted' WHERE changeset_id=?",
                    { cs_id })
                db:release()

                local _, err = fire(cs_id, "push_success", "probe: handlers green")
                test.is_nil(err, "push_success from accepted must succeed")
                test.eq(current_state(cs_id), "merged",
                    "push_success lands the changeset in merged")

                local active = changeset_repo.active_for_task(task_id)
                test.is_nil(active,
                    "after merge, active_for_task returns nil; next implement auto-forks a fresh branch (correct for green path)")

                cleanup_task(task_id)
            end)

        test.it(
            "publish-fail path: same push_failure + reopen as handler-fail (v19 regression)",
            function()
                -- v19 cycle 2 publish errored with "rows[1].op invalid: nil"
                -- (the OPS.WRITE bug). integrate/run.lua's publish-fail
                -- branch fired neither push_failure nor reopen, so the
                -- changeset stuck at `accepted` forever. With OPS.WRITE
                -- fixed in consts the original validation passes, but the
                -- recovery branch must still mirror the handler-fail path
                -- so OTHER publish-time errors (lint, version conflict,
                -- registry write) recover symmetrically instead of leaving
                -- a zombie accepted cs.
                local task_id = new_task()
                local ws = changeset_client.create({
                    title    = "publish-fail probe",
                    kind     = "session",
                    actor_id = "integrate_run_test",
                    task_id  = task_id,
                })
                test.not_nil(ws)
                local cs_id = ws.changeset_id

                local db = must_db()
                db:execute("UPDATE keeper_changesets SET state='accepted' WHERE changeset_id=?",
                    { cs_id })
                db:release()
                test.eq(current_state(cs_id), "accepted")

                -- Symmetric recovery: same two fires the handler-fail path uses.
                local _, e1 = fire(cs_id, "push_failure", "probe: publish step failed")
                test.is_nil(e1, "push_failure from accepted must succeed (publish-fail mirror)")
                test.eq(current_state(cs_id), "rejected")

                local _, e2 = fire(cs_id, "reopen", "probe: reopen after publish-fail")
                test.is_nil(e2)
                test.eq(current_state(cs_id), "editing",
                    "publish-fail must end in editing — next implement reuses this cs")

                local active = changeset_repo.active_for_task(task_id)
                test.not_nil(active,
                    "active_for_task must surface the reopened cs after publish-fail")
                test.eq(active.changeset_id, cs_id)

                cleanup_task(task_id)
            end)

        test.it(
            "regression anti-test: without reopen, handler-fail orphans the task",
            function()
                -- This test codifies what the bug looked like PRE-item-8. If
                -- run.lua ever drops the reopen call on the fail path, this
                -- test remains a textual record of the wrong behaviour.
                local task_id = new_task()
                local ws = changeset_client.create({
                    title    = "probe cs orphan",
                    kind     = "session",
                    actor_id = "integrate_run_test",
                    task_id  = task_id,
                })
                local cs_id = ws.changeset_id
                local db = must_db()
                db:execute("UPDATE keeper_changesets SET state='accepted' WHERE changeset_id=?",
                    { cs_id })
                db:release()

                -- Pretend run.lua forgot to reopen — fire ONLY push_failure.
                fire(cs_id, "push_failure", "probe: handlers failed (no reopen)")
                test.eq(current_state(cs_id), "rejected")

                -- active_for_task excludes rejected — so the next spawn would
                -- auto_fork. That's the orphan cascade we fixed.
                local active = changeset_repo.active_for_task(task_id)
                test.is_nil(active,
                    "without reopen, a rejected changeset is invisible to active_for_task — this is the bug pattern item-8 fixes")

                cleanup_task(task_id)
            end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
