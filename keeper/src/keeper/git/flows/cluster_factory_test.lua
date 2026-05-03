local test = require("test")
local cluster_factory = require("cluster_factory")
local consts = require("git_consts")

local function ch(target, op, opts)
    opts = opts or {}
    return {
        change_id = opts.change_id or target,
        target    = target,
        op        = op or "update",
        category  = opts.category or "registry",
        ns_root   = opts.ns_root or (target:match("^([^./:]+)") or "root"),
        namespace = opts.namespace,
        managed_namespace = opts.managed_namespace,
        source    = opts.source,
        added     = opts.added or 0,
        removed   = opts.removed or 0,
        changeset_id = opts.changeset_id,
    }
end

local cases = {
    {
        name = "build returns nil on empty change list",
        fn = function()
            local c = cluster_factory.build({ title = "t", change_ids = {} }, {}, {})
            test.is_nil(c)
        end,
    },
    {
        name = "topic cluster has detectors run, default decision pending",
        fn = function()
            local c = cluster_factory.build(
                { title = "X", plain_summary = "p", change_ids = { "a" } },
                { ch("app.foo:repo", "create", { change_id = "a", added = 5 }) },
                {}
            )
            test.not_nil(c)
            test.eq(c.title, "X")
            test.eq(c.decision, consts.DECISIONS.PENDING)
            test.not_nil(c.recommendations)
            test.eq(c.stats.files, 1)
            test.eq(c.stats.added, 5)
        end,
    },
    {
        name = "topic cluster id uses cl- prefix by default",
        fn = function()
            local c = cluster_factory.build(
                { title = "X", change_ids = { "a" } },
                { ch("app.foo:repo", "update", { change_id = "a" }) },
                {}
            )
            test.is_true(c.id:sub(1, 3) == "cl-")
        end,
    },
    {
        name = "id_prefix override applied",
        fn = function()
            local c = cluster_factory.build(
                { title = "S", change_ids = { "a" } },
                { ch("app.foo:repo", "update", { change_id = "a" }) },
                { id_prefix = "cl-suspect-" }
            )
            test.is_true(c.id:sub(1, 11) == "cl-suspect-")
        end,
    },
    {
        name = "suspect mode skips detector verdict, fixes importance=suspect",
        fn = function()
            local c = cluster_factory.build(
                { title = "Suspect", change_ids = { "a" } },
                { ch("app.scratch:hello", "create", { change_id = "a" }) },
                { suspect = true, skip_detectors = true }
            )
            test.eq(c.importance, consts.IMPORTANCE.SUSPECT)
            test.eq(c.verdict, consts.VERDICTS.CLOSER_LOOK)
            test.is_true(c.is_suspect)
        end,
    },
    {
        name = "suspect mode honors verdict_text override",
        fn = function()
            local c = cluster_factory.build(
                { title = "Suspect", change_ids = { "a" } },
                { ch("app.scratch:foo", "create", { change_id = "a" }) },
                { suspect = true, skip_detectors = true, verdict_text = "Custom" }
            )
            test.eq(c.verdict_text, "Custom")
        end,
    },
    {
        name = "skip_detectors uses extra_recs as the rec list",
        fn = function()
            local c = cluster_factory.build(
                { title = "Z", change_ids = { "a" } },
                { ch("app.foo:repo", "create", { change_id = "a" }) },
                {
                    skip_detectors = true,
                    extra_recs = { { severity = consts.SEVERITY.WARN, text = "hi" } },
                }
            )
            test.eq(#c.recommendations, 1)
            local rec = c.recommendations[1]
            if not rec then error("recommendation missing") end
            test.eq(rec.text, "hi")
            test.eq(rawget(rec, "state"), consts.REC_STATES.OPEN)
        end,
    },
    {
        name = "stats aggregates added/removed across changes",
        fn = function()
            local c = cluster_factory.build(
                { title = "X", change_ids = { "a", "b" } },
                {
                    ch("app.foo:r", "create", { change_id = "a", added = 10, removed = 1 }),
                    ch("app.foo:s", "update", { change_id = "b", added = 3, removed = 7 }),
                },
                {}
            )
            test.eq(c.stats.added, 13)
            test.eq(c.stats.removed, 8)
            test.eq(c.stats.files, 2)
        end,
    },
    {
        name = "stats namespaces are sorted+unique",
        fn = function()
            local c = cluster_factory.build(
                { title = "X", change_ids = { "a", "b", "c" } },
                {
                    ch("wippy.x:y", "update", { change_id = "a", ns_root = "wippy" }),
                    ch("app.x:y",   "update", { change_id = "b", ns_root = "app" }),
                    ch("app.z:y",   "update", { change_id = "c", ns_root = "app" }),
                },
                {}
            )
            test.eq(#c.stats.namespaces, 2)
            test.eq(c.stats.namespaces[1], "app")
            test.eq(c.stats.namespaces[2], "wippy")
        end,
    },
    {
        name = "compact_changes preserves path/op/added/removed",
        fn = function()
            local out = cluster_factory._compact_changes({
                ch("app.foo:repo", "create", {
                    change_id = "a",
                    added = 5,
                    removed = 0,
                    changeset_id = "cs-1",
                    namespace = "app.foo",
                    managed_namespace = true,
                    source = "changeset",
                }),
            })
            test.eq(#out, 1)
            test.eq(out[1].path, "app.foo:repo")
            test.eq(out[1].op, "create")
            test.eq(out[1].added, 5)
            test.eq(out[1].changeset_id, "cs-1")
            test.eq(out[1].namespace, "app.foo")
            test.is_true(out[1].managed_namespace)
        end,
    },
    {
        name = "primary_changeset_id set when single changeset",
        fn = function()
            local change_list = {
                ch("app.foo:r", "update", { change_id = "a" }),
                ch("app.bar:s", "update", { change_id = "b" }),
            }
            change_list[1].changeset_id = "cs-X"
            change_list[2].changeset_id = "cs-X"
            local c = cluster_factory.build(
                { title = "X", change_ids = { "a", "b" } },
                change_list,
                {}
            )
            test.eq(c.primary_changeset_id, "cs-X")
            test.eq(#c.changeset_ids, 1)
            test.is_true(c.pushable)
        end,
    },
    {
        name = "primary_changeset_id nil when multiple changesets",
        fn = function()
            local change_list = {
                ch("app.foo:r", "update", { change_id = "a" }),
                ch("app.bar:s", "update", { change_id = "b" }),
            }
            change_list[1].changeset_id = "cs-X"
            change_list[2].changeset_id = "cs-Y"
            local c = cluster_factory.build(
                { title = "X", change_ids = { "a", "b" } },
                change_list,
                {}
            )
            test.is_nil(c.primary_changeset_id)
            test.eq(#c.changeset_ids, 2)
            test.is_false(c.pushable)
            test.is_true(c.push_blockers[1]:find("spans 2 changesets") ~= nil)
        end,
    },
    {
        name = "stats prefer full namespace over root",
        fn = function()
            local c = cluster_factory.build(
                { title = "X", change_ids = { "a", "b" } },
                {
                    ch("src/app/notes/repo.lua", "update", { change_id = "a", namespace = "app.notes" }),
                    ch("src/app/notes/_index.yaml", "update", { change_id = "b", namespace = "app.notes" }),
                },
                {}
            )
            test.eq(#c.stats.namespaces, 1)
            test.eq(c.stats.namespaces[1], "app.notes")
        end,
    },
    {
        name = "git_scan clusters are review-only even when approved later",
        fn = function()
            local c = cluster_factory.build(
                { title = "X", change_ids = { "a" } },
                {
                    ch("src/keeper/git/flows/git_scan.lua", "update", {
                        change_id = "a",
                        namespace = "keeper.git.flows",
                        managed_namespace = true,
                        source = "git_scan",
                    }),
                },
                {}
            )
            test.is_false(c.pushable)
            test.is_true(c.push_blockers[1]:find("review%-only") ~= nil)
        end,
    },
    {
        name = "refresh_metadata recomputes partial-split source pushability",
        fn = function()
            local c = {
                id = "source",
                change_ids = { "a" },
                changes = {
                    ch("src/app/a.lua", "update", {
                        changeset_id = "cs-A",
                        source = "changeset",
                    }),
                },
                changeset_ids = { "cs-A", "cs-B" },
                primary_changeset_id = nil,
                pushable = false,
                push_blockers = { "cluster spans multiple changesets" },
                recommendations = {},
            }
            cluster_factory.refresh_metadata(c)
            test.eq(#c.changeset_ids, 1)
            test.eq(c.primary_changeset_id, "cs-A")
            test.is_true(c.pushable)
            test.eq(#c.push_blockers, 0)
        end,
    },
}

local function define_tests()
    describe("keeper.git.flows:cluster_factory", function()
        for _, case in ipairs(cases) do it(case.name, case.fn) end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
