local test = require("test")
local clusterer = require("clusterer")

local cases = {
    {
        name = "build_user_prompt enumerates every change",
        fn = function()
            local out = clusterer._build_user_prompt({
                { change_id = "x1", op = "create", category = "registry", target = "app.foo:bar" },
                { change_id = "x2", op = "update", category = "filesystem", target = "frontend/x.vue" },
            })
            test.is_true(out:find("x1") ~= nil)
            test.is_true(out:find("x2") ~= nil)
            test.is_true(out:find("app.foo:bar") ~= nil)
        end,
    },
}

local function define_tests()
    describe("keeper.git.flows:clusterer", function()
        for _, case in ipairs(cases) do
            it(case.name, case.fn)
        end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
