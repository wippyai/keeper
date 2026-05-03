local test = require("test")
local rebuild_flow = require("rebuild_flow")

local function ch(id)
    return {
        change_id = id,
        target = "src/app/" .. id .. ".lua",
        op = "update",
        category = "registry",
        ns_root = "app",
        namespace = "app",
        managed_namespace = true,
        source = "changeset",
        status = "pending",
        added = 0,
        removed = 0,
    }
end

local cases = {
    {
        name = "max change guard accepts changes within limit",
        fn = function()
            local ok, err = rebuild_flow._enforce_max_changes({ ch("a"), ch("b") }, 2)
            test.is_true(ok)
            test.is_nil(err)
        end,
    },
    {
        name = "max change guard rejects oversized rebuilds",
        fn = function()
            local ok, err = rebuild_flow._enforce_max_changes({ ch("a"), ch("b"), ch("c") }, 2)
            test.is_false(ok)
            test.not_nil(err)
            test.is_true(err:find("too many git changes") ~= nil)
        end,
    },
    {
        name = "max change guard can be disabled with non-positive limit",
        fn = function()
            local ok, err = rebuild_flow._enforce_max_changes({ ch("a"), ch("b"), ch("c") }, 0)
            test.is_true(ok)
            test.is_nil(err)
        end,
    },
}

local function define_tests()
    describe("keeper.git.flows:rebuild", function()
        for _, case in ipairs(cases) do it(case.name, case.fn) end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
