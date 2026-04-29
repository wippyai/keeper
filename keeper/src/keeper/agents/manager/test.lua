local test = require("test")
local funcs = require("funcs")
local uuid = require("uuid")
local registry = require("registry")
local analyze = require("analyze_tool")
local drop = require("drop")
local open = require("open")
local search = require("search_tool")
local state_reader = require("state_reader")

local MANAGER_ID = "keeper.agents.manager:manager"

local function has_class(entry, name)
    local class = entry and entry.meta and entry.meta.class
    if type(class) ~= "table" then return false end
    for _, value in ipairs(class) do
        if value == name then return true end
    end
    return false
end

local function require_entry(id, expected_type)
    local entry = registry.get(id)
    test.not_nil(entry, "missing registry entry: " .. tostring(id))
    test.eq(entry.meta and entry.meta.type, expected_type,
        tostring(id) .. " should be meta.type=" .. tostring(expected_type))
    return entry
end

local function call_clone_on_branch(branch, changeset_id, args)
    local executor, exec_err = funcs.new()
    test.is_nil(exec_err)
    executor = executor:with_context({
        overlay_branch = branch,
        changeset_id = changeset_id,
    })
    return executor:call("keeper.agents.manager:clone", args)
end

local function read_branch_entry(branch, id)
    local reader, rerr = state_reader.for_branch(branch, "main")
    test.is_nil(rerr)
    reader = reader:with_entries(id):include_chunks()
    local entries, eerr = reader:all()
    test.is_nil(eerr)
    return entries and entries[1] or nil
end

local function define_tests()
    test.describe("keeper.agents.manager", function()
        test.it("exposes the Agent Manager as a public user-facing agent", function()
            local entry = require_entry(MANAGER_ID, "agent.gen1")
            test.eq(entry.meta.title, "Agent Manager")
            test.is_true(has_class(entry, "public"))
            test.eq(entry.data.model, "class:smart")
            test.is_true(type(entry.data.prompt) == "string" and #entry.data.prompt > 500)
        end)

        test.it("keeps manager tool references concrete and resolvable", function()
            local entry = require_entry(MANAGER_ID, "agent.gen1")
            local expected = {
                ["keeper.agents.manager:analyze"] = true,
                ["keeper.agents.manager:clone"] = true,
                ["keeper.agents.manager:search"] = true,
                ["keeper.knowledge.tools:kb_read"] = true,
            }

            for _, tool_id in ipairs(entry.data.tools or {}) do
                local id = tostring(tool_id or "")
                test.is_true(expected[id] == true, "unexpected manager tool: " .. id)
                require_entry(id, "tool")
                expected[id] = nil
            end

            for missing in pairs(expected) do
                test.is_true(false, "manager missing required tool: " .. missing)
            end
        end)

        test.it("keeps manager trait references concrete and resolvable", function()
            local entry = require_entry(MANAGER_ID, "agent.gen1")
            local expected = {
                ["keeper.agents.traits.state:editor"] = true,
                ["keeper.agents.traits.state:manager"] = true,
                ["keeper.agents.traits.state:explorer"] = true,
                ["keeper.agents.traits.state:comparer"] = true,
                ["keeper.agents.traits.state:publisher"] = true,
                ["keeper.agents.manager:lifecycle"] = true,
                ["keeper.agents.manager:orchestration"] = true,
                ["keeper.agents.manager:diagnose"] = true,
                ["wippy.agent.traits:time_aware"] = true,
            }

            for _, trait_id in ipairs(entry.data.traits or {}) do
                local id = tostring(trait_id or "")
                test.is_true(expected[id] == true, "unexpected manager trait: " .. id)
                require_entry(id, "agent.trait")
                expected[id] = nil
            end

            for missing in pairs(expected) do
                test.is_true(false, "manager missing required trait: " .. missing)
            end
        end)

        test.it("analyzes itself without missing tool or trait references", function()
            local out = analyze.handler({ agent_id = MANAGER_ID })
            test.is_true(out.success == true, tostring(out.error or "analyze failed"))
            test.eq(#out.analysis.tools_analysis.missing_tools, 0)
            test.eq(#out.analysis.tools_analysis.invalid_tools, 0)
            test.eq(#out.analysis.traits_analysis.invalid_traits, 0)
            test.is_true(out.analysis.basic_info.is_visible)
        end)

        test.it("clone stages a new agent on the active changeset branch", function()
            local suffix = uuid.v7():gsub("[^%w]", "_")
            local branch = "agent-manager-test/" .. suffix
            local new_id = "userspace.agent_tests:clone_" .. suffix

            local ws, open_err = open.run({
                title = "Agent manager clone test",
                kind = "manual",
                actor_id = "test.agent.manager",
                state_branch = branch,
            })
            test.is_nil(open_err)
            test.not_nil(ws)

            local result, clone_err = call_clone_on_branch(branch, ws.changeset_id, {
                source_agent_id = MANAGER_ID,
                new_agent_id = new_id,
                modifications = {
                    title = "Agent Manager Clone Test",
                    class = { "public" },
                },
            })

            test.is_nil(clone_err)
            test.is_true(result.success == true, tostring(result.error or clone_err))
            test.eq(result.new_agent_id, new_id)
            test.is_true(result.staged == true)

            local staged = read_branch_entry(branch, new_id)
            test.not_nil(staged, "clone must be visible in the overlay branch")
            test.eq(staged.id, new_id)
            test.eq(staged.kind, "registry.entry")

            local _, drop_err = drop.run({ changeset_id = ws.changeset_id })
            test.is_nil(drop_err)
        end)

        test.it("search finds the manager through public agent filters", function()
            local out = search.handler({
                query = "agent manager",
                filters = {
                    namespace = "keeper.agents.manager",
                    class = "public",
                    has_tools = true,
                    has_traits = true,
                },
                limit = 5,
            })
            test.is_true(out.success)

            local found = false
            for _, row in ipairs(out.results or {}) do
                if row.id == MANAGER_ID then found = true end
            end
            test.is_true(found, "manager search should return " .. MANAGER_ID)
        end)
    end)
end

return { define_tests = define_tests }
