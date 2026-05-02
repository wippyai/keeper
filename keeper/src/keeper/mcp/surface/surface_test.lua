local test = require("test")
local surface = require("surface")

local function define_tests()
    describe("mcp.surface", function()
        describe("META_TOOLS shape", function()
            it("exposes a non-empty meta-tool catalog", function()
                test.is_true(type(surface.META_TOOLS) == "table")
                test.is_true(#surface.META_TOOLS > 0)
            end)

            it("each entry has name, description, and inputSchema", function()
                for _, m in ipairs(surface.META_TOOLS) do
                    test.is_true(type(m.name) == "string" and #m.name > 0)
                    test.is_true(type(m.description) == "string" and #m.description > 0)
                    test.is_true(type(m.inputSchema) == "table")
                end
            end)

            it("each inputSchema declares type=object", function()
                for _, m in ipairs(surface.META_TOOLS) do
                    test.eq(m.inputSchema.type, "object")
                end
            end)

            it("has no duplicate tool names across the catalog", function()
                local seen = {}
                for _, m in ipairs(surface.META_TOOLS) do
                    test.is_nil(seen[m.name])
                    seen[m.name] = true
                end
            end)
        end)

        describe("ALWAYS_VISIBLE invariants", function()
            it("contains exactly the meta-tools flagged always_visible", function()
                local expected = {}
                local expected_count = 0
                for _, m in ipairs(surface.META_TOOLS) do
                    if m.always_visible then
                        expected[m.name] = true
                        expected_count = expected_count + 1
                    end
                end
                local actual_count = 0
                for name, _ in pairs(surface.ALWAYS_VISIBLE) do
                    test.is_true(expected[name])
                    actual_count = actual_count + 1
                end
                test.eq(actual_count, expected_count)
            end)

            it("includes session_info, list_tools, call_tool (the core tools_only surface)", function()
                test.is_true(surface.ALWAYS_VISIBLE.session_info == true)
                test.is_true(surface.ALWAYS_VISIBLE.list_tools == true)
                test.is_true(surface.ALWAYS_VISIBLE.call_tool == true)
            end)

            it("declares native security requirements separately from visibility", function()
                local req = surface.META_REQUIRED_SECURITY.call_tool
                test.not_nil(req)
                test.eq(req.action, "keeper.mcp.call_tool")
                test.eq(req.resource, "call_tool")
            end)

            it("does not include trait-management tools", function()
                test.is_nil(surface.ALWAYS_VISIBLE.use_trait)
                test.is_nil(surface.ALWAYS_VISIBLE.drop_trait)
                test.is_nil(surface.ALWAYS_VISIBLE.activate_traits)
                test.is_nil(surface.ALWAYS_VISIBLE.set_traits)
            end)
        end)

        describe("supports_traits", function()
            it("returns true for access_mode=any", function()
                test.is_true(surface.supports_traits({ access_mode = "any" }))
            end)

            it("returns true for access_mode=traits", function()
                test.is_true(surface.supports_traits({ access_mode = "traits" }))
            end)

            it("returns false for access_mode=tools_only", function()
                test.is_false(surface.supports_traits({ access_mode = "tools_only" }))
            end)

            it("returns false for nil session (defaults to tools_only)", function()
                test.is_false(surface.supports_traits(nil))
            end)

            it("returns false when access_mode is absent", function()
                test.is_false(surface.supports_traits({}))
            end)
        end)

        describe("resolve_tool_name", function()
            it("returns the original name when no collision", function()
                test.eq(surface.resolve_tool_name("data", {}), "data")
            end)

            it("prefixes with tool_ when the name is already seen", function()
                test.eq(surface.resolve_tool_name("session_info", { session_info = true }), "tool_session_info")
            end)

            it("tolerates nil seen table", function()
                test.eq(surface.resolve_tool_name("data", nil), "data")
            end)

            it("does not re-prefix names that already start with tool_", function()
                test.eq(surface.resolve_tool_name("tool_foo", {}), "tool_foo")
            end)
        end)

        describe("names_from_tool_list", function()
            it("returns an empty set for an empty list", function()
                local names = surface.names_from_tool_list({})
                test.eq(next(names), nil)
            end)

            it("collects every tool name into the set", function()
                local names = surface.names_from_tool_list({
                    { name = "a" },
                    { name = "b" },
                    { name = "c" },
                })
                test.is_true(names.a == true)
                test.is_true(names.b == true)
                test.is_true(names.c == true)
            end)

            it("tolerates non-table input", function()
                local names = surface.names_from_tool_list(nil)
                test.eq(next(names), nil)
            end)

            it("skips entries missing a name", function()
                local names = surface.names_from_tool_list({ { name = "a" }, {}, { name = "b" } })
                test.is_true(names.a == true)
                test.is_true(names.b == true)
            end)
        end)

        describe("diff_added", function()
            it("returns names in after but not before", function()
                local added = surface.diff_added({ x = true }, { x = true, y = true, z = true })
                test.eq(#added, 2)
                test.eq(added[1], "y")
                test.eq(added[2], "z")
            end)

            it("returns an empty list when after is a subset of before", function()
                local added = surface.diff_added({ a = true, b = true }, { a = true })
                test.eq(#added, 0)
            end)

            it("sorts the result alphabetically", function()
                local added = surface.diff_added({}, { zeta = true, alpha = true, mid = true })
                test.eq(added[1], "alpha")
                test.eq(added[2], "mid")
                test.eq(added[3], "zeta")
            end)

            it("tolerates nil before or after", function()
                local added = surface.diff_added(nil, { x = true })
                test.eq(#added, 1)
                test.eq(added[1], "x")
                local empty = surface.diff_added({ x = true }, nil)
                test.eq(#empty, 0)
            end)
        end)

        describe("diff_removed", function()
            it("returns names in before but not after", function()
                local removed = surface.diff_removed({ x = true, y = true, z = true }, { x = true })
                test.eq(#removed, 2)
                test.eq(removed[1], "y")
                test.eq(removed[2], "z")
            end)

            it("returns an empty list when before is a subset of after", function()
                local removed = surface.diff_removed({ a = true }, { a = true, b = true })
                test.eq(#removed, 0)
            end)

            it("sorts the result alphabetically", function()
                local removed = surface.diff_removed({ zeta = true, alpha = true, mid = true }, {})
                test.eq(removed[1], "alpha")
                test.eq(removed[2], "mid")
                test.eq(removed[3], "zeta")
            end)

            it("tolerates nil before or after", function()
                local removed = surface.diff_removed({ x = true }, nil)
                test.eq(#removed, 1)
                test.eq(removed[1], "x")
                local empty = surface.diff_removed(nil, { x = true })
                test.eq(#empty, 0)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
