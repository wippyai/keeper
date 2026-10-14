local test = require("test")
local sync = require("sync")

local function define_tests()
    describe("gov.service.sync source-file helpers", function()
        describe("pick_kind_config", function()
            it("returns the direct config for a plain kind like function.lua", function()
                local cfg = sync.pick_kind_config("function.lua", nil)
                test.not_nil(cfg)
                test.eq(cfg.source_field, "source")
                test.eq(cfg.extension, ".lua")
            end)

            it("returns the direct config for legacy template.jet pages", function()
                local cfg = sync.pick_kind_config("template.jet", nil)
                test.not_nil(cfg)
                test.eq(cfg.source_field, "source")
                test.eq(cfg.extension, ".jet")
            end)

            it("falls through to the meta.type branch for registry.entry", function()
                local cfg = sync.pick_kind_config("registry.entry", "view.page")
                test.not_nil(cfg)
                test.eq(cfg.extension, ".html")
            end)

            it("returns nil for unknown kinds", function()
                test.is_nil(sync.pick_kind_config("bogus.kind", nil))
            end)

            it("returns nil when registry.entry has no matching meta.type", function()
                test.is_nil(sync.pick_kind_config("registry.entry", "unknown.thing"))
            end)

            it("returns nil when registry.entry is given no meta.type at all", function()
                test.is_nil(sync.pick_kind_config("registry.entry", nil))
            end)

            it("handles library.lua and process.lua symmetrically with function.lua", function()
                test.eq(sync.pick_kind_config("library.lua", nil).extension, ".lua")
                test.eq(sync.pick_kind_config("process.lua", nil).extension, ".lua")
            end)

            it("externalizes workflow.lua source to a .lua file like other actor kinds", function()
                local cfg = sync.pick_kind_config("workflow.lua", nil)
                test.not_nil(cfg)
                test.eq(cfg.source_field, "source")
                test.eq(cfg.extension, ".lua")
            end)
        end)

        describe("append_extension", function()
            it("appends when the filename has no extension", function()
                test.eq(sync.append_extension("foo", ".lua"), "foo.lua")
            end)

            it("is a no-op when the filename already ends with the extension", function()
                test.eq(sync.append_extension("foo.lua", ".lua"), "foo.lua")
            end)

            it("handles multi-segment extensions", function()
                test.eq(sync.append_extension("foo", ".yml"), "foo.yml")
                test.eq(sync.append_extension("foo.yml", ".yml"), "foo.yml")
            end)

            it("returns the filename unchanged when either argument is nil", function()
                test.eq(sync.append_extension(nil, ".lua"), nil)
                test.eq(sync.append_extension("foo", nil), "foo")
            end)
        end)

        describe("extract_filename", function()
            it("returns the path portion of a file:// URL", function()
                test.eq(sync.extract_filename("file://foo.lua"), "foo.lua")
            end)

            it("returns the path portion when it contains slashes", function()
                test.eq(sync.extract_filename("file://a/b/c.lua"), "a/b/c.lua")
            end)

            it("returns nil for non-file:// strings", function()
                test.is_nil(sync.extract_filename("http://x"))
                test.is_nil(sync.extract_filename("plain text"))
            end)

            it("returns nil for nil or non-string input", function()
                test.is_nil(sync.extract_filename(nil))
                test.is_nil(sync.extract_filename(42))
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
