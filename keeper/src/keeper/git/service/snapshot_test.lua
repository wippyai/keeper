local test = require("test")
local snapshot = require("snapshot_lib")
local consts = require("git_consts")

local function make_snap()
    return {
        run_id = "r1",
        built_at = "2026-04-27T00:00:00Z",
        journal_size_at_build = 100,
        ai_model = "sonnet",
        clusters = {
            ["c1"] = {
                id = "c1", title = "Audit fix", plain_summary = "...",
                importance = consts.IMPORTANCE.CRITICAL,
                verdict = consts.VERDICTS.CLOSER_LOOK, verdict_text = "...",
                decision = consts.DECISIONS.PENDING,
                change_ids = { "ch1", "ch2" },
                recommendations = {
                    { id = "r1", severity = consts.SEVERITY.WARN, text = "x", state = consts.REC_STATES.OPEN },
                    { id = "r2", severity = consts.SEVERITY.INFO, text = "y", state = consts.REC_STATES.OPEN },
                },
                stats = { added = 10, removed = 2, namespaces = { "app" }, files = 2 },
            },
            ["c2"] = {
                id = "c2", title = "Cleanup", plain_summary = "...",
                importance = consts.IMPORTANCE.CLEANUP,
                verdict = consts.VERDICTS.READY, verdict_text = "...",
                decision = consts.DECISIONS.PENDING,
                change_ids = { "ch3" },
                recommendations = {},
                stats = { added = 1, removed = 0, namespaces = { "wippy" }, files = 1 },
            },
            ["c3"] = {
                id = "c3", title = "Big refactor", plain_summary = "...",
                importance = consts.IMPORTANCE.HIGH,
                verdict = consts.VERDICTS.READY, verdict_text = "...",
                decision = consts.DECISIONS.APPROVED,
                change_ids = { "ch4" },
                changeset_ids = { "cs-3" },
                primary_changeset_id = "cs-3",
                pushable = true,
                recommendations = {},
                stats = { added = 5, removed = 5, namespaces = { "keeper" }, files = 1 },
            },
        },
        cluster_order = { "c1", "c2", "c3" },
        orphans = {},
    }
end

