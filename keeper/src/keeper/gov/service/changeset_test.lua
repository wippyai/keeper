local test = require("test")
local changeset_proc = require("changeset_proc")
local gov_consts = require("gov_consts")

local function define_tests()
    describe("gov.service.changeset helpers", function()
        describe("merge_options", function()
            it("returns empty table for both nil", function()
                local out = changeset_proc.merge_options(nil, nil)
                test.not_nil(out)
                test.eq(next(out), nil)
            end)

            it("returns copy of base when override nil", function()
                local base = { a = 1, b = 2 }
                local out = changeset_proc.merge_options(base, nil)
                test.eq(out.a, 1)
                test.eq(out.b, 2)
                out.a = 99
                test.eq(base.a, 1)
            end)

            it("returns copy of override when base nil", function()
                local out = changeset_proc.merge_options(nil, { a = 1 })
                test.eq(out.a, 1)
            end)

            it("override takes precedence on duplicate keys", function()
                local out = changeset_proc.merge_options({ a = 1, b = 2 }, { b = 99, c = 3 })
                test.eq(out.a, 1)
                test.eq(out.b, 99)
                test.eq(out.c, 3)
            end)

            it("tolerates non-table inputs", function()
                local out = changeset_proc.merge_options("x", 42)
                test.not_nil(out)
                test.eq(next(out), nil)
            end)
        end)

        describe("count_errors", function()
            it("returns 0 for empty list", function()
                test.eq(changeset_proc.count_errors({}), 0)
            end)

            it("returns 0 for non-table input", function()
                test.eq(changeset_proc.count_errors(nil), 0)
                test.eq(changeset_proc.count_errors("x"), 0)
            end)

            it("counts only type=error rows", function()
                local issues = {
                    { type = "error",   message = "e1" },
                    { type = "warning", message = "w1" },
                    { type = "error",   message = "e2" },
                    { type = "info",    message = "i1" },
                }
                test.eq(changeset_proc.count_errors(issues), 2)
            end)

            it("ignores rows without a type", function()
                test.eq(changeset_proc.count_errors({ { message = "no type" } }), 0)
            end)
        end)

        describe("check_basic_shape", function()
            it("flags empty / nil / non-table changeset with NO_CHANGESET", function()
                for _, input in ipairs({ nil, {}, "bogus" }) do
                    local issues = changeset_proc.check_basic_shape(input)
                    test.eq(#issues, 1)
                    test.eq(issues[1].id, "changeset")
                    test.eq(issues[1].type, "error")
                    test.eq(issues[1].message, gov_consts.ERRORS.NO_CHANGESET)
                end
            end)

            it("returns empty issues for a valid create in a managed namespace", function()
                local issues = changeset_proc.check_basic_shape({
                    { kind = gov_consts.REGISTRY_OPERATIONS.CREATE,
                      entry = { id = "app.x:svc", kind = "function.lua" } },
                })
                test.eq(#issues, 0)
            end)

            it("flags missing kind or entry", function()
                local issues = changeset_proc.check_basic_shape({ { entry = { id = "app.x:svc" } } })
                test.eq(#issues, 1)
                test.is_true(issues[1].message:find("Missing kind or entry", 1, true) ~= nil)
                test.eq(issues[1].id, "item:1")
            end)

            it("flags unknown op kinds", function()
                local issues = changeset_proc.check_basic_shape({
                    { kind = "rename", entry = { id = "app.x:svc" } },
                })
                test.eq(#issues, 1)
                test.is_true(issues[1].message:find(gov_consts.ERRORS.INVALID_OPERATION, 1, true) ~= nil)
                test.is_true(issues[1].message:find("rename", 1, true) ~= nil)
            end)

            it("flags delete with missing entry.id", function()
                local issues = changeset_proc.check_basic_shape({
                    { kind = gov_consts.REGISTRY_OPERATIONS.DELETE, entry = {} },
                })
                test.eq(#issues, 1)
                test.eq(issues[1].message, gov_consts.ERRORS.MISSING_ENTRY_ID)
            end)

            it("flags unmanaged namespace on create", function()
                local issues = changeset_proc.check_basic_shape({
                    { kind = gov_consts.REGISTRY_OPERATIONS.CREATE,
                      entry = { id = "random.ns:thing", kind = "function.lua" } },
                })
                test.eq(#issues, 1)
                test.is_true(issues[1].message:find(gov_consts.ERRORS.UNMANAGED_NAMESPACE, 1, true) ~= nil)
                test.is_true(issues[1].message:find("random.ns", 1, true) ~= nil)
            end)

            it("accumulates issues across multiple rows", function()
                local issues = changeset_proc.check_basic_shape({
                    { kind = gov_consts.REGISTRY_OPERATIONS.CREATE,
                      entry = { id = "app.x:svc", kind = "function.lua" } },
                    { entry = { id = "missing-kind" } },
                    { kind = "bogus", entry = { id = "app.y:other" } },
                })
                test.eq(#issues, 2)
            end)

            it("does NOT flag unmanaged namespace for DELETE-by-id only check (delete still scans id)", function()
                local issues = changeset_proc.check_basic_shape({
                    { kind = gov_consts.REGISTRY_OPERATIONS.DELETE,
                      entry = { id = "app.x:svc" } },
                })
                test.eq(#issues, 0)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
