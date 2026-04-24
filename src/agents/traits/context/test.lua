local test = require("test")
local endpoints = require("endpoints")
local migrations = require("migrations")
local frontend = require("frontend")

local function define_tests()
    describe("Context Tree Traits", function()

        describe("frontend_aware tree", function()
            it("returns non-empty tree with header", function()
                local output = frontend.handler()
                test.not_nil(output)
                test.is_true(type(output) == "string")
                test.is_true(#output > 0)
                test.is_true(output:find("FRONTEND TREE") ~= nil, "header missing")
            end)

            it("lists routes and pages", function()
                local output = frontend.handler()
                test.is_true(output:find("Routes") ~= nil, "Routes section missing")
                test.is_true(output:find("Pages") ~= nil, "Pages section missing")
                test.is_true(output:find("%.vue") ~= nil, "expected at least one .vue file")
            end)
        end)

        describe("endpoints_aware tree", function()
            it("returns non-empty tree with routers and endpoints", function()
                local output = endpoints.handler()
                test.not_nil(output)
                test.is_true(type(output) == "string")
                test.is_true(#output > 0)
                test.is_true(output:find("HTTP ENDPOINTS") ~= nil, "header missing")
            end)

            it("includes at least one known router and endpoint", function()
                local output = endpoints.handler()
                test.is_true(
                    output:find("%.api[^%s]*:[^%s]+%.endpoint") ~= nil or
                    output:find("api:") ~= nil,
                    "expected at least one api endpoint entry"
                )
            end)
        end)

        describe("migrations_aware tree", function()
            it("returns non-empty tree with databases and migrations", function()
                local output = migrations.handler()
                test.not_nil(output)
                test.is_true(type(output) == "string")
                test.is_true(#output > 0)
                test.is_true(output:find("DATABASE MIGRATIONS TREE") ~= nil, "header missing")
            end)

            it("lists APPLIED / PENDING status for at least one migration", function()
                local output = migrations.handler()
                local has_status = output:find("Status: APPLIED") ~= nil
                    or output:find("Status: PENDING") ~= nil
                    or output:find("Status: UNKNOWN") ~= nil
                test.is_true(has_status, "expected at least one migration status line")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
