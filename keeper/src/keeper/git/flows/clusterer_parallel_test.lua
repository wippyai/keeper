local test = require("test")
local cp = require("clusterer_parallel")

local function ch(target)
    return { change_id = target, target = target, op = "update", category = "registry" }
end

local cases = {
    {
        name = "path_prefix returns root/ for empty path",
        fn = function() test.eq(cp._path_prefix("", 2), "root/") end,
    },
    {
        name = "path_prefix returns full path when fewer segments than depth",
        fn = function() test.eq(cp._path_prefix("a", 3), "a/") end,
    },
    {
        name = "path_prefix at depth 2 truncates correctly",
        fn = function()
            test.eq(cp._path_prefix("src/keeper/git/_index.yaml", 2), "src/keeper/")
            test.eq(cp._path_prefix("frontend/applications/keeper/src/x.vue", 2), "frontend/applications/")
        end,
    },
    {
        name = "path_prefix at depth 3 deeper",
        fn = function()
            test.eq(cp._path_prefix("src/keeper/git/_index.yaml", 3), "src/keeper/git/")
        end,
    },
    {
        name = "partition groups by 2nd-level prefix",
        fn = function()
            local out = cp._partition({
                ch("src/keeper/a.lua"),
                ch("src/keeper/b.lua"),
                ch("src/app/c.lua"),
                ch("frontend/applications/x.vue"),
            })
            test.eq(#out, 3)
            local keys = {}
            for _, b in ipairs(out) do keys[b.key] = #b.items end
            test.eq(keys["src/keeper/"], 2)
            test.eq(keys["src/app/"], 1)
            test.eq(keys["frontend/applications/"], 1)
        end,
    },
    {
        name = "partition recurses on oversized buckets",
        fn = function()
            -- 300 files in src/keeper/<sub>/... where sub varies — exceeds SOFT_LIMIT
            local list = {}
            for i = 1, cp.SOFT_LIMIT + 50 do
                local sub = (i % 3 == 0) and "git" or (i % 3 == 1) and "state" or "agents"
                table.insert(list, ch(("src/keeper/%s/file%d.lua"):format(sub, i)))
            end
            local out = cp._partition(list)
            -- Top-level bucket "src/keeper/" exceeded SOFT_LIMIT, so recursed → 3+ deeper buckets
            test.is_true(#out >= 2)
            for _, b in ipairs(out) do
                test.is_true(#b.items <= cp.SOFT_LIMIT)
            end
        end,
    },
    {
        name = "partition caps recursion at max_depth",
        fn = function()
            -- Even with 300 files all sharing the same long path, recursion stops at depth 5.
            local list = {}
            for i = 1, 300 do
                table.insert(list, ch(("a/b/c/d/e/file%d.lua"):format(i)))
            end
            local out = cp._partition(list, 2, 5)
            -- All files share prefix; partition can't split further → one bucket at max_depth
            test.eq(#out, 1)
            test.eq(#out[1].items, 300)
        end,
    },
    {
        name = "run with empty input returns ok+empty",
        fn = function()
            local r = cp.run({}, {})
            test.is_true(r.ok)
            test.eq(#r.clusters, 0)
        end,
    },
}

local function define_tests()
    describe("keeper.git.flows:clusterer_parallel", function()
        for _, case in ipairs(cases) do it(case.name, case.fn) end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
