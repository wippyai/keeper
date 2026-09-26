local test = require("test")
local sql = require("sql")
local install_test_support = require("install_test_support")

local fixture = install_test_support.fixture

local function define_tests()
    test.describe("Package I production installer: install flows", function()
        test.after_each(install_test_support.cleanup_install_locks)

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
