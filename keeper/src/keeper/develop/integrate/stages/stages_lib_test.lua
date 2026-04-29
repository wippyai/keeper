-- Structural smoke tests for the integrate stage library. Each method is
-- invoked with minimal inputs; we assert argument validation and the trail
-- side-effect shape. Actual end-to-end integrate behaviour is covered by
-- running an integrate phase against a real task — those live tests live in
-- keeper.develop.integrate.pipeline:*_test.

local test = require("test")
local sql  = require("sql")
local stages_lib = require("stages_lib")
local task_writer = require("task_writer")
local nodes_writer = require("nodes_writer")

local DB = "keeper.state:db"

local function must_db()
    local db, err = sql.get(DB)
    if err then error("db: " .. tostring(err)) end
    if not db then error("db unavailable") end
    return db
end

local function make_task(title)
    local res = task_writer.create_task({
        title   = title or "stages_lib probe",
        actor_id = "stages_lib_test",
    }):execute()
    return res and res.task_id or nil
end

local function make_root(task_id)
    local r = nodes_writer.record({
        task_id       = task_id,
        type          = "integrate_stage",
        discriminator = "run",
        title         = "run",
        status        = "running",
        visibility    = "user",
    })
    return r and r.node_id or nil
end

local function count_stages(task_id, discriminator)
    local db = must_db()
    local rows = db:query(
        "SELECT COUNT(*) AS n FROM keeper_task_nodes WHERE task_id=? AND type='integrate_stage' AND discriminator=?",
        { task_id, discriminator }) or {}
    db:release()
    return rows[1] and rows[1].n or 0
end

local function cleanup_task(task_id)
    local db = must_db()
    db:execute("DELETE FROM keeper_task_nodes WHERE task_id=?", { task_id })
    db:execute("DELETE FROM keeper_tasks WHERE task_id=?", { task_id })
    db:release()
end

local function define_tests()
    test.describe("keeper.develop.integrate.stages:stages_lib", function()
        test.it("snapshot returns baseline_version + emits trail row", function()
            local task_id = make_task()
            test.not_nil(task_id)
            local root = make_root(task_id)
            test.not_nil(root)

            local out, err = stages_lib.snapshot({
                task_id  = task_id,
                run_root = root,
                branch   = "ws/probe",
            })
            test.is_nil(err)
            test.not_nil(out)
            test.not_nil(out.baseline_version,
                "snapshot must surface baseline_version")
            test.eq(count_stages(task_id, "snapshot"), 1,
                "snapshot must emit exactly one integrate_stage row")

            cleanup_task(task_id)
        end)

        test.it("snapshot errors on missing task_id", function()
            local _, err = stages_lib.snapshot({ run_root = "x" })
            test.not_nil(err)
        end)

        test.it("snapshot errors on missing run_root", function()
            local _, err = stages_lib.snapshot({ task_id = "x" })
            test.not_nil(err)
        end)

        test.it("record_handlers emits stage row for passed", function()
            local task_id = make_task()
            local root = make_root(task_id)
            local out, err = stages_lib.record_handlers({
                task_id   = task_id,
                run_root  = root,
                passed    = true,
                execution = { handlers = { { handler_id = "x", result = {} } } },
            })
            test.is_nil(err)
            test.eq(out.ok, true)
            test.eq(count_stages(task_id, "handlers"), 1)
            cleanup_task(task_id)
        end)

        test.it("record_handlers emits stage row for failed", function()
            local task_id = make_task()
            local root = make_root(task_id)
            local out = stages_lib.record_handlers({
                task_id   = task_id,
                run_root  = root,
                passed    = false,
                execution = { handlers = {} },
            })
            test.eq(out.ok, false)
            test.eq(count_stages(task_id, "handlers"), 1)
            cleanup_task(task_id)
        end)

        test.it("restore_version errors without baseline_version", function()
            local _, err = stages_lib.restore_version({
                task_id = "x", run_root = "y",
            })
            test.not_nil(err)
        end)

        test.it("finalize updates root + returns status table", function()
            local task_id = make_task()
            local root = make_root(task_id)
            -- finalize normally calls lifecycle.handle_exit which would try to
            -- spawn the next phase; the task has no changeset so that path
            -- returns the result dict without scheduling. We only assert the
            -- trail-side effects.
            local out = stages_lib.finalize({
                task_id  = task_id,
                run_root = root,
                ok       = true,
                summary  = "probe ok",
            })
            test.not_nil(out)
            test.eq(out.status, "ok")
            test.eq(out.summary, "probe ok")
            cleanup_task(task_id)
        end)

        test.it("finalize flips status to failed when ok=false", function()
            local task_id = make_task()
            local root = make_root(task_id)
            local out = stages_lib.finalize({
                task_id  = task_id,
                run_root = root,
                ok       = false,
                summary  = "probe fail",
            })
            test.eq(out.status, "fail")
            cleanup_task(task_id)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
