local test = require("test")
local floor_catalog = require("floor_catalog")
local preflight = require("preflight")
local install_state = require("install_state")
local sql = require("sql")
local json = require("json")

-- Test suite for Package I: MIG-09..11, CMP-01..03, service quiescence lifecycle.
local function define_tests()
    test.describe("Package I - Safe Installer & Preflight", function()

        test.describe("floor_catalog", function()
            test.it("CMP-03: exact-hash certified legacy catalog covers full installed closure", function()
                local known_hash = "c154e2cc11ca94ddd368307aced96cfbbd411a58e74e46339d50b4a9befc1d65"
                local entry, err = floor_catalog.lookup(known_hash)
                test.is_nil(err)
                test.not_nil(entry)
                test.eq(entry.name, "userspace/contract")
                test.eq(entry.min_runtime, "0.3.40a")

                local floor, floor_err = floor_catalog.get_floor({ hash = known_hash, name = "userspace/contract" })
                test.is_nil(floor_err)
                test.eq(floor, "0.3.40a")
            end)

            test.it("CMP-03: unknown hash never gets a fallback floor and is refused", function()
                local unknown_hash = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
                local entry, err = floor_catalog.lookup(unknown_hash)
                test.is_nil(entry)
                test.not_nil(err)
                test.is_true(string.find(err, "UNKNOWN_HASH") ~= nil)

                local floor, floor_err = floor_catalog.get_floor({ hash = unknown_hash, name = "unknown/pkg" })
                test.is_nil(floor)
                test.not_nil(floor_err)
                test.is_true(string.find(floor_err, "UNKNOWN_HASH") ~= nil)
            end)

            test.it("prefers declared manifest min_runtime when present", function()
                local art = { name = "custom/pkg", min_runtime = "0.3.45", hash = "dummy" }
                local floor, err = floor_catalog.get_floor(art)
                test.is_nil(err)
                test.eq(floor, "0.3.45")
            end)
        end)

        test.describe("preflight version parsing & comparison", function()
            test.it("parses standard semver and wippy version strings", function()
                local v1, err1 = preflight.parse_version("0.1.44")
                test.is_nil(err1)
                test.eq(v1.major, 0)
                test.eq(v1.minor, 1)
                test.eq(v1.patch, 44)
                test.eq(v1.suffix, "")

                local v2, err2 = preflight.parse_version("v0.3.43a")
                test.is_nil(err2)
                test.eq(v2.major, 0)
                test.eq(v2.minor, 3)
                test.eq(v2.patch, 43)
                test.eq(v2.suffix, "a")
            end)

            test.it("correctly compares version precedence", function()
                -- 0.3.40a < 0.3.42a
                local c1 = preflight.compare_versions("0.3.40a", "0.3.42a")
                test.is_true(c1 < 0)

                -- 0.3.42a == 0.3.42a
                local c2 = preflight.compare_versions("v0.3.42a", "0.3.42a")
                test.eq(c2, 0)

                -- 0.3.43a > 0.3.42a
                local c3 = preflight.compare_versions("0.3.43a", "0.3.42a")
                test.is_true(c3 > 0)

                -- 0.3.43 > 0.3.42a
                local c4 = preflight.compare_versions("0.3.43", "0.3.42a")
                test.is_true(c4 > 0)
            end)
        end)

        test.describe("preflight checks (CMP-01, CMP-02, MIG-09)", function()
            test.it("CMP-01: component 0.1.44 on v0.3.40a is refused before migration/publication", function()
                local candidate_closure = {
                    { module = "kickside/component", version = "0.1.44", min_runtime = "0.3.42a" },
                }
                local res, err = preflight.check({
                    candidate_closure = candidate_closure,
                    binary_version = "v0.3.40a",
                })
                test.is_nil(err)
                test.not_nil(res)
                test.is_false(res.accepted)
                test.not_nil(res.blocker)
                test.eq(res.blocker.code, "INCOMPATIBLE_RUNTIME_FLOOR")
                test.eq(res.blocker.module, "kickside/component")
                test.eq(res.blocker.required_floor, "0.3.42a")
                test.eq(res.blocker.binary_version, "v0.3.40a")
            end)

            test.it("CMP-01: component 0.1.44 on .42a and .43a is accepted", function()
                local candidate_closure = {
                    { module = "kickside/component", version = "0.1.44", min_runtime = "0.3.42a" },
                }
                local res42, err42 = preflight.check({
                    candidate_closure = candidate_closure,
                    binary_version = "0.3.42a",
                })
                test.is_nil(err42)
                test.is_true(res42.accepted)
                test.is_nil(res42.blocker)

                local res43, err43 = preflight.check({
                    candidate_closure = candidate_closure,
                    binary_version = "v0.3.43a",
                })
                test.is_nil(err43)
                test.is_true(res43.accepted)
                test.is_nil(res43.blocker)
            end)

            test.it("CMP-02: closure declaring floor requires runtime version; closures without floor install normally", function()
                -- Closure declaring floor without runtime version is refused with UNKNOWN_BINARY_VERSION
                local res_floor_no_bin = preflight.check({
                    candidate_closure = { { module = "acme/needs_floor", version = "1.0.0", min_runtime = "0.3.42a" } },
                    binary_version = "",
                })
                test.is_false(res_floor_no_bin.accepted)
                test.eq(res_floor_no_bin.blocker.code, "UNKNOWN_BINARY_VERSION")

                -- Closure without a floor installs normally without binary version
                local res_no_floor = preflight.check({
                    candidate_closure = { { module = "acme/no_floor", version = "1.0.0" } },
                    binary_version = "",
                })
                test.is_true(res_no_floor.accepted)
                test.is_nil(res_no_floor.blocker)

                -- Unparseable floor is refused
                local res_unparseable = preflight.check({
                    candidate_closure = { { module = "acme/bad", version = "1.0.0", min_runtime = "not-a-semver" } },
                    binary_version = "0.3.43a",
                })
                test.is_false(res_unparseable.accepted)
                test.eq(res_unparseable.blocker.code, "UNPARSEABLE_FLOOR")

                -- Transitive higher-floor dependency is refused
                local res_transitive = preflight.check({
                    candidate_closure = {
                        { module = "acme/root", version = "1.0.0", min_runtime = "0.3.40a" },
                        { module = "acme/child", version = "1.0.0", min_runtime = "0.3.45a" },
                    },
                    binary_version = "0.3.43a",
                })
                test.is_false(res_transitive.accepted)
                test.eq(res_transitive.blocker.code, "INCOMPATIBLE_RUNTIME_FLOOR")
                test.eq(res_transitive.blocker.module, "acme/child")
                test.eq(res_transitive.blocker.required_floor, "0.3.45a")
                test.eq(res_transitive.blocker.binary_version, "0.3.43a")
            end)

            test.it("MIG-09: boot floor covers full installed closure; unknown hash refuses boot", function()
                local known_installed = {
                    { name = "userspace/contract", version = "0.4.1",
                      hash = "c154e2cc11ca94ddd368307aced96cfbbd411a58e74e46339d50b4a9befc1d65" },
                    { name = "wippy/migration", version = "0.3.18",
                      hash = "e00cad6706bb95f556aeab5318a04e55d3884c027b09f6340fc4e7d69c905a17" },
                }
                local res_ok = preflight.check({
                    installed_artifacts = known_installed,
                    binary_version = "0.3.43a",
                })
                test.is_true(res_ok.accepted)

                -- Unknown hash in installed closure
                local unknown_installed = {
                    { name = "unverified/tampered", version = "0.1.0",
                      hash = "0000000000000000000000000000000000000000000000000000000000000000" },
                }
                local res_unknown = preflight.check({
                    installed_artifacts = unknown_installed,
                    binary_version = "0.3.43a",
                })
                test.is_false(res_unknown.accepted)
                test.eq(res_unknown.blocker.code, "UNKNOWN_HASH")
            end)
        end)

        test.describe("install_state & single installer lock (MIG-11)", function()
            test.it("MIG-11: single installer lock prevents concurrent conflicting install", function()
                install_state.reset_in_memory()
                local s1, err1 = install_state.begin_install(nil, {
                    lock_token = "tok-1",
                    candidate_hash = "hash-AAA",
                    steps = { "preflight", "candidate_migrations", "publish" },
                })
                test.is_nil(err1)
                test.not_nil(s1)
                test.is_false(s1.resumed)
                test.eq(s1.current_step, "preflight")

                -- Second install with different candidate hash must be refused!
                local s2, err2 = install_state.begin_install(nil, {
                    lock_token = "tok-2",
                    candidate_hash = "hash-BBB",
                    steps = { "preflight", "candidate_migrations", "publish" },
                })
                test.is_nil(s2)
                test.not_nil(err2)
                test.is_true(string.find(err2, "CONFLICT") ~= nil)
            end)

            test.it("MIG-11: interruption resumes same candidate hash and recorded step", function()
                install_state.reset_in_memory()
                local s1, _ = install_state.begin_install(nil, {
                    lock_token = "tok-resume",
                    candidate_hash = "hash-RESUME",
                    steps = { "preflight", "candidate_migrations", "publish" },
                })
                test.not_nil(s1)

                -- Simulate step progression and interruption
                install_state.record_step(nil, "tok-resume", "preflight", { status = "done" })
                install_state.record_step(nil, "tok-resume", "candidate_migrations", { status = "done", step_hash = "step-hash-1" })

                -- Resume attempt with same candidate hash
                local s_resumed, res_err = install_state.begin_install(nil, {
                    lock_token = "tok-retry",
                    candidate_hash = "hash-RESUME",
                    steps = { "preflight", "candidate_migrations", "publish" },
                })
                test.is_nil(res_err)
                test.not_nil(s_resumed)
                test.is_true(s_resumed.resumed)
                test.eq(s_resumed.current_step, "candidate_migrations")

                -- Completing install
                local done, done_err = install_state.complete_install(nil, "tok-resume")
                test.is_true(done)
                test.is_nil(done_err)

                -- Now lock is free for another candidate
                local s3, err3 = install_state.begin_install(nil, {
                    lock_token = "tok-next",
                    candidate_hash = "hash-CCC",
                    steps = { "preflight", "publish" },
                })
                test.is_nil(err3)
                test.not_nil(s3)
                test.is_false(s3.resumed)
            end)
        end)

        test.describe("Dual-engine SQL verification (SQLite & PostgreSQL)", function()
            test.it("creates install_state table and performs full lifecycle on database", function()
                local db, err = sql.get("app:db")
                test.is_nil(err)
                test.not_nil(db)
                local ok, ensure_err = install_state.ensure(db)
                test.is_true(ok)
                test.is_nil(ensure_err)

                -- Begin install 1
                local s, b_err = install_state.begin_install(db, {
                    lock_token = "db-test-tok",
                    candidate_hash = "cand-hash-1",
                    steps = { "preflight", "candidate_migrations", "publish" },
                })
                test.is_nil(b_err)
                test.not_nil(s)
                test.is_false(s.resumed)

                -- Conflict check: different candidate refused under active lock
                local _, conf_err = install_state.begin_install(db, {
                    lock_token = "db-test-tok-2",
                    candidate_hash = "cand-hash-different",
                    steps = { "preflight", "publish" },
                })
                test.not_nil(conf_err)
                test.is_true(string.find(conf_err, "CONFLICT") ~= nil)

                -- Record step progress
                local updated, rec_err = install_state.record_step(db, "db-test-tok", "preflight", {
                    status = "done",
                })
                test.is_nil(rec_err)
                test.eq(updated.current_step, "preflight")

                -- Resume check: same candidate resumes recorded step
                local s_res, res_err = install_state.begin_install(db, {
                    lock_token = "db-test-tok",
                    candidate_hash = "cand-hash-1",
                    steps = { "preflight", "candidate_migrations", "publish" },
                })
                test.is_nil(res_err)
                test.is_true(s_res.resumed)
                test.eq(s_res.current_step, "preflight")

                -- Complete install
                local comp, c_err = install_state.complete_install(db, "db-test-tok")
                test.is_true(comp)
                test.is_nil(c_err)

                -- Lock is now released
                local s_next, n_err = install_state.begin_install(db, {
                    lock_token = "db-test-tok-3",
                    candidate_hash = "cand-hash-different",
                    steps = { "preflight" },
                })
                test.is_nil(n_err)
                test.not_nil(s_next)
                test.is_false(s_next.resumed)
                local finished, finish_err = install_state.complete_install(db, "db-test-tok-3")
                test.is_true(finished)
                test.is_nil(finish_err)
                db:release()
            end)
        end)


    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run, run = run }
