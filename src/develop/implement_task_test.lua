local test = require("test")
local funcs = require("funcs")

local FN_ID = "keeper.develop:implement_task"

local function call_fn(args)
    return funcs.new():call(FN_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop:implement_task", function()
        test.it("errors when task is missing", function()
            local out, err = call_fn({ agent_id = "any" })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(err:find("task required") ~= nil)
        end)

        test.it("errors when task is empty string", function()
            local out, err = call_fn({ task = "", agent_id = "any" })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(err:find("task required") ~= nil)
        end)

        test.it("errors when agent_id is missing", function()
            local out, err = call_fn({ task = "do something" })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(err:find("agent_id required") ~= nil)
        end)

        test.it("errors when task_id is not set in ctx", function()
            -- Running outside a task phase — ctx.task_id is absent.
            local out, err = call_fn({
                task     = "implement x",
                agent_id = "keeper.develop.context:test_target",
            })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(
                err:find("task_id not set") ~= nil,
                "error should mention task_id not set"
            )
        end)
    end)
end

return { define_tests = define_tests }
