local test = require("test")
local validate = require("validate")

local function define_tests()
    describe("mcp.validate", function()
        describe("type_name", function()
            it("returns the scalar lua type name for non-tables", function()
                test.eq(validate.type_name("x"), "string")
                test.eq(validate.type_name(42), "number")
                test.eq(validate.type_name(true), "boolean")
                test.eq(validate.type_name(nil), "nil")
            end)

            it("reports empty tables as object (safe default)", function()
                test.eq(validate.type_name({}), "object")
            end)

            it("reports integer-indexed tables as array", function()
                test.eq(validate.type_name({ "a", "b" }), "array")
            end)

            it("reports string-keyed tables as object", function()
                test.eq(validate.type_name({ foo = 1 }), "object")
            end)
        end)

        describe("check_type", function()
            it("accepts values that match the expected primitive type", function()
                test.is_nil(validate.check_type("x", "string", "arg"))
                test.is_nil(validate.check_type(1.5, "number", "arg"))
                test.is_nil(validate.check_type(1, "integer", "arg"))
                test.is_nil(validate.check_type(true, "boolean", "arg"))
                test.is_nil(validate.check_type({}, "object", "arg"))
                test.is_nil(validate.check_type({ 1 }, "array", "arg"))
            end)

            it("rejects non-integer numbers when integer is required", function()
                local err = validate.check_type(1.5, "integer", "arg")
                test.not_nil(err)
                test.is_true(err:find("integer", 1, true) ~= nil)
            end)

            it("returns an error string that embeds the path", function()
                local err = validate.check_type(42, "string", "arguments.name")
                test.is_true(err:find("arguments.name", 1, true) ~= nil)
                test.is_true(err:find("string", 1, true) ~= nil)
            end)

            it("silently accepts unknown type names (lenient by design)", function()
                test.is_nil(validate.check_type("anything", "unknown-kind", "arg"))
            end)
        end)

        describe("check: type mismatches", function()
            it("fails when a required string is given as a number", function()
                local err = validate.check({ name = 42 }, {
                    type = "object",
                    properties = { name = { type = "string" } },
                })
                test.not_nil(err)
                test.is_true(err:find("arguments.name", 1, true) ~= nil)
            end)

            it("accepts a correctly-typed object", function()
                test.is_nil(validate.check({ name = "x" }, {
                    type = "object",
                    properties = { name = { type = "string" } },
                }))
            end)

            it("reports path into nested properties", function()
                local err = validate.check({ outer = { inner = 1 } }, {
                    type = "object",
                    properties = {
                        outer = {
                            type = "object",
                            properties = { inner = { type = "string" } },
                        },
                    },
                })
                test.not_nil(err)
                test.is_true(err:find("arguments.outer.inner", 1, true) ~= nil)
            end)
        end)

        describe("check: required", function()
            it("fails when a required key is missing", function()
                local err = validate.check({}, {
                    type = "object",
                    required = { "name" },
                    properties = { name = { type = "string" } },
                })
                test.not_nil(err)
                test.is_true(err:find("arguments.name is required", 1, true) ~= nil)
            end)

            it("passes when all required keys are present", function()
                test.is_nil(validate.check({ name = "x" }, {
                    type = "object",
                    required = { "name" },
                    properties = { name = { type = "string" } },
                }))
            end)

            it("does not complain about properties that are not listed as required", function()
                test.is_nil(validate.check({ name = "x" }, {
                    type = "object",
                    required = { "name" },
                    properties = {
                        name  = { type = "string" },
                        extra = { type = "string" },
                    },
                }))
            end)
        end)

        describe("check: enum", function()
            it("accepts values in the enum", function()
                test.is_nil(validate.check("a", { enum = { "a", "b" } }))
            end)

            it("rejects values not in the enum", function()
                local err = validate.check("c", { enum = { "a", "b" } })
                test.not_nil(err)
                test.is_true(err:find("allowed", 1, true) ~= nil)
            end)
        end)

        describe("check: arrays", function()
            it("validates items against the items schema", function()
                local err = validate.check({ tags = { "a", 42 } }, {
                    type = "object",
                    properties = {
                        tags = { type = "array", items = { type = "string" } },
                    },
                })
                test.not_nil(err)
                test.is_true(err:find("arguments.tags%[2%]") ~= nil)
            end)

            it("accepts a fully-typed array", function()
                test.is_nil(validate.check({ tags = { "a", "b" } }, {
                    type = "object",
                    properties = {
                        tags = { type = "array", items = { type = "string" } },
                    },
                }))
            end)

            it("tolerates arrays without an items schema", function()
                test.is_nil(validate.check({ tags = { 1, "x", true } }, {
                    type = "object",
                    properties = { tags = { type = "array" } },
                }))
            end)
        end)

        describe("check: overall behavior", function()
            it("returns nil when schema is nil or non-table", function()
                test.is_nil(validate.check({ foo = 1 }, nil))
                test.is_nil(validate.check({ foo = 1 }, "bogus"))
            end)

            it("treats missing args as an empty object for required-checking", function()
                local err = validate.check(nil, {
                    type = "object",
                    required = { "name" },
                    properties = { name = { type = "string" } },
                })
                test.not_nil(err)
            end)

            it("stops at the first error it finds (short-circuits)", function()
                -- Two problems present. Validator should return one error string,
                -- but is only required to surface at least one.
                local err = validate.check({ name = 42, age = "x" }, {
                    type = "object",
                    properties = {
                        name = { type = "string" },
                        age  = { type = "integer" },
                    },
                })
                test.not_nil(err)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
