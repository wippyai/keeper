local test = require("test")
local render = require("render")

local function define_tests()
    describe("Flow render helpers", function()

        describe("shorten", function()
            it("returns short ids unchanged", function()
                test.eq(render.shorten("abc"), "abc")
                test.eq(render.shorten("short123"), "short123")
            end)

            it("truncates long ids with ellipsis middle", function()
                local out = render.shorten("0123456789abcdef")
                test.eq(out, "01234567..cdef")
            end)

            it("stringifies non-string input", function()
                test.eq(render.shorten(42), "42")
            end)
        end)

        describe("clip", function()
            it("leaves short strings untouched", function()
                test.eq(render.clip("hello", 10), "hello")
            end)

            it("truncates with trailing ellipsis", function()
                test.eq(render.clip("0123456789", 5), "0123...")
            end)

            it("collapses newlines and runs of spaces", function()
                test.eq(render.clip("a\nb   c", 20), "a b c")
            end)

            it("encodes non-strings via json", function()
                local out = render.clip({ a = 1 }, 100)
                test.is_true(out:find('"a":1') ~= nil)
            end)
        end)

        describe("short_type", function()
            it("takes the tail after the colon", function()
                test.eq(render.short_type("foo:bar"), "bar")
            end)

            it("strips dataflow node prefixes", function()
                test.eq(
                    render.short_type("userspace.dataflow.node.agent:node"),
                    "node")
            end)

            it("handles types without colon", function()
                test.eq(render.short_type("plain_type"), "plain_type")
            end)
        end)

        describe("status_marker", function()
            it("maps known statuses", function()
                test.eq(render.status_marker("completed"), "OK ")
                test.eq(render.status_marker("failed"), "FAIL")
                test.eq(render.status_marker("running"), "RUN ")
                test.eq(render.status_marker("pending"), "WAIT")
                test.eq(render.status_marker("cancelled"), "CANC")
                test.eq(render.status_marker("terminated"), "TERM")
                test.eq(render.status_marker("template"), "TMPL")
            end)

            it("falls back to uppercase 4-char prefix", function()
                test.eq(render.status_marker("quantum"), "QUAN")
                test.eq(render.status_marker(nil), "?")
            end)
        end)

        describe("fmt_duration_ms", function()
            it("returns dash for nil or non-positive", function()
                test.eq(render.fmt_duration_ms(nil), "-")
                test.eq(render.fmt_duration_ms(0), "-")
                test.eq(render.fmt_duration_ms(-5), "-")
            end)

            it("formats sub-second as ms", function()
                test.eq(render.fmt_duration_ms(250), "250ms")
            end)

            it("formats sub-minute with seconds", function()
                test.eq(render.fmt_duration_ms(1500), "1.5s")
            end)

            it("formats minute+ with mmss", function()
                test.eq(render.fmt_duration_ms(125000), "2m05s")
            end)
        end)

        describe("node_title", function()
            it("prefers metadata.title", function()
                test.eq(
                    render.node_title({ metadata = { title = "hi" } }),
                    "hi")
            end)

            it("falls back to status_message", function()
                test.eq(
                    render.node_title({ metadata = { status_message = "msg" } }),
                    "msg")
            end)

            it("falls back to public_meta.title", function()
                test.eq(
                    render.node_title({ metadata = { public_meta = { title = "pm" } } }),
                    "pm")
            end)

            it("falls back to agent_id via state", function()
                test.eq(
                    render.node_title({ metadata = { state = { agent_id = "agent-7" } } }),
                    "agent-7")
            end)

            it("falls back to short_type of node.type", function()
                test.eq(
                    render.node_title({ type = "userspace.dataflow.node.agent:node" }),
                    "node")
            end)
        end)

        describe("node_error", function()
            it("returns metadata.error_message when present", function()
                test.eq(
                    render.node_error({ metadata = { error_message = "boom" } }),
                    "boom")
            end)

            it("joins code and message from metadata.error", function()
                test.eq(
                    render.node_error({ metadata = { error = { code = "E1", message = "oops" } } }),
                    "E1: oops")
            end)

            it("uses status_message only when node status=failed", function()
                test.eq(
                    render.node_error({ status = "failed", metadata = { status_message = "s" } }),
                    "s")
                test.is_nil(
                    render.node_error({ status = "completed", metadata = { status_message = "s" } }))
            end)

            it("returns nil when no error info present", function()
                test.is_nil(render.node_error({ metadata = {} }))
            end)
        end)

        describe("table_header / table_row", function()
            it("emits pipe-separated markdown header with divider", function()
                local h = render.table_header({ "a", "b", "c" })
                test.eq(h, "| a | b | c |\n|---|---|---|")
            end)

            it("escapes pipes and newlines in row cells", function()
                local r = render.table_row({ "hi|there", "line\nbreak", 42 })
                test.eq(r, "| hi\\|there | line break | 42 |")
            end)

            it("renders empty cells safely", function()
                local r = render.table_row({ "", "" })
                test.eq(r, "|  |  |")
            end)
        end)

        describe("to_ms", function()
            it("passes through sub-second epoch seconds", function()
                test.eq(render.to_ms(1700000000), 1700000000000)
            end)

            it("passes through ms-scale numbers unchanged", function()
                test.eq(render.to_ms(1700000000000), 1700000000000)
            end)

            it("parses RFC3339 without fractional seconds", function()
                local ms = render.to_ms("2024-01-01T00:00:00")
                test.is_true(ms > 0)
            end)

            it("parses RFC3339 with fractional seconds", function()
                local ms_plain = render.to_ms("2024-01-01T00:00:00")
                local ms_frac  = render.to_ms("2024-01-01T00:00:00.500")
                test.eq(ms_frac - ms_plain, 500)
            end)

            it("returns 0 for garbage input", function()
                test.eq(render.to_ms("not a date"), 0)
                test.eq(render.to_ms(nil), 0)
                test.eq(render.to_ms(true), 0)
            end)
        end)

    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
