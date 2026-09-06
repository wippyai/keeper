local test = require("test")
local step_runner = require("step_runner")

-- A fake executor records the steps it receives and returns a caller-supplied
-- wrapped row per step, so the engine can be exercised without registry deps.
local function recording_executor(script)
    local s = script :: any
    local seen = ({}) :: { any }
    local i = 0
    local exec = function(step)
        i = i + 1
        table.insert(seen, step)
        local produce = s[i] or s.default
        if type(produce) == "function" then return produce(step) end
        return produce
    end
    return exec, seen
end

local function define_tests()
    test.describe("keeper.develop.integrate.pipeline:step_runner", function()
        test.it("runs steps in order and returns the ledger shape", function()
            local exec, seen = recording_executor({
                default = function(step)
                    return { op = step.op, result = { { id = step.op, success = true } } }
                end,
            })
            local out = step_runner.run({
                { op = "a", label = "a" },
                { op = "b", label = "b" },
                { op = "c", label = "c" },
            }, { execute = exec })

            test.is_true(out.success)
            test.not_nil(out.execution)
            test.not_nil(out.execution.handlers)
            test.eq(#out.execution.handlers, 3)
            test.eq(seen[1].op, "a")
            test.eq(seen[2].op, "b")
            test.eq(seen[3].op, "c")
            test.eq(out.execution.handlers[1].op, "a")
            test.eq(out.execution.handlers[3].op, "c")
        end)

        test.it("accumulates applied_ids from successful result rows", function()
            local exec = recording_executor({
                { op = "a", result = { { id = "ns:one", success = true }, { id = "ns:skip", success = false } } },
                { op = "b", result = { { id = "ns:two", success = true } } },
            })
            local out = step_runner.run({ { op = "a" }, { op = "b" } }, { execute = exec })
            test.is_true(out.success)
            test.eq(#out.applied_ids, 2)
            test.eq(out.applied_ids[1], "ns:one")
            test.eq(out.applied_ids[2], "ns:two")
        end)

        test.it("stops at the first failing step", function()
            local exec, seen = recording_executor({
                { op = "a", result = {} },
                { op = "b", error = "boom" },
                { op = "c", result = {} },
            })
            local out = step_runner.run({ { op = "a" }, { op = "b" }, { op = "c" } }, { execute = exec })
            test.is_false(out.success)
            test.eq(#seen, 2, "third step must not run after the second fails")
            test.eq(#out.execution.handlers, 2)
            test.eq(out.execution.handlers[2].error, "boom")
        end)

        test.it("records the descriptor inverse onto the ledger row", function()
            local exec = recording_executor({
                default = function() return { result = {} } end,
            })
            local out = step_runner.run({
                { op = "a", label = "a", inverse = { op = "undo_a", data = { v = 1 } } },
            }, { execute = exec })
            test.is_true(out.success)
            test.not_nil(out.execution.handlers[1].inverse)
            test.eq(out.execution.handlers[1].inverse.op, "undo_a")
            test.eq(out.execution.handlers[1].inverse.data.v, 1)
        end)

        test.it("preserves an executor-supplied inverse over the descriptor default", function()
            local exec = recording_executor({
                default = function(step) return { op = step.op, result = {}, inverse = { op = "from_executor" } } end,
            })
            local out = step_runner.run({
                { op = "a", inverse = { op = "from_descriptor" } },
            }, { execute = exec })
            test.eq(out.execution.handlers[1].inverse.op, "from_executor")
        end)

        test.it("attaches the step input_snapshot to the ledger row", function()
            local exec = recording_executor({ default = function() return { result = {} } end })
            local snap = { operation = "up", entries = { { id = "ns:x" } }, fs_paths = {} }
            local out = step_runner.run({ { op = "a", input_snapshot = snap } }, { execute = exec })
            test.not_nil(out.execution.handlers[1].input_snapshot)
            test.eq(out.execution.handlers[1].input_snapshot.entries[1].id, "ns:x")
        end)
    end)

    test.describe("keeper.develop.integrate.pipeline:step_runner.reverse", function()
        test.it("short-circuits with success on empty or nil execution", function()
            local empty = step_runner.reverse({}, { execute = function() error("must not run") end })
            test.is_true(empty.success)
            test.eq(#empty.execution.handlers, 0)

            local nilled = step_runner.reverse(nil, { execute = function() error("must not run") end })
            test.is_true(nilled.success)
        end)

        test.it("unwraps a {handlers=...} ledger and walks rows in reverse", function()
            local order = {}
            local out = step_runner.reverse(
                { handlers = { { op = "a", label = "a" }, { op = "b", label = "b" } } },
                {
                    execute = function(row)
                        table.insert(order, row.op)
                        return { op = row.op, result = {} }
                    end,
                })
            test.is_true(out.success)
            test.eq(order[1], "b")
            test.eq(order[2], "a")
        end)

        test.it("skips rows whose executor returns nil and continues past a failing undo", function()
            local out = step_runner.reverse(
                { { op = "a", label = "a" }, { op = "b", label = "b" }, { op = "c", label = "c" } },
                {
                    execute = function(row)
                        if row.op == "c" then return nil end
                        if row.op == "b" then return { op = "b", error = "undo failed" } end
                        return { op = "a", result = {} }
                    end,
                })
            test.is_false(out.success)
            -- c skipped, b + a recorded (b failed, a ran) — best-effort continue.
            test.eq(#out.execution.handlers, 2)
            test.eq(out.execution.handlers[1].op, "b")
            test.eq(out.execution.handlers[2].op, "a")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
