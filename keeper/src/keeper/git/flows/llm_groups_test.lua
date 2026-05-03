local test = require("test")
local llm_groups = require("llm_groups")

local CLUSTERS_OPTS = {
    root_key         = "clusters",
    fallback_title   = "Misc",
    fallback_summary = "Changes the clusterer didn't fit into a named topic.",
}
local GROUPS_OPTS = {
    root_key         = "groups",
    fallback_title   = "Remaining",
    fallback_summary = "Files the suggester did not place in a named group",
}

local cases = {
    {
        name = "parse strips markdown fences (clusters key)",
        fn = function()
            local raw = '```json\n{"clusters":[{"title":"X","change_ids":["a"]}]}\n```'
            local out, err = llm_groups.parse(raw, CLUSTERS_OPTS)
            test.is_nil(err)
            test.eq(out.clusters[1].title, "X")
        end,
    },
    {
        name = "parse strips markdown fences (groups key)",
        fn = function()
            local raw = '```json\n{"groups":[{"title":"G","change_ids":["a"]}]}\n```'
            local out, err = llm_groups.parse(raw, GROUPS_OPTS)
            test.is_nil(err)
            test.eq(out.groups[1].title, "G")
        end,
    },
    {
        name = "parse rejects empty input",
        fn = function()
            local out, err = llm_groups.parse("", CLUSTERS_OPTS)
            test.is_nil(out)
            test.not_nil(err)
        end,
    },
    {
        name = "parse rejects shape missing root key",
        fn = function()
            local out, err = llm_groups.parse('{"foo":1}', CLUSTERS_OPTS)
            test.is_nil(out)
            test.not_nil(err)
        end,
    },
    {
        name = "validate preserves valid groups",
        fn = function()
            local out, err = llm_groups.validate(
                { clusters = { { title = "X", change_ids = { "a", "b" } } } },
                { "a", "b" }, CLUSTERS_OPTS
            )
            test.is_nil(err)
            test.eq(#out, 1)
            test.eq(#out[1].change_ids, 2)
        end,
    },
    {
        name = "validate drops hallucinated change_ids",
        fn = function()
            local out, err = llm_groups.validate(
                { clusters = { { title = "X", change_ids = { "a", "ghost" } } } },
                { "a" }, CLUSTERS_OPTS
            )
            test.is_nil(err)
            test.eq(#out[1].change_ids, 1)
            test.eq(out[1].change_ids[1], "a")
        end,
    },
    {
        name = "validate drops duplicate assignments across groups",
        fn = function()
            local out, err = llm_groups.validate(
                { clusters = {
                    { title = "X", change_ids = { "a" } },
                    { title = "Y", change_ids = { "a", "b" } },
                } },
                { "a", "b" }, CLUSTERS_OPTS
            )
            test.is_nil(err)
            test.eq(out[1].change_ids[1], "a")
            test.eq(out[2].change_ids[1], "b")
        end,
    },
    {
        name = "validate appends Misc fallback for unassigned",
        fn = function()
            local out, err = llm_groups.validate(
                { clusters = { { title = "X", change_ids = { "a" } } } },
                { "a", "b", "c" }, CLUSTERS_OPTS
            )
            test.is_nil(err)
            test.eq(#out, 2)
            test.eq(out[2].title, "Misc")
            test.eq(#out[2].change_ids, 2)
        end,
    },
    {
        name = "validate appends Remaining fallback for unassigned (groups variant)",
        fn = function()
            local out, err = llm_groups.validate(
                { groups = { { title = "G1", change_ids = { "a" } } } },
                { "a", "b" }, GROUPS_OPTS
            )
            test.is_nil(err)
            test.eq(#out, 2)
            test.eq(out[2].title, "Remaining")
        end,
    },
    {
        name = "validate rejects entry missing title",
        fn = function()
            local out, err = llm_groups.validate(
                { clusters = { { change_ids = { "a" } } } },
                { "a" }, CLUSTERS_OPTS
            )
            test.is_nil(out)
            test.not_nil(err)
        end,
    },
    {
        name = "validate rejects entry with empty change_ids",
        fn = function()
            local out, err = llm_groups.validate(
                { clusters = { { title = "X", change_ids = {} } } },
                { "a" }, CLUSTERS_OPTS
            )
            test.is_nil(out)
            test.not_nil(err)
        end,
    },
}

local function define_tests()
    describe("keeper.git.flows:llm_groups", function()
        for _, case in ipairs(cases) do it(case.name, case.fn) end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
