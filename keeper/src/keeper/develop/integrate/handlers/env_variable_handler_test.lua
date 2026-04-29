local test = require("test")
local funcs = require("funcs")

local HANDLER_ID = "keeper.develop.integrate.handlers:env_variable_handler"

local function call_handler(args)
    return funcs.new():call(HANDLER_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.integrate.handlers:env_variable_handler", function()
        test.it("returns empty table for empty entry_ids", function()
            local result, err = call_handler({ operation = "up", entry_ids = {} })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result, 0)
        end)

        test.it("marks each requested entry success on up", function()
            local result, err = call_handler({
                operation = "up",
                entry_ids = { "ns.a:VAR_ONE", "ns.b:VAR_TWO" },
            })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result, 2)
            test.eq(result[1].id, "ns.a:VAR_ONE")
            test.is_true(result[1].success)
            test.eq(result[1].data.operation, "up")
            test.eq(result[2].id, "ns.b:VAR_TWO")
            test.is_true(result[2].success)
        end)

        test.it("propagates operation=down into per-entry data", function()
            local result, err = call_handler({
                operation = "down",
                entry_ids = { "ns.a:VAR_ONE" },
            })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(result[1].id, "ns.a:VAR_ONE")
            test.eq(result[1].data.operation, "down")
        end)

        test.it("defaults operation to up when omitted", function()
            local result, err = call_handler({ entry_ids = { "ns.a:VAR_ONE" } })
            test.is_nil(err)
            test.eq(result[1].data.operation, "up")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
