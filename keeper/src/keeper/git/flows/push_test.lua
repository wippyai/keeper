-- Pure tests for push_flow validation paths. Tests that exercise the
-- keeper.state.tools:push call live in the integration suite (push_test
-- under keeper.git.test) since funcs.new() is a runtime-only construct.

local test = require("test")
local push_flow = require("push_flow")
local consts = require("git_consts")

local cases = {
    {
        name = "push_cluster requires approved decision",
        fn = function()
            local res, err = push_flow.push_cluster({
                decision = consts.DECISIONS.PENDING,
                primary_changeset_id = "cs1",
            })
            test.is_nil(res)
            test.not_nil(err)
            test.is_true(err:find("not approved") ~= nil)
        end,
    },
    {
        name = "push_cluster rejects nil cluster",
        fn = function()
            local res, err = push_flow.push_cluster(nil)
            test.is_nil(res)
            test.not_nil(err)
        end,
    },
    {
        name = "push_cluster fails on multi-changeset cluster",
        fn = function()
            local res, err = push_flow.push_cluster({
                decision = consts.DECISIONS.APPROVED,
                primary_changeset_id = nil,
                changeset_ids = { "cs1", "cs2" },
            })
            test.is_nil(res)
            test.not_nil(err)
            test.is_true(err:find("split first") ~= nil)
        end,
    },
    {
        name = "push_cluster fails when no changeset_id resolvable",
        fn = function()
            local res, err = push_flow.push_cluster({
                decision = consts.DECISIONS.APPROVED,
                primary_changeset_id = nil,
                changeset_ids = {},
            })
            test.is_nil(res)
            test.not_nil(err)
            test.is_true(err:find("no resolvable") ~= nil)
        end,
    },
    {
        name = "push_cluster rejects git_scan review-only clusters",
        fn = function()
            local res, err = push_flow.push_cluster({
                decision = consts.DECISIONS.APPROVED,
                source = "git_scan",
                changes = {
                    { change_id = "a", category = "registry", managed_namespace = true },
                },
            })
            test.is_nil(res)
            test.not_nil(err)
            test.is_true(err:find("review%-only") ~= nil)
        end,
    },
    {
        name = "push_cluster rejects unmanaged registry namespace",
        fn = function()
            local res, err = push_flow.push_cluster({
                decision = consts.DECISIONS.APPROVED,
                primary_changeset_id = "cs1",
                changeset_ids = { "cs1" },
                changes = {
                    { change_id = "a", category = "registry", managed_namespace = false },
                },
            })
            test.is_nil(res)
            test.not_nil(err)
            test.is_true(err:find("unmanaged") ~= nil)
        end,
    },
    {
        name = "push_cluster rejects open blocking recommendations",
        fn = function()
            local res, err = push_flow.push_cluster({
                decision = consts.DECISIONS.APPROVED,
                primary_changeset_id = "cs1",
                changeset_ids = { "cs1" },
                recommendations = {
                    { severity = consts.SEVERITY.BLOCK, state = consts.REC_STATES.OPEN },
                },
            })
            test.is_nil(res)
            test.not_nil(err)
            test.is_true(err:find("blocking") ~= nil)
        end,
    },
    {
        name = "push_cluster allows fixed blocking recommendations",
        fn = function()
            local blockers = push_flow.push_blockers({
                decision = consts.DECISIONS.APPROVED,
                primary_changeset_id = "cs1",
                changeset_ids = { "cs1" },
                recommendations = {
                    { severity = consts.SEVERITY.BLOCK, state = consts.REC_STATES.FIXED },
                },
            })
            test.eq(#blockers, 0)
        end,
    },
    {
        name = "plan_cluster returns non-mutating publish plan for approved cluster",
        fn = function()
            local plan = push_flow.plan_cluster({
                id = "cl1",
                title = "app.notes",
                decision = consts.DECISIONS.APPROVED,
                verdict = consts.VERDICTS.READY,
                source = "changeset",
                primary_changeset_id = "cs1",
                changeset_ids = { "cs1" },
                changes = {
                    { change_id = "a", category = "registry", managed_namespace = true },
                },
                stats = { files = 1, namespaces = { "app.notes" }, added = 10, removed = 2 },
            }, "ship notes")
            test.is_true(plan.ok)
            test.is_true(plan.pushable)
            test.is_true(plan.approved)
            test.eq(plan.branch, "ws/cs1")
            test.eq(plan.message, "ship notes")
            test.eq(plan.stats.files, 1)
            test.eq(plan.stats.namespaces[1], "app.notes")
            test.eq(#plan.blockers, 0)
        end,
    },
    {
        name = "plan_cluster reports both approval and push blockers",
        fn = function()
            local plan = push_flow.plan_cluster({
                id = "cl1",
                decision = consts.DECISIONS.PENDING,
                source = "git_scan",
                changes = {
                    { change_id = "a", category = "registry", managed_namespace = true },
                },
            })
            test.is_false(plan.ok)
            test.is_false(plan.pushable)
            test.is_false(plan.approved)
            test.is_true(plan.blockers[1]:find("not approved") ~= nil)
            test.is_true(plan.blockers[2]:find("review%-only") ~= nil)
        end,
    },
    {
        name = "push_many dry_run does not invoke mark_pushed",
        fn = function()
            local marked = 0
            local res = push_flow.push_many(
                {
                    a = {
                        id = "a",
                        decision = consts.DECISIONS.APPROVED,
                        source = "changeset",
                        primary_changeset_id = "csA",
                        changeset_ids = { "csA" },
                        changes = {
                            { change_id = "x", category = "registry", managed_namespace = true },
                        },
                    },
                },
                { "a" },
                "dry run",
                function() marked = marked + 1 end,
                { dry_run = true }
            )
            test.is_true(res.ok)
            test.is_true(res.dry_run)
            test.eq(res.pushed, 0)
            test.eq(res.failed, 0)
            test.eq(marked, 0)
            test.eq(res.results[1].branch, "ws/csA")
        end,
    },
    {
        name = "push_many returns ghost-id failures without invoking funcs",
        fn = function()
            local res = push_flow.push_many(
                {
                    a = { decision = consts.DECISIONS.PENDING,  primary_changeset_id = "csA" },
                    b = { decision = consts.DECISIONS.APPROVED, primary_changeset_id = nil,
                          changeset_ids = { "x", "y" } },
                },
                { "a", "b", "ghost" },
                nil,
                function() end
            )
            test.eq(res.pushed, 0)
            test.eq(res.failed, 3)
            test.is_false(res.ok)
            -- ghost gets a clear "unknown cluster_id" error
            local ghost_err = nil
            for _, r in ipairs(res.results) do
                if r.cluster_id == "ghost" then ghost_err = r.error end
            end
            test.not_nil(ghost_err)
            test.is_true(ghost_err:find("unknown") ~= nil)
        end,
    },
    {
        name = "push_many handles empty cluster_ids list",
        fn = function()
            local res = push_flow.push_many({}, {}, nil, function() end)
            test.eq(res.pushed, 0)
            test.eq(res.failed, 0)
            test.is_true(res.ok)
        end,
    },
}

local function define_tests()
    describe("keeper.git.flows:push", function()
        for _, case in ipairs(cases) do
            it(case.name, case.fn)
        end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
