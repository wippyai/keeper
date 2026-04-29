-- Regression test for lifecycle.emit_phase_summary — specifically the
-- 2026-04-24 fix that surfaces failing integrate_stage.error_message rows
-- into the phase_summary_integrate finding content.
--
-- Without this, the next implement phase reads "integrate exited fail"
-- with no diagnostic and wastes a turn researching which handler broke.
-- With it, the finding explicitly names the handler + its error message,
-- copied from the DB column integrate/run.lua already populates.

local test          = require("test")
local sql           = require("sql")
local lifecycle     = require("lifecycle")
local nodes_reader  = require("nodes_reader")
local nodes_writer  = require("nodes_writer")
local state_machine = require("state_machine")
local task_writer   = require("task_writer")

local DB = "keeper.state:db"
local P = state_machine.PHASES
local S = state_machine.SIGNALS

local function must_db()
    local db, err = sql.get(DB)
    if err then error("db: " .. tostring(err)) end
    if not db then error("db unavailable") end
    return db
end

local function cleanup(task_id)
    if not task_id or task_id == "" then return end
    local db = must_db()
    db:execute("DELETE FROM keeper_task_nodes WHERE task_id=?", { task_id })
    db:execute("DELETE FROM keeper_tasks WHERE task_id=?", { task_id })
    db:release()
end

local function new_task(title)
    local res = task_writer.create_task({
        title    = title or "phase_summary probe",
        actor_id = "phase_summary_test",
    }):execute()
    return res and res.task_id or nil
end

local function record_stage(task_id, discriminator, status, err_msg)
    nodes_writer.record({
        task_id       = task_id,
        type          = "integrate_stage",
        discriminator = discriminator,
        title         = discriminator,
        status        = status,
        visibility    = "user",
        error_message = err_msg,
    })
end

local function latest_summary(task_id)
    return nodes_reader.latest_of_type(task_id, "finding",
        { discriminator = "phase_summary_" .. P.INTEGRATE })
end

local function define_tests()
    test.describe("lifecycle.emit_phase_summary — integrate failure surfacing", function()
        test.it(
            "copies failed integrate_stage error_messages into the summary",
            function()
                local task_id = new_task("integrate fail visibility")
                test.not_nil(task_id)

                record_stage(task_id, "snapshot", "passed", nil)
                record_stage(task_id, "publish",  "passed", nil)
                record_stage(task_id, "handlers", "failed",
                    "keeper.develop.integrate.handlers:test_handler: test_handler: 1 test(s) failed — FAILED 1 passed, 1 failed, 0 skipped (total 2)")
                record_stage(task_id, "rollback", "passed", nil)

                lifecycle._emit_phase_summary(
                    task_id, P.INTEGRATE, S.FAIL,
                    "one or more handlers reported failure", P.IMPLEMENT)

                local row = latest_summary(task_id)
                test.not_nil(row, "phase_summary_integrate must be recorded")
                test.not_nil(row.content)
                test.is_true(row.content:find("Stage handlers failed:", 1, true) ~= nil,
                    "summary must name the failing stage")
                test.is_true(row.content:find("test_handler", 1, true) ~= nil,
                    "summary must carry the handler id from error_message")
                test.is_true(row.content:find("1 test%(s%) failed") ~= nil,
                    "summary must carry the error_message verbatim")

                cleanup(task_id)
            end)

        test.it(
            "does not surface stage errors on handler-success path",
            function()
                local task_id = new_task("integrate ok no noise")
                record_stage(task_id, "snapshot", "passed", nil)
                record_stage(task_id, "handlers", "passed", nil)

                lifecycle._emit_phase_summary(
                    task_id, P.INTEGRATE, S.OK,
                    "published and handlers green", P.TEST)

                local row = latest_summary(task_id)
                test.not_nil(row)
                test.is_true(row.content:find("Stage handlers", 1, true) == nil,
                    "happy-path summary must not include per-stage diagnostic noise")

                cleanup(task_id)
            end)

        test.it(
            "ignores non-integrate phases even on fail signal",
            function()
                -- Other phases don't emit integrate_stage rows, but defending
                -- the branch against a stray failed integrate_stage leaking
                -- into an unrelated phase summary.
                local task_id = new_task("wrong phase guard")
                record_stage(task_id, "handlers", "failed", "stale row from prior run")

                lifecycle._emit_phase_summary(
                    task_id, P.REVIEW, S.BUGS,
                    "reviewer raised bugs", P.IMPLEMENT)

                local row = nodes_reader.latest_of_type(task_id, "finding",
                    { discriminator = "phase_summary_" .. P.REVIEW })
                test.not_nil(row)
                test.is_true(row.content:find("Stage handlers", 1, true) == nil,
                    "review summary must not leak integrate stage errors")

                cleanup(task_id)
            end)

        test.it(
            "handles multiple failed stages cleanly",
            function()
                local task_id = new_task("integrate multi-fail")
                record_stage(task_id, "migrations", "failed",
                    "migration_handler: app.probe:01 — syntax error near 'TABEL'")
                record_stage(task_id, "handlers",   "failed",
                    "test_handler: 3 test(s) failed")

                lifecycle._emit_phase_summary(
                    task_id, P.INTEGRATE, S.FAIL,
                    "two stages failed", P.IMPLEMENT)

                local row = latest_summary(task_id)
                test.not_nil(row)
                test.is_true(row.content:find("Stage migrations failed:", 1, true) ~= nil,
                    "summary must include migration failure")
                test.is_true(row.content:find("Stage handlers failed:", 1, true) ~= nil,
                    "summary must include handler failure")
                test.is_true(row.content:find("TABEL", 1, true) ~= nil,
                    "summary must carry migration error text verbatim")
                test.is_true(row.content:find("3 test%(s%) failed") ~= nil,
                    "summary must carry handler error text verbatim")

                cleanup(task_id)
            end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
