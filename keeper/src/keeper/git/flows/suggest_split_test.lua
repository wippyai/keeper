local test = require("test")
local ssf = require("suggest_split_flow")

local cases = {
    {
        name = "build_user_prompt enumerates every change",
        fn = function()
            local p = ssf._build_user_prompt({
                title = "T", plain_summary = "P",
                changes = {
                    { change_id = "x1", op = "create", path = "app.foo:bar" },
                    { change_id = "x2", op = "update", path = "app.foo:baz" },
                },
            })
            test.is_true(p:find("x1") ~= nil)
            test.is_true(p:find("x2") ~= nil)
            test.is_true(p:find("app.foo:bar") ~= nil)
        end,
    },
}

local function define_tests()
    describe("keeper.git.flows:suggest_split", function()
        for _, case in ipairs(cases) do it(case.name, case.fn) end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
