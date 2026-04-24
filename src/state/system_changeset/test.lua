local test = require("test")
local sql = require("sql")
local sys_cs = require("sys_cs")

local function find_error(resp, code)
    for _, e in ipairs(resp.errors or {}) do
        if e.code == code then return e end
    end
    return nil
end

local function define_tests()
    test.describe("keeper.state.system_changeset:library", function()
        test.it("rejects nil args", function()
            local resp, err = sys_cs.run(nil)
            test.is_nil(err)
            test.is_false(resp.ok)
            test.eq(resp.stage, "validate")
            test.is_true(#resp.errors >= 1)
        end)

        test.it("rejects missing kind", function()
            local resp = sys_cs.run({ title = "t", edits = { { op = "registry_set", entry = {} } } })
            test.is_false(resp.ok)
            test.eq(resp.stage, "validate")
            test.not_nil(find_error(resp, sys_cs.ERR.MISSING_FIELD))
        end)

        test.it("rejects missing title", function()
            local resp = sys_cs.run({ kind = "manual", edits = { { op = "registry_set", entry = {} } } })
            test.is_false(resp.ok)
            test.eq(resp.stage, "validate")
            test.not_nil(find_error(resp, sys_cs.ERR.MISSING_FIELD))
        end)

        test.it("rejects empty edits", function()
            local resp = sys_cs.run({ kind = "manual", title = "t", edits = {} })
            test.is_false(resp.ok)
            test.eq(resp.stage, "validate")
            test.not_nil(find_error(resp, sys_cs.ERR.NO_EDITS))
        end)

        test.it("rejects unknown edit op", function()
            local resp = sys_cs.run({
                kind = "manual", title = "t",
                edits = { { op = "nuke", entry_id = "ns:x" } },
            })
            test.is_false(resp.ok)
            test.eq(resp.stage, "validate")
            test.not_nil(find_error(resp, sys_cs.ERR.INVALID_EDIT_OP))
        end)

        test.it("registry_set requires entry.id + kind + definition", function()
            local resp = sys_cs.run({
                kind = "manual", title = "t",
                edits = { { op = "registry_set", entry = { id = "ns:x" } } },
            })
            test.is_false(resp.ok)
            test.eq(resp.stage, "validate")
            local e = find_error(resp, sys_cs.ERR.MISSING_FIELD)
            test.not_nil(e)
            test.is_true(string.find(e.message, "registry_set", 1, true) ~= nil)
        end)

        test.it("registry_delete requires entry_id", function()
            local resp = sys_cs.run({
                kind = "manual", title = "t",
                edits = { { op = "registry_delete" } },
            })
            test.is_false(resp.ok)
            test.not_nil(find_error(resp, sys_cs.ERR.MISSING_FIELD))
        end)

        test.it("fs_write requires rel_path and content", function()
            local resp1 = sys_cs.run({
                kind = "manual", title = "t",
                edits = { { op = "fs_write", content = "x" } },
            })
            test.is_false(resp1.ok)
            test.not_nil(find_error(resp1, sys_cs.ERR.MISSING_FIELD))

            local resp2 = sys_cs.run({
                kind = "manual", title = "t",
                edits = { { op = "fs_write", rel_path = "frontend/x.vue" } },
            })
            test.is_false(resp2.ok)
            test.not_nil(find_error(resp2, sys_cs.ERR.MISSING_FIELD))
        end)

        test.it("fs_delete requires rel_path", function()
            local resp = sys_cs.run({
                kind = "manual", title = "t",
                edits = { { op = "fs_delete" } },
            })
            test.is_false(resp.ok)
            test.not_nil(find_error(resp, sys_cs.ERR.MISSING_FIELD))
        end)

        test.it("rejects edit batches over the cap", function()
            local edits = {}
            for i = 1, 201 do
                edits[i] = { op = "registry_delete", entry_id = "ns:e" .. i }
            end
            local resp = sys_cs.run({ kind = "manual", title = "t", edits = edits })
            test.is_false(resp.ok)
            test.not_nil(find_error(resp, sys_cs.ERR.TOO_MANY_EDITS))
        end)

        test.it("exposes EDIT_OPS map with all four kinds", function()
            test.eq(sys_cs.EDIT_OPS.registry_set,    "registry_set")
            test.eq(sys_cs.EDIT_OPS.registry_delete, "registry_delete")
            test.eq(sys_cs.EDIT_OPS.fs_write,        "fs_write")
            test.eq(sys_cs.EDIT_OPS.fs_delete,       "fs_delete")
        end)

        test.it("end-to-end: pushed change writes a row into keeper_changeset_changes", function()
            local test_entry_id = "keeper.system_changeset_test:tmp_" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 1e9))
            local entry_ns, entry_name = test_entry_id:match("([^:]+):(.+)")

            local definition = table.concat({
                "version: \"1.0\"",
                "namespace: " .. entry_ns,
                "",
                "entries:",
                "  # " .. test_entry_id,
                "  - name: " .. entry_name,
                "    kind: registry.entry",
                "    meta:",
                "      comment: sys_cs e2e fixture",
                "",
            }, "\n")

            local function cleanup()
                return sys_cs.run({
                    kind  = "manual",
                    title = "sys_cs e2e cleanup",
                    edits = { { op = "registry_delete", entry_id = test_entry_id } },
                    message = "sys_cs e2e cleanup",
                })
            end

            local create_resp, create_err = sys_cs.run({
                kind  = "manual",
                title = "sys_cs e2e create",
                edits = {
                    {
                        op = "registry_set",
                        entry = {
                            id         = test_entry_id,
                            kind       = "registry.entry",
                            definition = definition,
                        },
                    },
                },
                message = "sys_cs e2e create",
            })

            test.is_nil(create_err)
            test.not_nil(create_resp)

            -- Push requires a security actor. If the test pool lacks one, the
            -- wrapper is still wired correctly — exit gracefully. The entry
            -- was never published, so no cleanup is required.
            if not create_resp.ok then
                local first = create_resp.errors and create_resp.errors[1]
                local msg = first and first.message or ""
                if msg:find("Authentication required", 1, true) then
                    test.eq(create_resp.stage, "push")
                    test.not_nil(create_resp.changeset_id)
                    test.eq(create_resp.edits_applied, 1)
                    return
                end
                test.fail("expected ok=true, got: stage=" .. tostring(create_resp.stage) ..
                    " errors[1]=" .. tostring(msg))
                return
            end

            local ok, err = pcall(function()
                test.not_nil(create_resp.changeset_id)
                test.eq(create_resp.edits_applied, 1)
                test.eq(create_resp.stage, "push")

                local db = sql.get("keeper.state:db")
                test.not_nil(db)
                local rows = db:query(
                    "SELECT change_id, category, op, target FROM keeper_changeset_changes WHERE changeset_id = ?",
                    { create_resp.changeset_id }
                ) or {}
                db:release()

                test.is_true(#rows >= 1,
                    "expected >= 1 keeper_changeset_changes row for " .. create_resp.changeset_id ..
                    " (got " .. #rows .. ")")

                local found
                for _, r in ipairs(rows) do
                    if r.target == test_entry_id then found = r; break end
                end
                test.not_nil(found)
                test.eq(found.category, "registry")
            end)

            local cleanup_resp = cleanup()
            if not ok then error(err) end
            test.not_nil(cleanup_resp)
            test.is_true(cleanup_resp.ok,
                "cleanup must succeed, otherwise fixture leaks into src/")
        end)

        test.it("record_diff rejects nil args", function()
            local resp = sys_cs.record_diff(nil)
            test.is_false(resp.ok)
            test.eq(resp.rows_written, 0)
            test.is_true(#resp.errors >= 1)
        end)

        test.it("record_diff rejects invalid source", function()
            local resp = sys_cs.record_diff({ source = "nope", ops = {} })
            test.is_false(resp.ok)
            test.not_nil(find_error(resp, sys_cs.ERR.INVALID_SOURCE))
        end)

        test.it("record_diff with empty ops is a no-op success", function()
            local resp = sys_cs.record_diff({ source = "synced_from_fs", ops = {} })
            test.is_true(resp.ok)
            test.eq(resp.rows_written, 0)
        end)

        test.it("record_diff rejects op without target", function()
            local resp = sys_cs.record_diff({
                source = "synced_from_fs",
                ops    = { { category = "registry", op = "create" } },
            })
            test.is_false(resp.ok)
            test.not_nil(find_error(resp, sys_cs.ERR.MISSING_FIELD))
        end)

        test.it("record_diff rejects invalid category", function()
            local resp = sys_cs.record_diff({
                source = "synced_from_fs",
                ops    = { { category = "nope", op = "create", target = "x" } },
            })
            test.is_false(resp.ok)
            test.not_nil(find_error(resp, sys_cs.ERR.INVALID_EDIT))
        end)

        test.it("record_diff rejects invalid op", function()
            local resp = sys_cs.record_diff({
                source = "synced_from_fs",
                ops    = { { category = "registry", op = "burn", target = "x" } },
            })
            test.is_false(resp.ok)
            test.not_nil(find_error(resp, sys_cs.ERR.INVALID_OP))
        end)

        test.it("record_diff writes rows with NULL changeset_id", function()
            local fixture_target = "sys_cs_rd_test:" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 1e9))
            local resp = sys_cs.record_diff({
                source = "synced_from_fs",
                ops    = {
                    { category = "registry",   op = "create", target = fixture_target },
                    { category = "filesystem", op = "update", target = fixture_target .. "/file.lua" },
                    { category = "registry",   op = "delete", target = fixture_target .. "_alt" },
                },
            })
            test.is_true(resp.ok, "record_diff should succeed, got errors: " ..
                tostring(resp.errors and resp.errors[1] and resp.errors[1].message or ""))
            test.eq(resp.rows_written, 3)

            local db = sql.get("keeper.state:db")
            test.not_nil(db)
            local rows = db:query([[
                SELECT category, op, target, source, status, changeset_id
                  FROM keeper_changeset_changes
                 WHERE target LIKE ? OR target LIKE ?
            ]], { fixture_target .. "%", fixture_target .. "_alt%" }) or {}
            db:release()

            test.eq(#rows, 3)
            for _, r in ipairs(rows) do
                test.eq(r.source, "synced_from_fs")
                test.eq(r.status, "applied")
                test.is_nil(r.changeset_id)
            end
        end)

        test.it("record_diff accepts all three system sources", function()
            local sources = { "synced_from_fs", "synced_to_fs", "fs_flushed" }
            local tag = "sys_cs_rd_src_" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 1e9))
            for i, src in ipairs(sources) do
                local resp = sys_cs.record_diff({
                    source = src,
                    ops    = {
                        { category = "filesystem", op = "create", target = tag .. "/" .. tostring(i) .. ".lua" },
                    },
                })
                test.is_true(resp.ok, "source " .. src .. " should be accepted")
                test.eq(resp.rows_written, 1)
            end
        end)

        test.it("record_version_revert writes version_revert registry rows", function()
            local tag = "sys_cs_rvr_" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 1e9))
            local changeset = {
                { kind = "entry.create", entry = { id = tag .. ":a" } },
                { kind = "entry.update", entry = { id = tag .. ":b" } },
                { kind = "entry.delete", entry_id = tag .. ":c" },
                { kind = "entry.create" },             -- no target → skipped
                { kind = "unknown",     entry_id = "x" }, -- unmapped → skipped
            }
            local resp = sys_cs.record_version_revert(changeset)
            test.is_true(resp.ok)
            test.eq(resp.rows_written, 3)

            local db = sql.get("keeper.state:db")
            test.not_nil(db)
            local rows = db:query([[
                SELECT category, op, target, source, status, changeset_id
                  FROM keeper_changeset_changes
                 WHERE target LIKE ?
            ]], { tag .. ":%" }) or {}
            db:release()

            test.eq(#rows, 3)
            local by_target = {}
            for _, r in ipairs(rows) do by_target[r.target] = r end
            test.not_nil(by_target[tag .. ":a"])
            test.eq(by_target[tag .. ":a"].op, "create")
            test.eq(by_target[tag .. ":b"].op, "update")
            test.eq(by_target[tag .. ":c"].op, "delete")
            for _, r in ipairs(rows) do
                test.eq(r.category, "registry")
                test.eq(r.source,   "version_revert")
                test.eq(r.status,   "applied")
                test.is_nil(r.changeset_id)
            end
        end)

        test.it("record_version_revert with empty/non-table input is a no-op", function()
            local r1 = sys_cs.record_version_revert(nil)
            test.is_true(r1.ok)
            test.eq(r1.rows_written, 0)

            local r2 = sys_cs.record_version_revert({})
            test.is_true(r2.ok)
            test.eq(r2.rows_written, 0)

            local r3 = sys_cs.record_version_revert("not-a-table")
            test.is_true(r3.ok)
            test.eq(r3.rows_written, 0)
        end)

        test.it("record_version_revert skips rows with no resolvable target", function()
            local tag = "sys_cs_rvr_skip_" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 1e9))
            local changeset = {
                { kind = "entry.create", entry = { id = tag .. ":ok" } },
                { kind = "entry.create", entry = {} },          -- missing id
                { kind = "entry.update" },                      -- no entry, no entry_id
                { kind = "entry.delete", entry_id = tag .. ":del" },
            }
            local resp = sys_cs.record_version_revert(changeset)
            test.is_true(resp.ok)
            test.eq(resp.rows_written, 2)
        end)

        test.it("record_upload_diff reuses the same changeset mapping", function()
            local tag = "sys_cs_rud_" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 1e9))
            local resp = sys_cs.record_upload_diff({
                changeset = {
                    { kind = "entry.create", entry = { id = tag .. ":a" } },
                    { kind = "entry.update", entry = { id = tag .. ":b" } },
                    { kind = "entry.delete", entry_id = tag .. ":c" },
                    { kind = "unknown", entry = { id = tag .. ":skip" } },
                }
            })
            test.is_true(resp.ok)
            test.eq(resp.rows_written, 3)

            local db = sql.get("keeper.state:db")
            local rows = db:query([[
                SELECT op, target, source
                  FROM keeper_changeset_changes
                 WHERE target LIKE ?
            ]], { tag .. ":%" }) or {}
            db:release()

            test.eq(#rows, 3)
            for _, r in ipairs(rows) do
                test.eq(r.source, "synced_from_fs")
                test.is_true(r.op == "create" or r.op == "update" or r.op == "delete")
            end
        end)

        test.it("record_upload_diff tolerates nil and missing changeset", function()
            local r1 = sys_cs.record_upload_diff(nil)
            test.is_true(r1.ok)
            test.eq(r1.rows_written, 0)

            local r2 = sys_cs.record_upload_diff({})
            test.is_true(r2.ok)
            test.eq(r2.rows_written, 0)

            local r3 = sys_cs.record_upload_diff({ changeset = "not-a-table" })
            test.is_true(r3.ok)
            test.eq(r3.rows_written, 0)
        end)

        test.it("record_version_revert rejects version_revert injection via record_diff", function()
            -- Regression guard: the new SOURCES.VERSION_REVERT must be on the
            -- allow-list so direct record_diff calls also accept it (otherwise
            -- the sys_cs wrapper would succeed but a downstream tool using
            -- record_diff({ source = "version_revert" }) would silently error).
            local tag = "sys_cs_rvr_direct_" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 1e9))
            local resp = sys_cs.record_diff({
                source = "version_revert",
                ops = { { category = "registry", op = "create", target = tag } },
            })
            test.is_true(resp.ok,
                "record_diff must accept version_revert source, got: " ..
                tostring(resp.errors and resp.errors[1] and resp.errors[1].message or ""))
            test.eq(resp.rows_written, 1)
        end)
    end)
end

return {
    define_tests = test.run_cases(define_tests)
}
