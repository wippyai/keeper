local test = require("test")
local observers = require("observers")

local function define_tests()
    describe("gov.discovery.observers helpers", function()
        describe("is_valid_observer", function()
            it("accepts a well-formed observer entry", function()
                local entry = {
                    id = "ns:obs",
                    meta = { type = observers.OBSERVER_TYPE, priority = 10 },
                }
                test.is_true(observers.is_valid_observer(entry))
            end)

            it("rejects nil and non-table input", function()
                test.is_false(observers.is_valid_observer(nil))
                test.is_false(observers.is_valid_observer("x"))
                test.is_false(observers.is_valid_observer(42))
            end)

            it("rejects entries with missing or non-table meta", function()
                test.is_false(observers.is_valid_observer({ id = "x" }))
                test.is_false(observers.is_valid_observer({ id = "x", meta = "bogus" }))
            end)

            it("rejects entries whose meta.type is not the observer type", function()
                test.is_false(observers.is_valid_observer({
                    id = "x",
                    meta = { type = "something.else", priority = 10 },
                }))
            end)

            it("rejects entries without a priority", function()
                test.is_false(observers.is_valid_observer({
                    id = "x",
                    meta = { type = observers.OBSERVER_TYPE },
                }))
            end)
        end)

        describe("entry_to_observer_info", function()
            it("projects id, priority, namespace, kind, tags verbatim", function()
                local info = observers.entry_to_observer_info({
                    id = "ns:obs",
                    namespace = "ns",
                    kind = "function.lua",
                    meta = {
                        type = observers.OBSERVER_TYPE,
                        priority = 25,
                        name = "nm",
                        comment = "cm",
                        description = "ds",
                        tags = { "a", "b" },
                    },
                })
                test.eq(info.id, "ns:obs")
                test.eq(info.priority, 25)
                test.eq(info.namespace, "ns")
                test.eq(info.kind, "function.lua")
                test.eq(info.name, "nm")
                test.eq(info.comment, "cm")
                test.eq(info.description, "ds")
                test.eq(info.tags[1], "a")
                test.eq(info.tags[2], "b")
            end)

            it("defaults string fields to empty and tags to empty table when meta omits them", function()
                local info = observers.entry_to_observer_info({
                    id = "ns:obs",
                    meta = { type = observers.OBSERVER_TYPE, priority = 5 },
                })
                test.eq(info.name, "")
                test.eq(info.comment, "")
                test.eq(info.description, "")
                test.not_nil(info.tags)
                test.eq(#info.tags, 0)
            end)
        end)

        describe("aggregate_stats", function()
            it("returns zero-value stats for empty input", function()
                local stats = observers.aggregate_stats({})
                test.eq(stats.total_count, 0)
                test.not_nil(stats.by_namespace)
                test.eq(next(stats.by_namespace), nil)
                test.is_nil(stats.priority_range.min)
                test.is_nil(stats.priority_range.max)
            end)

            it("returns zero-value stats for non-table input", function()
                local stats = observers.aggregate_stats(nil)
                test.eq(stats.total_count, 0)
                test.is_nil(stats.priority_range.min)
                local stats2 = observers.aggregate_stats("x")
                test.eq(stats2.total_count, 0)
            end)

            it("counts total and groups by namespace", function()
                local stats = observers.aggregate_stats({
                    { namespace = "app.x", priority = 10 },
                    { namespace = "app.x", priority = 20 },
                    { namespace = "app.y", priority = 5 },
                })
                test.eq(stats.total_count, 3)
                test.eq(stats.by_namespace["app.x"], 2)
                test.eq(stats.by_namespace["app.y"], 1)
            end)

            it("uses 'unknown' bucket when namespace is missing", function()
                local stats = observers.aggregate_stats({
                    { priority = 1 },
                    { namespace = "app.x", priority = 2 },
                })
                test.eq(stats.by_namespace["unknown"], 1)
                test.eq(stats.by_namespace["app.x"], 1)
            end)

            it("tracks priority min and max across the list", function()
                local stats = observers.aggregate_stats({
                    { namespace = "a", priority = 50 },
                    { namespace = "a", priority = 10 },
                    { namespace = "a", priority = 30 },
                })
                test.eq(stats.priority_range.min, 10)
                test.eq(stats.priority_range.max, 50)
            end)

            it("ignores rows with nil priority for range but still counts them", function()
                local stats = observers.aggregate_stats({
                    { namespace = "a" },
                    { namespace = "a", priority = 7 },
                })
                test.eq(stats.total_count, 2)
                test.eq(stats.priority_range.min, 7)
                test.eq(stats.priority_range.max, 7)
            end)
        end)
        describe("failure_message", function()
            it("returns nil for a successful observer", function()
                test.is_nil(observers.failure_message({ success = true }, nil))
                test.is_nil(observers.failure_message(nil, nil))
            end)

            it("reports a call error", function()
                test.eq(observers.failure_message(nil, "scope projection did not finish"),
                    "scope projection did not finish")
            end)

            it("reports a result with success = false", function()
                test.eq(observers.failure_message({ success = false, message = "sync timeout" }, nil),
                    "sync timeout")
            end)
        end)

        describe("run_observers", function()
            local function with_stubs(calls, fn)
                observers._registry = {
                    find = function()
                        return {
                            { id = "a:ok", meta = { type = observers.OBSERVER_TYPE, priority = 1 } },
                            { id = "b:err", meta = { type = observers.OBSERVER_TYPE, priority = 2 } },
                            { id = "c:fail", meta = { type = observers.OBSERVER_TYPE, priority = 3 } },
                        }
                    end,
                }
                observers._funcs = {
                    new = function()
                        return {
                            call = function(_, id)
                                local reply = calls[id]
                                if reply then return reply[1], reply[2] end
                                return { success = true }, nil
                            end,
                        }
                    end,
                }
                local ok, res = pcall(fn)
                observers._registry = nil
                observers._funcs = nil
                if not ok then error(res) end
                return res
            end

            it("returns a warning for each failed observer", function()
                local warnings = with_stubs({
                    ["b:err"] = { nil, "scope projection did not finish" },
                    ["c:fail"] = { { success = false, message = "sync timeout" }, nil },
                }, function()
                    return observers.run_observers({ {} }, { success = true }, "req-1", "user-1")
                end)
                test.eq(#warnings, 2)
                test.eq(warnings[1].observer, "b:err")
                test.eq(warnings[1].message, "scope projection did not finish")
                test.eq(warnings[2].observer, "c:fail")
                test.eq(warnings[2].message, "sync timeout")
            end)

            it("returns no warnings when every observer succeeds", function()
                local warnings = with_stubs({}, function()
                    return observers.run_observers({ {} }, { success = true }, "req-2", "user-2")
                end)
                test.eq(#warnings, 0)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
