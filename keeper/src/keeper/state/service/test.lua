local test = require("test")
local reconcile = require("reconcile")
local sync = require("sync")
local sync_branch = require("sync_branch")

local function stub_materialize(opts)
    opts = opts or {}
    local fail_entry_ids = {}
    for _, id in ipairs(opts.fail_entry or {}) do fail_entry_ids[id] = true end
    local fail_set_cmd = {}
    for _, id in ipairs(opts.fail_set_cmd or {}) do fail_set_cmd[id] = true end
    local fail_delete_for = {}
    for _, id in ipairs(opts.fail_delete_for or {}) do fail_delete_for[id] = true end
    local edges_for = opts.edges_for or {}

    local mat = {}
    function mat.entry(entry)
        if fail_entry_ids[entry.id] then
            return nil, "boom"
        end
        return { id = entry.id, definition_hash = "d-" .. entry.id, content_hash = "c-" .. entry.id }
    end
    function mat.to_set_command(m, branch)
        if fail_set_cmd[m.id] then
            return nil, "set-fail"
        end
        return { op = "set", entry_id = m.id, branch = branch }
    end
    function mat.to_delete_command(id, branch)
        if fail_delete_for[id] then
            return nil, "del-fail"
        end
        return { op = "delete", entry_id = id, branch = branch }
    end
    function mat.extract_edges(entry)
        return edges_for[entry.id] or {}
    end
    function mat.edges_to_commands(edges, branch)
        local out = {}
        for _, e in ipairs(edges) do
            table.insert(out, {
                op = "edge",
                source_id = e.source_id, target_id = e.target_id,
                edge_type = e.edge_type, branch = branch,
            })
        end
        return out
    end
    return mat
end

