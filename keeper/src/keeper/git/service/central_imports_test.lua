local registry = require("registry")
local test = require("test")

local function define_tests()
    test.describe("keeper.git.service:central imports", function()
        test.it("declares every handler required by central.lua", function()
            local entry, err = registry.get("keeper.git.service:central")
            test.is_nil(err)
            test.not_nil(entry)

            local imports = entry.data and entry.data.imports or {}
            test.eq(imports.snapshot_handler, "keeper.git.service.handlers:snapshot")
            test.eq(imports.decisions_handler, "keeper.git.service.handlers:decisions")
            test.eq(imports.rebuild_handler, "keeper.git.service.handlers:rebuild")
            test.eq(imports.push_handler, "keeper.git.service.handlers:push")
            test.eq(imports.explain_handler, "keeper.git.service.handlers:explain")
            test.eq(imports.split_handler, "keeper.git.service.handlers:split")
            test.eq(imports.pr_handler, "keeper.git.service.handlers:pr")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
