-- Regression: pin the trait set on context-gatherer agents that need to
-- read frontend source on disk. Live evidence from v18 — design researcher
-- blocked at "frontend source files not accessible" because view_context
-- and the upstream researcher had no `fs` tool. The fix gives them the
-- `keeper.agents.traits.context.frontend:frontend_aware` trait which
-- carries `keeper.components.tools:fs` plus an injected Vue tree context.
--
-- This test asserts the trait is wired so future edits don't silently drop
-- it and reintroduce the same blocker.

local test     = require("test")
local registry = require("registry")

local function trait_set(entry)
    local out = {}
    if not entry or not entry.data then return out end
    local list = entry.data.traits or {}
    for _, t in ipairs(list) do out[t] = true end
    return out
end

local FRONTEND_TRAIT = "keeper.agents.traits.context.frontend:frontend_aware"
local CURATOR_TRAIT = "keeper.agents.traits.knowledge:curator"

local CONTEXT_AGENT_IDS = {
    "keeper.develop.context.agents:agents_context",
    "keeper.develop.context.agents:dataflow_context",
    "keeper.develop.context.agents:http_endpoint_context",
    "keeper.develop.context.agents:migration_context",
    "keeper.develop.context.agents:persist_context",
    "keeper.develop.context.agents:tool_context",
    "keeper.develop.context.agents:view_context",
}

local function list_set(list)
    local out = {}
    for _, value in ipairs(list or {}) do out[value] = true end
    return out
end

local function define_tests()
    test.describe("FE-aware agents must carry the frontend_aware trait", function()
        test.it("view_context gatherer has frontend_aware (so it can fs view useWippy.ts)",
            function()
                local entry, err = registry.get("keeper.develop.context.agents:view_context")
                test.is_nil(err)
                test.not_nil(entry)
                local traits = trait_set(entry)
                test.is_true(traits[FRONTEND_TRAIT],
                    "view_context must carry " .. FRONTEND_TRAIT ..
                    " — without it the gatherer cannot read the host SDK precedents and the design researcher blocks the cycle")
            end)

        test.it("researcher carries frontend_aware (so cross-domain research can read frontend source)",
            function()
                local entry, err = registry.get("keeper.agents:researcher")
                test.is_nil(err)
                test.not_nil(entry)
                local traits = trait_set(entry)
                test.is_true(traits[FRONTEND_TRAIT],
                    "researcher must carry " .. FRONTEND_TRAIT ..
                    " — observed live in v18 where the design phase blocked because researcher had no fs access to the keeper SPA source")
            end)

        test.it("frontend_aware trait actually exposes the fs tool", function()
            -- Sanity: the trait we are mounting on these agents must really
            -- carry the fs tool. If someone renames or drops the tool from
            -- the trait this test fails loudly here instead of in a live
            -- design phase.
            local trait, err = registry.get(FRONTEND_TRAIT)
            test.is_nil(err)
            test.not_nil(trait)
            local tools = (trait.data and trait.data.tools) or {}
            local has_fs = false
            for _, t in ipairs(tools) do
                if t == "keeper.components.tools:fs" then has_fs = true; break end
            end
            test.is_true(has_fs,
                "frontend_aware must expose keeper.components.tools:fs")
        end)

        test.it("context gatherers stay live-context only and do not carry KB/doc tools", function()
            for _, id in ipairs(CONTEXT_AGENT_IDS) do
                local entry, err = registry.get(id)
                test.is_nil(err)
                test.not_nil(entry)
                local tools = list_set(entry.data and entry.data.tools)
                test.is_nil(tools["keeper.knowledge.tools:kb_read"],
                    id .. " must not read KB directly; delegate KB gaps to keeper.agents:researcher")
                test.is_nil(tools["keeper.knowledge.tools:fetch_docs"],
                    id .. " must not fetch docs directly; delegate docs gaps to keeper.agents:researcher")
            end
        end)

        test.it("task researcher is read-only and not a durable KB curator", function()
            local entry, err = registry.get("keeper.agents:researcher")
            test.is_nil(err)
            test.not_nil(entry)
            local traits = trait_set(entry)
            test.is_nil(traits[CURATOR_TRAIT],
                "keeper.agents:researcher must stay read-only; durable KB writes use keeper.agents:kb_curator")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
