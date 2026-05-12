local governance = require("governance")
local test = require("test")
local funcs = require("funcs")
local security = require("security")

local function call_as_admin(func_id, args)
    local scope, scope_err = security.named_scope("app.security:admin")
    test.is_nil(scope_err, "admin scope must be available: " .. tostring(scope_err))
    test.not_nil(scope)

    local actor = security.new_actor("keeper-test-admin")
    return funcs.new()
        :with_actor(actor)
        :with_scope(scope)
        :call(func_id, args or {})
end

local function define_tests()
    describe("keeper.state.publish:governance", function()

        describe("current_version", function()
            it("returns a non-negative integer version", function()
                local result, err = call_as_admin("keeper.state.publish:current_version_probe")
                test.is_nil(err, "current_version error: " .. tostring(err))
                test.not_nil(result)
                local version = result.version
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
