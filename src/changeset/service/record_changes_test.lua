local test = require("test")
local record_changes = require("record_changes")

local function valid_row(overrides)
    local r = {
        category = "registry",
        op = "create",
        target = "app.users:svc",
        source = "materialized",
        status = "pending",
    }
    for k, v in pairs(overrides or {}) do r[k] = v end
    return r
end

local function define_tests()
    describe("record_changes helpers", function()
        describe("validate_rows", function()
            it("accepts an empty array", function()
                test.is_nil(record_changes.validate_rows({}))
            end)

            it("accepts a minimally valid row", function()
                test.is_nil(record_changes.validate_rows({ valid_row() }))
            end)

            it("accepts both registry and filesystem categories", function()
                test.is_nil(record_changes.validate_rows({
                    valid_row({ category = "registry" }),
                    valid_row({ category = "filesystem" }),
                }))
            end)

            it("accepts all three ops", function()
                test.is_nil(record_changes.validate_rows({ valid_row({ op = "create" }) }))
                test.is_nil(record_changes.validate_rows({ valid_row({ op = "update" }) }))
                test.is_nil(record_changes.validate_rows({ valid_row({ op = "delete" }) }))
            end)

            it("accepts all four statuses", function()
                test.is_nil(record_changes.validate_rows({ valid_row({ status = "pending" }) }))
                test.is_nil(record_changes.validate_rows({ valid_row({ status = "applied", source = "pushed" }) }))
                test.is_nil(record_changes.validate_rows({ valid_row({ status = "superseded" }) }))
                test.is_nil(record_changes.validate_rows({ valid_row({ status = "rejected" }) }))
            end)

            it("rejects non-array rows", function()
                test.eq(record_changes.validate_rows(nil), "rows must be an array")
                test.eq(record_changes.validate_rows("x"), "rows must be an array")
            end)

            it("rejects non-table row", function()
                local err = record_changes.validate_rows({ "not a table" })
                test.is_true(err:find("rows[1]", 1, true) ~= nil)
                test.is_true(err:find("must be a table", 1, true) ~= nil)
            end)

            it("rejects invalid category", function()
                local err = record_changes.validate_rows({ valid_row({ category = "bogus" }) })
                test.is_true(err:find("category invalid", 1, true) ~= nil)
                test.is_true(err:find("bogus", 1, true) ~= nil)
            end)

            it("rejects nil category", function()
                local row = valid_row()
                row.category = nil
                local err = record_changes.validate_rows({ row })
                test.is_true(err:find("category invalid", 1, true) ~= nil)
            end)

            it("rejects invalid op", function()
                local err = record_changes.validate_rows({ valid_row({ op = "drop" }) })
                test.is_true(err:find("op invalid", 1, true) ~= nil)
            end)

            it("rejects missing target", function()
                local row = valid_row()
                row.target = nil
                local err = record_changes.validate_rows({ row })
                test.is_true(err:find("target is required", 1, true) ~= nil)
            end)

            it("rejects empty target", function()
                local err = record_changes.validate_rows({ valid_row({ target = "" }) })
                test.is_true(err:find("target is required", 1, true) ~= nil)
            end)

            it("rejects missing source", function()
                local row = valid_row()
                row.source = nil
                local err = record_changes.validate_rows({ row })
                test.is_true(err:find("source is required", 1, true) ~= nil)
            end)

            it("rejects invalid status", function()
                local err = record_changes.validate_rows({ valid_row({ status = "closed" }) })
                test.is_true(err:find("status invalid", 1, true) ~= nil)
            end)

            it("points at the correct row index in multi-row input", function()
                local err = record_changes.validate_rows({
                    valid_row(),
                    valid_row(),
                    valid_row({ op = "ruin" }),
                })
                test.is_true(err:find("rows[3]", 1, true) ~= nil)
                test.is_true(err:find("op invalid", 1, true) ~= nil)
            end)
        end)

        describe("is_applied_push", function()
            it("true for changeset_id + APPLIED + PUSHED", function()
                test.is_true(record_changes.is_applied_push({
                    changeset_id = "cs-1", status = "applied", source = "pushed",
                }))
            end)

            it("true for changeset_id + APPLIED + FS_FLUSHED", function()
                test.is_true(record_changes.is_applied_push({
                    changeset_id = "cs-1", status = "applied", source = "fs_flushed",
                }))
            end)

            it("false when changeset_id is missing (orphan row)", function()
                test.is_false(record_changes.is_applied_push({
                    status = "applied", source = "pushed",
                }))
            end)

            it("false when status is not APPLIED", function()
                test.is_false(record_changes.is_applied_push({
                    changeset_id = "cs-1", status = "pending", source = "pushed",
                }))
            end)

            it("false when source is not a push-path source", function()
                test.is_false(record_changes.is_applied_push({
                    changeset_id = "cs-1", status = "applied", source = "materialized",
                }))
            end)

            it("false for completely empty row", function()
                test.is_false(record_changes.is_applied_push({}))
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
