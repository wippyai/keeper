-- SPDX-License-Identifier: MPL-2.0
local test = require("test")
local planner = require("planner")
local registry = require("registry")
local native_preview = require("native_preview")
local new_planner = planner.new

local MARKER = "app.hub_preview:concurrent"
local original

-- Commit through the real registry between snapshot staging and native planning.
-- Only the fixture writes; a Hub preview must never apply its proposed entries.
local function moved_snapshot(on_plan)
    local instances, plans = {}, 0
    local governance = {get_managed_namespaces = function() return {"app.defaults"} end,
        is_namespace_managed = function(ns) return ns == "app.defaults" end}
    local adapter = {get = registry.get, find = registry.find, snapshot = function()
        local snapshot = assert(registry.snapshot())
        return {
            state = function() return snapshot:state() end,
            version = function() return snapshot:version() end,
            changes = function()
                local changes = snapshot:changes()
                return {
                    create = function(_, entry) return changes:create(entry) end,
                    update = function(_, entry) return changes:update(entry) end,
                    plan = function()
                        plans = plans + 1
                        local failure = on_plan(plans, snapshot)
                        if failure then return nil, failure end
                        return changes:plan()
                    end,
                }
            end,
        }
    end}
    planner.new = function()
        local instance = new_planner({registry = adapter, gov = governance})
        instances[#instances + 1] = instance
        return instance
    end
    return function(parameters, batch)
        local entry = assert(registry.get("app.defaults:dependency"))
        local args = {id = entry.id, component = entry.data.component,
            version = entry.data.version, parameters = parameters}
        return planner.plan_install(batch and {dependencies = {args}} or args)
    end, function() return #instances, plans, instances end
end

local function commit_marker(attempt: integer)
    local snapshot = assert(registry.snapshot())
    local changes = snapshot:changes()
    local entry: {id: string, kind: string, data: any, meta: {[string]: any}} = {
        id = MARKER, kind = "registry.entry", data = {attempt = attempt}, meta = {},
    }
    if attempt == 1 then changes:create(entry) else changes:update(entry) end
    local applied, err = changes:apply()
    test.is_nil(err)
    test.not_nil(applied)
end

local function parameters()
    return {{name = "defaults.fixture:user_security_scope", value = "preview-only"}}
end

local function define_tests()
    describe("native Hub preview contention", function()
        test.before_each(function() original = assert(registry.current_version()) end)
        test.after_each(function()
            planner.new = new_planner
            local restored, err = registry.apply_version(original)
            test.is_nil(err)
            test.is_true(restored)
        end)

        it("recomputes a refused read-only preview from fresh state without applying the dependency", function()
            local run, counts = moved_snapshot(function(attempt)
                if attempt == 1 then commit_marker(attempt) end
            end)
            local result, err = run(parameters())
            test.is_nil(err, tostring(err))
            test.not_nil(result.native_plan.digest)
            local attempts, plans, instances = counts()
            test.eq(attempts, 2)
            test.eq(plans, 2)
            local found
            for _, entry in ipairs(instances[2].native_entries) do if entry.id == MARKER then found = entry end end
            test.not_nil(found, "the recovered preview must include the intervening registry commit")
            test.eq(found.data.attempt, 1)
            test.eq(assert(registry.get("defaults.fixture:resolved")).data.value, "default-members",
                "planning must not apply the proposed requirement binding")
        end)

        it("restarts a complete read-only batch with a fresh planner", function()
            local run, counts = moved_snapshot(function(attempt)
                if attempt == 1 then commit_marker(attempt) end
            end)
            local result, err = run(parameters(), true)
            test.is_nil(err, tostring(err))
            test.is_true(result.applicable)
            test.eq(#result.plans, 1)
            local attempts, plans = counts()
            test.eq(attempts, 2)
            test.eq(plans, 3, "the recovered batch includes its final native preview")
            test.eq(assert(registry.get("defaults.fixture:resolved")).data.value, "default-members")
        end)

        it("keeps the install-side planner instance single-attempt", function()
            local _, counts = moved_snapshot(function(attempt) commit_marker(attempt) end)
            local entry = assert(registry.get("app.defaults:dependency"))
            local instance = planner.new()
            local result, err = instance:plan_install({id = entry.id, component = entry.data.component,
                version = entry.data.version, parameters = parameters()})
            test.is_nil(result)
            test.is_true(errors.is(err, errors.CONFLICT))
            local attempts, plans = counts()
            test.eq(attempts, 1)
            test.eq(plans, 1)
            test.eq(assert(registry.get("defaults.fixture:resolved")).data.value, "default-members")
        end)

        it("stops after a second native conflict and preserves its typed details", function()
            local run, counts = moved_snapshot(function(attempt) commit_marker(attempt) end)
            local result, err = run(parameters())
            test.is_nil(result)
            test.is_true(errors.is(err, errors.CONFLICT))
            test.is_true(err:retryable())
            test.is_true(err:details().current_version > err:details().plan_version)
            local attempts, plans = counts()
            test.eq(attempts, 2, "registry contention must not cause an unbounded loop")
            test.eq(plans, 2)
            test.eq(assert(registry.get(MARKER)).data.attempt, 2)
            test.eq(assert(registry.get("defaults.fixture:resolved")).data.value, "default-members")
        end)

        for _, kind in ipairs({errors.INVALID, errors.UNAVAILABLE, errors.CONFLICT}) do
            it("preserves an unrelated " .. kind .. " error without retrying", function()
                local failure = errors.new({kind = kind, retryable = true, message = "unrelated planning failure"})
                local run, counts = moved_snapshot(function() return failure end)
                local result, err = run(parameters())
                test.is_nil(result)
                test.eq(err, failure)
                local attempts, plans = counts()
                test.eq(attempts, 1)
                test.eq(plans, 1)
            end)
        end

        it("does not classify a legacy string by its error message", function()
            local failure = "registry moved since the plan was computed"
            local attempts = 0
            local result, err = native_preview.run(function()
                attempts = attempts + 1
                return nil, failure, native_preview.refusal(failure, {})
            end)
            test.is_nil(result)
            test.eq(err, failure)
            test.eq(attempts, 1)
        end)

        it("re-reads concurrent host bindings instead of replaying earlier requirement decisions", function()
            local run, counts = moved_snapshot(function(attempt)
                if attempt ~= 1 then return end
                local entry = assert(registry.get("app.defaults:dependency"))
                local changes = assert(registry.snapshot()):changes()
                changes:update({id = entry.id, kind = entry.kind, meta = entry.meta, data = {
                    component = entry.data.component, version = entry.data.version,
                    parameters = {{name = "defaults.fixture:user_security_scope", value = "concurrent-binding"}},
                }})
                local applied, err = changes:apply()
                test.is_nil(err)
                test.not_nil(applied)
            end)
            local result, err = run(nil)
            test.is_nil(err, tostring(err))
            test.eq(result.parameter_values["defaults.fixture:user_security_scope"], "concurrent-binding")
            test.eq(result.install_payload.parameters[1].value, "concurrent-binding")
            local instances, plans = counts()
            test.eq(instances, 2)
            test.eq(plans, 2)
            test.eq(assert(registry.get("defaults.fixture:resolved")).data.value, "concurrent-binding")
        end)

        for _, variant in ipairs({"nonretryable", "different-base"}) do
            it("does not repeat a " .. variant .. " version conflict", function()
                local failure
                local run, counts = moved_snapshot(function(_, snapshot)
                    local version = snapshot:version():id()
                    failure = errors.new({kind = errors.CONFLICT, retryable = variant ~= "nonretryable",
                        message = "unrelated version conflict", details = {
                            plan_version = variant == "different-base" and version + 1 or version,
                            current_version = version + 2}})
                    return failure
                end)
                local result, err = run(parameters())
                test.is_nil(result)
                test.eq(err, failure)
                local attempts, plans = counts()
                test.eq(attempts, 1)
                test.eq(plans, 1)
            end)
        end
    end)
end
return {define_tests = test.run_cases(define_tests)}
