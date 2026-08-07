local test = require("test")
local registry = require("registry")

type RequirementTarget = {
    entry: string,
    path: string,
}

type RequirementData = {
    targets?: {RequirementTarget},
}

type RequirementEntry = {
    targets?: {RequirementTarget},
    data?: RequirementData,
}

type EntryMeta = {
    depends_on?: {string},
}

type Policy = {
    resources?: string,
}

type LinkedEntryData = {
    meta?: EntryMeta,
    policy?: Policy,
}

type LinkedEntry = {
    meta?: EntryMeta,
    policy?: Policy,
    data?: LinkedEntryData,
}

type StringSet = { [string]: boolean }
type TargetPaths = { [string]: StringSet }

local function requirement_targets(entry: RequirementEntry?): {RequirementTarget}
    if entry == nil then return {} end
    if entry.targets ~= nil then return entry.targets end
    if entry.data ~= nil and entry.data.targets ~= nil then return entry.data.targets end
    return {}
end

local function target_paths(entry: RequirementEntry?): TargetPaths
    local result: TargetPaths = {}
    for _, target in ipairs(requirement_targets(entry)) do
        local paths = result[target.entry]
        if paths == nil then
            paths = {}
            result[target.entry] = paths
        end
        paths[target.path] = true
    end
    return result
end

local function linked_meta(entry: LinkedEntry?): EntryMeta
    if entry == nil then return {} end
    if entry.meta ~= nil then return entry.meta end
    if entry.data ~= nil and entry.data.meta ~= nil then return entry.data.meta end
    return {}
end

local function linked_policy(entry: LinkedEntry?): Policy
    if entry == nil then return {} end
    if entry.policy ~= nil then return entry.policy end
    if entry.data ~= nil and entry.data.policy ~= nil then return entry.data.policy end
    return {}
end

local function set_size(values: StringSet): number
    local count = 0
    for _ in pairs(values) do
        count = count + 1
    end
    return count
end

local function assert_paths(actual: TargetPaths, entry_id: string, expected: {string})
    local paths = actual[entry_id]
    test.not_nil(paths, entry_id .. " must be targeted by its requirement")
    if paths == nil then return end

    test.eq(set_size(paths), #expected, entry_id .. " must have only the expected requirement paths")
    for _, path in ipairs(expected) do
        test.eq(paths[path], true, entry_id .. " must be targeted at " .. path)
    end
end

local function define_tests()
    test.describe("keeper packaging", function()
        test.it("routes every bundled UI mount through ui_server", function()
            local requirement, err = registry.get("keeper:ui_server")
            test.is_nil(err)
            test.not_nil(requirement)

            local actual = target_paths(requirement :: RequirementEntry)

            assert_paths(actual, "keeper.components:ui_static", { ".meta.server" })
            assert_paths(actual, "keeper.components:git_static", { ".meta.server" })
            assert_paths(actual, "keeper.components:wippy_monaco_static", { ".meta.server" })
        end)

        test.it("routes event controls and pull requests through api_router", function()
            local requirement, err = registry.get("keeper:api_router")
            test.is_nil(err)
            test.not_nil(requirement)

            local actual = target_paths(requirement :: RequirementEntry)

            assert_paths(actual, "keeper.events.api:subscribe.endpoint", { ".meta.router" })
            assert_paths(actual, "keeper.events.api:unsubscribe.endpoint", { ".meta.router" })
            assert_paths(actual, "keeper.git.api:pull_request.endpoint", { ".meta.router" })
        end)

        test.it("routes registry endpoint ordering through api_router", function()
            local requirement, err = registry.get("keeper:api_router")
            test.is_nil(err)
            test.not_nil(requirement)

            local actual = target_paths(requirement :: RequirementEntry)
            local handlers = {
                "keeper.gov.api.registry:get_entry",
                "keeper.gov.api.registry:list_entries",
                "keeper.gov.api.registry:list_namespaces",
                "keeper.gov.api.registry:update_entry",
            }

            for _, handler_id in ipairs(handlers) do
                assert_paths(actual, handler_id, { ".meta.depends_on +=" })
                assert_paths(actual, handler_id .. ".endpoint", {
                    ".meta.router",
                    ".meta.depends_on +=",
                })

                local handler, handler_err = registry.get(handler_id)
                test.is_nil(handler_err)
                test.not_nil(handler)
                local handler_deps = linked_meta(handler :: LinkedEntry).depends_on or {}
                test.eq(#handler_deps, 1, handler_id .. " must not retain a stale router dependency")
                test.eq(handler_deps[1], "app:api")

                local endpoint, endpoint_err = registry.get(handler_id .. ".endpoint")
                test.is_nil(endpoint_err)
                test.not_nil(endpoint)
                local endpoint_deps = linked_meta(endpoint :: LinkedEntry).depends_on or {}
                test.eq(#endpoint_deps, 1, handler_id .. ".endpoint must not retain a stale router dependency")
                test.eq(endpoint_deps[1], "app:api")
            end
        end)

        test.it("grants MCP endpoint access through app_db", function()
            local requirement, requirement_err = registry.get("keeper:app_db")
            test.is_nil(requirement_err)
            test.not_nil(requirement)

            local actual = target_paths(requirement :: RequirementEntry)
            assert_paths(actual, "keeper.mcp.security:endpoint_db_access", { ".policy.resources" })

            local policy_entry, policy_err = registry.get("keeper.mcp.security:endpoint_db_access")
            test.is_nil(policy_err)
            test.not_nil(policy_entry)
            test.eq(linked_policy(policy_entry :: LinkedEntry).resources, "app:db")
        end)
    end)
end

return { define_tests = define_tests }
