local governance = require("governance")
local test = require("test")

local function define_tests()
    describe("keeper.state.publish:governance", function()

        describe("current_version", function()
            it("returns a non-negative integer version", function()
                local version, err = governance.current_version()
                test.is_nil(err, "current_version error: " .. tostring(err))
                test.not_nil(version)
                test.eq(type(version), "number")
                test.is_true(version >= 0, "registry version should be >= 0")
            end)
        end)

        describe("publish input guards", function()
            it("rejects nil changeset", function()
                local _, err = governance.publish(nil, {})
                test.not_nil(err)
                test.is_true(err:find("changeset required") ~= nil)
            end)
        end)

        describe("restore_version input guards", function()
            it("rejects nil version", function()
                local _, err = governance.restore_version(nil, "x")
                test.not_nil(err)
                test.is_true(err:find("version_id required") ~= nil)
            end)

            it("rejects empty version", function()
                local _, err = governance.restore_version("", "x")
                test.not_nil(err)
                test.is_true(err:find("version_id required") ~= nil)
            end)

            it("rejects non-numeric version", function()
                local _, err = governance.restore_version("abc", "x")
                test.not_nil(err)
                test.is_true(err:find("must be numeric") ~= nil)
            end)

            it("rejects negative version", function()
                local _, err = governance.restore_version(-1, "x")
                test.not_nil(err)
                test.is_true(err:find("non%-negative") ~= nil)
            end)
        end)

    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
