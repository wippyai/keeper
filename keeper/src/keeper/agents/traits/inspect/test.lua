local registry = require("registry")
local test = require("test")

local INSPECT_NS = "keeper.agents.traits.inspect:"

local REQUIRED_TRAITS = {
    agent_manager = { "keeper.agents.tools:manager" },
    data_inspector = { "keeper.agents.tools:data" },
    flow_debugger = { "keeper.agents.tools:dataflow", "keeper.agents.tools:sessions" },
    test_runner = { "keeper.agents.tools:run_test", "keeper.agents.tools:test_endpoint" },
    system_inspector = { "keeper.agents.tools:system" },
    task_debugger = { "keeper.agents.tools.task:debug" },
}

local function list_contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then return true end
    end
    return false
end

local function assert_tool_exists(tool_id)
    local entry, err = registry.get(tool_id)
    test.is_nil(err)
    test.not_nil(entry)
    test.eq(entry.meta and entry.meta.type, "tool")
end

local function define_tests()
    describe("inspect trait wiring", function()
        it("defines every inspect trait referenced by agents", function()
            local agents = registry.find({
                [".kind"] = "registry.entry",
                ["meta.type"] = "agent.gen1",
            }) or {}

            for _, agent in ipairs(agents) do
                local traits = (agent.data and agent.data.traits) or {}
                for _, trait_id in ipairs(traits) do
                    if type(trait_id) == "string" and trait_id:sub(1, #INSPECT_NS) == INSPECT_NS then
                        local trait, err = registry.get(trait_id)
                        test.is_nil(err)
                        test.not_nil(trait)
                        test.eq(trait.meta and trait.meta.type, "agent.trait")
                    end
                end
            end
        end)

        it("exposes the expected tools from each inspect trait", function()
            for name, expected_tools in pairs(REQUIRED_TRAITS) do
                local trait_id = INSPECT_NS .. name
                local trait, err = registry.get(trait_id)
                test.is_nil(err)
                test.not_nil(trait)
                test.eq(trait.meta and trait.meta.type, "agent.trait")

                local tools = (trait.data and trait.data.tools) or {}
                for _, tool_id in ipairs(expected_tools) do
                    test.is_true(list_contains(tools, tool_id), trait_id .. " must include " .. tool_id)
                    assert_tool_exists(tool_id)
                end
            end
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