local function define_tests()
    describe("keeper.state.service", function()
        describe("reconcile.edge_key", function()
            it("joins source|target|type", function()
                test.eq(
                    reconcile.edge_key({ source_id = "a", target_id = "b", edge_type = "imports" }),
                    "a|b|imports"
                )
            end)
        end)

        describe("reconcile.index_entries_by_chunks", function()
            it("splits definition and content chunks by type", function()
                local idx = reconcile.index_entries_by_chunks({
                    {
                        id = "e1", kind = "function.lua",
                        chunks = {
                            { type = "definition", hash = "d1" },
                            { type = "content", hash = "c1" },
                        },
                    },
                })
                test.not_nil(idx["e1"])
                test.eq(idx["e1"].definition_hash, "d1")
                test.eq(idx["e1"].content_hash, "c1")
                test.eq(idx["e1"].kind, "function.lua")
            end)

            it("leaves hashes nil when chunks missing", function()
                local idx = reconcile.index_entries_by_chunks({
                    { id = "e2", kind = "library.lua" },
                })
                test.not_nil(idx["e2"])
                test.is_nil(idx["e2"].definition_hash)
                test.is_nil(idx["e2"].content_hash)
            end)

            it("ignores unknown chunk types", function()
                local idx = reconcile.index_entries_by_chunks({
                    {
                        id = "e3", kind = "template.jet",
                        chunks = {
                            { type = "metadata", hash = "m1" },
                            { type = "definition", hash = "d3" },
                        },
                    },
                })
                test.eq(idx["e3"].definition_hash, "d3")
                test.is_nil(idx["e3"].content_hash)
            end)

            it("returns empty table for empty input", function()
                local idx = reconcile.index_entries_by_chunks({})
                test.eq(next(idx), nil)
            end)
        end)

        describe("reconcile.index_edges_by_key", function()
            it("keys edges by source|target|type", function()
                local m = reconcile.index_edges_by_key({
                    { source_id = "a", target_id = "b", edge_type = "imports" },
                    { source_id = "a", target_id = "c", edge_type = "calls" },
                })
                test.is_true(m["a|b|imports"])
                test.is_true(m["a|c|calls"])
                test.is_nil(m["a|b|calls"])
            end)

            it("collapses duplicates to the same key", function()
                local m = reconcile.index_edges_by_key({
                    { source_id = "a", target_id = "b", edge_type = "imports" },
                    { source_id = "a", target_id = "b", edge_type = "imports" },
                })
                local count = 0
                for _ in pairs(m) do count = count + 1 end
                test.eq(count, 1)
            end)
        end)

        describe("reconcile.needs_update", function()
            it("returns true when definition hashes differ", function()
                test.is_true(reconcile.needs_update(
                    { definition_hash = "d-new", content_hash = "c-new" },
                    { definition_hash = "d-old", content_hash = "c-new" }
                ))
            end)

            it("returns true when content hashes differ", function()
                test.is_true(reconcile.needs_update(
                    { definition_hash = "d", content_hash = "c-new" },
                    { definition_hash = "d", content_hash = "c-old" }
                ))
            end)

            it("returns false when both hashes match", function()
                test.is_false(reconcile.needs_update(
                    { definition_hash = "d", content_hash = "c" },
                    { definition_hash = "d", content_hash = "c" }
                ))
            end)

            it("ignores content hash when materialized has none", function()
                test.is_false(reconcile.needs_update(
                    { definition_hash = "d", content_hash = nil },
                    { definition_hash = "d", content_hash = "c-old" }
                ))
            end)
        end)

        describe("sync.convert_ops", function()
            it("flags dependency directive changes for full reconciliation", function()
                test.is_true(sync.requires_reconciliation({
                    { kind = "entry.create", entry = { id = "app.deps:foo", kind = "ns.dependency" } },
                }))
                test.is_true(sync.requires_reconciliation({
                    { kind = "entry.update", entry = { id = "app.deps:foo", kind = "ns.dependency" } },
                }))
                test.is_true(sync.requires_reconciliation({
                    { kind = "entry.delete", entry = { id = "app.deps:foo", kind = "ns.dependency" } },
                }))
                test.is_false(sync.requires_reconciliation({
                    { kind = "entry.create", entry = { id = "app:foo", kind = "function.lua" } },
                }))
            end)

            it("runs full reconciliation for dependency directive changes", function()
                local calls = { reconcile = 0, apply = 0 }
                local out = sync.run({
                    version = 9,
                    changeset = {
                        { kind = "entry.create", entry = { id = "app.deps:foo", kind = "ns.dependency" } },
                    },
                }, {
                    reconcile = {
                        run = function(args)
                            calls.reconcile = calls.reconcile + 1
                            test.eq(args.reason, "dependency directive changed")
                            return { success = true, changes_made = true, stats = {} }, nil
                        end,
                    },
                    state_ops = {
                        apply_commands = function()
                            calls.apply = calls.apply + 1
                            return { changes_made = true }, nil
                        end,
                    },
                })

                test.is_true(out.success)
                test.is_true(out.dependency_reconcile)
                test.eq(out.version, 9)
                test.eq(calls.reconcile, 1)
                test.eq(calls.apply, 0)
            end)

            it("reconciles dependency directive create, update, and delete operations", function()
                for _, kind in ipairs({ "entry.create", "entry.update", "entry.delete" }) do
                    local calls = { reconcile = 0, apply = 0 }
                    local out = sync.run({
                        version = kind,
                        changeset = {
                            { kind = kind, entry = { id = "app.deps:foo", kind = "ns.dependency" } },
                        },
                    }, {
                        reconcile = {
                            run = function()
                                calls.reconcile = calls.reconcile + 1
                                return { success = true, changes_made = true, stats = {} }, nil
                            end,
                        },
                        state_ops = {
                            apply_commands = function()
                                calls.apply = calls.apply + 1
                                return { changes_made = true }, nil
                            end,
                        },
                    })

                    test.is_true(out.success)
                    test.is_true(out.dependency_reconcile)
                    test.eq(calls.reconcile, 1)
                    test.eq(calls.apply, 0)
                end
            end)

            it("bubbles dependency reconciliation failures", function()
                local out = sync.run({
                    version = 10,
                    changeset = {
                        { kind = "entry.delete", entry = { id = "app.deps:foo", kind = "ns.dependency" } },
                    },
                }, {
                    reconcile = {
                        run = function()
                            return { success = false, error = "reconcile exploded" }, nil
                        end,
                    },
                    state_ops = {
                        apply_commands = function()
                            return { changes_made = true }, nil
                        end,
                    },
                })

                test.is_false(out.success)
                test.eq(out.error, "reconcile exploded")
                test.eq(out.version, 10)
            end)

            it("keeps normal entry changes on the incremental path", function()
                local calls = { reconcile = 0, apply = 0 }
                local out = sync.run({
                    version = 11,
                    changeset = {
                        { kind = "entry.create", entry = { id = "app:handler", kind = "function.lua" } },
                    },
                }, {
                    materialize = stub_materialize({}),
                    reconcile = {
                        run = function()
                            calls.reconcile = calls.reconcile + 1
                            return { success = true }, nil
                        end,
                    },
                    state_ops = {
                        apply_commands = function(commands)
                            calls.apply = calls.apply + 1
                            test.eq(#commands, 1)
                            test.eq(commands[1].op, "set")
                            test.eq(commands[1].entry_id, "app:handler")
                            return { changes_made = true }, nil
                        end,
                    },
                })

                test.is_true(out.success)
                test.eq(out.version, 11)
                test.eq(calls.reconcile, 0)
                test.eq(calls.apply, 1)
            end)

            it("reconciles the whole state when dependency directives are mixed with ordinary entries", function()
                local calls = { reconcile = 0, apply = 0 }
                local out = sync.run({
                    version = 12,
                    changeset = {
                        { kind = "entry.create", entry = { id = "app:handler", kind = "function.lua" } },
                        { kind = "entry.update", entry = { id = "app.deps:foo", kind = "ns.dependency" } },
                    },
                }, {
                    materialize = stub_materialize({}),
                    reconcile = {
                        run = function()
                            calls.reconcile = calls.reconcile + 1
                            return { success = true, changes_made = true }, nil
                        end,
                    },
                    state_ops = {
                        apply_commands = function()
                            calls.apply = calls.apply + 1
                            return { changes_made = true }, nil
                        end,
                    },
                })

                test.is_true(out.success)
                test.is_true(out.dependency_reconcile)
                test.eq(calls.reconcile, 1)
                test.eq(calls.apply, 0)
            end)

            it("produces a set command + edges for entry.create", function()
                local mat = stub_materialize({
                    edges_for = {
                        ["e1"] = { { source_id = "e1", target_id = "x", edge_type = "imports" } },
                    },
                })
                local cmds, errs = sync.convert_ops({
                    { kind = "entry.create", entry = { id = "e1" } },
                }, mat, "main")
                test.eq(#errs, 0)
                test.eq(#cmds, 2)
                test.eq(cmds[1].op, "set")
                test.eq(cmds[1].entry_id, "e1")
                test.eq(cmds[2].op, "edge")
                test.eq(cmds[2].branch, "main")
            end)

            it("produces a delete command for entry.delete", function()
                local mat = stub_materialize({})
                local cmds, errs = sync.convert_ops({
                    { kind = "entry.delete", entry = { id = "gone" } },
                }, mat, "main")
                test.eq(#errs, 0)
                test.eq(#cmds, 1)
                test.eq(cmds[1].op, "delete")
                test.eq(cmds[1].entry_id, "gone")
            end)

            it("places deletes after sets in the output", function()
                local mat = stub_materialize({})
                local cmds, errs = sync.convert_ops({
                    { kind = "entry.delete", entry = { id = "gone" } },
                    { kind = "entry.create", entry = { id = "new" } },
                }, mat, "main")
                test.eq(#errs, 0)
                test.eq(#cmds, 2)
                test.eq(cmds[1].op, "set")
                test.eq(cmds[2].op, "delete")
            end)

            it("captures materialization failures without aborting", function()
                local mat = stub_materialize({ fail_entry = { "bad" } })
                local cmds, errs = sync.convert_ops({
                    { kind = "entry.create", entry = { id = "ok" } },
                    { kind = "entry.create", entry = { id = "bad" } },
                }, mat, "main")
                test.eq(#cmds, 1)
                test.eq(cmds[1].entry_id, "ok")
                test.eq(#errs, 1)
                test.eq(errs[1].entry_id, "bad")
                test.eq(errs[1].index, 2)
            end)

            it("captures to_set_command failures", function()
                local mat = stub_materialize({ fail_set_cmd = { "bad" } })
                local cmds, errs = sync.convert_ops({
                    { kind = "entry.create", entry = { id = "bad" } },
                }, mat, "main")
                test.eq(#cmds, 0)
                test.eq(#errs, 1)
                test.is_true(errs[1].error:find("Command creation failed", 1, true) ~= nil)
            end)

            it("captures delete command failures", function()
                local mat = stub_materialize({ fail_delete_for = { "bad" } })
                local cmds, errs = sync.convert_ops({
                    { kind = "entry.delete", entry = { id = "bad" } },
                }, mat, "main")
                test.eq(#cmds, 0)
                test.eq(#errs, 1)
                test.is_true(errs[1].error:find("Delete command", 1, true) ~= nil)
            end)

            it("ignores unknown op kinds silently", function()
                local mat = stub_materialize({})
                local cmds, errs = sync.convert_ops({
                    { kind = "entry.unknown", entry = { id = "x" } },
                }, mat, "main")
                test.eq(#cmds, 0)
                test.eq(#errs, 0)
            end)
        end)

        describe("sync_branch.validate_args", function()
            it("accepts valid args", function()
                test.is_nil(sync_branch.validate_args({ branch = "b1", entry_ids = { "a" } }))
            end)

            it("rejects missing branch", function()
                local err = sync_branch.validate_args({ entry_ids = { "a" } })
                test.is_true(err:find("Branch", 1, true) ~= nil)
            end)

            it("rejects empty branch", function()
                local err = sync_branch.validate_args({ branch = "", entry_ids = { "a" } })
                test.is_true(err:find("Branch", 1, true) ~= nil)
            end)

            it("rejects missing entry_ids", function()
                local err = sync_branch.validate_args({ branch = "b" })
                test.is_true(err:find("entry_ids", 1, true) ~= nil)
            end)

            it("rejects empty entry_ids array", function()
                local err = sync_branch.validate_args({ branch = "b", entry_ids = {} })
                test.is_true(err:find("entry_ids", 1, true) ~= nil)
            end)

            it("rejects non-table entry_ids", function()
                local err = sync_branch.validate_args({ branch = "b", entry_ids = "x" })
                test.is_true(err:find("entry_ids", 1, true) ~= nil)
            end)

            it("rejects nil args", function()
                local err = sync_branch.validate_args(nil)
                test.is_true(err:find("Branch", 1, true) ~= nil)
            end)
        end)

        describe("sync_branch.build_branch_commands", function()
            it("only materializes entries in the id set", function()
                local mat = stub_materialize({})
                local entries = {
                    { id = "a" }, { id = "b" }, { id = "c" },
                }
                local cmds, errs = sync_branch.build_branch_commands(entries, { "a", "c" }, mat, "feat/x")
                test.eq(#errs, 0)
                test.eq(#cmds, 2)
                test.eq(cmds[1].entry_id, "a")
                test.eq(cmds[2].entry_id, "c")
                test.eq(cmds[1].branch, "feat/x")
            end)

            it("emits edge commands alongside set commands", function()
                local mat = stub_materialize({
                    edges_for = {
                        ["a"] = { { source_id = "a", target_id = "b", edge_type = "imports" } },
                    },
                })
                local cmds, errs = sync_branch.build_branch_commands({ { id = "a" } }, { "a" }, mat, "main")
                test.eq(#errs, 0)
                test.eq(#cmds, 2)
                test.eq(cmds[1].op, "set")
                test.eq(cmds[2].op, "edge")
            end)

            it("captures materialization failures for targeted entries", function()
                local mat = stub_materialize({ fail_entry = { "bad" } })
                local cmds, errs = sync_branch.build_branch_commands(
                    { { id = "good" }, { id = "bad" } },
                    { "good", "bad" },
                    mat, "main"
                )
                test.eq(#cmds, 1)
                test.eq(cmds[1].entry_id, "good")
                test.eq(#errs, 1)
                test.eq(errs[1].entry_id, "bad")
            end)

            it("returns empty commands when id set has no matches", function()
                local mat = stub_materialize({})
                local cmds, errs = sync_branch.build_branch_commands(
                    { { id = "a" } }, { "missing" }, mat, "main"
                )
                test.eq(#cmds, 0)
                test.eq(#errs, 0)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
