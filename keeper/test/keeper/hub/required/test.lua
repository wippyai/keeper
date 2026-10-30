-- SPDX-License-Identifier: MPL-2.0
local test = require("test")
local planner = require("planner")
local registry = require("registry")

local function define_tests()
    describe("native required host bindings", function()
        for _, shape in ipairs({"single", "batch", "batch_with_peer"}) do
            local batch = shape ~= "single"
            for _, mode in ipairs({"missing", "parameters", "reviewed"}) do
                local supplied = mode ~= "missing"
                it("preflights a new required value, " .. shape .. ", binding " .. mode, function()
                    local before = assert(registry.snapshot()):version():id()
                    local gov = {
                        get_managed_namespaces = function() return {"app.required", "app.empty"} end,
                        is_namespace_managed = function(ns) return ns == "app.required" or ns == "app.empty" end,
                    }
                    -- Supply only catalog metadata; linking still uses the real
                    -- local module replacement and registry changeset pipeline.
                    local catalog = {versions = {list = function(component)
                        if component == "keeper/empty-fixture" then
                            return {items = {{version = "1.0.0", dependencies = {},
                                requirements = {{name = "text", namespace = "empty.fixture",
                                    default = "", meta = {value_type = "string"}}}}}, total = 1}, nil
                        end
                        test.eq(component, "keeper/required-fixture")
                        return {items = {{version = "1.0.0", dependencies = {},
                            requirements = {{name = "tenant", namespace = "required.fixture",
                                meta = {value_type = "string"}}}}}, total = 1}, nil
                    end}}
                    local previews = 0
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
                                        previews = previews + 1
                                        return changes:plan()
                                    end,
                                }
                            end,
                        }
                    end}
                    local instance = planner.new({gov = gov, catalog = catalog, registry = adapter})
                    local input = {id = "app.required:dependency", component = "keeper/required-fixture", version = "1.0.0"}
                    local binding = {name = "required.fixture:tenant", value = "reviewed-tenant"}
                    if mode == "reviewed" then input.requirement_bindings = {binding}
                    elseif mode == "parameters" then input.parameters = {binding} end
                    local dependencies = {input}
                    if shape == "batch_with_peer" then
                        dependencies[#dependencies + 1] = {id = "app.empty:dependency",
                            component = "keeper/empty-fixture", version = "1.0.0"}
                    end
                    local result, err = instance:plan_install(batch and {dependencies = dependencies} or input)
                    test.is_nil(err, tostring(err))
                    test.eq(result.applicable, supplied)
                    if batch then
                        test.is_true(previews <= 3, "binding preflight must remain bounded")
                        if mode == "parameters" then
                            test.eq(previews, 2, "complete batches keep their existing native planning cost")
                        end
                    end
                    local plan = batch and result.plans[1] or result
                    if supplied then
                        test.not_nil(result.native_plan.digest)
                        test.eq(plan.parameter_values["required.fixture:tenant"], "reviewed-tenant")
                        test.eq(plan.install_payload.parameters[1].value, "reviewed-tenant")
                        if shape == "batch_with_peer" then
                            test.eq(result.plans[2].parameter_values["empty.fixture:text"], "",
                                "recovering one root must preserve another root's saved binding")
                            test.eq(result.plans[2].install_payload.parameters[1].value, "",
                                "the peer binding must stay explicit in the reviewed payload")
                        end
                    else
                        test.is_nil(result.native_plan, "blocked planning must not fabricate native validation")
                        test.eq(plan.missing_requirements[1], "required.fixture:tenant")
                    end
                    test.eq(assert(registry.snapshot()):version():id(), before, "preflight must not apply its changes")
                    local installed = registry.get("required.fixture:resolved")
                    test.is_nil(installed, "preflight must not install the proposed module")
                end)
            end
        end
    end)
end

return {define_tests = test.run_cases(define_tests)}
