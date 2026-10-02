-- migration_handler contract tests.
--
-- Uses the live migration app.probe.verify:01_create_probe_table (kept on
-- main as a permanent probe) with a reset before/after each test so the
-- handler is exercised against real-registry + real-db side effects, not
-- synthetic fixtures. Covers: empty input, missing-entry error, apply,
-- idempotent re-apply, down/revert, undiscovered-id safety net.

local test  = require("test")
local sql   = require("sql")
local funcs = require("funcs")
local runner_lib = require("runner")
local subject = require("subject")

local HANDLER_ID = "keeper.develop.integrate.handlers:migration_handler"
local PROBE_ID   = "app.probe.verify:01_create_probe_table"
local PROBE_TBL  = "probe_verify"

local function must_db()
    local db, err = sql.get("app:db")
    if err then error("app:db unavailable: " .. tostring(err)) end
    if not db then error("app:db unavailable") end
    return db
end

local function call_handler(args)
    return funcs.new():call(HANDLER_ID, args or {})
end

local function reset()
    local db, err = sql.get("app:db")
    if err or not db then return end
    db:execute("DROP TABLE IF EXISTS " .. PROBE_TBL)
    db:execute("DELETE FROM _migrations WHERE id=?", { PROBE_ID })
    db:release()
end

local function find_row(rows, id)
    for _, r in ipairs(rows or {}) do
        if r.id == id then return r end
    end
    return nil
end

local function probe_table_exists()
    local db = must_db()
    local rows = db:query(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        { PROBE_TBL }) or {}
    db:release()
    return #rows == 1
end

local function migration_applied(id)
    local db = must_db()
    local rows = db:query("SELECT 1 FROM _migrations WHERE id=?", { id }) or {}
    db:release()
    return #rows == 1
end

local function define_tests()
    test.describe("keeper.develop.integrate.handlers:migration_handler", function()
        local original_setup = runner_lib.setup
        test.before_each(reset)
        test.after_each(function()
            runner_lib.setup = original_setup
            reset()
        end)

        local function simulate_discovery(record_applied, status)
            runner_lib.setup = function()
                return {
                    run_next = function(_, options)
                        test.eq(options.allowed_ids[1], PROBE_ID)
                        if record_applied then
                            -- A second runner commits after the handler's first
                            -- ledger read, before run_next finishes discovery.
                            local db = must_db()
                            local _, err = db:execute(
                                "INSERT INTO _migrations (id, description) VALUES (?, ?)",
                                {PROBE_ID, "committed by competing runner"})
                            db:release()
                            test.is_nil(err)
                        end
                        return {status = status or "complete", migrations = {}, skipped_details = {}}
                    end,
                }
            end
        end

        test.it("skips a migration committed by another runner during discovery", function()
            simulate_discovery(true)
            local result, err = subject.handler({operation = "up", entry_ids = {PROBE_ID}})
            test.is_nil(err)
            test.eq(#result, 1)
            test.eq(result[1].id, PROBE_ID)
            test.eq(result[1].data.status, "skipped")
            test.eq(result[1].data.reason, "Already applied")
            test.is_true(migration_applied(PROBE_ID))
        end)

        test.it("still fails undiscovered migrations without a committed ledger row", function()
            simulate_discovery(false)
            local result, err = subject.handler({operation = "up", entry_ids = {PROBE_ID}})
            test.is_nil(result)
            test.contains(tostring(err), "migration not discovered by runner")
        end)

        test.it("does not hide a runner failure behind a competing ledger row", function()
            simulate_discovery(true, "error")
            local result, err = subject.handler({operation = "up", entry_ids = {PROBE_ID}})
            test.is_nil(result)
            test.not_nil(err)
        end)

        test.it("returns empty list for empty entry_ids", function()
            local result, err = call_handler({ operation = "up", entry_ids = {} })
            test.is_nil(err)
            test.eq(#result, 0)
        end)

        test.it("errors when a referenced entry does not exist", function()
            local result, err = call_handler({
                operation = "up",
                entry_ids = { "app.fake.does_not_exist:01_missing" },
            })
            test.is_nil(result)
            local err_str = tostring(err or "")
            test.is_true(err_str:find("app.fake.does_not_exist:01_missing", 1, true) ~= nil,
                "error must name the missing id; got: " .. err_str)
        end)

        test.it("applies a pushed migration and records it in _migrations", function()
            local result, err = call_handler({
                operation = "up",
                entry_ids = { PROBE_ID },
            })
            test.is_nil(err)
            local row = find_row(result, PROBE_ID)
            test.not_nil(row, "target row must be present in result")
            test.is_true(row.success)
            test.eq(row.data.status, "applied")
            test.is_true(probe_table_exists())
            test.is_true(migration_applied(PROBE_ID))
        end)

        test.it("a re-applied migration comes back as skipped, not failure", function()
            call_handler({ operation = "up", entry_ids = { PROBE_ID } })
            local result, err = call_handler({
                operation = "up",
                entry_ids = { PROBE_ID },
            })
            test.is_nil(err)
            local row = find_row(result, PROBE_ID)
            test.not_nil(row)
            test.eq(row.data.status, "skipped")
            test.is_true(probe_table_exists(), "table must still exist after idempotent re-apply")
        end)

        test.it("down operation reverts the requested migration", function()
            call_handler({ operation = "up", entry_ids = { PROBE_ID } })
            test.is_true(probe_table_exists())

            local result, err = call_handler({
                operation = "down",
                entry_ids = { PROBE_ID },
            })
            test.is_nil(err)
            local row = find_row(result, PROBE_ID)
            test.not_nil(row, "down must include the reverted id in result")
            test.is_true(row.success)
            test.eq(row.data.status, "reverted")
            test.is_false(probe_table_exists())
            test.is_false(migration_applied(PROBE_ID))
        end)

        test.it("result only reports on wanted ids, not unrelated pending migrations",
            function()
                -- run_next honours allowed_ids, so even when other migrations are
                -- pending in the system, the handler result must not leak them.
                local result, err = call_handler({
                    operation = "up",
                    entry_ids = { PROBE_ID },
                })
                test.is_nil(err)
                test.eq(#result, 1,
                    "handler result must list exactly one row (our wanted id); got " ..
                    tostring(#result))
                test.eq(result[1].id, PROBE_ID)
            end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
