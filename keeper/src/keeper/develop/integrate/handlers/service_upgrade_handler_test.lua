local test = require("test")
local funcs = require("funcs")

local HANDLER_ID = "keeper.develop.integrate.handlers:service_upgrade_handler"

local function call_handler(args)
    return funcs.new():call(HANDLER_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.integrate.handlers:service_upgrade_handler", function()
        test.it("returns empty list for empty entry_ids", function()
            local result, err = call_handler({ operation = "up", entry_ids = {} })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result, 0)
        end)

        test.it("down operation returns a noop row per entry", function()
            local result, err = call_handler({
                operation = "down",
                entry_ids = { "app:alpha", "app:beta" },
            })
            test.is_nil(err)
            test.eq(#result, 2)
            test.is_true(result[1].success)
            test.eq(result[1].data.status, "noop")
            test.eq(result[2].id, "app:beta")
        end)

        test.it("up with entries backing no upgradable service returns no rows", function()
            local result, err = call_handler({
                operation = "up",
                entry_ids = { "app:no_such_process_xyz" },
            })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result, 0)
        end)

        test.it("ignores non-string entry ids defensively", function()
            local result, err = call_handler({
                operation = "up",
                entry_ids = { 123, "", false },
            })
            test.is_nil(err)
            test.eq(#result, 0)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
