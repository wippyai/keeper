local scanner = require("scanner")
local test = require("test")

local function define_tests()
    describe("components scanner policy", function()
        it("marks keeper app source as module-owned when keeper/keeper is installed", function()
            local slugs = scanner._test.module_owned_app_slugs_from_modules({ "keeper/keeper" })
            test.eq(slugs.keeper, true)
        end)

        it("does not hide unrelated module frontends", function()
            local slugs = scanner._test.module_owned_app_slugs_from_modules({ "wippy/dataflow", "keeper/git" })
            test.is_nil(slugs.git)
        end)

        it("does not hide unrelated modules with the same package suffix", function()
            local slugs = scanner._test.module_owned_app_slugs_from_modules({ "example/keeper" })
            test.is_nil(slugs.keeper)
        end)

        it("treats a missing installed-module list as no module-owned apps", function()
            local empty = scanner._test.module_owned_app_slugs_from_modules(nil)
            test.is_nil(empty.keeper)
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

    describe("components scanner resolution", function()
        it("resolves a filesystem component from its source package", function()
            local desc, err = scanner.get("@wippy/app-keeper-git")
            test.is_nil(err)
            test.eq(desc.id, "@wippy/app-keeper-git")
            test.eq(desc.kind, "app")
            test.eq(desc.path, "plugins/git/frontend/applications/git")
            test.eq(desc.link_kind, "local")
            test.eq(desc.editable, true)
        end)

        it("resolves a registry view.component by its entry id", function()
            local desc, err = scanner.get("app.components:mounted_view")
            test.is_nil(err)
            test.eq(desc.id, "app.components:mounted_view")
            test.eq(desc.kind, "widget")
            test.eq(desc.title, "Mounted View")
            test.eq(desc.tag_name, "fixture-mounted-view")
            test.eq(desc.base_path, "fixture-mounted")
            test.eq(desc.entry_point, "index.js")
            test.eq(desc.link_kind, "registry")
            test.eq(desc.editable, false)
            test.eq(desc.is_main_app, false)
            test.eq(desc.built, true)
        end)

        it("resolves a registry view.component by its tag name", function()
            local desc, err = scanner.get("fixture-mounted-view")
            test.is_nil(err)
            test.eq(desc.id, "app.components:mounted_view")
        end)

        it("refuses a tag name that several registry components declare", function()
            local desc, err = scanner.get("fixture-shared-tag")
            test.is_nil(desc)
            test.contains(tostring(err), "app.components:shared_tag_a")
            test.contains(tostring(err), "app.components:shared_tag_b")
            local exact = scanner.get("app.components:shared_tag_b")
            test.eq(exact.base_path, "fixture-shared-b")
        end)

        it("keeps registry components out of the filesystem scan", function()
            local result = assert(scanner.scan())
            for _, list in ipairs({ result.applications, result.widgets }) do
                for _, desc in ipairs(list) do
                    test.neq(desc.link_kind, "registry", tostring(desc.id))
                end
            end
        end)

        it("reports an id that neither source declares", function()
            local desc, err = scanner.get("fixture-unknown-component")
            test.is_nil(desc)
            test.contains(tostring(err), "component not found: fixture-unknown-component")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
