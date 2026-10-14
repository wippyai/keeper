local test = require("test")
local planner = require("planner")
local registry = require("registry")
local json = require("json")

local function define_tests()
    describe("implicit requirement defaults", function()
        local function plan(parameters, batch)
            local stored, read_err = registry.get("app.defaults:dependency")
            test.is_nil(read_err)
            test.eq(#(stored.data.parameters or {}), 0)
            local resolved, resolved_err = registry.get("defaults.fixture:resolved")
            test.is_nil(resolved_err)
            test.eq(resolved.data.value, "default-members")
            local gov = {
                get_managed_namespaces = function() return {"app.defaults"} end,
                is_namespace_managed = function(ns) return ns == "app.defaults" end,
            }
            local pl = planner.new({gov = gov}) :: any
            local native_parameters
            local preview = pl.preview_dependencies
            pl.preview_dependencies = function(self, dependencies)
                native_parameters = dependencies[1].data.parameters or {}
                return preview(self, dependencies)
            end
            local args = {
                id = stored.id, component = stored.data.component, version = stored.data.version,
                parameters = parameters or {},
            }
            local result, plan_err = pl:plan_install(batch and {dependencies = {args}} or args)
            test.is_nil(plan_err)
            if batch then
                test.is_true(result.applicable)
                test.not_nil(result.native_plan.digest)
                result = result.plans[1]
            end
            test.is_true(result.applicable)
            test.not_nil(result.native_plan.digest)
            test.eq(result.requirements[1].value, "default-members")
            test.eq(result.parameter_values["defaults.fixture:user_security_scope"], "default-members")
            test.eq(result.recommended_parameters[1].value, "default-members")
            test.eq(#native_parameters, #result.install_payload.parameters)
            return result
        end

        it("leaves a default absent from the install payload", function()
            for _, batch in ipairs({false, true}) do
                local result = plan(nil, batch)
                test.eq(result.requirements[1].value_source, "default")
                test.eq(#result.install_payload.parameters, 0)
            end
        end)

        it("retains an explicit binding equal to the default", function()
            for _, batch in ipairs({false, true}) do
                local result = plan({{name = "defaults.fixture:user_security_scope", value = "default-members"}}, batch)
                test.eq(result.requirements[1].value_source, "provided")
                test.eq(#result.install_payload.parameters, 1)
                test.eq(result.install_payload.parameters[1].name, "defaults.fixture:user_security_scope")
                test.eq(result.install_payload.parameters[1].value, "default-members")
            end
        end)

        it("keeps typed implicit values resolved and typed recorded values explicit", function()
            local function assert_value(actual, expected)
                test.eq(type(actual), type(expected))
                local actual_json, actual_err = json.encode(actual)
                local expected_json, expected_err = json.encode(expected)
                test.is_nil(actual_err)
                test.is_nil(expected_err)
                test.eq(actual_json, expected_json)
            end
            for _, value in ipairs({false, 0, "members", {}, {"member"}, {enabled = false}}) do
                local pl = planner.new({registry = {find = function() return {}, nil end}}) :: any
                pl.existing_parameter_values = function() return {}, nil end
                local graph = {{module = "example/options", namespace = "example.options", depth = 0,
                    direct = true, requirements = {{name = "value", default = value}}}}
                local result, plan_err = pl:plan_requirements(graph, {})
                test.is_nil(plan_err)
                test.eq(result.requirements[1].value_source, "default")
                assert_value(result.values["example.options:value"], value)
                test.eq(type(result.install_parameters), "table")
                test.eq(#result.install_parameters, 0)
                pl.existing_parameter_values = function()
                    return {{name = "example.options:value", value = value,
                        dependency_id = "app:options", component = "example/options"}}, nil
                end
                result, plan_err = pl:plan_requirements(graph, {})
                test.is_nil(plan_err)
                test.eq(result.requirements[1].value_source, "existing")
                test.eq(#result.install_parameters, 1)
                assert_value(result.install_parameters[1].value, value)
            end
        end)
    end)
end

return {define_tests = test.run_cases(define_tests)}
