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

        describe("changeset_entry_ops", function()
            it("collects only entry ids directly named by the changeset", function()
                local ids, ops = sync.changeset_entry_ops({
                    { kind = "entry.update", entry = { id = "app.alpha:changed" } },
                    { kind = "entry.create", entry = { id = "app.beta:new" } },
                    { kind = "entry.update", entry = { id = "app.alpha:changed" } },
                    { kind = "entry.update", entry = { id = "malformed" } },
                })

                test.eq(#ids, 2)
                test.eq(ids[1], "app.alpha:changed")
                test.eq(ids[2], "app.beta:new")
                test.eq(ops["app.alpha:changed"], "entry.update")
                test.eq(ops["app.beta:new"], "entry.create")
                test.is_nil(ops["app.alpha:sibling"])
            end)

            it("tracks the last operation and whether repeated entry ids were created", function()
                local _, ops, created = sync.changeset_entry_ops({
                    { kind = "entry.delete", entry = { id = "app.deps:recreated" } },
                    { kind = "entry.create", entry = { id = "app.deps:recreated" } },
                    { kind = "entry.create", entry = { id = "app.deps:removed" } },
                    { kind = "entry.delete", entry = { id = "app.deps:removed" } },
                    { kind = "entry.delete", entry = { id = "app.deps:updated" } },
                    { kind = "entry.update", entry = { id = "app.deps:updated" } },
                })

                test.eq(ops["app.deps:recreated"], "entry.create")
                test.eq(ops["app.deps:removed"], "entry.delete")
                test.eq(ops["app.deps:updated"], "entry.update")
                test.is_true(created["app.deps:recreated"])
                test.is_true(created["app.deps:removed"])
                test.is_nil(created["app.deps:updated"])
            end)
        end)

        describe("entry_sync_decision", function()
            local function decision_for(ops)
                local _, final_ops, created = sync.changeset_entry_ops(ops)
                return sync.entry_sync_decision(
                    "app.deps:root", "ns.dependency", final_ops, created)
            end

            it("writes a dependency created then updated without guarding it as missing", function()
                local decision = decision_for({
                    { kind = "entry.create", entry = { id = "app.deps:root" } },
                    { kind = "entry.update", entry = { id = "app.deps:root" } },
                })
                test.is_false(decision.delete)
                test.is_false(decision.guarded_missing)
            end)

            it("keeps a dependency deleted then recreated", function()
                local decision = decision_for({
                    { kind = "entry.delete", entry = { id = "app.deps:root" } },
                    { kind = "entry.create", entry = { id = "app.deps:root" } },
                })
                test.is_false(decision.delete)
                test.is_false(decision.guarded_missing)
            end)

            it("deletes a dependency created then deleted", function()
                local decision = decision_for({
                    { kind = "entry.create", entry = { id = "app.deps:root" } },
                    { kind = "entry.delete", entry = { id = "app.deps:root" } },
                })
                test.is_true(decision.delete)
            end)

            it("guards an ordinary dependency update when its block is missing", function()
                local decision = decision_for({
                    { kind = "entry.update", entry = { id = "app.deps:root" } },
                })
                test.is_false(decision.delete)
                test.is_true(decision.guarded_missing)
            end)
        end)

        describe("patch_index_content", function()
            it("replaces one entry block while preserving untouched siblings byte-identical", function()
                local sibling_block = [[
  # app.ns:sibling
  - name: sibling
    kind: function.lua
    # keep this hand-written comment
    source: file://sibling.lua]]
                local before = [[version: "1.0"
namespace: app.ns
entries:
  # app.ns:changed
  - name: changed
    kind: function.lua
    source: file://old.lua
]] .. sibling_block

                local after, changed = sync.patch_index_content(before, "app.ns", {
                    changed = [[  # app.ns:changed
  - name: changed
    kind: function.lua
    source: file://new.lua]]
                }, {})

                test.is_true(changed)
                test.is_true(after:find("source: file://new.lua", 1, true) ~= nil)
                test.is_true(after:find(sibling_block, 1, true) ~= nil)
            end)

            it("does not create a new dependency root block for a non-create change", function()
                local after, changed = sync.patch_index_content(nil, "throwaway.deps", {
                    root = [[  # throwaway.deps:root
  - name: root
    kind: ns.dependency]]
                }, {}, { root = true })

                test.is_nil(after)
                test.is_false(changed)
            end)

            it("allows explicit dependency creates to create a new index", function()
                local after, changed = sync.patch_index_content(nil, "app.deps", {
                    root = [[  # app.deps:root
  - name: root
    kind: ns.dependency]]
                }, {}, {})

                test.is_true(changed)
                test.is_true(after:find("kind: ns.dependency", 1, true) ~= nil)
            end)

            it("removes a deleted dependency block while preserving siblings byte-identical", function()
                local before_prefix = [[version: "1.0"
namespace: app.deps
entries:
  # app.deps:keep
  - name: keep
    kind: ns.dependency
    component: wippy/keep
    version: v1.0.0]]
                local target_block = [[  # app.deps:actor
  - version: v0.4.0
    name: 'actor'
    kind: ns.dependency
    component: wippy/actor
    parameters:
      - name: nested-parameter-name
        value: app:db]]
                local before_suffix = [[  # app.deps:tail
  - name: tail
    kind: ns.dependency
    component: wippy/tail
    version: v2.0.0]]
                local before = before_prefix .. "\n" .. target_block .. "\n"
                    .. target_block .. "\n" .. before_suffix

                local after, changed = sync.patch_index_content(before, "app.deps", {}, { actor = true }, {})

                test.is_true(changed)
                test.is_true(after:find(before_prefix, 1, true) ~= nil)
                test.is_true(after:find(before_suffix, 1, true) ~= nil)
                test.is_true(after:find(target_block, 1, true) == nil)
            end)

            it("ignores nested names when a malformed block has no direct name", function()
                local before = [[version: "1.0"
namespace: app.deps
entries:
  # malformed dependency without a direct name
  - version: v1.0.0
    kind: ns.dependency
    component: wippy/malformed
    parameters:
      - name: root
        value: app:db]]

                local after, changed = sync.patch_index_content(
                    before, "app.deps", {}, { root = true }, {})

                test.eq(after, before)
                test.is_false(changed)
            end)

            it("updates one canonical version-first block and collapses touched duplicates", function()
                local sibling_block = [[  # app.deps:keep
  - version: v1.0.0
    name: keep
    kind: ns.dependency
    component: wippy/keep]]
                local old_block = [[  # app.deps:workflows
  - version: '>=v0.0.0'
    name: workflows
    kind: ns.dependency
    component: kickside/workflows]]
                local new_block = [[  # app.deps:workflows
  - version: '>=v0.1.0'
    name: workflows
    kind: ns.dependency
    component: kickside/workflows]]
                local before = [[version: "1.0"
namespace: app.deps
entries:
]] .. sibling_block .. "\n" .. old_block .. "\n" .. old_block

                local after, changed = sync.patch_index_content(
                    before, "app.deps", { workflows = new_block }, {}, {})
                if not after then error("expected patched index content") end
                local _, occurrences = after:gsub("# app%.deps:workflows", "")

                test.is_true(changed)
                test.eq(occurrences, 1)
                test.is_true(after:find(new_block, 1, true) ~= nil)
                test.is_true(after:find(sibling_block, 1, true) ~= nil)
            end)

            it("keeps one dependency block when a version-first entry is deleted then recreated", function()
                local block = sync.render_index_entry("app.deps", {
                    version = ">=v0.0.0",
                    name = "workflows",
                    kind = "ns.dependency",
                    component = "kickside/workflows",
                })
                local before = [[version: "1.0"
namespace: app.deps
entries:
]] .. block

                local after_delete = sync.patch_index_content(
                    before, "app.deps", {}, { workflows = true }, {})
                local after_recreate = sync.patch_index_content(
                    after_delete, "app.deps", { workflows = block }, {}, {})
                if not after_recreate then error("expected recreated index content") end
                local _, occurrences = after_recreate:gsub("# app%.deps:workflows", "")
                local after_repeat, repeat_changed = sync.patch_index_content(
                    after_recreate, "app.deps", { workflows = block }, {}, {})

                test.eq(occurrences, 1)
                test.eq(after_repeat, after_recreate)
                test.is_false(repeat_changed)
            end)

            it("is byte-idempotent with the canonical serializer field order", function()
                local block = sync.render_index_entry("app.deps", {
                    version = ">=v0.0.0",
                    name = "workflows",
                    kind = "ns.dependency",
                    component = "kickside/workflows",
                })
                local before = [[version: "1.0"
namespace: app.deps
entries:
]] .. block

                local after, changed = sync.patch_index_content(
                    before, "app.deps", { workflows = block }, {}, {})

                test.eq(after, before)
                test.is_false(changed)
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

            it("builds a .jet path for legacy template.jet pages", function()
                test.eq(
                    sync.entry_file_path({
                        id = "app.legacy.views:approval",
                        kind = "template.jet",
                        meta = { type = "view.page" },
                    }),
                    "./app/legacy/views/approval.jet"
                )
            end)

            it("does not invent a source file for template.set entries", function()
                test.is_nil(sync.entry_file_path({
                    id = "app.legacy.views:templates",
                    kind = "template.set",
                }))
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
