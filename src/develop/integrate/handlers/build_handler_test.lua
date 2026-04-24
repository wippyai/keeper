local funcs = require("funcs")
local test = require("test")

local HANDLER_ID = "keeper.develop.integrate.handlers:build_handler"

local function call_handler(args)
    return funcs.new():call(HANDLER_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.integrate.handlers:build_handler", function()
        test.it("returns empty result for empty entry_ids", function()
            local result, err = call_handler({ operation = "up", entry_ids = {} })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result, 0)
        end)

        test.it("down operation returns a record-only row per entry", function()
            local result, err = call_handler({
                operation = "down",
                entry_ids = { "app:nonexistent_view" },
            })
            test.is_nil(err)
            test.eq(#result, 1)
            test.is_true(result[1].success)
            test.eq(result[1].data.status, "noop")
        end)

        test.it("surfaces a structured error when the entry cannot be loaded", function()
            local result, err = call_handler({
                operation = "up",
                entry_ids = { "nope:does_not_exist" },
            })
            test.is_nil(result)
            test.not_nil(err)
            test.is_true(err:find("build_handler") ~= nil)
        end)
    end)
end

return { define_tests = define_tests }
