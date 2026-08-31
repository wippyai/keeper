local test = require("test")
local helpers = require("gov_helpers")

local function define_tests()
    describe("Gov Tools", function()
        describe("format_stats", function()
            it("returns empty string for nil/non-table input", function()
                test.eq(helpers.format_stats(nil), "")
                test.eq(helpers.format_stats("not a table"), "")
                test.eq(helpers.format_stats(42), "")
            end)

            it("returns empty string for empty table", function()
                test.eq(helpers.format_stats({}), "")
            end)

            it("orders known keys consistently", function()
                local out = helpers.format_stats({
                    total = 10, deleted = 3, created = 2, updated = 5,
                })
                test.eq(out, "created=2 updated=5 deleted=3 total=10")
            end)

            it("includes unknown keys after known ones", function()
                local out = helpers.format_stats({ created = 1, custom_count = 7 })
                test.is_true(out:find("created=1") ~= nil)
                test.is_true(out:find("custom_count=7") ~= nil)
                test.is_true(out:find("created=1") < out:find("custom_count=7"))
            end)

            it("skips nested table values", function()
                local out = helpers.format_stats({
                    created = 1,
                    nested = { a = 1 },
                })
                test.is_true(out:find("created=1") ~= nil)
                test.is_true(out:find("nested=") == nil)
            end)

            it("preserves 0 values", function()
                local out = helpers.format_stats({ created = 0, updated = 0 })
                test.eq(out, "created=0 updated=0")
            end)

            it("carries the index file count into the summary line", function()
                local out = helpers.format_stats({ files = 0, index_files = 22 })
                test.is_true(out:find("index_files=22", 1, true) ~= nil)
            end)

            it("keeps an index file count of zero in the summary line", function()
                local out = helpers.format_stats({ files = 0, index_files = 0 })
                test.is_true(out:find("index_files=0", 1, true) ~= nil)
            end)

            it("includes sync unmanaged skip counters", function()
                local out = helpers.format_stats({
                    skipped_unmanaged_source = 2,
                    skipped_unmanaged_registry = 3,
                    managed_namespaces = 1,
                })
                test.is_true(out:find("skipped_unmanaged_source=2", 1, true) ~= nil)
                test.is_true(out:find("skipped_unmanaged_registry=3", 1, true) ~= nil)
                test.is_true(out:find("managed_namespaces=1", 1, true) ~= nil)
            end)
        end)

        describe("sync_options", function()
            it("passes one-shot managed_namespaces without other input", function()
                local opts = helpers.sync_options({ managed_namespaces = { "alpha" }, timeout = "30s" })
                local namespaces = opts.managed_namespaces or {}
                test.eq(#namespaces, 1)
                test.eq(namespaces[1], "alpha")
                test.is_nil(opts.timeout)
            end)

            it("returns empty options when no managed_namespaces provided", function()
                local opts = helpers.sync_options({ timeout = "30s" })
                test.not_nil(opts)
                test.eq(next(opts), nil)
            end)
        end)

        describe("run_sync", function()
            it("returns descriptive error when gov_fn fails", function()
                local out, err = helpers.run_sync({
                    tool_name = "sync_test",
                    direction = "test direction",
                    gov_fn = function() return nil, "boom" end,
                    diff_fn = function() return nil end,
                }, {})
                test.is_nil(out)
                test.is_true(err:find("sync_test failed") ~= nil)
                test.is_true(err:find("boom") ~= nil)
            end)

            it("composes summary with stats and version on success", function()
                local diff_called = false
                local out, err = helpers.run_sync({
                    tool_name = "sync_test",
                    direction = "Up",
                    gov_fn = function()
                        return {
                            message = "ok",
                            version = 42,
                            stats   = { created = 1, updated = 2 },
                        }
                    end,
                    diff_fn = function()
                        diff_called = true
                        return { ok = true, rows_written = 5 }
                    end,
                }, {})
                test.is_nil(err)
                test.not_nil(out)
                test.eq(out.version, 42)
                test.eq(out.journaled, 5)
                test.is_nil(out.journal_error)
                test.is_true(diff_called)
                test.is_true(out.summary:find("Up completed") ~= nil)
                test.is_true(out.summary:find("created=1") ~= nil)
            end)

            it("forwards the file operations the sync reported", function()
                local out = helpers.run_sync({
                    tool_name = "sync_test",
                    direction = "Down",
                    gov_fn = function()
                        return {
                            message   = "ok",
                            stats     = { files = 0, index_files = 2 },
                            file_ops  = {
                                { path = "./app/mail/_index.yaml", op = "update" },
                                { path = "./xepozz/smtp/_index.yaml", op = "update" },
                            },
                        }
                    end,
                    diff_fn = function() return { ok = true, rows_written = 2 } end,
                }, {})
                test.not_nil(out.file_ops)
                test.eq(#out.file_ops, 2)
                test.eq(out.file_ops[1].path, "./app/mail/_index.yaml")
                test.eq(out.file_ops[1].op, "update")
                test.is_true(out.summary:find("index_files=2", 1, true) ~= nil)
            end)

            it("leaves file operations absent when the sync reported none", function()
                local out = helpers.run_sync({
                    tool_name = "sync_test",
                    direction = "Up",
                    gov_fn = function() return { message = "ok", stats = {} } end,
                    diff_fn = function() return { ok = true, rows_written = 0 } end,
                }, {})
                test.is_nil(out.file_ops)
            end)

            it("captures diff_fn error without failing sync", function()
                local out, err = helpers.run_sync({
                    tool_name = "sync_test",
                    direction = "Down",
                    gov_fn = function() return { message = "ok", stats = {} } end,
                    diff_fn = function()
                        return {
                            ok = false,
                            errors = { { message = "journal wedged" } },
                        }
                    end,
                }, {})
                test.is_nil(err)
                test.eq(out.journaled, 0)
                test.eq(out.journal_error, "journal wedged")
            end)

            it("respects timeout override from input", function()
                local seen_timeout
                helpers.run_sync({
                    tool_name = "sync_test",
                    direction = "Up",
                    gov_fn = function(options, timeout)
                        seen_timeout = timeout
                        local namespaces = options.managed_namespaces or {}
                        test.eq(namespaces[1], "alpha")
                        return { message = "ok", stats = {} }
                    end,
                    diff_fn = function() return { ok = true, rows_written = 0 } end,
                }, { timeout = "30s", managed_namespaces = { "alpha" } })
                test.eq(seen_timeout, "30s")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
