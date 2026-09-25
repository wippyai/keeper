local test = require("test")
local sql = require("sql")
local hub_service = require("hub_service")
local preflight = require("preflight")
local install_candidate = require("install_candidate")

local function fixture(label, fail_migration, mode)
    local observed = { "pid-old" }
    local state = { status = "running", desired = "running" }
    local trace = {}
    local receipts = {}
    local entry = { id = "app.deps:example", kind = "ns.dependency",
        data = { component = "example/pkg", version = "1.0.0", parameters = {} }, meta = {} }
    local migration = { id = "example.migrations:01", kind = "function.lua",
        meta = { type = "migration", target_db = "app:db",
            quiesce_services = { "app:worker" } }, data = { code = "return true" } }
    local candidate = { closure = { { module = "example/pkg", version = label,
        hash = label, min_runtime = "0.3.40a", migrations = { migration } } } }
    local svc = hub_service.new({
        sql = sql,
        config = { app_db = function() return "app:db" end },
        uuid = { v4 = function() return "installer-" .. label end },
        registry = { get = function(id)
            if receipts[id] then return receipts[id], nil end
            if id == "app:worker" then
                -- Short same-namespace ref, as real service entries declare
                -- it; quiescence qualifies it against the service namespace.
                return { id = id, kind = "process.service", data = { process = "worker.run" } }, nil
            end
            return nil, nil
        end },
        system = {
            version = function() return "0.3.43a" end,
            supervisor = { state = function()
                if mode == "inspection_error" then return nil, "permission denied" end
                return state, nil
            end },
            hosts = {
                list = function() return { { id = "app:host" } }, nil end,
                processes = function()
                    local rows = {}
                    for _, pid in ipairs(observed) do
                        rows[#rows + 1] = { pid = pid, source = "app:worker.run", state = "running" }
                    end
                    return rows, nil
                end,
            },
        },
        events = { send = function(system_name, kind, id)
            test.eq(system_name, "supervisor")
            test.eq(id, "app:worker")
            trace[#trace + 1] = kind
            if kind == "service.stop" then
                if mode == "stop_timeout" then
                    state = { status = "stopping", desired = "stopped" }
                else
                    state = { status = "stopped", desired = "stopped" }
                    observed = {}
                end
            elseif kind == "service.start" then
                state = { status = "running", desired = "running" }
                observed = { mode == "old_pid_start" and "pid-old" or "pid-new" }
            end
            return true, nil
        end },
        time = { sleep = function() return true, nil end },
        candidate_resolver = { staged = true },
        candidate_migrations_up = function(args)
            trace[#trace + 1] = "migration"
            test.eq(args.target_db, "app:db")
            test.eq(args.installer_lock_token, "installer-" .. label)
            test.not_nil(args.expected_hashes[migration.id])
            if fail_migration then return nil, "injected migration failure" end
            return { applied = { { id = migration.id, hash = args.expected_hashes[migration.id] } }, skipped = {} }, nil
        end,
    })
    svc.prepare_install = function()
        return { candidate = candidate, plan = { graph = {} }, args = { migration_policy = "up" },
            entry = entry, entries = { entry }, create_only = {}, patches = {}, patch = {},
            policy = "up" }, nil
    end
    svc.dependency_create_or_update_op = function(_, row)
        return { kind = "entry.create", entry = row }, nil
    end
    svc.bootloader_step_data = function()
        return { baseline_modules = {}, reconfigured = {} }, nil
    end
    svc.validate_planned_entries = function()
        trace[#trace + 1] = "validation"
        return { ok = true }, nil
    end
    svc.migration_status = function()
        return mode == "applied_hash_changed" and "applied" or "pending", nil
    end
    svc.publish_dependency_changeset = function(self, args)
        trace[#trace + 1] = "publication"
        if mode ~= "publish_never_commits" then
            local receipt, receipt_err = self:publication_receipt(args.lock_token, args.candidate_hash, args.entries)
            test.is_nil(receipt_err)
            receipts[receipt.entry.id] = receipt.entry
        end
        return { version = 2 }, nil
    end
    svc.run_installed_bootloaders = function()
        trace[#trace + 1] = "bootloaders"
        return { count = 0 }, nil
    end
    return svc, trace
end

local function define_tests()
    test.describe("Package I production installer", function()
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

        test.it("real installer stops, migrates, publishes, starts new PID, then completes", function()
            local svc, trace = fixture("round3-success", false)
            local result, install_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(install_err)
            test.not_nil(result)
            test.eq(table.concat(trace, ","),
                "validation,service.stop,migration,publication,bootloaders,service.start")
            test.eq(result.fence.records["app:worker"].new_pid, "pid-new")
            test.not_nil(result.fence.records["app:worker"].old_pids["pid-old"])
            local db = sql.get("app:db")
            local active = svc.install_state.get_active_install(db)
            test.is_nil(active)
            db:release()
        end)

        test.it("batch install uses the same stop and staged migration order", function()
            local svc, trace = fixture("round3-batch", false)
            local result, install_err = svc:install({
                dependencies = { { component = "example/pkg" } },
            }, {})
            test.is_nil(install_err)
            test.not_nil(result)
            test.eq(table.concat(trace, ","),
                "validation,service.stop,migration,publication,bootloaders,service.start")
        end)

        test.it("direct up stages the installed artifact and uses the fenced runner", function()
            local svc, trace = fixture("round3-direct", false)
            local known = "c154e2cc11ca94ddd368307aced96cfbbd411a58e74e46339d50b4a9befc1d65"
            local staged_entry = { id = "example.migrations:01", kind = "function.lua",
                meta = { type = "migration", target_db = "app:db",
                    quiesce_services = { "app:worker" } }, data = { code = "return true" } }
            svc.registry.snapshot = function() return {
                state = function() return { resolution = { modules = {
                    { name = "userspace/contract", version = "0.4.1", digest = known },
                } } }, nil end,
            }, nil end
            svc.planner = { new = function() return {
                catalog = { versions = { open = function()
                    return { digest = known, entries = function() return { staged_entry }, nil end,
                        close = function() return true, nil end }, nil
                end } },
            } end }
            svc.migration_rows = function() return { {
                id = staged_entry.id, module = "userspace/contract", status = "pending",
                meta = staged_entry.meta,
            } }, nil end
            local result, migration_err = svc:run_migrations({ operation = "up" }, {})
            test.is_nil(migration_err)
            test.not_nil(result)
            test.eq(table.concat(trace, ","), "service.stop,migration,service.start")
            test.eq(result.result.applied[1].id, staged_entry.id)
        end)

        test.it("migration failure holds fence and refuses a competing candidate", function()
            local first, trace = fixture("round3-failure", true)
            local result, install_err = first:install({ component = "example/pkg" }, {})
            test.is_nil(result)
            test.not_nil(install_err)
            test.eq(table.concat(trace, ","), "validation,service.stop,migration")
            local db = sql.get("app:db")
            local active = first.install_state.get_active_install(db)
            test.not_nil(active)
            test.eq(active.candidate_hash ~= "", true)
            db:release()
            local second = fixture("round3-competing", false)
            local other, conflict = second:install({ component = "example/pkg" }, {})
            test.is_nil(other)
            test.eq(conflict:details().code, "INSTALL_CONFLICT")
            local cleanup = sql.get("app:db")
            first.install_state.fail_install(cleanup, active.lock_token, "test cleanup")
            cleanup:release()
        end)

        test.it("same candidate resumes at failed migration under original lock", function()
            local svc, trace = fixture("round3-resume", true)
            local first, first_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(first)
            test.not_nil(first_err)
            svc.candidate_migrations_up = function(args)
                trace[#trace + 1] = "migration-resumed"
                return { applied = { { id = "example.migrations:01",
                    hash = args.expected_hashes["example.migrations:01"] } }, skipped = {} }, nil
            end
            local resumed, resume_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(resume_err)
            test.not_nil(resumed)
            test.is_true(resumed.resumed)
            test.eq(resumed.operation_id, "installer-round3-resume")
            test.eq(table.concat(trace, ","),
                "validation,service.stop,migration,migration-resumed,publication,bootloaders,service.start")
        end)

        test.it("publication crash reconciles committed entries without republishing", function()
            local svc, trace = fixture("round3-publish-crash", false)
            local prepared = svc:prepare_install({ component = "example/pkg" })
            local published = false
            local original_publish = svc.publish_dependency_changeset
            svc.publish_dependency_changeset = function(self, args)
                published = true
                return original_publish(self, args)
            end
            local original_get = svc.registry.get
            svc.registry.get = function(id)
                if id == prepared.entry.id and published then return prepared.entry, nil end
                return original_get(id)
            end
            local base_state = svc.install_state
            local fail_once = true
            svc.install_state = setmetatable({ record_step = function(db, token, name, outcome)
                if name == "publication" and outcome.status == "done" and fail_once then
                    fail_once = false
                    return nil, "injected crash before publication receipt"
                end
                return base_state.record_step(db, token, name, outcome)
            end }, { __index = base_state })
            local first, first_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(first)
            test.eq(first_err:details().code, "INSTALL_STATE_FAILED")
            local resumed, resume_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(resume_err)
            test.not_nil(resumed)
            test.is_true(resumed.apply.reconciled)
            test.eq(table.concat(trace, ","),
                "validation,service.stop,migration,publication,bootloaders,service.start")
        end)

        test.it("absent publication receipt retries the same governance request", function()
            local svc, trace = fixture("round3-publish-unknown", false, "publish_never_commits")
            local base_state = svc.install_state
            local fail_once = true
            svc.install_state = setmetatable({ record_step = function(db, token, name, outcome)
                if name == "publication" and outcome.status == "done" and fail_once then
                    fail_once = false
                    return nil, "injected crash before publication receipt"
                end
                return base_state.record_step(db, token, name, outcome)
            end }, { __index = base_state })
            local first, first_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(first)
            test.eq(first_err:details().code, "INSTALL_STATE_FAILED")
            local second, second_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(second_err)
            test.not_nil(second)
            test.eq(table.concat(trace, ","),
                "validation,service.stop,migration,publication,publication,bootloaders,service.start")
        end)

        test.it("changed already applied migration hash refuses before publication", function()
            local svc, trace = fixture("round3-changed-applied", true, "applied_hash_changed")
            local result, install_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(result)
            test.eq(install_err:details().code, "CANDIDATE_MIGRATIONS_FAILED")
            test.eq(table.concat(trace, ","), "validation,migration")
            local db = sql.get("app:db")
            local active = svc.install_state.get_active_install(db)
            test.not_nil(active)
            svc.install_state.fail_install(db, active.lock_token, "test cleanup")
            db:release()
        end)

        test.it("stopping without terminal exit refuses before migration and stays fenced", function()
            local svc, trace = fixture("round3-timeout", false, "stop_timeout")
            local result, install_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(result)
            test.eq(install_err:details().code, "QUIESCENCE_TIMEOUT")
            test.eq(table.concat(trace, ","), "validation,service.stop")
            local db = sql.get("app:db")
            local active = svc.install_state.get_active_install(db)
            test.not_nil(active)
            test.eq(active.status, "fenced")
            svc.install_state.fail_install(db, active.lock_token, "test cleanup")
            db:release()
        end)

        test.it("inspection error refuses before supervisor stop and migration", function()
            local svc, trace = fixture("round3-inspection", false, "inspection_error")
            local result, install_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(result)
            test.eq(install_err:details().code, "INSPECTION_FAILED")
            test.eq(table.concat(trace, ","), "validation")
            local db = sql.get("app:db")
            local active = svc.install_state.get_active_install(db)
            test.not_nil(active)
            svc.install_state.fail_install(db, active.lock_token, "test cleanup")
            db:release()
        end)

        test.it("old PID restart cannot satisfy new startup or release the fence", function()
            local svc, trace = fixture("round3-old-pid", false, "old_pid_start")
            local result, install_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(result)
            test.eq(install_err:details().code, "QUIESCENCE_TIMEOUT")
            test.eq(table.concat(trace, ","),
                "validation,service.stop,migration,publication,bootloaders,service.start")
            local db = sql.get("app:db")
            local active = svc.install_state.get_active_install(db)
            test.not_nil(active)
            test.eq(active.metadata.fence.held, true)
            svc.install_state.fail_install(db, active.lock_token, "test cleanup")
            db:release()
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run, run = run }
