local test = require("test")
local security = require("security")

local function define_tests()
    test.describe("Hub registry resolution permission", function()
        test.it("grants Hub administrators resolution reads without adding writes or user access", function()
            local actor = security.new_actor("hub-resolution-test")
            local policy = security.policy("keeper.hub.security:admin_catalog")
            test.eq(policy:evaluate(actor, "registry.resolution.get", "", {}), "allow")
            test.eq(policy:evaluate(actor, "registry.apply", "", {}), "undefined")
            local admin = security.named_scope("app.security:admin")
            local user = security.named_scope("app.security:user")
            test.eq(admin:evaluate(actor, "registry.resolution.get", "", {}), "allow")
            test.eq(user:evaluate(actor, "registry.resolution.get", "", {}), "undefined")
        end)
    end)
end

return { define_tests = test.run_cases(define_tests) }
