local test = require("test")
local contracts = require("contracts")

local function find(errors, code)
    for _, e in ipairs(errors or {}) do
        if e.code == code then return e end
    end
    return nil
end

local function find_for(errors, code, field)
    for _, e in ipairs(errors or {}) do
        if e.code == code and e.message and e.message:find(field, 1, true) then
            return e
        end
    end
    return nil
end

local function define_tests()
    test.describe("keeper.state.contracts:library", function()
        test.it("passes a well-formed function.lua entry", function()
            local errs = contracts.validate_registry({
                id   = "ns:foo",
                kind = "function.lua",
                meta = { comment = "x" },
                data = { source = "file://foo.lua", method = "handler" },
            })
            test.eq(#errs, 0)
        end)

        test.it("flags function.lua missing method", function()
            local errs = contracts.validate_registry({
                id   = "ns:foo",
                kind = "function.lua",
                data = { source = "file://foo.lua" },
            })
            test.not_nil(find_for(errs, contracts.ERR.SCHEMA_MISSING_FIELD, "method"))
            local e = find_for(errs, contracts.ERR.SCHEMA_MISSING_FIELD, "method")
            test.not_nil(e.fix_hint)
            test.is_false(e.retryable)
            test.eq(e.stage, "validate")
            test.eq(e.target, "ns:foo")
        end)

        test.it("flags function.lua with empty {} data", function()
            local errs = contracts.validate_registry({
                id   = "ns:foo",
                kind = "function.lua",
                data = {},
            })
            test.not_nil(find_for(errs, contracts.ERR.SCHEMA_MISSING_FIELD, "source"))
            test.not_nil(find_for(errs, contracts.ERR.SCHEMA_MISSING_FIELD, "method"))
        end)

        test.it("flags wrong type for source", function()
            local errs = contracts.validate_registry({
                id   = "ns:foo",
                kind = "function.lua",
                data = { source = {}, method = "h" },
            })
            test.not_nil(find_for(errs, contracts.ERR.SCHEMA_WRONG_TYPE, "source"))
        end)

        test.it("passes a well-formed library.lua entry", function()
            local errs = contracts.validate_registry({
                id   = "ns:lib",
                kind = "library.lua",
                data = { source = "file://lib.lua" },
            })
            test.eq(#errs, 0)
        end)

        test.it("flags library.lua with method field (convention violation)", function()
            local errs = contracts.validate_registry({
                id   = "ns:lib",
                kind = "library.lua",
                data = { source = "file://lib.lua", method = "handler" },
            })
            test.not_nil(find(errs, contracts.ERR.SCHEMA_FORBIDDEN_FIELD))
        end)

        test.it("flags http.endpoint missing method/path/func/router", function()
            local errs = contracts.validate_registry({
                id   = "ns:ep",
                kind = "http.endpoint",
                data = {},
            })
            test.not_nil(find_for(errs, contracts.ERR.SCHEMA_MISSING_FIELD, "method"))
            test.not_nil(find_for(errs, contracts.ERR.SCHEMA_MISSING_FIELD, "path"))
            test.not_nil(find_for(errs, contracts.ERR.SCHEMA_MISSING_FIELD, "func"))
            test.not_nil(find_for(errs, contracts.ERR.SCHEMA_MISSING_FIELD, "router"))
        end)

        test.it("passes a well-formed http.endpoint entry", function()
            local errs = contracts.validate_registry({
                id   = "ns:ep",
                kind = "http.endpoint",
                meta = { router = "app:api" },
                data = { method = "GET", path = "/api/x", func = "handler" },
            })
            test.eq(#errs, 0)
        end)

        test.it("flags contract.binding missing contracts array", function()
            local errs = contracts.validate_registry({
                id   = "ns:bind",
                kind = "contract.binding",
                data = {},
            })
            test.not_nil(find_for(errs, contracts.ERR.SCHEMA_MISSING_FIELD, "contracts"))
        end)

        test.it("flags contract.binding empty contracts array", function()
            local errs = contracts.validate_registry({
                id   = "ns:bind",
                kind = "contract.binding",
                data = { contracts = {} },
            })
            test.not_nil(find_for(errs, contracts.ERR.SCHEMA_MISSING_FIELD, "contracts"))
        end)

        test.it("unknown kinds pass through", function()
            local errs = contracts.validate_registry({
                id   = "ns:weird",
                kind = "totally.new.kind",
                data = {},
            })
            test.eq(#errs, 0)
        end)

        test.it("missing id/kind is flagged", function()
            local e1 = contracts.validate_registry(nil)
            test.not_nil(find(e1, contracts.ERR.SCHEMA_WRONG_TYPE))
            local e2 = contracts.validate_registry({ id = "ns:foo" })
            test.not_nil(find(e2, contracts.ERR.SCHEMA_MISSING_FIELD))
        end)

        test.it("validate_many flattens errors across entries", function()
            local errs = contracts.validate_many({
                { id = "ns:a", kind = "function.lua", data = {} },
                { id = "ns:b", kind = "library.lua",  data = { source = "file://b.lua" } },
                { id = "ns:c", kind = "function.lua", data = { source = "file://c.lua", method = "h" } },
            })
            test.is_true(#errs >= 2)
            test.not_nil(find(errs, contracts.ERR.SCHEMA_MISSING_FIELD))
        end)
    end)
end

return {
    define_tests = test.run_cases(define_tests)
}
