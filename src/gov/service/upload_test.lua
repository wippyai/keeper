local test = require("test")
local upload = require("upload")

local function define_tests()
    describe("gov.service.upload pure helpers", function()
        describe("compute_managed_partition", function()
            local function always(_) return true end
            local function never(_) return false end
            local function only_x(ns) return ns == "app.x" end

            it("returns two empty lists for nil or non-table input", function()
                local filtered, skipped = upload.compute_managed_partition(nil, always)
                test.eq(#filtered, 0)
                test.eq(#skipped, 0)
                filtered, skipped = upload.compute_managed_partition("bogus", always)
                test.eq(#filtered, 0)
                test.eq(#skipped, 0)
            end)

            it("routes all entries into filtered when the predicate is true", function()
                local filtered, skipped = upload.compute_managed_partition({
                    { id = "app.x:a" }, { id = "app.y:b" },
                }, always)
                test.eq(#filtered, 2)
                test.eq(#skipped, 0)
            end)

            it("routes all entries into skipped when the predicate is false", function()
                local filtered, skipped = upload.compute_managed_partition({
                    { id = "app.x:a" }, { id = "app.y:b" },
                }, never)
                test.eq(#filtered, 0)
                test.eq(#skipped, 2)
                test.eq(skipped[1].id, "app.x:a")
                test.eq(skipped[1].namespace, "app.x")
            end)

            it("splits according to the predicate", function()
                local filtered, skipped = upload.compute_managed_partition({
                    { id = "app.x:a" }, { id = "app.y:b" }, { id = "app.x:c" },
                }, only_x)
                test.eq(#filtered, 2)
                test.eq(#skipped, 1)
                test.eq(skipped[1].namespace, "app.y")
            end)

            it("tolerates entries without an id", function()
                local filtered, skipped = upload.compute_managed_partition({
                    { id = "app.x:a" }, {}, { id = "malformed-no-colon" },
                }, only_x)
                test.eq(#filtered, 1)
                test.eq(#skipped, 2)
                test.eq(skipped[1].id, "unknown")
                test.eq(skipped[1].namespace, "unknown")
                test.eq(skipped[2].id, "malformed-no-colon")
                test.eq(skipped[2].namespace, "unknown")
            end)
        end)

        describe("compute_changeset_stats", function()
            it("returns zeroed stats for an empty or nil changeset", function()
                local s = upload.compute_changeset_stats({})
                test.eq(s.create, 0)
                test.eq(s.update, 0)
                test.eq(s.delete, 0)
                s = upload.compute_changeset_stats(nil)
                test.eq(s.create, 0)
            end)

            it("tallies create/update/delete operations separately", function()
                local s = upload.compute_changeset_stats({
                    { kind = upload.OP.CREATE },
                    { kind = upload.OP.CREATE },
                    { kind = upload.OP.UPDATE },
                    { kind = upload.OP.DELETE },
                    { kind = upload.OP.DELETE },
                    { kind = upload.OP.DELETE },
                })
                test.eq(s.create, 2)
                test.eq(s.update, 1)
                test.eq(s.delete, 3)
            end)

            it("ignores ops with unknown kinds", function()
                local s = upload.compute_changeset_stats({
                    { kind = upload.OP.CREATE },
                    { kind = "entry.rename" },
                    { kind = "unknown" },
                })
                test.eq(s.create, 1)
                test.eq(s.update, 0)
                test.eq(s.delete, 0)
            end)

            it("exposes OP constants consistent with changeset kinds", function()
                test.eq(upload.OP.CREATE, "entry.create")
                test.eq(upload.OP.UPDATE, "entry.update")
                test.eq(upload.OP.DELETE, "entry.delete")
            end)
        end)

        describe("order_changeset", function()
            it("returns non-tables unchanged", function()
                test.eq(upload.order_changeset(nil), nil)
                test.eq(upload.order_changeset("bogus"), "bogus")
            end)

            it("sorts CREATE before UPDATE before DELETE", function()
                local out = upload.order_changeset({
                    { kind = upload.OP.DELETE, entry = { id = "a:1" } },
                    { kind = upload.OP.UPDATE, entry = { id = "a:2" } },
                    { kind = upload.OP.CREATE, entry = { id = "a:3" } },
                })
                test.eq(out[1].kind, upload.OP.CREATE)
                test.eq(out[2].kind, upload.OP.UPDATE)
                test.eq(out[3].kind, upload.OP.DELETE)
            end)

            it("preserves relative order inside a kind (stable)", function()
                local out = upload.order_changeset({
                    { kind = upload.OP.DELETE, entry = { id = "a:z" } },
                    { kind = upload.OP.DELETE, entry = { id = "a:y" } },
                    { kind = upload.OP.DELETE, entry = { id = "a:x" } },
                })
                test.eq(out[1].entry.id, "a:z")
                test.eq(out[2].entry.id, "a:y")
                test.eq(out[3].entry.id, "a:x")
            end)

            it("keeps unknown-kind ops at the tail without dropping them", function()
                local out = upload.order_changeset({
                    { kind = "entry.rename", entry = { id = "a:r" } },
                    { kind = upload.OP.CREATE, entry = { id = "a:c" } },
                    { kind = upload.OP.DELETE, entry = { id = "a:d" } },
                })
                test.eq(#out, 3)
                test.eq(out[1].kind, upload.OP.CREATE)
                test.eq(out[2].kind, upload.OP.DELETE)
                test.eq(out[3].kind, "entry.rename")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
