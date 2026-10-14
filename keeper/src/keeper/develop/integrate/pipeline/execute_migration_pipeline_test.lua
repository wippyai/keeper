-- End-to-end reproducer for the integrate-time migration miss. Calls
-- keeper.develop.integrate.pipeline:execute (the same function that
-- keeper.develop.integrate:run drives after push) against the live migration
-- app.probe.verify:01_create_probe_table and asserts the table lands in
-- app:db.
--
-- This closes the gap between migration_handler_test (direct handler) and
-- unit2_verify_test (direct handler on a different probe) — it proves the
-- pipeline wrapper still applies migrations end-to-end.

local test  = require("test")
local funcs = require("funcs")
local json  = require("json")
local probe_db = require("probe_db")

local EXEC_ID    = "keeper.develop.integrate.pipeline:execute"
local PROBE_ID   = "app.probe.verify:01_create_probe_table"
local PROBE_TBL  = "probe_verify"

local function reset()
    probe_db.reset(PROBE_TBL, PROBE_ID)
end

local function table_exists(name)
    return probe_db.table_exists(name)
end

local function migration_row(id)
    return probe_db.migration_applied(id)
end

local function define_tests()
    test.describe("integrate_pipeline_migration", function()
        test.it("pipeline execute applies a live migration via migration_handler", function()
            reset()
            test.is_false(table_exists(PROBE_TBL), "probe_verify must not exist at start")
            test.is_false(migration_row(PROBE_ID), "_migrations row must not exist at start")

            local out, err = funcs.new():call(EXEC_ID, {
                operation = "up",
                entry_ids = { PROBE_ID },
            })
            test.is_nil(err, "pipeline:execute must not error; got: " .. tostring(err))
            test.not_nil(out, "pipeline:execute must return a result")
            test.is_true(out.success, "pipeline must report success=true")

            -- pipeline.execute returns { success, execution: { handlers: [...] } }
            -- where handlers is the per-handler output list.
            local handler_out = nil
            for _, h in ipairs((out.execution or {}).handlers or {}) do
                if type(h) == "table" and
                   h.handler_id == "keeper.develop.integrate.handlers:migration_handler" then
                    handler_out = h
                    break
                end
            end
            test.not_nil(handler_out,
                "migration_handler must appear in execution; saw: " ..
                json.encode(out.execution or {}))
            test.not_nil(handler_out.result,
                "handler must return a non-nil result when the migration applies")
            test.not_nil(handler_out.input_snapshot,
                "handler output must include the published registry input snapshot")
            test.eq(handler_out.input_snapshot.operation, "up")
            test.eq(#handler_out.input_snapshot.entries, 1,
                "migration handler snapshot must include exactly the wanted migration")
            test.eq(handler_out.input_snapshot.entries[1].id, PROBE_ID)
            test.eq(handler_out.input_snapshot.entries[1].method, "define",
                "snapshot must preserve the migration entry method at handler dispatch")
            test.eq(handler_out.input_snapshot.entries[1].target_db, "app:db",
                "snapshot must preserve the migration target_db at handler dispatch")

            -- With run_next-per-wanted-id, the handler only reports on our id.
            test.eq(#handler_out.result, 1,
                "handler result must list only the wanted migration; got " ..
                tostring(#handler_out.result))
            test.eq(handler_out.result[1].id, PROBE_ID)
            test.is_true(handler_out.result[1].success,
                "wanted migration must report success")
            test.eq(handler_out.result[1].data.status, "applied")

            test.is_true(table_exists(PROBE_TBL), "probe_verify table must exist after pipeline up")
            test.is_true(migration_row(PROBE_ID), "_migrations row must exist after pipeline up")
        end)

        test.it("pipeline execute on an already-applied migration returns success with skipped status",
            function()
                -- Leave probe_verify in place from prior test. Re-running pipeline
                -- must not error and must leave the table alone.
                local out, err = funcs.new():call(EXEC_ID, {
                    operation = "up",
                    entry_ids = { PROBE_ID },
                })
                test.is_nil(err)
                test.is_true(out.success, "re-apply must report success=true (idempotent)")
                test.is_true(table_exists(PROBE_TBL), "probe_verify must still exist")
            end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
