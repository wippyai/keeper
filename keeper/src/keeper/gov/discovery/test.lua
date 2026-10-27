local test = require("test")
local observers = require("observers")

local function make_fake_registry(entries_by_id)
    local entry_list = {}
    for _, e in pairs(entries_by_id) do table.insert(entry_list, e) end
    return {
        get = function(id)
            local e = entries_by_id[id]
            if not e then return nil, "not found" end
            return e
        end,
        find = function(query)
            local result = {}
            for _, e in ipairs(entry_list) do
                local matches = true
                if query["meta.type"] and (not e.meta or e.meta.type ~= query["meta.type"]) then
                    matches = false
                end
                if matches and query[".ns"] and e.namespace ~= query[".ns"] then
                    matches = false
                end
                if matches then table.insert(result, e) end
            end
            return result
        end,
    }
end

local function define_tests()
    describe("Observers", function()
        local saved_registry

        before_each(function() saved_registry = observers._registry end)
        after_each(function() observers._registry = saved_registry end)

        local function fixture()
            return {
                ["ns.a:one"] = {
                    id = "ns.a:one", namespace = "ns.a", kind = "function.lua",
                    meta = { type = "registry.observer", name = "one", priority = 30, tags = { "fast" } },
                },
                ["ns.a:two"] = {
                    id = "ns.a:two", namespace = "ns.a", kind = "function.lua",
                    meta = { type = "registry.observer", name = "two", priority = 10 },
                },
                ["ns.b:three"] = {
                    id = "ns.b:three", namespace = "ns.b", kind = "function.lua",
                    meta = { type = "registry.observer", name = "three", priority = 20, tags = { "slow" } },
                },
                ["ns.c:invalid"] = {
                    id = "ns.c:invalid", namespace = "ns.c", kind = "function.lua",
                    meta = { type = "registry.observer", name = "missing-priority" },
                },
                ["ns.c:not_observer"] = {
                    id = "ns.c:not_observer", namespace = "ns.c", kind = "function.lua",
                    meta = { type = "other", priority = 5 },
                },
            }
        end

        describe("get_by_id", function()
            it("returns observer info for valid entries", function()
                observers._registry = make_fake_registry(fixture())
                local info, err = observers.get_by_id("ns.a:one")
                test.is_nil(err)
                test.not_nil(info)
                test.eq(info.id, "ns.a:one")
                test.eq(info.priority, 30)
                test.eq(info.namespace, "ns.a")
            end)

            it("rejects missing id", function()
                local _, err = observers.get_by_id(nil)
                test.not_nil(err)
                test.is_true(err:find("required") ~= nil)
            end)

            it("errors on entry without observer type", function()
                observers._registry = make_fake_registry(fixture())
                local _, err = observers.get_by_id("ns.c:not_observer")
                test.not_nil(err)
            end)

            it("errors on observer without priority", function()
                observers._registry = make_fake_registry(fixture())
                local _, err = observers.get_by_id("ns.c:invalid")
                test.not_nil(err)
                test.is_true(err:find("valid observer") ~= nil)
            end)
        end)

        describe("list_all", function()
            it("returns valid observers sorted by priority ascending", function()
                observers._registry = make_fake_registry(fixture())
                local list = observers.list_all()
                test.eq(#list, 3)
                test.eq(list[1].id, "ns.a:two")
                test.eq(list[2].id, "ns.b:three")
                test.eq(list[3].id, "ns.a:one")
            end)

            it("returns empty list when no observers match", function()
                observers._registry = make_fake_registry({})
                local list = observers.list_all()
                test.eq(#list, 0)
            end)

            it("raw_entries=true returns original entries", function()
                observers._registry = make_fake_registry(fixture())
                local list = observers.list_all({ raw_entries = true })
                test.eq(#list, 3)
                local row = list[1]
                if not row then error("observer row missing") end
                local meta = rawget(row, "meta")
                test.not_nil(meta)
                test.eq(meta.priority, 10)
            end)
        end)

        describe("list_by_priority_range", function()
            it("filters inclusive of both bounds", function()
                observers._registry = make_fake_registry(fixture())
                local list = observers.list_by_priority_range(10, 20)
                if not list then error("priority list missing") end
                test.eq(#list, 2)
                local first = list[1]
                local second = list[2]
                if not first or not second then error("priority rows missing") end
                test.eq(first.priority, 10)
                test.eq(second.priority, 20)
            end)

            it("requires both bounds", function()
                local _, err = observers.list_by_priority_range(10, nil)
                test.not_nil(err)
                test.is_true(err:find("required") ~= nil)
            end)
        end)

        describe("find_observers", function()
            it("filters by namespace", function()
                observers._registry = make_fake_registry(fixture())
                local list = observers.find_observers({ namespace = "ns.a" })
                test.eq(#list, 2)
                for _, obs in ipairs(list) do
                    test.eq(obs.namespace, "ns.a")
                end
            end)

            it("filters by min_priority", function()
                observers._registry = make_fake_registry(fixture())
                local list = observers.find_observers({ min_priority = 20 })
                test.eq(#list, 2)
            end)

            it("filters by max_priority", function()
                observers._registry = make_fake_registry(fixture())
                local list = observers.find_observers({ max_priority = 15 })
                test.eq(#list, 1)
                test.eq(list[1].priority, 10)
            end)
        end)

        describe("get_stats", function()
            it("reports counts and priority range", function()
                observers._registry = make_fake_registry(fixture())
                local stats = observers.get_stats()
                test.eq(stats.total_count, 3)
                test.eq(stats.by_namespace["ns.a"], 2)
                test.eq(stats.by_namespace["ns.b"], 1)
                test.eq(stats.priority_range.min, 10)
                test.eq(stats.priority_range.max, 30)
            end)

            it("handles empty observer set", function()
                observers._registry = make_fake_registry({})
                local stats = observers.get_stats()
                test.eq(stats.total_count, 0)
                test.is_nil(stats.priority_range.min)
                test.is_nil(stats.priority_range.max)
            end)
        end)

        describe("before_apply observers", function()
            local saved_funcs
            before_each(function() saved_funcs = observers._funcs end)
            after_each(function() observers._funcs = saved_funcs end)

            local function phased()
                return {
                    ["ns.a:after"] = {
                        id = "ns.a:after", namespace = "ns.a", kind = "function.lua",
                        meta = { type = "registry.observer", priority = 10 },
                    },
                    ["ns.s:scopes"] = {
                        id = "ns.s:scopes", namespace = "ns.s", kind = "function.lua",
                        meta = { type = "registry.observer", priority = 10, phase = "before_apply",
                            kinds = { "security.policy" } },
                    },
                }
            end

            local function fake_funcs(handlers, calls)
                return {
                    new = function()
                        return {
                            call = function(_, id, args)
                                calls[#calls + 1] = { id = id, args = args }
                                local handler = handlers[id]
                                if not handler then return { success = true }, nil end
                                return handler(args)
                            end,
                        }
                    end,
                }
            end

            local planned = {
                { op = "create", entry = { id = "mod.api:list.endpoint", kind = "http.endpoint", meta = {}, data = {} } },
                { op = "create", entry = { id = "mod.security:access", kind = "security.policy",
                    meta = { intent = "module_access" }, data = { groups = {} } } },
                { op = "delete", entry = { id = "mod.security:old", kind = "security.policy",
                    meta = {}, data = { policy = { resources = "x" } } } },
            }

            it("lists only before_apply observers for the plan phase", function()
                observers._registry = make_fake_registry(phased())
                local list = observers.list_before_apply()
                test.eq(#list, 1)
                test.eq(list[1].id, "ns.s:scopes")
            end)

            it("keeps before_apply observers out of the post-apply run", function()
                observers._registry = make_fake_registry(phased())
                local calls = {}
                observers._funcs = fake_funcs({}, calls)
                local warnings = observers.run_observers({}, { success = true }, "r1", "u1")
                test.eq(#warnings, 0)
                test.eq(#calls, 1)
                test.eq(calls[1].id, "ns.a:after")
            end)

            it("passes the planned operations of the declared kinds and returns the observer ops", function()
                observers._registry = make_fake_registry(phased())
                local calls = {}
                observers._funcs = fake_funcs({
                    ["ns.s:scopes"] = function()
                        return { ops = { { kind = "entry.update", entry = {
                            id = "sec.groups:members", kind = "security.scope", data = { policies = { "mod.security:access" } },
                        } } } }, nil
                    end,
                }, calls)
                local ops, warnings = observers.run_before_apply({}, planned, "r1", "u1")
                test.eq(#warnings, 0)
                test.eq(#calls, 1)
                test.eq(calls[1].args.phase, "before_apply")
                test.eq(#calls[1].args.planned, 2)
                test.eq(calls[1].args.planned[1].entry.id, "mod.security:access")
                test.eq(calls[1].args.planned[2].op, "delete")
                test.eq(calls[1].args.planned[2].entry.id, "mod.security:old")
                test.is_nil(calls[1].args.planned[2].entry.data)
                test.eq(#ops, 1)
                test.eq(ops[1].entry.id, "sec.groups:members")
            end)

            it("refuses ops on entries the changeset already touches and invalid ops", function()
                observers._registry = make_fake_registry(phased())
                observers._funcs = fake_funcs({
                    ["ns.s:scopes"] = function()
                        return { ops = {
                            { kind = "entry.update", entry = { id = "mod.security:access", kind = "security.policy" } },
                            { kind = "entry.rename", entry = { id = "x:y", kind = "security.scope" } },
                            { kind = "entry.create", entry = { id = "x:z" } },
                        } }, nil
                    end,
                }, {})
                local ops, warnings = observers.run_before_apply({}, planned, "r1", "u1")
                test.eq(#ops, 0)
                test.eq(#warnings, 3)
                test.is_true(warnings[1].message:find("conflicts with the changeset", 1, true) ~= nil)
            end)

            it("turns an observer failure into a warning and adds no ops", function()
                observers._registry = make_fake_registry(phased())
                observers._funcs = fake_funcs({
                    ["ns.s:scopes"] = function() return nil, "projection unavailable" end,
                }, {})
                local ops, warnings = observers.run_before_apply({}, planned, "r1", "u1")
                test.eq(#ops, 0)
                test.eq(#warnings, 1)
                test.eq(warnings[1].observer, "ns.s:scopes")
                test.eq(warnings[1].message, "projection unavailable")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
