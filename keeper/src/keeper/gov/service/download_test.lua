local test = require("test")
local download = require("download")

local function define_tests()
    describe("gov.service.download pure helpers", function()
        describe("compute_file_ops", function()
            it("returns empty array for empty or nil input", function()
                test.eq(#download.compute_file_ops({}), 0)
                test.eq(#download.compute_file_ops(nil), 0)
            end)

            it("turns each map key/value pair into a {path, op} row", function()
                local ops = download.compute_file_ops({
                    ["./a/x.lua"] = "create",
                    ["./b/y.lua"] = "update",
                })
                test.eq(#ops, 2)
                local kinds = { [ops[1].op] = true, [ops[2].op] = true }
                test.is_true(kinds["create"])
                test.is_true(kinds["update"])
            end)

            it("sorts results by path so callers get deterministic ordering", function()
                local ops = download.compute_file_ops({
                    ["./b.lua"] = "update",
                    ["./a.lua"] = "create",
                    ["./c.lua"] = "create",
                })
                test.eq(ops[1].path, "./a.lua")
                test.eq(ops[2].path, "./b.lua")
                test.eq(ops[3].path, "./c.lua")
            end)

            it("tolerates non-table input with an empty result", function()
                test.eq(#download.compute_file_ops("bogus"), 0)
                test.eq(#download.compute_file_ops(42), 0)
            end)

            it("preserves the op verbatim without validating it", function()
                local ops = download.compute_file_ops({ ["p"] = "weird" })
                test.eq(ops[1].op, "weird")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
