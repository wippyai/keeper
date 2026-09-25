local test = require("test")
local sql = require("sql")
local install_test_support = require("install_test_support")
local sql_dialect = require("sql_dialect")

local fixture = install_test_support.fixture
local real_migration = install_test_support.real_migration

local function define_tests()
    test.describe("Package I production installer: real runner", function()
        test.after_each(install_test_support.cleanup_install_locks)

        test.it("real runner applies a staged quiesced migration end to end", function()
            local svc, trace = fixture("r5-real-success", false, "real")
            local result, install_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(install_err)
            test.not_nil(result)
            test.eq(table.concat(trace, ","),
                "validation,service.stop,publication,bootloaders,service.start")
            test.eq(#result.migrations.applied, 1)
            test.eq(result.migrations.applied[1].id, "example.migrations:01")
            test.eq(result.fence.records["app:worker"].new_pid, "pid-new")
            local db = sql.get("app:db")
            local probe, probe_err = sql_dialect.query(db,
                "SELECT id, content_hash FROM _migrations WHERE id = ?",
                { "example.migrations:01" })
            test.is_nil(probe_err)
            test.eq(#probe, 1)
            test.not_nil(probe[1].content_hash)
            test.eq(probe[1].content_hash, result.migrations.applied[1].hash)
            local active = svc.install_state.get_active_install(db)
            test.is_nil(active)
            db:release()
        end)

        test.it("real runner refuses changed source under an applied id", function()
            local svc, _ = fixture("r5-real-changed", false, "real")
            local first, first_err = svc:install({ component = "example/pkg" }, {})
            test.is_nil(first_err)
            test.not_nil(first)
            local changed = real_migration("example.migrations:01", "2026-03",
                "CREATE TABLE r5e2e_changed (id TEXT PRIMARY KEY)", true)
            local second, _ = fixture("r5-real-changed-v2", false, "real")
            second.prepare_install = function()
                return { candidate = { closure = { { module = "example/pkg",
                    version = "r5-real-changed-v2", hash = "r5-real-changed-v2",
                    min_runtime = "0.3.40a", migrations = { changed } } } },
                    plan = { graph = {} }, args = { migration_policy = "up" },
                    entry = { id = "app.deps:example", kind = "ns.dependency",
                        data = { component = "example/pkg", version = "1.0.0",
                            parameters = {} }, meta = {} },
                    entries = {}, create_only = {}, patches = {}, patch = {},
                    policy = "up" }, nil
            end
            second.dependency_create_or_update_op = function(_, row)
                return { kind = "entry.create", entry = row }, nil
            end
            second.bootloader_step_data = function()
                return { baseline_modules = {}, reconfigured = {} }, nil
            end
            second.validate_planned_entries = function() return { ok = true }, nil end
            local result, install_err = second:install({ component = "example/pkg" }, {})
            test.is_nil(result)
            test.not_nil(install_err)
            test.eq(install_err:details().code, "CANDIDATE_MIGRATIONS_FAILED")
            local db = sql.get("app:db")
            local active = svc.install_state.get_active_install(db)
            test.not_nil(active)
            svc.install_state.fail_install(db, active.lock_token, "test cleanup")
            db:release()
        end)

        test.it("real runner resumes a crashed candidate without reapplying", function()
            local good = real_migration("r5e2e:resume-01", "2026-03",
                "CREATE TABLE IF NOT EXISTS r5e2e_resume (id TEXT PRIMARY KEY)", false)
            local bad = real_migration("r5e2e:resume-02", "2026-04",
                "INSERT INTO r5e2e_missing_table VALUES ('x')", false)
            local fixed = real_migration("r5e2e:resume-02", "2026-04",
                "INSERT INTO r5e2e_resume VALUES ('two')", false)
            local function resume_fixture(second)
                local svc, _ = fixture("r5-real-resume", false, "real")
                local base = svc.prepare_install()
                base.candidate = { closure = { { module = "example/pkg",
                    version = "r5-real-resume", hash = "r5-real-resume",
                    min_runtime = "0.3.40a",
                    migrations = { good, second } } } }
                svc.prepare_install = function() return base, nil end
                return svc
            end
            local crashing = resume_fixture(bad)
            local first, first_err = crashing:install({ component = "example/pkg" }, {})
            test.is_nil(first)
            test.eq(first_err:details().code, "CANDIDATE_MIGRATIONS_FAILED")
            local db = sql.get("app:db")
            local partial, partial_err = sql_dialect.query(db,
                "SELECT id FROM _migrations WHERE id LIKE ?",
                { "r5e2e:resume%" })
            test.is_nil(partial_err)
            test.eq(#partial, 1)
            test.eq(partial[1].id, "r5e2e:resume-01")
            db:release()
            local resuming = resume_fixture(fixed)
            local resumed, resume_err = resuming:install({ component = "example/pkg" }, {})
            test.is_nil(resume_err)
            test.not_nil(resumed)
            test.is_true(resumed.resumed)
            test.eq(resumed.operation_id, "installer-r5-real-resume")
            test.eq(#resumed.migrations.applied, 1)
            test.eq(resumed.migrations.applied[1].id, "r5e2e:resume-02")
            test.eq(#resumed.migrations.skipped, 1)
            test.eq(resumed.migrations.skipped[1].id, "r5e2e:resume-01")
            local check = sql.get("app:db")
            local rows = check:query("SELECT id FROM r5e2e_resume ORDER BY id")
            test.eq(#rows, 1)
            test.eq(rows[1].id, "two")
            local ledger, ledger_err = sql_dialect.query(check,
                "SELECT id FROM _migrations WHERE id LIKE ?",
                { "r5e2e:resume%" })
            test.is_nil(ledger_err)
            test.eq(#ledger, 2)
            local active = resuming.install_state.get_active_install(check)
            test.is_nil(active)
            check:release()
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run, run = run }
