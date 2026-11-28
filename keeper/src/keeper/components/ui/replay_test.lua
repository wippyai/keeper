-- Unit tests for keeper.components.ui:replay: a container respawned after an
-- idle kill replays the last open session before the requested op runs.

local test = require("test")
local replay = require("replay")

local function harness(opts)
    opts = opts or {}
    local sent = {}
    local calls = { spawn = 0, mint = 0 }
    local deps = {
        spawn = function(state)
            calls.spawn = calls.spawn + 1
            if opts.spawn_fail then return nil, "docker unavailable" end
            state.proc = {}
            return true
        end,
        send = function(_state, op, args, timeout_s)
            table.insert(sent, { op = op, args = args, timeout_s = timeout_s })
            if op == "open" and opts.replay_fail then return { ok = false, error = "navigation failed" } end
            return { ok = true, op = op }
        end,
        mint = function()
            calls.mint = calls.mint + 1
            return "fresh-admin-token"
        end,
        base_url = function() return "http://host" end,
        storage_state = function(origin, token) return { origin = origin, token = token } end,
        now = function() return 100000 end,
        refresh_after_s = 60,
        log = { info = function() end, warn = function() end },
    }
    return replay.new(deps), sent, calls
end

local function define_tests()
    test.describe("keeper.components.ui:replay — idle-killed container", function()
        test.it("replays a minted session with a refreshed token before the op", function()
            local container, sent, calls = harness()
            local state = { proc = nil, last_open = {
                start_url = "http://host/", origin = "http://host", token_source = "minted",
                minted_at = 0, storage_state = { origin = "http://host", token = "stale" },
            } }
            local res, err = container.call(state, "snapshot", {}, 30)
            test.is_nil(err)
            test.eq(res.op, "snapshot")
            test.eq(calls.spawn, 1)
            test.eq(calls.mint, 1)
            test.eq(#sent, 2)
            test.eq(sent[1].op, "open")
            test.eq(sent[1].args.start_url, "http://host/")
            test.eq(sent[1].args.storage_state.token, "fresh-admin-token")
            test.eq(sent[2].op, "snapshot")
            test.eq(state.last_open.minted_at, 100000)
        end)

        test.it("replays a caller session without minting", function()
            local container, sent, calls = harness()
            local state = { last_open = { start_url = "http://host/", origin = "http://host",
                token_source = "caller", minted_at = 0, storage_state = { token = "caller-token" } } }
            local _, err = container.call(state, "click", { selector = "#a" }, 30)
            test.is_nil(err)
            test.eq(calls.mint, 0)
            test.eq(sent[1].op, "open")
            test.eq(sent[1].args.storage_state.token, "caller-token")
            test.eq(sent[2].op, "click")
        end)

        test.it("keeps a recently minted token", function()
            local container, sent, calls = harness()
            local state = { last_open = { origin = "http://host", token_source = "minted",
                minted_at = 99990, storage_state = { token = "recent" } } }
            container.call(state, "snapshot", {}, 30)
            test.eq(calls.mint, 0)
            test.eq(sent[1].args.storage_state.token, "recent")
        end)

        test.it("reports failed replay before dispatching the pending op", function()
            local container, sent = harness({ replay_fail = true })
            local state = { last_open = { start_url = "http://host/", token_source = "caller" } }
            local res, err = container.call(state, "snapshot", {}, 30)
            test.eq(err, "navigation failed")
            test.is_nil(res)
            test.is_nil(state.last_open)
            test.eq(#sent, 1)
        end)

        test.it("does not replay on a live container", function()
            local container, sent, calls = harness()
            local state = { proc = {}, last_open = { token_source = "caller" } }
            container.call(state, "snapshot", {}, 30)
            test.eq(calls.spawn, 0)
            test.eq(#sent, 1)
            test.eq(sent[1].op, "snapshot")
        end)

        test.it("does not replay before an explicit open", function()
            local container, sent = harness()
            local state = { last_open = { token_source = "caller" } }
            container.call(state, "open", { start_url = "http://host/x" }, 50)
            test.eq(#sent, 1)
            test.eq(sent[1].args.start_url, "http://host/x")
        end)

        test.it("restores the latest authenticated navigation after idle", function()
            local container, sent, calls = harness()
            local state = { last_open = { token_source = "minted", start_url = "http://host/old" } }
            local storage = { token = "caller-token" }
            container.call(state, "goto", { storage_state = storage, url = "http://host/new",
                origin = "http://host" }, 30)
            test.eq(#sent, 1)
            test.eq(sent[1].op, "goto")
            container.call(state, "goto", { url = "http://host/next" }, 30)
            state.proc = nil
            container.call(state, "snapshot", {}, 30)
            test.eq(sent[3].op, "open")
            test.eq(sent[3].args.start_url, "http://host/next")
            test.eq(sent[3].args.storage_state.token, "caller-token")
            test.eq(calls.mint, 0)
        end)

        test.it("closes an idle session without replaying or refreshing it", function()
            local container, sent, calls = harness()
            local state = { next_id = 4, last_open = { token_source = "minted", minted_at = 0 } }
            local res = container.call(state, "close", {}, 30)
            test.eq(res.id, 5)
            test.eq(res.ok, true)
            test.eq(#sent, 0)
            test.eq(calls.spawn, 0)
            test.eq(calls.mint, 0)
            test.is_nil(state.last_open)
        end)

        test.it("reuses only the current unexpired caller session at the same origin", function()
            local runner, sent = harness()
            local state = {}
            local function navigate(binding, origin, storage_state, issued_at)
                return runner.call(state, "goto", {
                    url = origin .. "/next", binding = binding, origin = origin,
                    storage_state = storage_state, issued_at = issued_at,
                }, 30)
            end
            local origin = "http://host"
            test.is_true(navigate("a", origin).needs_caller_token)
            test.eq(#sent, 0)
            navigate("a", origin, { token = "first" }, 99990)
            for i = 1, 30 do
                test.is_true(navigate("a", origin).ok)
                test.eq(sent[#sent].args.storage_state.token, "first")
                test.is_nil(sent[#sent].args.binding)
            end
            state.proc = nil
            test.is_true(navigate("a", origin).ok)
            test.eq(sent[#sent].op, "goto")
            test.eq(state.caller_issued_at, 99990)
            test.is_true(navigate("b", origin).needs_caller_token)
            test.is_true(navigate("a", "http://new").needs_caller_token)
            state.caller_issued_at = 99730
            test.is_true(navigate("a", origin).needs_caller_token)
            navigate("b", origin, { token = "second" }, 100000)
            test.is_true(navigate("a", origin).needs_caller_token)
            test.is_true(navigate("b", origin).ok)
            test.eq(sent[#sent].args.storage_state.token, "second")
        end)

        test.it("reports a failed respawn", function()
            local container, sent = harness({ spawn_fail = true })
            local res, err = container.call({ last_open = { token_source = "caller" } }, "snapshot", {}, 30)
            test.is_nil(res)
            test.eq(err, "docker unavailable")
            test.eq(#sent, 0)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
