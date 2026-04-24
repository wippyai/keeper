local test = require("test")
local funcs = require("funcs")

local ROLLBACK_ID = "keeper.develop.integrate.pipeline:rollback"

local function call_rollback(args)
    return funcs.new():call(ROLLBACK_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.integrate.pipeline:rollback", function()
        test.it("short-circuits with success=true on empty execution", function()
            local out, err = call_rollback({ execution = {} })
            test.is_nil(err)
            test.not_nil(out)
            test.is_true(out.success)
            test.not_nil(out.execution)
            test.not_nil(out.execution.handlers)
            test.eq(#out.execution.handlers, 0)
        end)

        test.it("short-circuits when execution is nil", function()
            local out, err = call_rollback({})
            test.is_nil(err)
            test.not_nil(out)
            test.is_true(out.success)
        end)

        test.it("errors when an entry referenced in execution is missing from registry", function()
            local out, err = call_rollback({
                execution = {
                    {
                        handler_id = "keeper.develop.integrate.handlers:migration_handler",
                        entry_ids  = { "app.fake.does_not_exist:01_missing" },
                        result     = {},
                    },
                },
            })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(
                err:find("Failed to load entry for rollback") ~= nil,
                "error should mention the failed load for rollback"
            )
        end)
    end)
end

return { define_tests = define_tests }
