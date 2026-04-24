local test = require("test")
local funcs = require("funcs")

local HANDLER_ID = "keeper.develop.integrate.handlers:view_handler"

local function call_handler(args)
    return funcs.new():call(HANDLER_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.integrate.handlers:view_handler", function()
        test.it("returns empty list for empty entry_ids", function()
            local result, err = call_handler({ operation = "up", entry_ids = {} })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result, 0)
        end)

        test.it("errors when a referenced view entry does not exist", function()
            local result, err = call_handler({
                operation = "up",
                entry_ids = { "app.fake.view:does_not_exist" },
            })
            test.is_nil(result)
            test.not_nil(err)
            test.is_true(
                err:find("app.fake.view:does_not_exist") ~= nil
                    or err:find("Failed to get view entry") ~= nil,
                "error should mention the missing view id"
            )
        end)
    end)
end

return { define_tests = define_tests }
