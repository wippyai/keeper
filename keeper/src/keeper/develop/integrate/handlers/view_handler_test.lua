local test = require("test")
local funcs = require("funcs")
local subject = require("subject")

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

        test.it("reads view path/route from entry.data", function()
            local path, route = subject.__test.view_fields({
                meta = { path = "/meta-wrong.vue", route = "/meta-wrong" },
                data = {
                    path = "frontend/applications/keeper/src/pages/right.vue",
                    route = "/right",
                },
            })
            test.eq(path, "frontend/applications/keeper/src/pages/right.vue")
            test.eq(route, "/right")
        end)

        test.it("can verify local-module frontend files from project root", function()
            test.is_true(subject.__test.file_exists(
                "plugins/git/frontend/applications/git/package.json"
            ))
        end)

        test.it("errors when a referenced view entry does not exist", function()
            local result, err = call_handler({
                operation = "up",
                entry_ids = { "app.fake.view:does_not_exist" },
            })
            test.is_nil(result)
            test.not_nil(err)
            local err_str = tostring(err or "")
            test.is_true(
                err_str:find("app.fake.view:does_not_exist", 1, true) ~= nil or
                err_str:find("Failed to get view entry", 1, true) ~= nil,
                "error should mention the missing view id; got: " .. err_str
            )
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
