local funcs = require("funcs")
local test = require("test")
local subject = require("subject")

local HANDLER_ID = "keeper.develop.integrate.handlers:endpoint_handler"

local function call_handler(args)
    return funcs.new():call(HANDLER_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.integrate.handlers:endpoint_handler", function()
        test.it("returns empty result for empty entry_ids", function()
            local result, err = call_handler({ operation = "up", entry_ids = {} })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result, 0)
        end)

        test.it("down operation returns a record-only row per entry", function()
            local result, err = call_handler({
                operation = "down",
                entry_ids = { "app:nonexistent_endpoint" },
            })
            test.is_nil(err)
            test.eq(#result, 1)
            test.is_true(result[1].success)
            test.eq(result[1].data.status, "noop")
        end)

        test.it("reads endpoint method/path from entry.data and applies router prefix", function()
            local method, path = subject.__test.endpoint_url({
                kind = "http.endpoint",
                method = "DELETE",
                path = "/top-level-wrong",
                meta = { method = "PATCH", path = "/meta-wrong" },
                data = { method = "post", path = "/data-right/{id}" },
            }, {
                kind = "http.router",
                prefix = "/top-level-wrong",
                data = { prefix = "/api/v1/" },
            })
            test.eq(method, "POST")
            test.eq(path, "/api/v1/data-right/__probe__")
        end)

        test.it("does not double-prefix paths that already include the router prefix", function()
            local method, path = subject.__test.endpoint_url({
                data = { method = "GET", path = "/api/v1/data-right" },
            }, {
                data = { prefix = "/api/v1/" },
            })
            test.eq(method, "GET")
            test.eq(path, "/api/v1/data-right")
        end)

        test.it("parses status from test_endpoint string output", function()
            local status = subject.__test.parse_status("GET /api/v1/probe -> 204\nContent-Type: application/json")
            test.eq(status, 204)
        end)

        test.it("surfaces a structured error when the entry cannot be loaded", function()
            local result, err = call_handler({
                operation = "up",
                entry_ids = { "nope:does_not_exist" },
            })
            test.is_nil(result)
            test.not_nil(err)
            local err_str = tostring(err or "")
            test.is_true(err_str:find("endpoint_handler", 1, true) ~= nil or
                err_str:find("nope:does_not_exist", 1, true) ~= nil,
                "error should mention handler or missing id; got: " .. err_str)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
