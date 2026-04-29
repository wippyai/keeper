local registry = require("registry")
local test = require("test")

local function must_get(id)
    local entry, err = registry.get(id)
    test.is_nil(err)
    test.not_nil(entry)
    return entry
end

local function expect_missing(id)
    local entry, err = registry.get(id)
    test.is_nil(entry)
    test.not_nil(err)
end

local function define_tests()
    test.describe("keeper internal namespace conventions", function()
        test.it("keeps shared helpers under keeper.internal", function()
            must_get("keeper.internal.flow:render")
            must_get("keeper.internal.flow:repo")
            must_get("keeper.internal.session:repo")
            must_get("keeper.internal.llm:summarize")
        end)

        test.it("does not expose stale top-level helper namespaces", function()
            expect_missing("keeper.agents.lib.flow:render")
            expect_missing("keeper.agents.lib.session:repo")
            expect_missing("keeper.llm:summarize")
        end)

        test.it("agent-facing debug tools import internal helpers", function()
            local dataflow = must_get("keeper.agents.tools:dataflow")
            local imports = dataflow.data and dataflow.data.imports or {}
            test.eq(imports.detectors, "keeper.internal.flow:detectors")
            test.eq(imports.render, "keeper.internal.flow:render")
            test.eq(imports.repo, "keeper.internal.flow:repo")

            local sessions = must_get("keeper.agents.tools:sessions")
            imports = sessions.data and sessions.data.imports or {}
            test.eq(imports.render, "keeper.internal.flow:render")
            test.eq(imports.repo, "keeper.internal.session:repo")
        end)

        test.it("state/component/task tools import the internal summarizer", function()
            for _, id in ipairs({
                "keeper.state.tools:compare",
                "keeper.state.tools:explore",
                "keeper.state.tools:get_entries",
                "keeper.components.tools:fs",
                "keeper.task.tools:read_context",
            }) do
                local entry = must_get(id)
                local imports = entry.data and entry.data.imports or {}
                test.eq(imports.summarize, "keeper.internal.llm:summarize", id .. " must use the internal summarizer")
            end
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