local cases = {
    {
        name = "empty() returns clean shape",
        fn = function()
            local s = snapshot.empty()
            test.is_true(snapshot.is_empty(s))
            test.eq(#s.cluster_order, 0)
            test.eq(#s.orphans, 0)
        end,
    },
    {
        name = "is_empty distinguishes filled snapshots",
        fn = function()
            test.is_true(snapshot.is_empty(snapshot.empty()))
            test.is_false(snapshot.is_empty(make_snap()))
        end,
    },
    {
        name = "reorder sorts pending first, then critical-before-cleanup",
        fn = function()
            local s = make_snap()
            snapshot.reorder(s)
            -- Pending clusters first (c1 critical, c2 cleanup), approved (c3) last
            test.eq(s.cluster_order[1], "c1")
            test.eq(s.cluster_order[2], "c2")
            test.eq(s.cluster_order[3], "c3")
        end,
    },
    {
        name = "set_decision moves cluster + reorders",
        fn = function()
            local s = make_snap()
            local ok, err = snapshot.set_decision(s, "c1", consts.DECISIONS.APPROVED)
            test.is_true(ok)
            test.is_nil(err)
            test.eq(s.clusters["c1"].decision, consts.DECISIONS.APPROVED)
            -- After moving c1 to approved, c2 (still pending, cleanup) is first
            test.eq(s.cluster_order[1], "c2")
        end,
    },
    {
        name = "set_decision unknown cluster returns error",
        fn = function()
            local s = make_snap()
            local ok, err = snapshot.set_decision(s, "nope", consts.DECISIONS.APPROVED)
            test.is_false(ok)
            test.not_nil(err)
        end,
    },
    {
        name = "set_decision rejects invalid decision values",
        fn = function()
            local s = make_snap()
            local ok, err = snapshot.set_decision(s, "c1", "split")
            test.is_false(ok)
            test.not_nil(err)
            test.eq(s.clusters["c1"].decision, consts.DECISIONS.PENDING)
        end,
    },
    {
        name = "update_recommendation flips state",
        fn = function()
            local s = make_snap()
            local ok, err = snapshot.update_recommendation(s, "c1", "r1", consts.REC_STATES.ACKNOWLEDGED)
            test.is_true(ok)
            test.is_nil(err)
            test.eq(s.clusters["c1"].recommendations[1].state, consts.REC_STATES.ACKNOWLEDGED)
        end,
    },
    {
        name = "update_recommendation unknown rec returns error",
        fn = function()
            local s = make_snap()
            local ok, err = snapshot.update_recommendation(s, "c1", "ghost", consts.REC_STATES.FIXED)
            test.is_false(ok)
            test.not_nil(err)
        end,
    },
    {
        name = "update_recommendation rejects invalid states",
        fn = function()
            local s = make_snap()
            local ok, err = snapshot.update_recommendation(s, "c1", "r1", "done-ish")
            test.is_false(ok)
            test.not_nil(err)
            test.eq(s.clusters["c1"].recommendations[1].state, consts.REC_STATES.OPEN)
        end,
    },
    {
        name = "to_summary on empty snapshot returns zero counts",
        fn = function()
            local out = snapshot.to_summary(snapshot.empty())
            test.eq(out.counts.all, 0)
            test.eq(out.counts.pending, 0)
            test.eq(out.counts.ready, 0)
            test.eq(out.counts.pushable_ready, 0)
            test.is_nil(out.run_id)
        end,
    },
    {
        name = "to_summary aggregates counts by decision",
        fn = function()
            local s = make_snap()
            snapshot.reorder(s)
            local out = snapshot.to_summary(s)
            test.eq(out.counts.all, 3)
            test.eq(out.counts.pending, 2)
            test.eq(out.counts.ready, 1)
            test.eq(out.counts.pushable_ready, 1)
            test.eq(out.counts.blocked_ready, 0)
            test.eq(out.counts.hidden, 0)
            test.eq(out.run_id, "r1")
        end,
    },
    {
        name = "to_summary separates approved review-only clusters from pushable ready",
        fn = function()
            local s = make_snap()
            s.clusters["c3"].source = "git_scan"
            local out = snapshot.to_summary(s)
            test.eq(out.counts.ready, 1)
            test.eq(out.counts.pushable_ready, 0)
            test.eq(out.counts.blocked_ready, 1)
            local c3 = nil
            for _, c in ipairs(out.clusters) do if c.id == "c3" then c3 = c end end
            test.is_false(c3.pushable)
            test.is_true(c3.push_blockers[1]:find("review%-only") ~= nil)
        end,
    },
    {
        name = "to_summary blocks approved clusters with open blocking recommendation",
        fn = function()
            local s = make_snap()
            s.clusters["c3"].recommendations = {
                { id = "block", severity = consts.SEVERITY.BLOCK, state = consts.REC_STATES.OPEN },
            }
            local out = snapshot.to_summary(s)
            test.eq(out.counts.ready, 1)
            test.eq(out.counts.pushable_ready, 0)
            test.eq(out.counts.blocked_ready, 1)
        end,
    },
    {
        name = "to_summary reopens pushability when blocking recommendation is fixed",
        fn = function()
            local s = make_snap()
            s.clusters["c3"].recommendations = {
                { id = "block", severity = consts.SEVERITY.BLOCK, state = consts.REC_STATES.FIXED },
            }
            local out = snapshot.to_summary(s)
            test.eq(out.counts.pushable_ready, 1)
            test.eq(out.counts.blocked_ready, 0)
        end,
    },
    {
        name = "to_summary reports rec_open count per cluster",
        fn = function()
            local s = make_snap()
            snapshot.reorder(s)
            local out = snapshot.to_summary(s)
            local c1 = nil
            for _, c in ipairs(out.clusters) do if c.id == "c1" then c1 = c end end
            test.not_nil(c1)
            test.eq(c1.rec_open, 2)
        end,
    },
    {
        name = "to_summary respects acknowledged state in rec_open count",
        fn = function()
            local s = make_snap()
            snapshot.update_recommendation(s, "c1", "r1", consts.REC_STATES.FIXED)
            snapshot.reorder(s)
            local out = snapshot.to_summary(s)
            local c1 = nil
            for _, c in ipairs(out.clusters) do if c.id == "c1" then c1 = c end end
            test.eq(c1.rec_open, 1)
        end,
    },
}

local function define_tests()
    describe("keeper.git.service:snapshot", function()
        for _, case in ipairs(cases) do
            it(case.name, case.fn)
        end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
