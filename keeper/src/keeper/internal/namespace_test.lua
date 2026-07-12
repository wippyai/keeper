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

local function is_version_range(version)
    if type(version) ~= "string" or version == "" then return false end
    return version:find("[<>=~%^%*xX]", 1) ~= nil
end

local function define_tests()
    test.describe("keeper internal namespace conventions", function()
        test.it("keeps shared helpers under keeper.internal", function()
            must_get("keeper.internal:sql_dialect")
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

        test.it("uses launch_task naming for the task launcher tool", function()
            local launch = must_get("keeper.task.tools:launch")
            test.eq(launch.meta.llm_alias, "launch_task")
            expect_missing("keeper.task.tools:" .. "e2" .. "e_launch")
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

        test.it("app-db migrations support sqlite and postgres", function()
            for _, id in ipairs({
                "keeper.components.migrations:migration_01",
                "keeper.components.migrations:migration_02",
                "keeper.knowledge.migrations:migration_01",
                "keeper.mcp.migrations:migration_01",
                "keeper.mcp.migrations:migration_02",
                "keeper.mcp.migrations:migration_03",
                "keeper.mcp.migrations:migration_04",
                "keeper.mcp.migrations:migration_05",
                "keeper.mcp.migrations:migration_06",
            }) do
                local entry = must_get(id)
                local source = tostring(entry.data and entry.data.source or "")
                test.is_true(source:find('database%("sqlite"', 1) ~= nil, id .. " must keep sqlite support")
                test.is_true(source:find('database%("postgres"', 1) ~= nil, id .. " must support postgres app DBs")
            end
        end)

        test.it("publishes compatible dependency ranges rather than lockfile pins", function()
            local dependencies, err = registry.find({ [".kind"] = "ns.dependency" })
            test.is_nil(err)
            local keeper_dependency_count = 0

            for _, dependency in ipairs(dependencies or {}) do
                local id = tostring(dependency.id or "")
                if id:sub(1, 11) == "keeper:dep." then
                    keeper_dependency_count = keeper_dependency_count + 1
                    local version = dependency.data and dependency.data.version
                    test.is_true(is_version_range(version), id .. " must publish a version range, not an exact lockfile version")
                end
            end

            test.eq(keeper_dependency_count, 8)

            local dataflow = must_get("keeper:dep.wippy.dataflow")
            test.eq(dataflow.data.version, ">=v0.4.10")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
