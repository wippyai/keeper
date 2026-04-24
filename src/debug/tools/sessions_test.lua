local test = require("test")
local sessions = require("sessions_tool")

local function define_tests()
    describe("sessions tool helpers", function()
        describe("fmt_int", function()
            it("stringifies integers", function()
                test.eq(sessions.fmt_int(42), "42")
            end)

            it("coerces numeric strings", function()
                test.eq(sessions.fmt_int("7"), "7")
            end)

            it("returns 0 for nil", function()
                test.eq(sessions.fmt_int(nil), "0")
            end)

            it("returns 0 for non-numeric", function()
                test.eq(sessions.fmt_int("abc"), "0")
            end)
        end)

        describe("since_from_window", function()
            it("returns since verbatim when provided", function()
                test.eq(
                    sessions.since_from_window("2026-04-01T00:00:00Z", 24),
                    "2026-04-01T00:00:00Z"
                )
            end)

            it("returns nil when neither since nor window given", function()
                test.is_nil(sessions.since_from_window(nil, nil))
            end)

            it("computes iso timestamp from window_hours", function()
                local now = 1700000000
                local got = sessions.since_from_window(nil, 1, now)
                test.eq(got, os.date("!%Y-%m-%dT%H:%M:%SZ", now - 3600))
            end)

            it("falls back to 168h default for non-numeric window", function()
                local now = 1700000000
                local got = sessions.since_from_window(nil, "nope", now)
                test.eq(got, os.date("!%Y-%m-%dT%H:%M:%SZ", now - 168 * 3600))
            end)

            it("accepts numeric string window", function()
                local now = 1700000000
                local got = sessions.since_from_window(nil, "2", now)
                test.eq(got, os.date("!%Y-%m-%dT%H:%M:%SZ", now - 2 * 3600))
            end)
        end)

        describe("parse_types_csv", function()
            it("splits comma-separated values", function()
                local out = sessions.parse_types_csv("user,assistant,function")
                test.eq(#out, 3)
                test.eq(out[1], "user")
                test.eq(out[2], "assistant")
                test.eq(out[3], "function")
            end)

            it("tolerates spaces around commas", function()
                local out = sessions.parse_types_csv("user, assistant , function")
                test.eq(#out, 3)
                test.eq(out[2], "assistant")
            end)

            it("returns nil for empty string", function()
                test.is_nil(sessions.parse_types_csv(""))
            end)

            it("returns nil for nil", function()
                test.is_nil(sessions.parse_types_csv(nil))
            end)

            it("returns nil for non-string", function()
                test.is_nil(sessions.parse_types_csv({ "user" }))
            end)

            it("returns nil when result is empty after split", function()
                test.is_nil(sessions.parse_types_csv(",,  ,"))
            end)
        end)

        describe("role_marker", function()
            it("maps known types to canonical markers", function()
                test.eq(sessions.role_marker("user"), "USER")
                test.eq(sessions.role_marker("assistant"), "ASSISTANT")
                test.eq(sessions.role_marker("function"), "FUNC")
                test.eq(sessions.role_marker("private_function"), "PFUNC")
                test.eq(sessions.role_marker("delegation"), "DELEG")
            end)

            it("uppercases unknown types", function()
                test.eq(sessions.role_marker("custom"), "CUSTOM")
            end)

            it("returns ? for nil type", function()
                test.eq(sessions.role_marker(nil), "?")
            end)
        end)

        describe("format_message_header", function()
            it("builds header with index, marker, date, id", function()
                local h = sessions.format_message_header(3, {
                    type = "user", date = "2026-04-21T10:00:00Z", message_id = "m-1",
                })
                test.eq(h, "## [3] USER  (2026-04-21T10:00:00Z)  `m-1`")
            end)

            it("appends function_name when present", function()
                local h = sessions.format_message_header(1, {
                    type = "function", date = "", message_id = "m-2",
                    metadata = { function_name = "do_thing" },
                })
                test.is_true(h:find("fn=do_thing", 1, true) ~= nil)
            end)

            it("appends status when present", function()
                local h = sessions.format_message_header(1, {
                    type = "assistant", date = "", message_id = "m-3",
                    metadata = { status = "completed" },
                })
                test.is_true(h:find("status=completed", 1, true) ~= nil)
            end)

            it("omits fn/status when metadata missing", function()
                local h = sessions.format_message_header(1, {
                    type = "user", date = "", message_id = "m-4",
                })
                test.is_nil(h:find("fn=", 1, true))
                test.is_nil(h:find("status=", 1, true))
            end)

            it("handles missing date/message_id", function()
                local h = sessions.format_message_header(1, { type = "user" })
                test.is_true(h:find("## [1] USER", 1, true) ~= nil)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
