local test = require("test")
local funcs = require("funcs")

local EXEC_ID = "keeper.develop.integrate.pipeline:execute"

local function call_exec(args)
    return funcs.new():call(EXEC_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.integrate.pipeline:execute", function()
        test.it("short-circuits with success=true on empty entry_ids", function()
            local out, err = call_exec({ operation = "up", entry_ids = {} })
            test.is_nil(err)
            test.not_nil(out)
            test.is_true(out.success)
            test.not_nil(out.execution)
            test.not_nil(out.execution.handlers)
            test.eq(#out.execution.handlers, 0)
        end)

        test.it("errors when a requested entry does not exist in the registry", function()
            local out, err = call_exec({
                operation = "up",
                entry_ids = { "app.fake.does_not_exist:01_missing" },
            })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(
                err:find("Failed to load entry") ~= nil,
                "error should mention failure to load entry"
            )
        end)

        test.it("returns success=true with no handlers when entries match none", function()
            -- wippy.test:test is a library.lua; no integration.handler matches it.
            local out, err = call_exec({
                operation = "up",
                entry_ids = { "wippy.test:test" },
            })
            test.is_nil(err)
            test.not_nil(out)
            test.is_true(out.success)
            test.eq(#out.execution.handlers, 0)
        end)
    end)
end

return { define_tests = define_tests }
