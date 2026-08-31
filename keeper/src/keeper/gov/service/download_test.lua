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

        describe("count_index_files", function()
            it("returns zero for empty, nil or non-table input", function()
                test.eq(download.count_index_files({}), 0)
                test.eq(download.count_index_files(nil), 0)
                test.eq(download.count_index_files("bogus"), 0)
                test.eq(download.count_index_files(42), 0)
            end)

            it("counts one index file per namespace directory", function()
                test.eq(download.count_index_files({
                    ["./app/mail/_index.yaml"] = "update",
                    ["./xepozz/smtp/_index.yaml"] = "update",
                    ["./app/access/_index.yaml"] = "create",
                }), 3)
            end)

            it("does not count the source bodies written beside them", function()
                test.eq(download.count_index_files({
                    ["./app/mail/_index.yaml"] = "update",
                    ["./app/mail/fetch_body.lua"] = "update",
                    ["./app/mail/smtp_pull.lua"] = "create",
                }), 1)
            end)

            it("counts a create and an update alike", function()
                test.eq(download.count_index_files({
                    ["./a/_index.yaml"] = "create",
                    ["./b/_index.yaml"] = "update",
                }), 2)
            end)

            it("does not count a file merely ending in the index name", function()
                test.eq(download.count_index_files({
                    ["./app/mail/not_index.yaml"] = "update",
                    ["./app/mail/my_index.yaml"] = "update",
                }), 0)
            end)

            it("ignores a bare index name with no directory before it", function()
                test.eq(download.count_index_files({ ["_index.yaml"] = "create" }), 0)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
