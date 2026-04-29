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
                    gov_fn = function(_, timeout)
                        seen_timeout = timeout
                        return { message = "ok", stats = {} }
                    end,
                    diff_fn = function() return { ok = true, rows_written = 0 } end,
                }, { timeout = "30s" })
                test.eq(seen_timeout, "30s")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
