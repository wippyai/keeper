local test = require("test")
local planner = require("planner")
local service = require("service")
local registry = require("registry")

local function assert_empty(parameters)
    test.eq(#parameters, 1, "the explicit empty binding survives")
    test.eq(parameters[1].name, "empty.fixture:text")
    test.eq(parameters[1].value, "")
end

local function define_tests()
    describe("explicit empty requirement bindings", function()
        for _, batch in ipairs({false, true}) do
            it("preserves a stored empty string through " .. (batch and "batch" or "single") .. " plan and install", function()
                local stored, read_err = registry.get("app.empty:dependency")
                test.is_nil(read_err)
                assert_empty(stored.data.parameters)
                local resolved, resolved_err = registry.get("empty.fixture:resolved")
                test.is_nil(resolved_err)
                test.eq(resolved.data.value, "")
                for _, supplied in ipairs({false, true}) do
                    local args = {id = stored.id, component = stored.data.component, version = stored.data.version}
                    if supplied then args.parameters = stored.data.parameters end
                    local request = batch and {dependencies = {args}} or args
                    local svc = service.new()
                    local result, plan_err = svc:plan_install(request)
                    test.is_nil(plan_err)
                    local payload = batch and result.install_payload.dependencies[1] or result.install_payload
                    assert_empty(payload.parameters)
                    test.is_true(result.applicable)
                    test.not_nil(result.native_plan.digest)
                    local installed, install_err = svc:install(result.install_payload)
                    test.is_nil(install_err)
                    test.not_nil(installed)
                    for _, step in ipairs(installed.execution) do test.eq(step.status, "ok") end
                    stored, read_err = registry.get(stored.id)
                    test.is_nil(read_err)
                    assert_empty(stored.data.parameters)
                    resolved, resolved_err = registry.get("empty.fixture:resolved")
                    test.is_nil(resolved_err)
                    test.eq(resolved.data.value, "")
                end
            end)
        end

        it("preserves provided full and bare empty strings while absent values stay implicit", function()
            for _, value in ipairs({"", "  "}) do
                for _, name in ipairs({"example.options:text", "text"}) do
                    local pl = planner.new({registry = {find = function() return {}, nil end}}) :: any
                    pl.existing_parameter_values = function() return {}, nil end
                    local graph = {{module = "example/options", namespace = "example.options", depth = 0,
                        direct = true, requirements = {{name = "text", default = "fallback", meta = {value_type = "string"}}}}}
                    local result, plan_err = pl:plan_requirements(graph, {{name = name, value = value}})
                    test.is_nil(plan_err)
                    test.eq(#result.install_parameters, 1)
                    test.eq(result.install_parameters[1].value, value)
                    graph[1].requirements[1].default = nil
                    result, plan_err = pl:plan_requirements(graph, {})
                    test.is_nil(plan_err)
                    test.eq(#result.install_parameters, 0)
                    test.eq(#result.missing, 1)
                    result, plan_err = pl:plan_requirements(graph, {{name = name, value = value}})
                    test.is_nil(plan_err)
                    test.eq(#result.missing, 1, "an empty binding does not satisfy a required value")
                end
            end
        end)

        it("places an explicit empty transitive binding on its own dependency", function()
            local pl = planner.new({registry = {find = function() return {}, nil end}}) :: any
            pl.existing_parameter_values = function() return {}, nil end
            pl.resolve_dependency_destination_args = function(_, args)
                args.id = "app.empty:child"
                return args, nil
            end
            local result, plan_err = pl:plan_requirements({{module = "example/options",
                namespace = "example.options", depth = 1, direct = false,
                requirements = {{name = "text", default = "fallback", meta = {value_type = "string"}}}}},
                {{name = "example.options:text", value = ""}})
            test.is_nil(plan_err)
            test.eq(#result.install_parameters, 0)
            local bindings, binding_err = pl:plan_binding_dependencies(result.requirements,
                {id = "app.empty:parent", data = {component = "example/parent"}})
            test.is_nil(binding_err)
            test.eq(#bindings, 1)
            test.eq(bindings[1].component, "example/options")
            test.eq(#bindings[1].parameters, 1)
            test.eq(bindings[1].parameters[1].value, "")
        end)
    end)
end

return {define_tests = test.run_cases(define_tests)}
