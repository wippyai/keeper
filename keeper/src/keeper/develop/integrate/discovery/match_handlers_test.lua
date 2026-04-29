local test = require("test")
local discovery = require("discovery")

local function define_tests()
    test.describe("keeper.develop.integrate.discovery:match_handlers", function()
        test.it("routes a meta.type=migration entry to migration_handler", function()
            local entries = {
                {
                    id = "app.fake.migrations:01_test",
                    kind = "function.lua",
                    meta = { type = "migration", target_db = "app:db" },
                },
            }
            local matched = discovery.match_handlers(entries, "up")
            local found = false
            for _, row in ipairs(matched) do
                if row.handler_id == "keeper.develop.integrate.handlers:migration_handler" then
                    found = true
                    test.is_true(#row.entries >= 1,
                        "migration_handler should receive at least one entry")
                    test.eq(row.entries[1], "app.fake.migrations:01_test")
                end
            end
            test.is_true(found, "migration entry must route to migration_handler")
        end)

        test.it("routes an env.variable kind entry to env_variable_handler", function()
            local entries = {
                { id = "app.fake:env_x", kind = "env.variable", meta = {} },
            }
            local matched = discovery.match_handlers(entries, "up")
            local found = false
            for _, row in ipairs(matched) do
                if row.handler_id == "keeper.develop.integrate.handlers:env_variable_handler" then
                    found = true
                end
            end
            test.is_true(found, "env.variable kind must route to env_variable_handler")
        end)

        test.it("routes meta.type=view.page to view_handler", function()
            local entries = {
                { id = "app.fake:home", kind = "registry.entry",
                  meta = { type = "view.page", path = "/home" } },
            }
            local matched = discovery.match_handlers(entries, "up")
            local found = false
            for _, row in ipairs(matched) do
                if row.handler_id == "keeper.develop.integrate.handlers:view_handler" then
                    found = true
                end
            end
            test.is_true(found, "view.page must route to view_handler")
        end)

        test.it("orders matched handlers by meta.order ascending", function()
            local entries = {
                { id = "app.fake:env_x", kind = "env.variable", meta = {} },
                { id = "app.fake.migrations:01_test", kind = "function.lua",
                  meta = { type = "migration", target_db = "app:db" } },
            }
            local matched = discovery.match_handlers(entries, "up")
            test.is_true(#matched >= 2,
                "should match both migration and env handlers")
            test.is_true(matched[1].order < matched[2].order,
                "lower order runs first (migration=100 < env=200)")
            test.eq(matched[1].handler_id, "keeper.develop.integrate.handlers:migration_handler")
            test.eq(matched[2].handler_id, "keeper.develop.integrate.handlers:env_variable_handler")
        end)

        test.it("returns empty list for empty input", function()
            local matched = discovery.match_handlers({}, "up")
            test.eq(#matched, 0)
        end)

        test.it("skips handlers that do not declare the requested operation", function()
            -- All shipped handlers declare both up and down; pass an unknown op.
            local entries = {
                { id = "app.fake.migrations:01_test", kind = "function.lua",
                  meta = { type = "migration", target_db = "app:db" } },
            }
            local matched = discovery.match_handlers(entries, "sideways")
            test.eq(#matched, 0,
                "unknown operation must produce zero matches even if kind/meta matches")
        end)

        test.it("ignores entries that match no handler", function()
            local entries = {
                { id = "app.fake:random", kind = "library.lua", meta = {} },
            }
            local matched = discovery.match_handlers(entries, "up")
            test.eq(#matched, 0)
        end)

        test.it("routes frontend/applications/** fs paths to build_handler", function()
            -- Raw FS edit with no corresponding registry entry. Before the
            -- fs_prefix routing fix, build_handler never ran for these and
            -- the SPA bundle stayed stale after push.
            local fs_paths = {
                "frontend/applications/keeper/src/pages/probe-v11.vue",
                "frontend/applications/keeper/src/router/index.ts",
            }
            local matched = discovery.match_handlers({}, "up", fs_paths)
            local found = nil
            for _, row in ipairs(matched) do
                if row.handler_id == "keeper.develop.integrate.handlers:build_handler" then
                    found = row
                end
            end
            test.not_nil(found, "build_handler must be selected for frontend/ fs paths")
            test.eq(#found.entries, 0, "no entries in a pure fs-path invocation")
            test.eq(#found.fs_paths, 2,
                "all matching fs paths passed to the handler")
        end)

        test.it("routes local-module frontend application paths to build_handler", function()
            local fs_paths = {
                "plugins/git/frontend/applications/git/src/pages/git.vue",
                "plugins/usage/frontend/applications/usage/src/App.vue",
            }
            local matched = discovery.match_handlers({}, "up", fs_paths)
            local found = nil
            for _, row in ipairs(matched) do
                if row.handler_id == "keeper.develop.integrate.handlers:build_handler" then
                    found = row
                end
            end
            test.not_nil(found, "build_handler must be selected for plugin frontend paths")
            test.eq(#found.fs_paths, 2)
        end)

        test.it("does not route local-module backend source paths to build_handler", function()
            local fs_paths = {
                "plugins/git/src/keeper/git/flows/rebuild.lua",
            }
            local matched = discovery.match_handlers({}, "up", fs_paths)
            test.eq(#matched, 0,
                "plugin backend source must remain registry work, not frontend build work")
        end)

        test.it("combines entries and fs_paths onto the same handler", function()
            local entries = {
                { id = "app.fake:home", kind = "registry.entry",
                  meta = { type = "view.page", path = "/home" } },
            }
            local fs_paths = { "frontend/applications/keeper/src/pages/home.vue" }
            local matched = discovery.match_handlers(entries, "up", fs_paths)
            local found = nil
            for _, row in ipairs(matched) do
                if row.handler_id == "keeper.develop.integrate.handlers:build_handler" then
                    found = row
                end
            end
            test.not_nil(found)
            test.eq(#found.entries, 1, "entry routed alongside fs path")
            test.eq(#found.fs_paths, 1, "fs path routed alongside entry")
        end)

        test.it("does not route fs paths outside declared prefixes", function()
            -- A path that doesn't match any handler's fs_prefix must not
            -- hallucinate a build. Otherwise editing src/app/** would spin
            -- up SPA builds for no reason.
            local fs_paths = { "src/app/probe_v11/_index.yaml" }
            local matched = discovery.match_handlers({}, "up", fs_paths)
            test.eq(#matched, 0,
                "paths outside frontend/applications/ must not fire build_handler")
        end)

    end)
end

return { define_tests = define_tests }
