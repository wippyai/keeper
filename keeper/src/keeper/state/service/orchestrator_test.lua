local test = require("test")
local orchestrator = require("orchestrator")
local consts = require("consts")

local function define_tests()
    describe("State orchestrator registration", function()
        test.after_each(function()
            test.restore_mock("process.registry")
            test.restore_mock("process.pid")
        end)

        it("returns the PID error before registering", function()
            test.mock("process.pid", function()
                return nil, "PID unavailable"
            end)
            local registered = false
            test.mock("process.registry", {
                register = function()
                    registered = true
                    error("registration requires a PID")
                end,
            })

            local data, err = orchestrator.run()

            test.is_nil(data)
            test.eq(err, "PID unavailable")
            test.is_false(registered)
        end)

        it("registers the PID without a scope argument", function()
            test.mock("process.pid", function()
                return "test-pid", nil
            end)
            local registration = {}
            test.mock("process.registry", {
                register = function(...)
                    registration = { count = select("#", ...), name = select(1, ...), pid = select(2, ...) }
                    error("registration captured")
                end,
            })

            local ok, err = pcall(orchestrator.run)

            test.is_false(ok)
            test.is_true(tostring(err):find("registration captured", 1, true) ~= nil)
            test.eq(registration.name, consts.PROCESS_NAMES.ORCHESTRATOR)
            test.eq(registration.pid, "test-pid")
            test.eq(registration.count, 2)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
