local test = require("test")
local service = require("service")
local gov_consts = require("gov_consts")

local function define_tests()
    describe("installed module sources", function()
        local namespaces
        test.before_each(function()
            namespaces = gov_consts.get_managed_namespaces()
            local _, set_err = gov_consts.set_managed_namespaces({"app"})
            test.is_nil(set_err)
        end)
        test.after_each(function()
            local _, set_err = gov_consts.set_managed_namespaces(namespaces)
            test.is_nil(set_err)
        end)
        for _, include_modules in ipairs({true, false}) do
            it("exposes Hub and replacement sources with inventory " .. tostring(include_modules), function()
                local out, list_err = service.new():list_dependencies({
                    include_entries = false, include_migrations = false,
                    include_modules = include_modules,
                })
                test.is_nil(list_err)
                local roots, modules = {}, {}
                for _, row in ipairs(out.dependencies) do roots[row.component] = row end
                for _, row in ipairs(out.modules) do modules[row.name] = row end
                test.not_nil(roots["wippy/session"])
                test.not_nil(roots["keeper/empty-fixture"])
                test.eq(roots["wippy/session"].source, "hub")
                test.eq(roots["keeper/empty-fixture"].source, "replacement-tree-v1")
                if include_modules then
                    test.eq(modules["wippy/session"].source, "hub")
                    test.eq(modules["keeper/empty-fixture"].source, "replacement-tree-v1")
                    test.eq(modules["wippy/test"].source, "hub")
                end
            end)
        end
    end)
end

return {define_tests = test.run_cases(define_tests)}
