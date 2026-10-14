local test = require("test")
local security = require("security")
local registry = require("registry")
local funcs = require("funcs")
local catalog = require("catalog")
local dependencies = require("dependencies")
local migrations = require("migrations")
local tool_caller = require("tool_caller")

local DISCOVERY_POLICY = "keeper.hub.security:admin_discovery"
local CALL_POLICY = "keeper.hub.security:admin_call"
local CATALOG_POLICY = "keeper.hub.security:admin_catalog"
local PROBE = "keeper.hub.security:security_test"
local ADMIN_GROUP = "app.security:admin"
local USER_GROUP = "app.security:user"
local PERMISSIVE_GROUP = "keeper.hub.security:test_permissive"

local TRAIT_ID = "keeper.agents.traits.hub:operator"
local TOOL_IDS = {
    "keeper.hub.tools:catalog",
    "keeper.hub.tools:dependencies",
    "keeper.hub.tools:migrations",
}

local function includes(values, expected)
    for _, value in ipairs(values or {}) do
        if value == expected then return true end
    end
    return false
end

local function actor(id)
    return security.new_actor(id, { test = true })
end

local function fake_hub(calls)
    return {
        modules = {
            list = function(options)
                calls[#calls + 1] = { method = "modules.list", options = options }
                return { items = { { name = "keeper/keeper" } }, total = 1 }, nil
            end,
            search = function(query, options)
                calls[#calls + 1] = { method = "modules.search", query = query, options = options }
                return { items = { { name = "keeper/keeper" } }, total = 1 }, nil
            end,
            readme = function(module_ref, options)
                calls[#calls + 1] = { method = "modules.readme", module = module_ref, options = options }
                return { content = "Keeper docs", filename = "README.md", version = options.version }, nil
            end,
        },
        versions = {
            list = function(module_ref, options)
                calls[#calls + 1] = { method = "versions.list", module = module_ref, options = options }
                return { items = { { version = "0.5.57" } }, total = 1 }, nil
            end,
        },
    }
end

local function run_agent_probe(input)
    local call_id = "hub_catalog_security_probe"
    local caller = tool_caller.new()
    local validated
    local validation_err

    if input.prevalidated then
        validated = {
            [call_id] = {
                call_id = call_id,
                name = "hub_catalog",
                args = { action = "versions" },
                registry_id = TOOL_IDS[1],
                meta = {},
                valid = true,
            },
        }
    else
        validated, validation_err = caller:validate({
            {
                id = call_id,
                name = "hub_catalog",
                arguments = { action = "versions" },
                registry_id = TOOL_IDS[1],
            },
        })
    end

    local results = caller:execute({}, validated or {})
    local row = results[call_id] or {}
    return {
        validation_error = validation_err and tostring(validation_err) or nil,
        execution_error = row.error and tostring(row.error) or nil,
        result = row.result,
    }
end

local function run_discovery_probe()
    local direct, direct_err = registry.get(TRAIT_ID)
    local found, find_err = registry.find({ [".id"] = TRAIT_ID })
    return {
        direct = direct ~= nil,
        direct_error = direct_err and tostring(direct_err) or nil,
        found = #(found or {}),
        find_error = find_err and tostring(find_err) or nil,
    }
end

local function define_tests(input)
    if type(input) == "table" and input.agent_probe then
        return run_agent_probe(input)
    end
    if type(input) == "table" and input.discovery_probe then
        return run_discovery_probe()
    end

    test.describe("Hub Administrator native capability", function()
        test.it("bundles the public catalog, dependency, and migration tools", function()
            local trait, trait_err = registry.get(TRAIT_ID)
            test.is_nil(trait_err)
            test.not_nil(trait)
            test.eq(trait.meta.title, "Hub Administrator")
            test.is_true(trait.meta.public)
            local trait_data = trait.data :: any
            test.eq(#trait_data.tools, 3)
            for _, tool_id in ipairs(TOOL_IDS) do
                test.is_true(includes(trait_data.tools, tool_id))
                local tool, tool_err = registry.get(tool_id)
                test.is_nil(tool_err)
                test.not_nil(tool)
                test.eq(tool.meta.type, "tool")
                test.is_true(tool.meta.public)
            end
        end)

        test.it("injects all exact Hub policies into the configured admin group", function()
            for _, policy_id in ipairs({ DISCOVERY_POLICY, CALL_POLICY, CATALOG_POLICY }) do
                local entry, err = registry.get(policy_id)
                test.is_nil(err)
                test.not_nil(entry)
                test.eq(entry.kind, "security.policy")
                local policy_data = entry.data :: any
                test.eq(#policy_data.groups, 1)
                test.eq(policy_data.groups[1], ADMIN_GROUP)
            end
        end)

        test.it("keeps discovery and invocation resources exact", function()
            local admin_actor = actor("hub-policy-admin")
            local discovery = security.policy(DISCOVERY_POLICY)
            local call = security.policy(CALL_POLICY)
            local native_catalog = security.policy(CATALOG_POLICY)

            test.eq(discovery:evaluate(admin_actor, "registry.get", TRAIT_ID, {}), "allow")
            test.eq(discovery:evaluate(admin_actor, "registry.find", TRAIT_ID, {}), "allow")
            for _, tool_id in ipairs(TOOL_IDS) do
                test.eq(discovery:evaluate(admin_actor, "registry.get", tool_id, {}), "allow")
                test.eq(discovery:evaluate(admin_actor, "registry.find", tool_id, {}), "allow")
                test.eq(call:evaluate(admin_actor, "funcs.call", tool_id, {}), "allow")
                test.eq(call:evaluate(admin_actor, "access", tool_id, {}), "allow")
            end

            test.eq(discovery:evaluate(admin_actor, "registry.get", "keeper.hub:service", {}), "undefined")
            test.eq(discovery:evaluate(admin_actor, "funcs.call", TOOL_IDS[1], {}), "undefined")
            test.eq(call:evaluate(admin_actor, "funcs.call", TRAIT_ID, {}), "undefined")
            test.eq(call:evaluate(admin_actor, "funcs.call", "keeper.hub.scan:service", {}), "undefined")
            test.eq(native_catalog:evaluate(admin_actor, "hub.modules.list", "", {}), "allow")
            test.eq(native_catalog:evaluate(admin_actor, "hub.modules.search", "keeper", {}), "allow")
            test.eq(native_catalog:evaluate(admin_actor, "hub.modules.readme", "keeper/keeper", {}), "allow")
            test.eq(native_catalog:evaluate(admin_actor, "hub.versions.list", "keeper/keeper", {}), "allow")
            test.eq(native_catalog:evaluate(admin_actor, "hub.versions.open", "keeper/keeper", {}), "undefined")
        end)

        test.it("allows the admin scope and hides the public capability from the ordinary user scope", function()
            local admin_actor = actor("hub-scope-admin")
            local user_actor = actor("hub-scope-user")
            local admin_scope, admin_err = security.named_scope(ADMIN_GROUP)
            local user_scope, user_err = security.named_scope(USER_GROUP)
            test.is_nil(admin_err)
            test.is_nil(user_err)

            test.eq(admin_scope:evaluate(admin_actor, "registry.get", TRAIT_ID, {}), "allow")
            test.eq(admin_scope:evaluate(admin_actor, "funcs.call", TOOL_IDS[1], {}), "allow")
            test.eq(admin_scope:evaluate(admin_actor, "access", TOOL_IDS[1], {}), "allow")
            test.eq(user_scope:evaluate(user_actor, "registry.get", TRAIT_ID, {}), "undefined")
            test.eq(user_scope:evaluate(user_actor, "funcs.call", TOOL_IDS[1], {}), "undefined")
            test.eq(user_scope:evaluate(user_actor, "access", TOOL_IDS[1], {}), "undefined")

            local admin_discovery, admin_discovery_err = funcs.new()
                :with_actor(admin_actor)
                :with_scope(admin_scope)
                :call(PROBE, { discovery_probe = true })
            test.is_nil(admin_discovery_err)
            test.not_nil(admin_discovery)
            test.is_true(admin_discovery.direct)
            test.eq(admin_discovery.found, 1)

            local discovery, discovery_err = funcs.new()
                :with_actor(user_actor)
                :with_scope(user_scope)
                :call(PROBE, { discovery_probe = true })
            test.is_nil(discovery_err)
            test.not_nil(discovery)
            test.is_false(discovery.direct)
            test.eq(discovery.found, 0)
            test.is_nil(discovery.find_error)
        end)

        test.it("preserves admin actor and scope through the normal agent tool caller", function()
            local admin_actor = actor("hub-agent-admin")
            local admin_scope = security.named_scope(ADMIN_GROUP)
            local result, err = funcs.new()
                :with_actor(admin_actor)
                :with_scope(admin_scope)
                :call(PROBE, { agent_probe = true })
            test.is_nil(err)
            test.not_nil(result)
            test.is_nil(result.validation_error)
            test.is_true(string.find(result.execution_error or "", "component is required", 1, true) ~= nil)
            test.is_true(string.find(result.execution_error or "", "not allowed", 1, true) == nil)
            test.is_true(string.find(result.execution_error or "", "access denied", 1, true) == nil)
        end)

        test.it("preserves the exact access denial under permissive Keeper registry and function plumbing", function()
            local permissive_actor = actor("hub-agent-permissive")
            local permissive_scope = security.named_scope(PERMISSIVE_GROUP)

            local discovered, discovery_err = funcs.new()
                :with_actor(permissive_actor)
                :with_scope(permissive_scope)
                :call(PROBE, { agent_probe = true })
            test.is_nil(discovery_err)
            test.not_nil(discovered)
            test.is_nil(discovered.validation_error)
            test.is_true(string.find(discovered.execution_error or "", "access denied", 1, true) ~= nil)

            local executed, execution_err = funcs.new()
                :with_actor(permissive_actor)
                :with_scope(permissive_scope)
                :call(PROBE, { agent_probe = true, prevalidated = true })
            test.is_nil(execution_err)
            test.not_nil(executed)
            test.is_true(string.find(executed.execution_error or "", "access denied", 1, true) ~= nil)
        end)

        test.it("rejects non-object direct tool inputs without raising", function()
            for _, tool in ipairs({ catalog, dependencies, migrations }) do
                local result, err = tool._handle("invalid")
                test.is_nil(result)
                test.eq(err, "input must be an object")
            end
        end)

        test.it("calls only the native Hub catalog methods", function()
            local calls: {any} = {}
            local sdk = fake_hub(calls)

            local listed, list_err = catalog._handle({ action = "browse", page_size = 500 }, { hub = sdk })
            test.is_nil(list_err)
            test.eq(listed.total, 1)
            local list_call = calls[1] :: any
            test.not_nil(list_call)
            test.eq(list_call.method, "modules.list")
            test.eq(list_call.options.page_size, 100)

            local searched, search_err = catalog._handle({ action = "browse", query = "keeper" }, { hub = sdk })
            test.is_nil(search_err)
            test.eq(searched.query, "keeper")
            local search_call = calls[2] :: any
            test.not_nil(search_call)
            test.eq(search_call.method, "modules.search")
            test.eq(search_call.query, "keeper")

            local q_only, q_only_err = catalog._handle({ action = "browse", q = "keeper" }, { hub = sdk })
            test.is_nil(q_only_err)
            test.eq(q_only.query, "")
            local q_only_call = calls[3] :: any
            test.not_nil(q_only_call)
            test.eq(q_only_call.method, "modules.list")

            local versions, versions_err = catalog._handle({ action = "versions", component = "keeper/keeper" }, { hub = sdk })
            test.is_nil(versions_err)
            test.eq(versions.component, "keeper/keeper")
            local versions_call = calls[4] :: any
            test.not_nil(versions_call)
            test.eq(versions_call.method, "versions.list")

            local readme, readme_err = catalog._handle({ action = "readme", component = "keeper/keeper", version = "0.5.57" }, { hub = sdk })
            test.is_nil(readme_err)
            test.eq(readme.filename, "README.md")
            test.eq(readme.component, "keeper/keeper")
            local readme_call = calls[5] :: any
            test.not_nil(readme_call)
            test.eq(readme_call.method, "modules.readme")
            test.eq(readme_call.options.version, "0.5.57")
        end)
    end)
end

return { define_tests = define_tests }
