local funcs = require("funcs")
local test = require("test")

local HANDLER_ID = "keeper.develop.integrate.handlers:test_handler"

local function call_handler(args)
    return funcs.new():call(HANDLER_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.integrate.handlers:test_handler", function()
        test.it("returns empty result for empty entry_ids", function()
            local result, err = call_handler({ operation = "up", entry_ids = {} })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result, 0)
        end)

        test.it("down operation returns a no-op row per entry", function()
            local result, err = call_handler({
                operation = "down",
                entry_ids = { "keeper.task.phases:state_machine_test" },
            })
            test.is_nil(err)
            test.eq(#result, 1)
            test.is_true(result[1].success)
            test.eq(result[1].data.status, "noop")
            test.eq(result[1].data.operation, "down")
        end)

        test.it("up operation runs a real passing test and reports totals", function()
            local result, err = call_handler({
                operation = "up",
                entry_ids = { "keeper.task.phases:state_machine_test" },
            })
            test.is_nil(err, "passing test should not surface an error; got: " .. tostring(err))
            test.not_nil(result)
            test.eq(#result, 1)
            test.is_true(result[1].success)
            test.eq(result[1].data.status, "passed")
            test.is_true((result[1].data.total or 0) > 0,
                "expected run_test to report a positive total count")
        end)
    end)
end

return { define_tests = define_tests }
