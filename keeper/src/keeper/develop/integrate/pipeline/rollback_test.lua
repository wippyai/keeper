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

        test.it("returns handler-level failure when rollback handler cannot process an entry", function()
            local out, err = call_rollback({
                execution = {
                    {
                        handler_id = "keeper.develop.integrate.handlers:migration_handler",
                        entry_ids  = { "app.fake.does_not_exist:01_missing" },
                        result     = {},
                    },
                },
            })
            test.is_nil(err)
            test.not_nil(out)
            test.is_false(out.success)
            test.not_nil(out.execution.handlers[1].error)
            test.is_true(
                out.execution.handlers[1].error:find("app.fake.does_not_exist:01_missing") ~= nil,
                "handler error should mention the missing entry"
            )
        end)

        test.it("replays original handlers in reverse and preserves fs-only handlers", function()
            local out, err = call_rollback({
                execution = {
                    {
                        handler_id = "keeper.develop.integrate.handlers:env_variable_handler",
                        entry_ids  = { "ns.a:VAR_ONE" },
                        result     = {
                            { id = "ns.a:VAR_ONE", success = true, data = { operation = "up" } },
                        },
                    },
                    {
                        handler_id = "keeper.develop.integrate.handlers:build_handler",
                        entry_ids  = {},
                        fs_paths   = { "frontend/applications/keeper/src/pages/probe.vue" },
                        result     = {
                            {
                                id = "fs://frontend/applications/keeper/src/pages/probe.vue",
                                success = true,
                                data = { operation = "up" },
                            },
                        },
                    },
                },
            })
            test.is_nil(err)
            test.not_nil(out)
            test.is_true(out.success)
            test.eq(#out.execution.handlers, 2)
            test.eq(out.execution.handlers[1].handler_id,
                "keeper.develop.integrate.handlers:build_handler")
            test.eq(out.execution.handlers[1].fs_paths[1],
                "frontend/applications/keeper/src/pages/probe.vue")
            test.eq(out.execution.handlers[2].handler_id,
                "keeper.develop.integrate.handlers:env_variable_handler")
            test.eq(out.applied_ids[1], "ns.a:VAR_ONE")
        end)
    end)
end

return { define_tests = define_tests }
