local test = require("test")
local filenames = require("filenames")

local function define_tests()
    test.describe("keeper.components:filenames", function()
        test.it("keeps simple portable stems", function()
            test.eq(filenames.safe_stem("keeper-registry_01"), "keeper-registry_01")
            test.eq(filenames.safe_stem("keeper.png"), "keeper")
            test.eq(filenames.safe_stem("Keeper UI.PNG"), "Keeper_UI")
        end)

        test.it("neutralizes traversal, separators, whitespace, and hidden names", function()
            test.eq(filenames.safe_stem("../../etc/passwd.png"), "etc_passwd")
            test.eq(filenames.safe_stem("..\\.env"), "env")
            test.eq(filenames.safe_stem(" route:/settings/registry "), "route_settings_registry")
        end)

        test.it("falls back when the input has no safe characters", function()
            test.eq(filenames.safe_stem("   ", { fallback = "shot" }), "shot")
            test.eq(filenames.safe_stem("///", { fallback = "../safe fallback.png" }), "safe_fallback")
        end)

        test.it("avoids reserved device names", function()
            test.eq(filenames.safe_stem("CON"), "file_CON")
            test.eq(filenames.safe_stem("com1.png"), "file_com1")
            test.eq(filenames.safe_stem("LPT9"), "file_LPT9")
        end)

        test.it("caps long names", function()
            local stem = filenames.safe_stem(
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                { max_length = 32 }
            )
            test.is_true(#stem <= 32, "stem must be capped")
            test.eq(stem, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        end)

        test.it("adds an opaque seed while preserving filename safety", function()
            test.eq(
                filenames.with_random_seed("../../Registry View.PNG", { seed = "abc/123", max_length = 48 }),
                "Registry_View-abc_123"
            )
        end)

        test.it("caps seeded names without dropping the seed", function()
            local stem = filenames.with_random_seed(
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                { seed = "deadbeefcafebabe", max_length = 32 }
            )
            test.eq(stem, "aaaaaaaaaaaaaaa-deadbeefcafebabe")
            test.is_true(#stem <= 32, "seeded stem must be capped")
        end)

        test.it("derives component slugs from descriptor paths before ids", function()
            test.eq(filenames.component_slug({ path = "/components/Keeper App" }, "@wippy/app-keeper"), "Keeper_App")
            test.eq(filenames.component_slug(nil, "@wippy/app-keeper"), "wippy_app-keeper")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
