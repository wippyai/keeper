local test = require("test")
local install_test_support = require("install_test_support")
local hub_service = require("hub_service")
local preflight = require("preflight")
local install_candidate = require("install_candidate")
local install_digest = require("install_digest")
local install_resolver = require("install_resolver")
local candidate_runner = require("candidate_runner")

local fixture = install_test_support.fixture
local real_migration = install_test_support.real_migration

local function define_tests()
    test.describe("Package I production installer: staging and units", function()
        test.after_each(install_test_support.cleanup_install_locks)

        test.it("candidate without a declared or certified floor refuses", function()
            local result = preflight.check({
                candidate_closure = { { module = "example/unknown", version = "1", hash = "missing" } },
                binary_version = "0.3.43a",
            })
            test.is_false(result.accepted)
            test.eq(result.blocker.code, "UNKNOWN_HASH")
        end)

        test.it("staging uses exact planned digest and migration metadata", function()
            local planner = { new = function() return {
                catalog = { versions = { open = function()
                    return { digest = "exact-digest", entries = function() return {
                        { id = "example.migrations:01", kind = "function.lua",
                          meta = { type = "migration", target_db = "app:db",
                              quiesce_services = { "app:worker" } } },
                    }, nil end, close = function() return true, nil end }, nil
                end } },
            } end }
            local result, stage_err = install_candidate.stage(planner, {
                { module = "example/pkg", version = "1", digest = "exact-digest",
                    __selected = { version = "1", metadata = { min_wippy_version = "0.3.40a" } } },
            })
            test.is_nil(stage_err)
            test.eq(result.closure[1].min_runtime, "0.3.40a")
            test.eq(result.closure[1].migrations[1].meta.quiesce_services[1], "app:worker")
        end)

        test.it("staging refuses a planner digest without an opened package digest", function()
            local fake_planner = { new = function() return {
                inspect_artifact = function()
                    return { digest = "selected-digest", entries = {} }, nil
                end,
                catalog = { versions = { open = function()
                    return { digest = nil, entries = function() return {}, nil end,
                        close = function() return true, nil end }, nil
                end } },
            } end }
            local staged, stage_err = install_candidate.stage(fake_planner, {
                { module = "example/pkg", version = "1", digest = "selected-digest" },
            })
            test.is_nil(staged)
            test.eq(stage_err:details().code, "CANDIDATE_HASH_MISMATCH")
        end)

        test.it("quiescence wait accepts the real sleep nil return", function()
            local svc, _ = fixture("round3-sleep-nil", false, "fence")
            local calls = 0
            local token = "sleep-nil-token"
            local runtime = {
                registry = { get = function(id)
                    return { id = id, kind = "process.service",
                        data = { process = "app:worker.run" } }, nil
                end },
                system = {
                    supervisor = { state = function()
                        calls = calls + 1
                        if calls < 3 then
                            return { desired = "running", status = "running" }, nil
                        end
                        return { desired = "stopped", status = "stopped" }, nil
                    end },
                    hosts = {
                        list = function() return {}, nil end,
                        processes = function() return {}, nil end,
                    },
                },
                events = { send = function() return true, nil end },
                -- The real time.sleep returns nothing on success.
                time = { sleep = function() return nil, nil end },
                install_state = {
                    record_fence = function() return true, nil end,
                    get_active_install = function()
                        return { lock_token = token }, nil
                    end,
                },
            }
            local fence, fence_err = svc.install_quiescence.acquire(runtime, {}, token,
                "sleep-nil", { { id = "m", meta = { quiesce_services = { "app:worker" } },
                    status = "pending" } })
            test.is_nil(fence_err)
            test.not_nil(fence)
            test.is_true(fence.held)
            test.is_true(calls >= 3)
        end)

        test.it("start accepts a scheduler idle state for the new PID", function()
            local svc, _ = fixture("round3-idle-start", false, "fence")
            local phase = "stopping"
            local token = "idle-start-token"
            local runtime = {
                registry = { get = function(id)
                    return { id = id, kind = "process.service",
                        data = { process = "worker.run" } }, nil
                end },
                system = {
                    supervisor = { state = function()
                        if phase == "stopping" then
                            return { desired = "stopped", status = "stopped" }, nil
                        end
                        return { desired = "running", status = "running" }, nil
                    end },
                    hosts = {
                        list = function() return { { id = "h" } }, nil end,
                        processes = function()
                            if phase == "stopping" then return {}, nil end
                            return { { pid = "pid-new", source = "app:worker.run",
                                state = "idle" } }, nil
                        end,
                    },
                },
                events = { send = function() return true, nil end },
                time = { sleep = function() return nil, nil end },
                install_state = {
                    record_fence = function() return true, nil end,
                    get_active_install = function()
                        return { lock_token = token }, nil
                    end,
                },
            }
            local fence, fence_err = svc.install_quiescence.acquire(runtime, {}, token,
                "idle-start", { { id = "m", meta = { quiesce_services = { "app:worker" } },
                    status = "pending" } })
            test.is_nil(fence_err)
            test.not_nil(fence)
            phase = "running"
            local started, start_err = svc.install_quiescence.start(runtime, {}, token, fence)
            test.is_nil(start_err)
            test.is_true(started.started)
            test.eq(fence.records["app:worker"].new_pid, "pid-new")
        end)

        test.it("stop accepts a supervisor exited status for the old PID", function()
            local svc, _ = fixture("round4-exited-stop", false, "fence")
            local token = "exited-stop-token"
            local runtime = {
                registry = { get = function(id)
                    return { id = id, kind = "process.service",
                        data = { process = "worker.run" } }, nil
                end },
                system = {
                    supervisor = { state = function()
                        -- The runtime reports exited once the stopped
                        -- service process is gone; desired stays stopped.
                        return { desired = "stopped", status = "exited" }, nil
                    end },
                    hosts = {
                        list = function() return { { id = "h" } }, nil end,
                        processes = function() return {}, nil end,
                    },
                },
                events = { send = function() return true, nil end },
                time = { sleep = function() return nil, nil end },
                install_state = {
                    record_fence = function() return true, nil end,
                    get_active_install = function()
                        return { lock_token = token }, nil
                    end,
                },
            }
            local fence, fence_err = svc.install_quiescence.acquire(runtime, {}, token,
                "exited-stop", { { id = "m", meta = { quiesce_services = { "app:worker" } },
                    status = "pending" } })
            test.is_nil(fence_err)
            test.not_nil(fence)
            test.is_true(fence.held)
        end)

        test.it("helper failures are typed errors with kinds", function()
            local _, unavailable = install_candidate.stage({ new = function() return {
                catalog = { versions = { open = function() return nil, "gone" end } },
            } end }, {
                { module = "example/pkg", version = "1", digest = "d" },
            })
            test.eq(unavailable:details().code, "CANDIDATE_UNAVAILABLE")
            test.eq(unavailable:kind(), errors.UNAVAILABLE)
            local _, mismatch = install_candidate.stage({ new = function() return {
                catalog = { versions = { open = function()
                    return { digest = "other", entries = function() return {}, nil end,
                        close = function() return true, nil end }, nil
                end } },
            } end }, {
                { module = "example/pkg", version = "1", digest = "d" },
            })
            test.eq(mismatch:details().code, "CANDIDATE_HASH_MISMATCH")
            test.eq(mismatch:kind(), errors.CONFLICT)
        end)

        test.it("public caller version cannot override runtime floor refusal", function()
            local fake_planner = { new = function() return {
                plan_install = function()
                    return { graph = { { module = "example/pkg", version = "1",
                        digest = "exact-digest", __selected = { version = "1",
                            metadata = { min_wippy_version = "0.3.42a" } } } } }, nil
                end,
                catalog = { versions = { open = function()
                    return { digest = "exact-digest", entries = function() return {}, nil end,
                        close = function() return true, nil end }, nil
                end } },
            } end }
            local registry = { snapshot = function() return {
                state = function() return { resolution = { modules = {} } }, nil end,
            }, nil end }
            local svc = hub_service.new({ planner = fake_planner, registry = registry,
                system = { version = function() return "0.3.40a" end } })
            local prepared, prepare_err = svc:prepare_install({ component = "example/pkg",
                binary_version = "99.0.0" })
            test.is_nil(prepared)
            test.eq(prepare_err:details().code, "INCOMPATIBLE_RUNTIME_FLOOR")
        end)

        test.it("real readiness and health refuse unknown installed digest", function()
            local registry = { snapshot = function() return {
                state = function() return { resolution = { modules = {
                    { name = "example/unknown", version = "1", digest = "uncertified" },
                } } }, nil end,
            }, nil end }
            local svc = hub_service.new({ registry = registry,
                system = { version = function() return "0.3.43a" end } })
            local ready = svc:readiness({ binary_version = "99.0.0" })
            local health = svc:health({ binary_version = "99.0.0" })
            test.is_false(ready.ready)
            test.eq(ready.blocker.code, "UNKNOWN_HASH")
            test.eq(health.status, "unhealthy")
        end)

        test.it("production resolver serves staged bytes filtered by target DB", function()
            local first = { id = "b:mig", kind = "function.lua",
                meta = { type = "migration", target_db = "app:db" }, data = { source = "s" } }
            local second = { id = "a:mig", kind = "function.lua",
                meta = { type = "migration", target_db = "app:db" }, data = { source = "s" } }
            local other = { id = "c:mig", kind = "function.lua",
                meta = { type = "migration", target_db = "app:other" }, data = { source = "s" } }
            local plain = { id = "not-a-migration", kind = "function.lua",
                meta = { type = "page" }, data = {} }
            local fourth = { id = "d:mig", kind = "function.lua",
                meta = { type = "migration", target_db = "app:db" }, data = { source = "s" } }
            local closure = {
                { module = "example/pkg", version = "1", hash = "h",
                    migrations = { first, second, other } },
                { module = "example/legacy", version = "1", hash = "h",
                    entries = { plain, fourth } },
            }
            local resolver, resolver_err = install_resolver.for_closure(closure)
            test.is_nil(resolver_err)
            test.not_nil(resolver)
            local rows, find_err = resolver:find({ target_db = "app:db" })
            test.is_nil(find_err)
            test.eq(#rows, 3)
            test.eq(rows[1].id, "a:mig")
            test.eq(rows[2].id, "b:mig")
            test.eq(rows[3].id, "d:mig")
            test.is_true(rows[1] == second)
            test.is_true(rows[2] == first)
            test.is_true(rows[3] == fourth)
            local all, all_err = resolver:find({})
            test.is_nil(all_err)
            test.eq(#all, 4)
            local none, none_err = resolver:find({ target_db = "app:missing" })
            test.is_nil(none_err)
            test.eq(#none, 0)
            local missing, missing_err = install_resolver.for_closure(nil)
            test.is_nil(missing)
            test.eq(missing_err:details().code, "CANDIDATE_UNAVAILABLE")
        end)

        test.it("production resolver orders staged entries by timestamp then id", function()
            local early_id_late_ts = { id = "a:mig", kind = "function.lua",
                meta = { type = "migration", target_db = "app:db", timestamp = "2026-05" },
                data = { source = "s" } }
            local late_id_early_ts = { id = "z:mig", kind = "function.lua",
                meta = { type = "migration", target_db = "app:db", timestamp = "2026-01" },
                data = { source = "s" } }
            local untimestamped = { id = "m:mig", kind = "function.lua",
                meta = { type = "migration", target_db = "app:db" }, data = { source = "s" } }
            local closure = { { module = "example/pkg", version = "1", hash = "h",
                migrations = { early_id_late_ts, late_id_early_ts, untimestamped } } }
            local resolver, resolver_err = install_resolver.for_closure(closure)
            test.is_nil(resolver_err)
            local rows, find_err = resolver:find({ target_db = "app:db" })
            test.is_nil(find_err)
            test.eq(#rows, 3)
            test.eq(rows[1].id, "m:mig")
            test.eq(rows[2].id, "z:mig")
            test.eq(rows[3].id, "a:mig")
        end)

        test.it("keeper digest matches the framework entry hash byte for byte", function()
            local entry = real_migration("r5e2e:parity", "2026-03",
                "CREATE TABLE IF NOT EXISTS r5e2e_parity (id TEXT PRIMARY KEY)", true)
            local keeper_hash, keeper_err = install_digest.sha256({
                id = entry.id, kind = entry.kind,
                meta = entry.meta, data = entry.data,
            })
            test.is_nil(keeper_err)
            local framework_hash, framework_err = candidate_runner.entry_hash(entry)
            test.is_nil(framework_err)
            test.eq(keeper_hash, framework_hash)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run, run = run }
