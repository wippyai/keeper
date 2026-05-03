local test = require("test")
local split_lib = require("split_lib")

local function cluster(opts)
    opts = opts or {}
    return {
        id = "cl-X",
        change_ids = opts.change_ids or {},
        changes    = opts.changes or {},
    }
end

local function chf(path, change_id)
    return { change_id = change_id or path, path = path, op = "update" }
end

local cases = {
    -- ── propose_by_prefix ──────────────────────────────────────────────
    {
        name = "propose_by_prefix groups by N first segments",
        fn = function()
            local c = cluster({
                change_ids = { "a", "b", "c" },
                changes = {
                    chf("src/keeper/git/x.lua", "a"),
                    chf("src/keeper/state/y.lua", "b"),
                    chf("src/app/z.lua", "c"),
                },
            })
            local groups = split_lib.propose_by_prefix(c, 2)
            test.eq(#groups, 2)
            local sizes = {}
            for _, g in ipairs(groups) do sizes[g.title] = #g.change_ids end
            test.eq(sizes["src/keeper/"], 2)
            test.eq(sizes["src/app/"], 1)
        end,
    },
    {
        name = "propose_by_prefix at depth 3 splits keeper sub-modules",
        fn = function()
            local c = cluster({
                change_ids = { "a", "b" },
                changes = {
                    chf("src/keeper/git/x.lua", "a"),
                    chf("src/keeper/state/y.lua", "b"),
                },
            })
            local groups = split_lib.propose_by_prefix(c, 3)
            test.eq(#groups, 2)
        end,
    },
    {
        name = "propose_by_prefix sorts groups by descending size",
        fn = function()
            local c = cluster({
                change_ids = { "a", "b", "c" },
                changes = {
                    chf("src/big/x.lua", "a"),
                    chf("src/big/y.lua", "b"),
                    chf("src/small/z.lua", "c"),
                },
            })
            local groups = split_lib.propose_by_prefix(c, 2)
            test.eq(groups[1].title, "src/big/")
            test.eq(#groups[1].change_ids, 2)
        end,
    },
    -- ── propose_by_kind ────────────────────────────────────────────────
    {
        name = "propose_by_kind buckets migrations / tests / yaml / vue / lua / other",
        fn = function()
            local c = cluster({
                change_ids = { "m", "t", "y", "v", "l", "o" },
                changes = {
                    chf("src/keeper/migrations/01_x.lua", "m"),
                    chf("src/keeper/x_test.lua", "t"),
                    chf("src/keeper/_index.yaml", "y"),
                    chf("frontend/keeper/page.vue", "v"),
                    chf("src/keeper/lib.lua", "l"),
                    chf("README.md", "o"),
                },
            })
            local groups = split_lib.propose_by_kind(c)
            local titles = {}
            for _, g in ipairs(groups) do titles[g.title] = #g.change_ids end
            test.eq(titles["Migrations"], 1)
            test.eq(titles["Tests"], 1)
            test.eq(titles["Registry _index.yaml"], 1)
            test.eq(titles["Frontend"], 1)
            test.eq(titles["Lua source"], 1)
            test.eq(titles["Other"], 1)
        end,
    },
    -- ── validate_groups ────────────────────────────────────────────────
    {
        name = "validate_groups accepts well-formed split",
        fn = function()
            local c = cluster({
                change_ids = { "a", "b", "c" },
                changes = { chf("x", "a"), chf("y", "b"), chf("z", "c") },
            })
            local ok, err = split_lib.validate_groups(c, {
                { title = "G1", change_ids = { "a" } },
                { title = "G2", change_ids = { "b", "c" } },
            })
            test.is_true(ok)
            test.is_nil(err)
        end,
    },
    {
        name = "validate_groups rejects unknown change_id",
        fn = function()
            local c = cluster({
                change_ids = { "a" },
                changes = { chf("x", "a") },
            })
            local ok, err = split_lib.validate_groups(c, {
                { title = "G1", change_ids = { "ghost" } },
            })
            test.is_false(ok)
            test.is_true(err:find("not in source") ~= nil)
        end,
    },
    {
        name = "validate_groups rejects duplicate assignment across groups",
        fn = function()
            local c = cluster({
                change_ids = { "a", "b" },
                changes = { chf("x", "a"), chf("y", "b") },
            })
            local ok, err = split_lib.validate_groups(c, {
                { title = "G1", change_ids = { "a" } },
                { title = "G2", change_ids = { "a" } },  -- duplicate
            })
            test.is_false(ok)
        end,
    },
    {
        name = "validate_groups rejects empty group",
        fn = function()
            local c = cluster({ change_ids = { "a" }, changes = { chf("x", "a") } })
            local ok, err = split_lib.validate_groups(c, {
                { title = "Empty", change_ids = {} },
            })
            test.is_false(ok)
        end,
    },
    {
        name = "validate_groups rejects missing title",
        fn = function()
            local c = cluster({ change_ids = { "a" }, changes = { chf("x", "a") } })
            local ok, err = split_lib.validate_groups(c, {
                { change_ids = { "a" } },
            })
            test.is_false(ok)
        end,
    },
    {
        name = "validate_groups rejects too many groups",
        fn = function()
            local c = cluster({ change_ids = { "a" }, changes = { chf("x", "a") } })
            local groups = {}
            for i = 1, 21 do
                table.insert(groups, { title = "G" .. i, change_ids = { "a" } })
            end
            local ok = split_lib.validate_groups(c, groups)
            test.is_false(ok)
        end,
    },
    -- ── apply_split ────────────────────────────────────────────────────
    {
        name = "apply_split removes consumed ids from source",
        fn = function()
            local snap = {
                clusters = {
                    src = {
                        id = "src",
                        change_ids = { "a", "b", "c" },
                        changes = { chf("x", "a"), chf("y", "b"), chf("z", "c") },
                    },
                },
                cluster_order = { "src" },
            }
            local count = 0
            local result, err = split_lib.apply_split(snap, "src", {
                { title = "G1", change_ids = { "a" } },
            }, function(g, ch_list)
                count = count + 1
                return { id = "new-" .. count, change_ids = g.change_ids, changes = ch_list }
            end)
            test.is_nil(err)
            test.eq(#snap.clusters["src"].change_ids, 2)
            test.eq(#result.new_cluster_ids, 1)
            test.is_false(result.removed_source)
        end,
    },
    {
        name = "apply_split removes source when fully consumed",
        fn = function()
            local snap = {
                clusters = {
                    src = {
                        id = "src",
                        change_ids = { "a", "b" },
                        changes = { chf("x", "a"), chf("y", "b") },
                    },
                },
                cluster_order = { "src" },
            }
            local result, err = split_lib.apply_split(snap, "src", {
                { title = "G1", change_ids = { "a" } },
                { title = "G2", change_ids = { "b" } },
            }, function(g, ch_list)
                return { id = "new-" .. g.title, change_ids = g.change_ids, changes = ch_list }
            end)
            test.is_nil(err)
            test.is_nil(snap.clusters["src"])
            test.is_true(result.removed_source)
            test.eq(#snap.cluster_order, 2)  -- two new, source dropped
        end,
    },
    {
        name = "apply_split rejects unknown source cluster",
        fn = function()
            local snap = { clusters = {}, cluster_order = {} }
            local result, err = split_lib.apply_split(snap, "ghost", { { title = "G", change_ids = {} } }, function() end)
            test.is_nil(result)
            test.not_nil(err)
        end,
    },
}

local function define_tests()
    describe("keeper.git.flows:split", function()
        for _, case in ipairs(cases) do it(case.name, case.fn) end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
