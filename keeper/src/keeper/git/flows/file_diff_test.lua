local test = require("test")
local fd = require("file_diff")

local SAMPLE = [[
diff --git a/foo.lua b/foo.lua
index abc..def 100644
--- a/foo.lua
+++ b/foo.lua
@@ -10,3 +10,4 @@ local M = {}
 function M.bar()
-  return 1
+  return 2
+  -- comment
 end
]]

local cases = {
    {
        name = "parse_diff returns empty hunks for empty input",
        fn = function()
            test.eq(#fd._parse_diff(""), 0)
            test.eq(#fd._parse_diff(nil), 0)
        end,
    },
    {
        name = "parse_diff captures hunk header",
        fn = function()
            local hunks = fd._parse_diff(SAMPLE)
            test.eq(#hunks, 1)
            test.is_true(hunks[1].header:find("@@") ~= nil)
        end,
    },
    {
        name = "parse_diff classifies + and - lines",
        fn = function()
            local hunks = fd._parse_diff(SAMPLE)
            local lines = hunks[1].lines
            local plus, minus, ctx = 0, 0, 0
            for _, ln in ipairs(lines) do
                if ln.kind == "+" then plus = plus + 1
                elseif ln.kind == "-" then minus = minus + 1
                elseif ln.kind == " " then ctx = ctx + 1
                end
            end
            test.eq(plus, 2)
            test.eq(minus, 1)
            test.is_true(ctx >= 2)
        end,
    },
    {
        name = "parse_diff numbers context lines on both sides",
        fn = function()
            local hunks = fd._parse_diff(SAMPLE)
            local first_ctx
            for _, ln in ipairs(hunks[1].lines) do
                if ln.kind == " " then first_ctx = ln; break end
            end
            test.not_nil(first_ctx)
            test.eq(first_ctx.old_no, 10)
            test.eq(first_ctx.new_no, 10)
        end,
    },
    {
        name = "parse_diff numbers + lines on new side only",
        fn = function()
            local hunks = fd._parse_diff(SAMPLE)
            local first_plus
            for _, ln in ipairs(hunks[1].lines) do
                if ln.kind == "+" then first_plus = ln; break end
            end
            test.is_nil(first_plus.old_no)
            test.not_nil(first_plus.new_no)
        end,
    },
    {
        name = "parse_diff numbers - lines on old side only",
        fn = function()
            local hunks = fd._parse_diff(SAMPLE)
            local first_minus
            for _, ln in ipairs(hunks[1].lines) do
                if ln.kind == "-" then first_minus = ln; break end
            end
            test.not_nil(first_minus.old_no)
            test.is_nil(first_minus.new_no)
        end,
    },
    {
        name = "parse_diff handles multiple hunks",
        fn = function()
            local txt = SAMPLE .. "@@ -50,1 +51,2 @@\n-old\n+new1\n+new2\n"
            local hunks = fd._parse_diff(txt)
            test.eq(#hunks, 2)
        end,
    },
    {
        name = "parse_diff strips +++ / --- file headers",
        fn = function()
            local hunks = fd._parse_diff(SAMPLE)
            for _, h in ipairs(hunks) do
                for _, ln in ipairs(h.lines) do
                    test.is_true(ln.text:sub(1, 3) ~= "+++" and ln.text:sub(1, 3) ~= "---")
                end
            end
        end,
    },
    {
        name = 'parse_diff skips "\\ No newline at end of file"',
        fn = function()
            local txt = "@@ -1,1 +1,1 @@\n-old\n+new\n\\ No newline at end of file\n"
            local hunks = fd._parse_diff(txt)
            test.eq(#hunks, 1)
            -- The "\ No newline..." marker is dropped, only +/- lines remain
            local kinds = {}
            for _, ln in ipairs(hunks[1].lines) do kinds[ln.kind] = true end
            test.is_true(kinds["+"])
            test.is_true(kinds["-"])
            test.is_nil(kinds["\\"])
        end,
    },
    {
        name = "parse_diff handles single-count hunk header (no comma)",
        fn = function()
            local txt = "@@ -5 +6 @@\n-x\n+y\n"
            local hunks = fd._parse_diff(txt)
            test.eq(#hunks, 1)
            test.is_true(#hunks[1].lines >= 2)
        end,
    },
}

local function define_tests()
    describe("keeper.git.flows:file_diff", function()
        for _, case in ipairs(cases) do it(case.name, case.fn) end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
