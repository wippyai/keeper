local test = require("test")
local registry = require("registry")
local service = require("service")

local CURATOR_AGENT = "keeper.agents:kb_curator"
local TASK_RESEARCHER_AGENT = "keeper.agents:researcher"
local CURATOR_TRAIT = "keeper.agents.traits.knowledge:curator"
local KB_WRITE_TOOL = "keeper.knowledge.tools:kb_write"

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then return true end
    end
    return false
end

local function define_tests()
    test.describe("knowledge service research flow", function()
        test.it("uses the durable KB curator agent for research/learn orchestration", function()
            test.eq(service._test.knowledge_agent_id(), CURATOR_AGENT)
        end)

        test.it("curator has KB write capability and task researcher does not", function()
            local curator, curator_err = registry.get(CURATOR_AGENT)
            test.is_nil(curator_err)
            test.not_nil(curator)
            test.is_true(contains(curator.data and curator.data.traits, CURATOR_TRAIT),
                "durable KB research must run through the curator trait")

            local trait, trait_err = registry.get(CURATOR_TRAIT)
            test.is_nil(trait_err)
            test.not_nil(trait)
            test.is_true(contains(trait.data and trait.data.tools, KB_WRITE_TOOL),
                "curator trait must expose kb_write")

            local researcher, researcher_err = registry.get(TASK_RESEARCHER_AGENT)
            test.is_nil(researcher_err)
            test.not_nil(researcher)
            test.is_false(contains(researcher.data and researcher.data.traits, CURATOR_TRAIT),
                "task researcher must remain read-only")
        end)

        test.it("research prompt marks KB writes as durable, not task context", function()
            local prompt = service._test.with_kb_instruction("Capture the API pattern", "Wippy Patterns")
            test.is_true(prompt:find("durable knowledge curation flow", 1, true) ~= nil)
            test.is_true(prompt:find("write_knowledge", 1, true) ~= nil)
            test.is_true(prompt:find("Do not use save_context", 1, true) ~= nil)
            test.is_true(prompt:find('kb="Wippy Patterns"', 1, true) ~= nil)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
