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
    end)
end

return { define_tests = define_tests }
