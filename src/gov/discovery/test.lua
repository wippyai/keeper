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
                test.not_nil(list[1].meta)
                test.eq(list[1].meta.priority, 10)
            end)
        end)

        describe("list_by_priority_range", function()
            it("filters inclusive of both bounds", function()
                observers._registry = make_fake_registry(fixture())
                local list = observers.list_by_priority_range(10, 20)
                test.eq(#list, 2)
                test.eq(list[1].priority, 10)
                test.eq(list[2].priority, 20)
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
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
