local test = require("test")
local linter = require("linter")

local function define_tests()
    describe("HIL linter", function()
        describe("input validation", function()
            it("rejects a nil request", function()
                local result = linter.handle(nil)
                test.not_nil(result)
                test.is_false(result.success)
                test.eq(result.issues[1].code, "INVALID_INPUT")
                test.is_true(result.message:find("Invalid input") ~= nil)
            end)
        end)

        describe("pass-through", function()
            it("returns the changeset unchanged when options.request_hil is nil", function()
                local cs = { { id = "a:one", op = "create" }, { id = "a:two", op = "update" } }
                local result = linter.handle({ changeset = cs, options = {} })
                test.is_true(result.success)
                test.eq(#result.changeset, 2)
                test.eq(result.changeset[1].id, "a:one")
                test.eq(#result.issues, 0)
                test.is_true(result.message:find("HIL not requested") ~= nil)
            end)

            it("treats a missing options table as pass-through", function()
                local result = linter.handle({ changeset = { { id = "a:one" } } })
                test.is_true(result.success)
                test.eq(#result.changeset, 1)
            end)

            it("treats options.request_hil=false as pass-through", function()
                local result = linter.handle({
                    changeset = {},
                    options = { request_hil = false },
                })
                test.is_true(result.success)
            end)
        end)

        describe("HIL requested without session", function()
            it("fails with HIL_NO_SESSION when session_id is missing", function()
                local result = linter.handle({
                    changeset = { { id = "a:one" } },
                    options   = { request_hil = true },
                })
                test.is_false(result.success)
                test.eq(#result.changeset, 0, "rejected changesets must be empty")
                test.eq(result.issues[1].code, "HIL_NO_SESSION")
                test.eq(result.issues[1].level, "error")
            end)

            it("fails with HIL_NO_SESSION when session_id is empty string", function()
                local result = linter.handle({
                    changeset = {},
                    options   = { request_hil = true, session_id = "" },
                })
                test.is_false(result.success)
                test.eq(result.issues[1].code, "HIL_NO_SESSION")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
