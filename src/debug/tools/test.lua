local test = require("test")
local data = require("data_tool")
local dataflow = require("dataflow_tool")
local system = require("system_tool")

local function define_tests()
    describe("Debug tool helpers", function()

        describe("data.reject_non_select", function()
            it("accepts plain SELECT", function()
                test.is_nil(data.reject_non_select("SELECT 1"))
                test.is_nil(data.reject_non_select("select * from t"))
            end)

            it("accepts WITH, EXPLAIN, PRAGMA", function()
                test.is_nil(data.reject_non_select("WITH cte AS (SELECT 1) SELECT * FROM cte"))
                test.is_nil(data.reject_non_select("EXPLAIN SELECT 1"))
                test.is_nil(data.reject_non_select("PRAGMA table_info(foo)"))
            end)

            it("strips leading whitespace before checking", function()
                test.is_nil(data.reject_non_select("   \n\t SELECT 1"))
            end)

            it("strips leading line comments", function()
                test.is_nil(data.reject_non_select("-- a comment\nSELECT 1"))
                test.is_nil(data.reject_non_select("-- a\n-- b\nSELECT 1"))
            end)

            it("strips leading block comments", function()
                test.is_nil(data.reject_non_select("/* block */ SELECT 1"))
                test.is_nil(data.reject_non_select("/* a *//* b */SELECT 1"))
            end)

            it("rejects INSERT / UPDATE / DELETE / DROP", function()
                test.not_nil(data.reject_non_select("INSERT INTO t VALUES (1)"))
                test.not_nil(data.reject_non_select("UPDATE t SET a=1"))
                test.not_nil(data.reject_non_select("DELETE FROM t"))
                test.not_nil(data.reject_non_select("DROP TABLE t"))
            end)

            it("rejects non-string input", function()
                test.not_nil(data.reject_non_select(nil))
                test.not_nil(data.reject_non_select(42))
                test.not_nil(data.reject_non_select({}))
            end)

            it("rejects CREATE hidden behind a comment", function()
                test.not_nil(data.reject_non_select("-- sneaky\nCREATE TABLE t (a INT)"))
            end)
        end)

        describe("data.require_string", function()
            it("returns value for a non-empty string", function()
                local v, err = data.require_string({ name = "hello" }, "name")
                test.eq(v, "hello")
                test.is_nil(err)
            end)

            it("rejects nil", function()
                local v, err = data.require_string({}, "name")
                test.is_nil(v)
                test.is_true(err:find("is required") ~= nil)
            end)

            it("rejects empty string", function()
                local v, err = data.require_string({ name = "" }, "name")
                test.is_nil(v)
                test.is_true(err:find("is required") ~= nil)
            end)

            it("rejects non-string", function()
                local v, err = data.require_string({ name = 42 }, "name")
                test.is_nil(v)
                test.is_true(err:find("must be a string") ~= nil)
            end)
        end)

        describe("data.format_rows_as_table", function()
            it("returns no-rows marker for empty list", function()
                local out = data.format_rows_as_table({})
                test.eq(#out, 1)
                test.eq(out[1], "(no rows)")
            end)

            it("emits header + row lines", function()
                local out = data.format_rows_as_table({ { a = 1, b = "x" } })
                test.eq(#out, 2)
                test.is_true(out[1]:find("| a") ~= nil)
                test.is_true(out[1]:find("b |") ~= nil)
                test.is_true(out[2]:find("1") ~= nil)
                test.is_true(out[2]:find("x") ~= nil)
            end)

            it("unions column names across rows (sorted)", function()
                local out = data.format_rows_as_table({
                    { a = 1 },
                    { b = 2 },
                })
                local hdr = out[1]
                local a_pos = hdr:find("a")
                local b_pos = hdr:find("b")
                test.not_nil(a_pos)
                test.not_nil(b_pos)
                test.is_true(a_pos < b_pos)
            end)

            it("json-encodes table cell values", function()
                local out = data.format_rows_as_table({ { meta = { k = 1 } } })
                test.is_true(out[2]:find('"k":1') ~= nil)
            end)
        end)

        describe("dataflow.percent", function()
            it("formats 0..1 as percent with one decimal", function()
                test.eq(dataflow.percent(0), "0.0%")
                test.eq(dataflow.percent(0.5), "50.0%")
                test.eq(dataflow.percent(1), "100.0%")
            end)

            it("rounds to one decimal", function()
                test.eq(dataflow.percent(0.12345), "12.3%")
            end)
        end)

        describe("dataflow.node_signature", function()
            it("combines short_type with status", function()
                local sig = dataflow.node_signature({
                    type = "userspace.dataflow.node.agent:node",
                    status = "completed",
                })
                test.is_true(sig:find("|completed") ~= nil)
            end)

            it("falls back to ? when status missing", function()
                local sig = dataflow.node_signature({ type = "x:y" })
                test.is_true(sig:find("|%?") ~= nil)
            end)
        end)

        describe("dataflow.command_summary", function()
            it("stringifies non-table payload", function()
                test.eq(dataflow.command_summary("hi"), "hi")
                test.eq(dataflow.command_summary(nil), "")
            end)

            it("returns (empty) when ops list is missing and no .type", function()
                test.eq(dataflow.command_summary({}), "(empty)")
            end)

            it("returns payload.type for a single-command shape", function()
                test.eq(dataflow.command_summary({ type = "persist.node.upsert" }),
                    "persist.node.upsert")
            end)

            it("counts ops by type in commands[]", function()
                local out = dataflow.command_summary({
                    commands = {
                        { type = "a" }, { type = "a" }, { type = "b" },
                    },
                })
                test.is_true(out:find("a=2") ~= nil)
                test.is_true(out:find("b=1") ~= nil)
            end)

            it("accepts 'ops' or 'operations' alias for commands", function()
                test.eq(dataflow.command_summary({ ops = { { type = "a" } } }), "a=1")
                test.eq(dataflow.command_summary({ operations = { { type = "b" } } }), "b=1")
            end)

            it("sorts type tokens alphabetically", function()
                local out = dataflow.command_summary({
                    commands = {
                        { type = "zeta" }, { type = "alpha" },
                    },
                })
                test.is_true(out:find("alpha=1 zeta=1") ~= nil)
            end)
        end)

        describe("dataflow.collapse_siblings", function()
            it("leaves non-tool.call nodes as individual groups", function()
                local by_id = {
                    n1 = { node_id = "n1", type = "x:y" },
                    n2 = { node_id = "n2", type = "x:y" },
                }
                local groups = dataflow.collapse_siblings({ "n1", "n2" }, by_id)
                test.eq(#groups, 2)
                test.eq(groups[1].kind, "node")
                test.eq(groups[2].kind, "node")
            end)

            it("does NOT collapse runs shorter than 5", function()
                local by_id = {}
                for i = 1, 4 do
                    by_id["t" .. i] = {
                        node_id = "t" .. i, type = "tool.call", status = "completed",
                    }
                end
                local groups = dataflow.collapse_siblings({ "t1", "t2", "t3", "t4" }, by_id)
                test.eq(#groups, 4)
                for _, g in ipairs(groups) do test.eq(g.kind, "node") end
            end)

            it("collapses runs of 5+ same-status tool.call into one group", function()
                local by_id = {}
                local ids = {}
                for i = 1, 6 do
                    local id = "t" .. i
                    by_id[id] = { node_id = id, type = "tool.call", status = "completed" }
                    table.insert(ids, id)
                end
                local groups = dataflow.collapse_siblings(ids, by_id)
                test.eq(#groups, 1)
                test.eq(groups[1].kind, "collapsed")
                test.eq(groups[1].count, 6)
                test.eq(groups[1].status, "completed")
            end)

            it("breaks a collapse on status change", function()
                local by_id = {}
                local ids = {}
                for i = 1, 5 do
                    local id = "ok" .. i
                    by_id[id] = { node_id = id, type = "tool.call", status = "completed" }
                    table.insert(ids, id)
                end
                table.insert(ids, "fail1")
                by_id["fail1"] = { node_id = "fail1", type = "tool.call", status = "failed" }
                local groups = dataflow.collapse_siblings(ids, by_id)
                test.eq(#groups, 2)
                test.eq(groups[1].kind, "collapsed")
                test.eq(groups[1].count, 5)
                test.eq(groups[2].kind, "node")
                test.eq(groups[2].node.status, "failed")
            end)

            it("skips unknown child ids (missing from by_id)", function()
                local by_id = { k = { node_id = "k", type = "x:y" } }
                local groups = dataflow.collapse_siblings({ "missing", "k" }, by_id)
                test.eq(#groups, 1)
                test.eq(groups[1].kind, "node")
                test.eq(groups[1].node.node_id, "k")
            end)
        end)

        describe("system.fmt_bytes", function()
            it("renders bytes under 1K as B", function()
                test.eq(system.fmt_bytes(0), "0.0B")
                test.eq(system.fmt_bytes(512), "512.0B")
            end)

            it("scales up through KB/MB/GB/TB", function()
                test.eq(system.fmt_bytes(1024), "1.0KB")
                test.eq(system.fmt_bytes(1024 * 1024), "1.0MB")
                test.eq(system.fmt_bytes(1024 * 1024 * 1024), "1.0GB")
                test.eq(system.fmt_bytes(1024 * 1024 * 1024 * 1024), "1.0TB")
            end)

            it("caps at TB for very large values", function()
                local huge = 1024 * 1024 * 1024 * 1024 * 1024
                test.is_true(system.fmt_bytes(huge):find("TB$") ~= nil)
            end)

            it("coerces non-numeric to 0", function()
                test.eq(system.fmt_bytes(nil), "0.0B")
                test.eq(system.fmt_bytes("abc"), "0.0B")
            end)
        end)

        describe("system.format_log_entry", function()
            it("includes the timestamp", function()
                local line = system.format_log_entry({
                    timestamp = "2026-04-21T10:00:00Z", level = "ERROR",
                    source = "svc.x", message = "boom",
                })
                test.is_true(line:find("2026-04-21T10:00:00Z", 1, true) ~= nil)
            end)

            it("includes the level, source and message", function()
                local line = system.format_log_entry({
                    timestamp = "2026-04-21T10:00:00Z", level = "ERROR",
                    source = "svc.x", message = "boom",
                })
                test.is_true(line:find("ERROR", 1, true) ~= nil)
                test.is_true(line:find("svc.x", 1, true) ~= nil)
                test.is_true(line:find("boom", 1, true) ~= nil)
            end)

            it("falls back to .time / .severity / .logger / .msg aliases", function()
                local line = system.format_log_entry({
                    time = "T", severity = "WARN", logger = "L", msg = "M",
                })
                test.is_true(line:find("T", 1, true) ~= nil)
                test.is_true(line:find("WARN") ~= nil)
                test.is_true(line:find("L") ~= nil)
                test.is_true(line:find("M") ~= nil)
            end)

            it("defaults level to INFO when absent", function()
                local line = system.format_log_entry({ message = "x" })
                test.is_true(line:find("INFO") ~= nil)
            end)

            it("json-encodes a table message", function()
                local line = system.format_log_entry({ message = { k = 1 } })
                test.is_true(line:find('"k":1') ~= nil)
            end)
        end)

        describe("handler dispatch", function()
            it("data.handler rejects missing action", function()
                local v, err = data.handler({})
                test.is_nil(v)
                test.is_true(err:find("action") ~= nil)
            end)

            it("data.handler rejects unknown action", function()
                local v, err = data.handler({ action = "evaporate" })
                test.is_nil(v)
                test.is_true(err:find("unknown action") ~= nil)
            end)

            it("dataflow.handler rejects missing action", function()
                local v, err = dataflow.handler({})
                test.is_nil(v)
                test.is_true(err:find("action") ~= nil)
            end)

            it("dataflow.handler rejects unknown action", function()
                local v, err = dataflow.handler({ action = "sublimate" })
                test.is_nil(v)
                test.is_true(err:find("unknown action") ~= nil)
            end)

            it("system.handler rejects missing action", function()
                local v, err = system.handler({})
                test.is_nil(v)
                test.is_true(err:find("action") ~= nil)
            end)

            it("system.handler rejects unknown action", function()
                local v, err = system.handler({ action = "photosynthesize" })
                test.is_nil(v)
                test.is_true(err:find("unknown action") ~= nil)
            end)
        end)

    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
