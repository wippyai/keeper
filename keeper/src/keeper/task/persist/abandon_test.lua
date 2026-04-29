-- Regression tests for keeper.task.persist:abandon. The bug we are pinning:
-- flipping a task's status to 'abandoned' via the row update alone leaves
-- the running dataflow alive, which then auto-forks new changesets and
-- silently flushes work to disk after the user thought the task was
-- killed (observed live during the v15 -> v16 hand-off).
--
-- abandon_task must always:
--   - drop the task's active changeset (so the next phase spawn cannot
--     reuse it; auto_fork would create a fresh one if needed, but at
--     least the task is no longer attached to a live overlay)
--   - clear the task lock so other queue logic does not treat the task
--     as "owned" by a dead orchestrator
--   - return a structured cleanup summary the caller can surface

local test            = require("test")
local sql             = require("sql")
local uuid            = require("uuid")
local abandon         = require("abandon")
local changeset_repo  = require("changeset_repo")
local changeset_consts = require("changeset_consts")
local task_consts     = require("task_consts")
local task_writer     = require("task_writer")

local created_task_ids = {}
local created_cs_ids   = {}

local function fresh_task()
    local id = uuid.v7()
    local res = task_writer.create_task({
        task_id = id,
        title   = "abandon_test " .. id:sub(1, 8),
    }):execute()
    table.insert(created_task_ids, res.task_id)
    return res.task_id
end

local function fresh_changeset(task_id)
    local cs_id = "abandontest-" .. uuid.v7()
    local ws, err = changeset_repo.create_changeset({
        changeset_id     = cs_id,
        task_id          = task_id,
        title            = "abandon_test cs",
        kind             = changeset_consts.KINDS.SESSION,
        actor_id         = "test.abandon",
        state_branch     = changeset_consts.branch_for(cs_id),
        scratch_fs_path  = cs_id .. "/",
        baseline_version = "0",
        baseline_fs_hash = "",
    })
    if err then error(err) end
    table.insert(created_cs_ids, ws.changeset_id)
    return ws
end

local function purge()
    local db = sql.get(task_consts.DATABASE.RESOURCE_ID)
    if not db then return end
    for _, id in ipairs(created_task_ids) do
        db:execute("DELETE FROM keeper_task_nodes WHERE task_id = ?", { id })
        db:execute("DELETE FROM keeper_tasks WHERE task_id = ?", { id })
    end
    for _, cs_id in ipairs(created_cs_ids) do
        db:execute("DELETE FROM keeper_changeset_changes WHERE changeset_id = ?", { cs_id })
        db:execute("DELETE FROM keeper_changeset_baselines WHERE changeset_id = ?", { cs_id })
        db:execute("DELETE FROM keeper_changeset_fs_content WHERE changeset_id = ?", { cs_id })
        db:execute("DELETE FROM keeper_changesets WHERE changeset_id = ?", { cs_id })
    end
    db:release()
    created_task_ids = {}
    created_cs_ids   = {}
end

local function define_tests()
    test.describe("keeper.task.persist:abandon", function()
        test.after_all(purge)

        test.it("rejects empty task_id", function()
            local out, err = abandon.abandon_task("")
            test.is_nil(out)
            test.not_nil(err)
        end)

        test.it("returns clean summary on a task with no changeset and no dataflows",
            function()
                -- Pure no-op cleanup. Nothing to cancel, nothing to drop.
                -- The function still must succeed and report empty arrays.
                local task_id = fresh_task()
                local out, err = abandon.abandon_task(task_id)
                test.is_nil(err)
                test.not_nil(out)
                test.eq(#out.cancelled_dataflows, 0)
                test.eq(#out.cancelled_errors, 0)
                test.is_nil(out.dropped_changeset_id,
                    "task without an active changeset should report nil drop target")
                test.eq(out.task_id, task_id)
            end)

        test.it("drops the task's active changeset and releases the lock",
            function()
                local task_id = fresh_task()
                local ws = fresh_changeset(task_id)
                changeset_repo.set_task_lock(task_id, "test-orchestrator")

                local before = changeset_repo.active_for_task(task_id)
                test.not_nil(before, "fixture: task should have an active changeset")
                test.eq(before.changeset_id, ws.changeset_id)

                local out, err = abandon.abandon_task(task_id,
                    { reason = "regression test" })
                test.is_nil(err)
                test.not_nil(out)
                test.eq(out.dropped_changeset_id, ws.changeset_id,
                    "summary must name the dropped changeset")
                test.is_true(out.lock_released,
                    "lock release must succeed cleanly")

                -- Active for task is the canonical "is this changeset reusable"
                -- check; after drop it must return nil.
                local after = changeset_repo.active_for_task(task_id)
                test.is_nil(after,
                    "active_for_task must return nil after abandon")

                -- Underlying changeset row must reflect the drop transition.
                local cs = changeset_repo.get_changeset(ws.changeset_id)
                test.eq(cs.state, "dropped",
                    "changeset row state must be 'dropped' after abandon")
            end)

        test.it("is idempotent — calling abandon twice does not error",
            function()
                local task_id = fresh_task()
                fresh_changeset(task_id)

                local _, err1 = abandon.abandon_task(task_id)
                test.is_nil(err1, "first abandon should succeed")

                local out2, err2 = abandon.abandon_task(task_id)
                test.is_nil(err2, "second abandon must not error")
                test.not_nil(out2)
                test.is_nil(out2.dropped_changeset_id,
                    "second call has nothing left to drop")
            end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
