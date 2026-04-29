local test = require("test")
local format_context = require("format_context")

local function define_tests()
    test.describe("keeper.develop.context:format_context", function()
        test.it("returns placeholder string when content is nil", function()
            local out = format_context.run({ content = nil })
            test.eq(out, "No context gathered.")
        end)

        test.it("returns placeholder when content is empty string", function()
            local out = format_context.run({ content = "" })
            test.eq(out, "No context gathered.")
        end)

        test.it("joins an array-of-strings into separated blob", function()
            local out = format_context.run({ content = { "alpha", "beta", "gamma" } })
            test.is_true(out:find("alpha") ~= nil)
            test.is_true(out:find("beta") ~= nil)
            test.is_true(out:find("gamma") ~= nil)
            test.is_true(out:find("---") ~= nil, "expected --- separator between parts")
        end)

        test.it("ignores empty strings in array input", function()
            local out = format_context.run({ content = { "one", "", "two" } })
            test.is_true(out:find("one") ~= nil)
            test.is_true(out:find("two") ~= nil)
            -- No extra separator run from the empty entry
            local count = 0
            for _ in out:gmatch("---") do count = count + 1 end
            test.eq(count, 1, "should have exactly one --- between two real entries")
        end)

        test.it("returns placeholder when array has only empty strings", function()
            local out = format_context.run({ content = { "", "" } })
            test.eq(out, "No context gathered.")
        end)

        test.it("passes content through unchanged when there are no embed tags", function()
            local input = "Plain text with no embeds\nSecond line"
            local out = format_context.run({ content = input })
            test.eq(out, input)
        end)

        test.it("resolves <embed id=... mode=full/> against live state_reader for a known entry", function()
            -- Use wippy.test:test — stable registered library every task relies on.
            local input = 'Before\n<embed id="wippy.test:test" mode="full" />\nAfter'
            local out = format_context.run({ content = input })
            test.is_true(out:find("Before") ~= nil, "leading content preserved")
            test.is_true(out:find("After") ~= nil, "trailing content preserved")
            test.is_true(out:find("=== wippy.test:test ===") ~= nil,
                "embed should be replaced with === <id> === header + body")
        end)

        test.it("handles a missing entry gracefully without crashing", function()
            local input = '<embed id="app.nonexistent:does_not_exist" mode="full" />'
            local out = format_context.run({ content = input })
            -- format_context returns an error placeholder string rather than raising.
            test.is_true(type(out) == "string" and #out > 0)
        end)
    end)
end

return { define_tests = define_tests }
