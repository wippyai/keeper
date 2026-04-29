-- One-shot integration verifier for Unit 2 (migration_handler port).
-- Calls migration_handler on a pushed migration and asserts the target table
-- exists in app:db. This is the integrate-phase handler call site, not a
-- synthetic unit test.

local test = require("test")
local sql = require("sql")
local funcs = require("funcs")

local HANDLER_ID = "keeper.develop.integrate.handlers:migration_handler"
local PROBE_ID   = "app.probe.unit2:01_create_unit2_table"
local PROBE_TBL  = "unit2_probe"

local function must_db()
    local db, err = sql.get("app:db")
    if err then error("app:db unavailable: " .. tostring(err)) end
    if not db then error("app:db unavailable") end
    return db
end

local function reset()
    local db = must_db()
    db:execute("DROP TABLE IF EXISTS " .. PROBE_TBL)
    db:execute("DELETE FROM _migrations WHERE id=?", { PROBE_ID })
    db:release()
end

local function define_tests()
    test.describe("unit2_migration_handler_integration", function()
        test.it("runs the pushed migration end-to-end via the integrate handler", function()
            reset()

            local result, err = funcs.new():call(HANDLER_ID, {
                operation = "up",
                entry_ids = { PROBE_ID },
            })
            test.is_nil(err, "handler must not return err; got: " .. tostring(err))

            local row
            for _, r in ipairs(result or {}) do
                if r.id == PROBE_ID then row = r; break end
            end
            test.not_nil(row, "handler result must include the target migration")
            test.is_true(row.success)
            test.eq(row.data.status, "applied")

            local db = must_db()
            local tbl = db:query("SELECT name FROM sqlite_master WHERE type='table' AND name=?",
                { PROBE_TBL }) or {}
            local mig = db:query("SELECT 1 FROM _migrations WHERE id=?", { PROBE_ID }) or {}
            db:release()
            test.eq(#tbl, 1, "target table must be present on app:db")
            test.eq(#mig, 1, "_migrations row must exist for the applied id")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
