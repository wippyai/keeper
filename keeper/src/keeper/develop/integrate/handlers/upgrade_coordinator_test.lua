local test = require("test")
local coordinator = require("coordinator")

-- Behavioural coverage (find_targets matches a live upgradable service and the
-- signal drives process.upgrade) is exercised end-to-end against a running
-- counter service in the standalone integration proof. These unit tests pin the
-- pure contract that holds without registry fixtures.
local function define_tests()
    test.describe("keeper.develop.integrate.handlers:upgrade_coordinator", function()
        test.it("find_targets returns no targets for an empty changed set", function()
            local targets = coordinator.find_targets({})
            test.not_nil(targets)
            test.eq(#targets, 0)
        end)

        test.it("find_targets never matches a process id that is not in the changed set", function()
            local targets = coordinator.find_targets({ ["app:definitely_absent_process"] = true })
            test.not_nil(targets)
            test.eq(#targets, 0)
        end)

        test.it("run returns no rows when nothing changed", function()
            local rows = coordinator.run({}, 1)
            test.not_nil(rows)
            test.eq(#rows, 0)
        end)

        test.it("run is robust to unknown changed ids", function()
            local rows = coordinator.run({ "app:unknown_a", "app:unknown_b" }, 7)
            test.not_nil(rows)
            test.eq(#rows, 0)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
