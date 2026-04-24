local test = require("test")
local diff = require("diff")
local consts = require("consts")

local function define_tests()
    describe("diff helpers", function()
        describe("PARTS export", function()
            it("lists definition then content", function()
                test.eq(diff.PARTS[1], consts.CHUNKS.DEFINITION)
                test.eq(diff.PARTS[2], consts.CHUNKS.CONTENT)
                test.eq(#diff.PARTS, 2)
            end)
        end)

        describe("has_any_chunk", function()
            it("true when definition hash present", function()
                test.is_true(diff.has_any_chunk({ [consts.CHUNKS.DEFINITION] = "x" }))
            end)

            it("true when content hash present", function()
                test.is_true(diff.has_any_chunk({ [consts.CHUNKS.CONTENT] = "y" }))
            end)

            it("true when both present", function()
                test.is_true(diff.has_any_chunk({
                    [consts.CHUNKS.DEFINITION] = "x",
                    [consts.CHUNKS.CONTENT]    = "y",
                }))
            end)

            it("false for empty table", function()
                test.is_false(diff.has_any_chunk({}))
            end)

            it("false for non-table input", function()
                test.is_false(diff.has_any_chunk(nil))
                test.is_false(diff.has_any_chunk("x"))
                test.is_false(diff.has_any_chunk(42))
            end)

            it("ignores unrelated chunk keys", function()
                test.is_false(diff.has_any_chunk({ random = "z" }))
            end)
        end)

        describe("classify_part_change", function()
            it("returns CREATE when branch has hash, main has nil", function()
                test.eq(diff.classify_part_change("h1", nil), consts.OPS.CREATE)
            end)

            it("returns DELETE when main has hash, branch has nil", function()
                test.eq(diff.classify_part_change(nil, "h1"), consts.OPS.DELETE)
            end)

            it("returns UPDATE when hashes differ", function()
                test.eq(diff.classify_part_change("new", "old"), consts.OPS.UPDATE)
            end)

            it("returns nil when both nil", function()
                test.is_nil(diff.classify_part_change(nil, nil))
            end)

            it("returns nil when hashes match (no change)", function()
                test.is_nil(diff.classify_part_change("same", "same"))
            end)
        end)

        describe("fs_sort_order", function()
            it("orders create before update before delete alphabetically by op", function()
                local rows = {
                    { op = consts.OPS.UPDATE, target = "b" },
                    { op = consts.OPS.CREATE, target = "z" },
                    { op = consts.OPS.DELETE, target = "a" },
                }
                table.sort(rows, diff.fs_sort_order)
                test.eq(rows[1].op, consts.OPS.CREATE)
                test.eq(rows[2].op, consts.OPS.DELETE)
                test.eq(rows[3].op, consts.OPS.UPDATE)
            end)

            it("orders by target when op matches", function()
                local rows = {
                    { op = consts.OPS.CREATE, target = "c" },
                    { op = consts.OPS.CREATE, target = "a" },
                    { op = consts.OPS.CREATE, target = "b" },
                }
                table.sort(rows, diff.fs_sort_order)
                test.eq(rows[1].target, "a")
                test.eq(rows[2].target, "b")
                test.eq(rows[3].target, "c")
            end)

            it("is stable for identical rows", function()
                local rows = {
                    { op = consts.OPS.UPDATE, target = "x" },
                    { op = consts.OPS.UPDATE, target = "x" },
                }
                table.sort(rows, diff.fs_sort_order)
                test.eq(rows[1].target, "x")
                test.eq(rows[2].target, "x")
            end)
        end)

        describe("compute / registry_diff arg guards", function()
            it("registry_diff rejects nil changeset_id", function()
                local res, err = diff.registry_diff(nil)
                test.is_nil(res)
                test.is_true(err:find("changeset_id", 1, true) ~= nil)
            end)

            it("filesystem_diff rejects nil changeset_id", function()
                local res, err = diff.filesystem_diff(nil)
                test.is_nil(res)
                test.is_true(err:find("changeset_id", 1, true) ~= nil)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
