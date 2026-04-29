local scanner = require("scanner")
local test = require("test")

local function define_tests()
    describe("components scanner policy", function()
        it("marks keeper app source as module-owned when keeper/keeper is installed", function()
            local slugs = scanner._test.module_owned_app_slugs_from_lock([[
directories:
  src: ./src/app
modules:
  - name: keeper/keeper
    version: 0.4.2
    hash: abc
]])
            test.eq(slugs.keeper, true)
        end)

        it("does not hide plugin replacement frontends", function()
            local slugs = scanner._test.module_owned_app_slugs_from_lock([[
directories:
  src: ./src/app
modules:
  - name: wippy/dataflow
    version: 0.4.10
replacements:
  - from: keeper/git
    to: ./plugins/git
]])
            test.is_nil(slugs.git)
        end)

        it("does not hide unrelated modules with the same package suffix", function()
            local slugs = scanner._test.module_owned_app_slugs_from_lock([[
modules:
  - name: example/keeper
    version: 1.0.0
]])
            test.is_nil(slugs.keeper)
        end)

        it("treats missing or malformed lock content as no module-owned apps", function()
            local empty = scanner._test.module_owned_app_slugs_from_lock("")
            local malformed = scanner._test.module_owned_app_slugs_from_lock("modules: [")
            test.is_nil(empty.keeper)
            test.is_nil(malformed.keeper)
        end)

        it("accepts only clean component directory names", function()
            test.eq(scanner._test.is_component_dir_name("keeper"), true)
            test.eq(scanner._test.is_component_dir_name("keeper-git"), true)
            test.eq(scanner._test.is_component_dir_name("model_gallery.v2"), true)

            test.eq(scanner._test.is_component_dir_name("keeper "), false)
            test.eq(scanner._test.is_component_dir_name(" keeper"), false)
            test.eq(scanner._test.is_component_dir_name("keeper git"), false)
            test.eq(scanner._test.is_component_dir_name("../keeper"), false)
            test.eq(scanner._test.is_component_dir_name(""), false)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
