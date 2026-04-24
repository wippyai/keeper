local test = require("test")
local funcs = require("funcs")

local HANDLER_ID = "keeper.develop.integrate.handlers:migration_handler"

local function call_handler(args)
    return funcs.new():call(HANDLER_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.integrate.handlers:migration_handler", function()
        test.it("returns empty list for empty entry_ids", function()
            local result, err = call_handler({ operation = "up", entry_ids = {} })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result, 0)
        end)

        test.it("errors when a referenced migration entry does not exist", function()
            -- registry.get on a bogus id returns (nil, err). group_by_target_db
            -- surfaces the error with the failing entry id.
            local result, err = call_handler({
                operation = "up",
                entry_ids = { "app.fake.does_not_exist:01_missing" },
            })
            test.is_nil(result)
            test.not_nil(err)
            test.is_true(err:find("app.fake.does_not_exist:01_missing") ~= nil
                or err:find("Failed to get migration") ~= nil,
                "error should mention the missing migration id")
        end)
    end)
end

return { define_tests = define_tests }
