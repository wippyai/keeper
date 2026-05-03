local test = require("test")
local suspect = require("suspect")
local coverage = require("coverage")
local security = require("security")
local architecture = require("architecture")
local verdict = require("verdict")
local consts = require("git_consts")

local function ch(target, op, category)
    return {
        change_id = target,
        target = target,
        op = op or "update",
        category = category or "registry",
    }
end

local cases = {
    -- ── suspect ────────────────────────────────────────────────────────────
    {
        name = "suspect: bak file flagged",
        fn = function()
            test.not_nil(suspect.match("frontend/foo.vue.bak"))
        end,
    },
    {
        name = "suspect: DS_Store flagged",
        fn = function()
            test.not_nil(suspect.match("frontend/.DS_Store"))
        end,
    },
    {
        name = "suspect: scratch namespace flagged",
        fn = function()
            test.not_nil(suspect.match("app.scratch:hello"))
        end,
    },
    {
        name = "suspect: zzz_ prefix flagged",
        fn = function()
            test.not_nil(suspect.match("keeper.agents:zzz_tmp_agent"))
        end,
    },
    {
        name = "suspect: TODO_remove name flagged",
        fn = function()
            test.not_nil(suspect.match("keeper.task:TODO_remove_me"))
        end,
    },
    {
        name = "suspect: foo placeholder flagged",
        fn = function()
            test.not_nil(suspect.match("keeper.state.tools:foo"))
        end,
    },
    {
        name = "suspect: legitimate target not flagged",
        fn = function()
            test.is_nil(suspect.match("keeper.state.tools:push"))
            test.is_nil(suspect.match("frontend/applications/keeper/src/pages/git.vue"))
        end,
    },
    {
        name = "suspect: partition splits topic vs orphan",
        fn = function()
            local topic, orphans = suspect.partition({
                ch("app.scratch:hello", "create"),
                ch("app.notes:repo", "update"),
                ch("keeper.task:TODO_remove_me", "create"),
                ch("keeper.state.tools:push", "update"),
            })
            test.eq(#topic, 2)
            test.eq(#orphans, 2)
        end,
    },
    -- ── coverage ───────────────────────────────────────────────────────────
    {
        name = "coverage: new entry with no test → warn + per-entry hints",
        fn = function()
            local recs = coverage.run({
                ch("app.foo:repo", "create"),
                ch("app.foo:handler", "create"),
            })
            test.is_true(#recs >= 1)
            test.eq(recs[1].severity, consts.SEVERITY.WARN)
        end,
    },
    {
        name = "coverage: new entry paired with test → silent",
        fn = function()
            local recs = coverage.run({
                ch("app.foo:repo", "create"),
                ch("app.foo:repo_test", "create"),
            })
            test.eq(#recs, 0)
        end,
    },
    {
        name = "coverage: only updates → silent",
        fn = function()
            local recs = coverage.run({ ch("app.foo:repo", "update") })
            test.eq(#recs, 0)
        end,
    },
    -- ── security ───────────────────────────────────────────────────────────
    {
        name = "security: 8+ deletes blocks",
        fn = function()
            local list = {}
            for i = 1, 9 do table.insert(list, ch("app.foo:e" .. i, "delete")) end
            local recs = security.run(list)
            local has_block = false
            for _, r in ipairs(recs) do if r.severity == consts.SEVERITY.BLOCK then has_block = true end end
            test.is_true(has_block)
        end,
    },
    {
        name = "security: 4-7 deletes warns",
        fn = function()
            local list = {}
            for i = 1, 5 do table.insert(list, ch("app.foo:e" .. i, "delete")) end
            local recs = security.run(list)
            local has_warn = false
            for _, r in ipairs(recs) do if r.severity == consts.SEVERITY.WARN then has_warn = true end end
            test.is_true(has_warn)
        end,
    },
    {
        name = "security: auth touch blocks",
        fn = function()
            local recs = security.run({ ch("app.auth:guard", "update") })
            local has_block = false
            for _, r in ipairs(recs) do if r.severity == consts.SEVERITY.BLOCK then has_block = true end end
            test.is_true(has_block)
        end,
    },
    -- ── architecture ───────────────────────────────────────────────────────
    {
        name = "architecture: governance touch warns",
        fn = function()
            local recs = architecture.run({ ch("keeper.gov:client", "update") })
            test.is_true(#recs >= 1)
        end,
    },
    {
        name = "architecture: 4+ namespaces warns scope creep",
        fn = function()
            local recs = architecture.run({
                ch("app.a:x", "update"),
                ch("keeper.b:y", "update"),
                ch("userspace.c:z", "update"),
                ch("wippy.d:w", "update"),
            })
            local found = false
            for _, r in ipairs(recs) do
                if r.text:find("namespaces") then found = true end
            end
            test.is_true(found)
        end,
    },
    {
        name = "architecture: 25+ changes warns split",
        fn = function()
            local list = {}
            for i = 1, 30 do table.insert(list, ch("app.foo:e" .. i, "update")) end
            local recs = architecture.run(list)
            local found = false
            for _, r in ipairs(recs) do
                if r.text:find("large") then found = true end
            end
            test.is_true(found)
        end,
    },
    -- ── verdict ────────────────────────────────────────────────────────────
    {
        name = "verdict: no recs → ready",
        fn = function()
            local v, _, imp = verdict.from_recommendations({}, 5)
            test.eq(v, consts.VERDICTS.READY)
            test.eq(imp, consts.IMPORTANCE.NORMAL)
        end,
    },
    {
        name = "verdict: warn → closer_look + high",
        fn = function()
            local v, _, imp = verdict.from_recommendations({
                { severity = consts.SEVERITY.WARN, text = "x" },
            }, 5)
            test.eq(v, consts.VERDICTS.CLOSER_LOOK)
            test.eq(imp, consts.IMPORTANCE.HIGH)
        end,
    },
    {
        name = "verdict: block → do_not_push + critical",
        fn = function()
            local v, _, imp = verdict.from_recommendations({
                { severity = consts.SEVERITY.BLOCK, text = "x" },
            }, 5)
            test.eq(v, consts.VERDICTS.DO_NOT_PUSH)
            test.eq(imp, consts.IMPORTANCE.CRITICAL)
        end,
    },
    {
        name = "verdict: small clean cluster → cleanup importance",
        fn = function()
            local _, _, imp = verdict.from_recommendations({}, 2)
            test.eq(imp, consts.IMPORTANCE.CLEANUP)
        end,
    },
}

local function define_tests()
    describe("keeper.git.detectors", function()
        for _, case in ipairs(cases) do
            it(case.name, case.fn)
        end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
