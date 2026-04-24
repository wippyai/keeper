local test = require("test")
local sync = require("sync")

local function define_tests()
    describe("gov.service.sync pure helpers", function()
        describe("pick_kind_config", function()
            it("returns the direct config for a plain kind like function.lua", function()
                local cfg = sync.pick_kind_config("function.lua", nil)
                test.not_nil(cfg)
                test.eq(cfg.source_field, "source")
                test.eq(cfg.extension, ".lua")
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

        describe("namespace_dir", function()
            it("splits dotted namespaces into directory segments", function()
                test.eq(sync.namespace_dir(".", "a.b.c"), "./a/b/c")
            end)

            it("handles single-segment namespaces", function()
                test.eq(sync.namespace_dir(".", "single"), "./single")
            end)

            it("preserves the base directory", function()
                test.eq(sync.namespace_dir("/tmp/root", "a.b"), "/tmp/root/a/b")
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

        describe("changeset_namespaces", function()
            it("returns empty list for nil or empty changeset", function()
                test.eq(#sync.changeset_namespaces(nil), 0)
                test.eq(#sync.changeset_namespaces({}), 0)
            end)

            it("collects distinct namespaces preserving first-seen order", function()
                local ns = sync.changeset_namespaces({
                    { entry = { id = "app.x:a" } },
                    { entry = { id = "app.y:b" } },
                    { entry = { id = "app.x:c" } },
                })
                test.eq(#ns, 2)
                test.eq(ns[1], "app.x")
                test.eq(ns[2], "app.y")
            end)

            it("skips ops without a valid entry.id", function()
                local ns = sync.changeset_namespaces({
                    { entry = { id = "app.x:a" } },
                    { entry = nil },
                    {},
                    { entry = { id = "bogus-without-colon" } },
                })
                test.eq(#ns, 1)
                test.eq(ns[1], "app.x")
            end)
        end)

        describe("entry_file_path", function()
            it("builds a .lua path for function.lua", function()
                test.eq(
                    sync.entry_file_path({ id = "app.x:svc", kind = "function.lua" }),
                    "./app/x/svc.lua"
                )
            end)

            it("uses meta.type mapping for registry.entry", function()
                test.eq(
                    sync.entry_file_path({
                        id = "app.x:landing", kind = "registry.entry",
                        meta = { type = "view.page" },
                    }),
                    "./app/x/landing.html"
                )
            end)

            it("returns nil when the kind has no canonical file mapping", function()
                test.is_nil(sync.entry_file_path({ id = "app.x:svc", kind = "process.service" }))
            end)

            it("returns nil for malformed ids", function()
                test.is_nil(sync.entry_file_path({ id = "nocolon", kind = "function.lua" }))
                test.is_nil(sync.entry_file_path({ kind = "function.lua" }))
                test.is_nil(sync.entry_file_path(nil))
            end)

            it("does not double-append an extension that's already there", function()
                test.eq(
                    sync.entry_file_path({ id = "app.x:svc.lua", kind = "function.lua" }),
                    "./app/x/svc.lua"
                )
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
