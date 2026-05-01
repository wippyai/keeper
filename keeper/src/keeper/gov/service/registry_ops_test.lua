local test = require("test")
local registry_ops = require("registry_ops")
local gov_consts = require("gov_consts")

local function define_tests()
    describe("gov.service.registry_ops pure helpers", function()
        describe("deep_copy", function()
            it("returns non-tables unchanged", function()
                test.eq(registry_ops.deep_copy(42), 42)
                test.eq(registry_ops.deep_copy("x"), "x")
                test.eq(registry_ops.deep_copy(nil), nil)
                test.eq(registry_ops.deep_copy(true), true)
            end)

            it("duplicates a flat table so mutations do not leak", function()
                local src = { a = 1, b = 2 }
                local dst = registry_ops.deep_copy(src)
                dst.a = 99
                test.eq(src.a, 1)
                test.eq(dst.a, 99)
            end)

            it("recursively copies nested tables", function()
                local src = { inner = { v = { 1, 2, 3 } } }
                local dst = registry_ops.deep_copy(src)
                dst.inner.v[1] = 99
                test.eq(src.inner.v[1], 1)
            end)
        end)

        describe("is_empty_table", function()
            it("is true for {}", function()
                test.is_true(registry_ops.is_empty_table({}))
            end)

            it("is false for any populated table", function()
                test.is_false(registry_ops.is_empty_table({ 1 }))
                test.is_false(registry_ops.is_empty_table({ a = 1 }))
            end)

            it("is false for non-table inputs", function()
                test.is_false(registry_ops.is_empty_table(nil))
                test.is_false(registry_ops.is_empty_table("x"))
                test.is_false(registry_ops.is_empty_table(0))
            end)
        end)

        describe("is_json_array", function()
            it("recognizes a contiguous 1-based list", function()
                test.is_true(registry_ops.is_json_array({ "a", "b", "c" }))
            end)

            it("rejects empty tables", function()
                test.is_false(registry_ops.is_json_array({}))
            end)

            it("rejects maps", function()
                test.is_false(registry_ops.is_json_array({ a = 1 }))
            end)

            it("rejects mixed array+map", function()
                test.is_false(registry_ops.is_json_array({ "a", "b", extra = 1 }))
            end)

            it("rejects non-table input", function()
                test.is_false(registry_ops.is_json_array(nil))
                test.is_false(registry_ops.is_json_array("x"))
            end)
        end)

        describe("merge_explicit", function()
            it("copies scalar overrides into the result", function()
                local out = registry_ops.merge_explicit({ a = 1 }, { a = 2, b = 3 })
                test.eq(out.a, 2)
                test.eq(out.b, 3)
            end)

            it("deletes a key when override value is an empty table", function()
                local out = registry_ops.merge_explicit({ a = 1, b = 2 }, { a = {} })
                test.is_nil(out.a)
                test.eq(out.b, 2)
            end)

            it("replaces arrays rather than merging them", function()
                local out = registry_ops.merge_explicit({ tags = { "x", "y" } }, { tags = { "z" } })
                if type(out.tags) ~= "table" then error("tags missing") end
                local tags = out.tags :: string[]
                test.eq(#tags, 1)
                test.eq(tags[1], "z")
            end)

            it("recurses into nested maps", function()
                local out = registry_ops.merge_explicit(
                    { meta = { a = 1, b = 2 } },
                    { meta = { b = 99, c = 3 } }
                )
                test.eq(out.meta.a, 1)
                test.eq(out.meta.b, 99)
                test.eq(out.meta.c, 3)
            end)

            it("does not mutate the target", function()
                local target = { a = 1, nested = { v = 10 } }
                registry_ops.merge_explicit(target, { a = 2, nested = { v = 20 } })
                test.eq(target.a, 1)
                test.eq(target.nested.v, 10)
            end)
        end)

        describe("apply_updates", function()
            local base = { id = "ns:e", kind = "function.lua",
                meta = { title = "old", tags = { "x" } },
                data = { source = "s0" } }

            it("flags updates_made=false when payload has no recognized fields", function()
                local _, updates_made = registry_ops.apply_updates(base, {}, true)
                test.is_false(updates_made)
            end)

            it("applies kind override verbatim and flags updates_made", function()
                local out, updates_made = registry_ops.apply_updates(base, { kind = "library.lua" }, true)
                test.is_true(updates_made)
                test.eq(out.kind, "library.lua")
                test.eq(out.id, "ns:e")
            end)

            it("merges meta when should_merge is true", function()
                local out = registry_ops.apply_updates(base, { meta = { title = "new" } }, true)
                test.eq(out.meta.title, "new")
                test.eq(out.meta.tags[1], "x")
            end)

            it("replaces meta wholesale when should_merge is false", function()
                local out = registry_ops.apply_updates(base, { meta = { title = "new" } }, false)
                test.eq(out.meta.title, "new")
                test.is_nil(out.meta.tags)
            end)

            it("merges data when should_merge is true", function()
                local out = registry_ops.apply_updates(base, { data = { extra = 1 } }, true)
                test.eq(out.data.source, "s0")
                test.eq(out.data.extra, 1)
            end)

            it("replaces data wholesale when should_merge is false", function()
                local out = registry_ops.apply_updates(base, { data = { extra = 1 } }, false)
                test.eq(out.data.extra, 1)
                test.is_nil(out.data.source)
            end)

            it("deep-copies meta/data from the source entry so the result is independent", function()
                local entry = { id = "x", kind = "k", meta = { nested = { v = 1 } }, data = {} }
                local out = registry_ops.apply_updates(entry, { kind = "k2" }, true)
                out.meta.nested.v = 99
                test.eq(entry.meta.nested.v, 1)
            end)
        end)

        describe("update_changeset", function()
            it("uses governance registry update operations with runtime registry data", function()
                local source = "local function handler() return { ok = true } end\nreturn { handler = handler }"
                local entry = {
                    id = "app:test",
                    kind = "function.lua",
                    meta = { comment = "probe" },
                    data = {
                        method = "handler",
                        source = source,
                    },
                }
                local changeset, err = registry_ops.update_changeset(entry)
                test.is_nil(err)
                test.eq(#changeset, 1)
                test.eq(changeset[1].kind, gov_consts.REGISTRY_OPERATIONS.UPDATE)
                test.eq(changeset[1].entry.id, "app:test")
                test.eq(changeset[1].entry.kind, "function.lua")
                test.eq(changeset[1].entry.meta.comment, "probe")
                test.eq(changeset[1].entry.data.method, "handler")
                test.eq(changeset[1].entry.data.source, source)
                test.eq(entry.data.source, source)
                test.is_nil(changeset[1].entry.definition)
                test.is_nil(changeset[1].entry.content)
            end)

            it("rejects invalid entries before governance publish", function()
                local changeset, err = registry_ops.update_changeset({ id = "bad", kind = "function.lua", data = {} })
                test.is_nil(changeset)
                test.not_nil(err)
            end)
        end)

        describe("entry_matches_query", function()
            local entry = {
                id = "app.web:public",
                kind = "http.router",
                meta = {
                    type = "http.router",
                    title = "Public Web Router",
                    comment = "Receives public API traffic",
                },
            }

            it("matches id, kind, and metadata text case-insensitively", function()
                test.is_true(registry_ops.entry_matches_query(entry, "APP.WEB"))
                test.is_true(registry_ops.entry_matches_query(entry, "router"))
                test.is_true(registry_ops.entry_matches_query(entry, "public api"))
            end)

            it("rejects unrelated text", function()
                test.is_false(registry_ops.entry_matches_query(entry, "sqlite"))
            end)

            it("treats empty query as a match", function()
                test.is_true(registry_ops.entry_matches_query(entry, ""))
                test.is_true(registry_ops.entry_matches_query(entry, nil))
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
