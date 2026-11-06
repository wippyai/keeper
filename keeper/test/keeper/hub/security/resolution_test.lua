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

        test.it("grants Hub administrators exactly the install worker, its host and its lock", function()
            local actor = security.new_actor("hub-install-test")
            local admin = security.named_scope("app.security:admin")
            local user = security.named_scope("app.security:user")
            local allowed = {
                { "process.spawn", "keeper.hub.api:install_worker" },
                { "process.spawn.monitored", "keeper.hub.api:install_worker" },
                { "process.host", "app:processes" },
                { "process.registry.register", "keeper.hub.install" },
            }
            for _, grant in ipairs(allowed) do
                test.eq(admin:evaluate(actor, grant[1], grant[2], {}), "allow")
                test.eq(user:evaluate(actor, grant[1], grant[2], {}), "undefined")
            end
            local policy = security.policy("keeper.hub.security:admin_install_process")
            test.eq(policy:evaluate(actor, "process.spawn", "keeper.other:worker", {}), "undefined")
            test.eq(policy:evaluate(actor, "process.registry.register", "keeper.hub.api:install_worker", {}), "undefined")
            local lock = security.policy("keeper.hub.security:admin_install_lock")
            test.eq(lock:evaluate(actor, "process.registry.register", "keeper.other", {}), "undefined")
            test.eq(lock:evaluate(actor, "process.spawn", "keeper.hub.install", {}), "undefined")
        end)

        test.it("lets Hub administrators read the configured registry without sign-in rights", function()
            local actor = security.new_actor("hub-registry-test")
            local registry = "https://hub.stage.wippy.ai"
            local policy = security.policy("keeper.hub.security:admin_catalog")
            test.eq(policy:evaluate(actor, "hub.auth.status", registry, {}), "allow")
            test.eq(policy:evaluate(actor, "hub.auth.authenticate", registry, {}), "undefined")
            test.eq(policy:evaluate(actor, "hub.auth.logout", registry, {}), "undefined")
            local admin = security.named_scope("app.security:admin")
            local user = security.named_scope("app.security:user")
            test.eq(admin:evaluate(actor, "hub.auth.status", registry, {}), "allow")
            test.eq(user:evaluate(actor, "hub.auth.status", registry, {}), "undefined")
        end)
    end)
end

return { define_tests = test.run_cases(define_tests) }
