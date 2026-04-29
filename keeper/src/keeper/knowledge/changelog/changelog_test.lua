local test = require("test")
local uuid = require("uuid")
local sql = require("sql")
local changelog = require("changelog")

local function define_tests()
    describe("Knowledge Changelog", function()
        local test_version = "v-" .. uuid.v7()
        local test_namespace = "test.ns." .. uuid.v7():sub(1, 8)
        local test_request_id = "req-" .. uuid.v7()
        local test_user_id = "user-" .. uuid.v7()

        before_all(function()
            -- Pre-clean any stale data from previous runs (shouldn't exist with unique namespace, but defensive)
            local db = sql.get("app:db")
            if db then
                db:execute("DELETE FROM keeper_changelog WHERE namespace LIKE 'test.ns.%'")
                db:release()
            end

            changelog.record_changeset({
                user_id = test_user_id,
                request_id = test_request_id,
                changeset = {
                    {
                        kind = "entry.create",
                        entry = {
                            id = test_namespace .. ":alpha",
                            kind = "function.lua",
                            meta = { type = "handler" },
                        },
                    },
                    {
                        kind = "entry.update",
                        entry = {
                            id = test_namespace .. ":beta",
                            kind = "library.lua",
                            meta = { type = "lib" },
                        },
                    },
                    {
                        kind = "entry.delete",
                        entry = {
                            id = test_namespace .. ":gamma",
                            kind = "function.lua",
                            meta = { type = "handler" },
                        },
                    },
                },
                result = {
                    success = true,
                    version = test_version,
                },
            })
        end)

        describe("record_changeset", function()
            it("records operations that appear in list", function()
                local entries, err = changelog.list({ namespace = test_namespace })
                test.is_nil(err)
                test.not_nil(entries)
                test.eq(#entries, 3)
            end)

            it("ignores changeset when result.success is false", function()
                local ns = "fail.ns." .. uuid.v7():sub(1, 8)
                changelog.record_changeset({
                    user_id = "u1",
                    request_id = "r1",
                    changeset = {
                        {
                            kind = "entry.create",
                            entry = { id = ns .. ":x", kind = "function.lua" },
                        },
                    },
                    result = { success = false, version = "v-fail" },
                })

                local entries, err = changelog.list({ namespace = ns })
                test.is_nil(err)
                test.not_nil(entries)
                test.eq(#entries, 0)
            end)

            it("ignores nil args gracefully", function()
                changelog.record_changeset(nil)
                changelog.record_changeset({})
            end)
        end)

        describe("list filters", function()
            it("filters by namespace", function()
                local entries, err = changelog.list({ namespace = test_namespace })
                test.is_nil(err)
                test.not_nil(entries)
                test.eq(#entries, 3)
                for _, e in ipairs(entries) do
                    test.eq(e.namespace, test_namespace)
                end
            end)

            it("filters by op_type", function()
                local entries, err = changelog.list({
                    namespace = test_namespace,
                    op_type = "create",
                })
                test.is_nil(err)
                test.not_nil(entries)
                test.eq(#entries, 1)
                test.eq(entries[1].op_type, "create")
                test.eq(entries[1].entry_id, test_namespace .. ":alpha")
            end)

            it("filters by entry_id", function()
                local entries, err = changelog.list({
                    entry_id = test_namespace .. ":beta",
                })
                test.is_nil(err)
                test.not_nil(entries)
                test.eq(#entries, 1)
                test.eq(entries[1].op_type, "update")
            end)

            it("respects limit", function()
                local entries, err = changelog.list({
                    namespace = test_namespace,
                    limit = 1,
                })
                test.is_nil(err)
                test.not_nil(entries)
                test.eq(#entries, 1)
            end)

            it("returns empty for non-matching namespace", function()
                local entries, err = changelog.list({
                    namespace = "nonexistent.ns." .. uuid.v7(),
                })
                test.is_nil(err)
                test.not_nil(entries)
                test.eq(#entries, 0)
            end)
        end)

        describe("list_versions", function()
            it("returns grouped data with stats", function()
                local versions, err = changelog.list_versions({})
                test.is_nil(err)
                test.not_nil(versions)
                test.is_true(#versions >= 1)

                local found = false
                for _, v in ipairs(versions) do
                    if v.version == test_version then
                        found = true
                        test.eq(v.change_count, 3)
                        test.eq(v.creates, 1)
                        test.eq(v.updates, 1)
                        test.eq(v.deletes, 1)
                        test.eq(v.user_id, test_user_id)
                        test.eq(v.request_id, test_request_id)
                        test.not_nil(v.namespaces)
                        test.is_true(#v.namespaces >= 1)
                        break
                    end
                end
                test.is_true(found)
            end)

            it("respects limit", function()
                local versions, err = changelog.list_versions({ limit = 1 })
                test.is_nil(err)
                test.not_nil(versions)
                test.eq(#versions, 1)
            end)
        end)

        describe("stats", function()
            it("returns aggregate counts", function()
                local stats, err = changelog.stats()
                test.is_nil(err)
                test.not_nil(stats)
                test.is_true(stats.total >= 3)
                test.is_true(stats.versions >= 1)
                test.is_true(stats.namespaces >= 1)
                test.not_nil(stats.first_change)
                test.not_nil(stats.last_change)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
