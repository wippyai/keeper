local test = require("test")
local sql = require("sql")
local uuid = require("uuid")
local state_ops = require("state_ops")
local state_reader = require("state_reader")
local overlay_consts = require("overlay_consts")

local TEST_BRANCH = nil
local TEST_ENTRY_PREFIX = "ops_test.ns"

local function get_db()
    return sql.get(overlay_consts.DATABASE.RESOURCE_ID)
end

local function make_entry_id(suffix)
    return TEST_ENTRY_PREFIX .. ":" .. suffix
end

local function make_set_entry_cmd(entry_id, kind, definition, content, branch)
    return {
        type = state_ops.COMMAND.SET_ENTRY,
        payload = {
            id = entry_id,
            kind = kind or "function.lua",
            definition = definition or "version: \"1.0\"\nnamespace: ops_test.ns\nentries:\n  - name: test\n    kind: function.lua",
            content = content,
            branch = branch or TEST_BRANCH,
        }
    }
end

local function cleanup_test_data(branch)
    local db, err = get_db()
    if err or not db then return end

    db:execute("DELETE FROM keeper_overlay_entries WHERE branch = ?", {branch})
    db:execute("DELETE FROM keeper_overlay_chunks WHERE branch = ?", {branch})
    db:execute("DELETE FROM keeper_overlay_chunks_fts WHERE branch = ?", {branch})
    db:execute("DELETE FROM keeper_overlay_edges WHERE branch = ?", {branch})
    db:execute("DELETE FROM keeper_overlay_attributes WHERE branch = ?", {branch})
    db:release()
end

local function define_tests()
    describe("State Ops", function()
        before_all(function()
            TEST_BRANCH = "ops-test-" .. uuid.v4():sub(1, 8)
        end)

        after_all(function()
            cleanup_test_data(TEST_BRANCH)
        end)

        describe("execute validation", function()
            it("returns error when tx is nil", function()
                local result, err = state_ops.execute(nil, {})
                test.is_nil(result)
                test.eq(err, overlay_consts.ERRORS.TRANSACTION_REQUIRED)
            end)

            it("returns error when commands is nil", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                test.not_nil(db)

                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, nil)
                test.is_nil(result)
                test.eq(err, overlay_consts.ERRORS.COMMANDS_REQUIRED)

                tx:rollback()
                db:release()
            end)

            it("returns error when commands is empty", function()
                local db, db_err = get_db()
                test.is_nil(db_err)

                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, {})
                test.is_nil(result)
                test.eq(err, overlay_consts.ERRORS.COMMANDS_EMPTY)

                tx:rollback()
                db:release()
            end)

            it("returns error for unknown command type", function()
                local db, db_err = get_db()
                test.is_nil(db_err)

                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, {
                    { type = "nonexistent_command", payload = {} }
                })
                test.is_nil(result)
                test.not_nil(err)
                test.is_true(err:find("Unknown command type") ~= nil)

                tx:rollback()
                db:release()
            end)

            it("returns error for command missing type", function()
                local db, db_err = get_db()
                test.is_nil(db_err)

                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, {
                    { payload = { id = "test:entry" } }
                })
                test.is_nil(result)
                test.not_nil(err)

                tx:rollback()
                db:release()
            end)
        end)

        describe("set_entry", function()
            it("creates an entry with definition", function()
                local db, db_err = get_db()
                test.is_nil(db_err)

                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local entry_id = make_entry_id("set_basic_" .. uuid.v4():sub(1, 8))
                local result, err = state_ops.execute(tx, {
                    make_set_entry_cmd(entry_id, "function.lua", "version: 1.0\ntest definition", nil, TEST_BRANCH)
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(result.changes_made)
                test.eq(#result.results, 1)
                test.eq(result.results[1].entry_id, entry_id)
                test.eq(result.results[1].branch, TEST_BRANCH)

                tx:commit()
                db:release()

                local reader = state_reader.for_branch(TEST_BRANCH)
                local entries, read_err = reader:with_entries(entry_id):include_chunks():all()
                test.is_nil(read_err)
                test.eq(#entries, 1)
                test.eq(entries[1].id, entry_id)
                test.eq(entries[1].kind, "function.lua")

                local has_definition = false
                for _, chunk in ipairs(entries[1].chunks) do
                    if chunk.type == "definition" then
                        has_definition = true
                        test.eq(chunk.content, "version: 1.0\ntest definition")
                    end
                end
                test.is_true(has_definition)
            end)

            it("creates an entry with definition and content", function()
                local db, db_err = get_db()
                test.is_nil(db_err)

                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local entry_id = make_entry_id("set_content_" .. uuid.v4():sub(1, 8))
                local result, err = state_ops.execute(tx, {
                    make_set_entry_cmd(entry_id, "function.lua", "definition yaml", "local x = 1\nreturn x", TEST_BRANCH)
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(result.changes_made)

                tx:commit()
                db:release()

                local reader = state_reader.for_branch(TEST_BRANCH)
                local entries, read_err = reader:with_entries(entry_id):include_chunks():all()
                test.is_nil(read_err)
                test.eq(#entries, 1)

                local has_definition = false
                local has_content = false
                for _, chunk in ipairs(entries[1].chunks) do
                    if chunk.type == "definition" then
                        has_definition = true
                    elseif chunk.type == "content" then
                        has_content = true
                        test.eq(chunk.content, "local x = 1\nreturn x")
                    end
                end
                test.is_true(has_definition)
                test.is_true(has_content)
            end)

            it("creates an entry with attributes", function()
                local db, db_err = get_db()
                test.is_nil(db_err)

                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local entry_id = make_entry_id("set_attrs_" .. uuid.v4():sub(1, 8))
                local result, err = state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.SET_ENTRY,
                        payload = {
                            id = entry_id,
                            kind = "function.lua",
                            definition = "test def",
                            branch = TEST_BRANCH,
                            attributes = {
                                ["meta.type"] = "tool",
                                ["status"] = "active"
                            }
                        }
                    }
                })
                test.is_nil(err)
                test.not_nil(result)

                tx:commit()
                db:release()

                local reader = state_reader.for_branch(TEST_BRANCH)
                local entries, read_err = reader:with_entries(entry_id):include_attributes():all()
                test.is_nil(read_err)
                test.eq(#entries, 1)
                test.eq(entries[1].attributes["meta.type"], "tool")
                test.eq(entries[1].attributes["status"], "active")
            end)

            it("replaces entry on re-set", function()
                local db, db_err = get_db()
                test.is_nil(db_err)

                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local entry_id = make_entry_id("set_replace_" .. uuid.v4():sub(1, 8))

                state_ops.execute(tx, {
                    make_set_entry_cmd(entry_id, "function.lua", "original definition", "original content", TEST_BRANCH)
                })
                tx:commit()
                db:release()

                db, db_err = get_db()
                test.is_nil(db_err)
                tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, {
                    make_set_entry_cmd(entry_id, "library.lua", "updated definition", "updated content", TEST_BRANCH)
                })
                test.is_nil(err)
                test.not_nil(result)

                tx:commit()
                db:release()

                local reader = state_reader.for_branch(TEST_BRANCH)
                local entries, read_err = reader:with_entries(entry_id):include_chunks():all()
                test.is_nil(read_err)
                test.eq(#entries, 1)
                test.eq(entries[1].kind, "library.lua")

                for _, chunk in ipairs(entries[1].chunks) do
                    if chunk.type == "definition" then
                        test.eq(chunk.content, "updated definition")
                    elseif chunk.type == "content" then
                        test.eq(chunk.content, "updated content")
                    end
                end
            end)

            it("rejects entry missing required fields", function()
                local db, db_err = get_db()
                test.is_nil(db_err)

                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, {
                    { type = state_ops.COMMAND.SET_ENTRY, payload = { id = "test:x" } }
                })
                test.is_nil(result)
                test.not_nil(err)

                tx:rollback()
                db:release()
            end)
        end)

        describe("delete_entry", function()
            it("marks an existing entry as deleted", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local entry_id = make_entry_id("del_" .. uuid.v4():sub(1, 8))
                state_ops.execute(tx, {
                    make_set_entry_cmd(entry_id, "function.lua", "def", nil, TEST_BRANCH)
                })
                tx:commit()
                db:release()

                db, db_err = get_db()
                test.is_nil(db_err)
                tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.DELETE_ENTRY,
                        payload = { id = entry_id, branch = TEST_BRANCH }
                    }
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(result.changes_made)

                tx:commit()
                db:release()

                local reader = state_reader.for_branch(TEST_BRANCH):with_entries(entry_id)
                local entries, read_err = reader:all()
                test.is_nil(read_err)
                test.eq(#entries, 0)

                local deleted_reader = state_reader.for_branch(TEST_BRANCH):with_entries(entry_id):include_deleted()
                local deleted_entries, del_err = deleted_reader:all()
                test.is_nil(del_err)
                test.eq(#deleted_entries, 1)
                test.eq(deleted_entries[1].deleted, 1)
            end)

            it("returns error for nonexistent entry", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.DELETE_ENTRY,
                        payload = { id = "nonexistent.ns:missing_" .. uuid.v4():sub(1, 8), branch = TEST_BRANCH }
                    }
                })
                test.is_nil(result)
                test.not_nil(err)

                tx:rollback()
                db:release()
            end)
        end)

        describe("set_edge", function()
            it("creates an edge between entries", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local source_id = make_entry_id("edge_src_" .. uuid.v4():sub(1, 8))
                local target_id = make_entry_id("edge_tgt_" .. uuid.v4():sub(1, 8))

                local result, err = state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.SET_EDGE,
                        payload = {
                            source_id = source_id,
                            target_id = target_id,
                            edge_type = "imports",
                            branch = TEST_BRANCH
                        }
                    }
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(result.changes_made)
                test.eq(result.results[1].source_id, source_id)
                test.eq(result.results[1].target_id, target_id)
                test.eq(result.results[1].edge_type, "imports")

                tx:commit()
                db:release()

                local reader = state_reader.for_edges(TEST_BRANCH)
                local edges, read_err = reader:with_sources(source_id):all()
                test.is_nil(read_err)
                test.eq(#edges, 1)
                test.eq(edges[1].source_id, source_id)
                test.eq(edges[1].target_id, target_id)
                test.eq(edges[1].edge_type, "imports")
            end)

            it("creates an edge with metadata", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local source_id = make_entry_id("emeta_src_" .. uuid.v4():sub(1, 8))
                local target_id = make_entry_id("emeta_tgt_" .. uuid.v4():sub(1, 8))

                local result, err = state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.SET_EDGE,
                        payload = {
                            source_id = source_id,
                            target_id = target_id,
                            edge_type = "references",
                            branch = TEST_BRANCH,
                            metadata = { weight = 1, label = "test" }
                        }
                    }
                })
                test.is_nil(err)
                test.not_nil(result)

                tx:commit()
                db:release()

                local reader = state_reader.for_edges(TEST_BRANCH)
                local edges, read_err = reader:with_sources(source_id):all()
                test.is_nil(read_err)
                test.eq(#edges, 1)
                test.eq(edges[1].metadata.label, "test")
            end)

            it("rejects edge missing required fields", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.SET_EDGE,
                        payload = { source_id = "a:b", branch = TEST_BRANCH }
                    }
                })
                test.is_nil(result)
                test.not_nil(err)

                tx:rollback()
                db:release()
            end)
        end)

        describe("delete_edge", function()
            it("removes an existing edge", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local source_id = make_entry_id("dedge_src_" .. uuid.v4():sub(1, 8))
                local target_id = make_entry_id("dedge_tgt_" .. uuid.v4():sub(1, 8))

                state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.SET_EDGE,
                        payload = {
                            source_id = source_id,
                            target_id = target_id,
                            edge_type = "calls",
                            branch = TEST_BRANCH
                        }
                    }
                })
                tx:commit()
                db:release()

                db, db_err = get_db()
                test.is_nil(db_err)
                tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.DELETE_EDGE,
                        payload = {
                            source_id = source_id,
                            target_id = target_id,
                            edge_type = "calls",
                            branch = TEST_BRANCH
                        }
                    }
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(result.changes_made)

                tx:commit()
                db:release()

                local reader = state_reader.for_edges(TEST_BRANCH)
                local edges, read_err = reader:with_sources(source_id):with_edge_types("calls"):all()
                test.is_nil(read_err)
                test.eq(#edges, 0)
            end)
        end)

        describe("set_attribute", function()
            it("sets an attribute on an entry", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local entry_id = make_entry_id("attr_set_" .. uuid.v4():sub(1, 8))

                state_ops.execute(tx, {
                    make_set_entry_cmd(entry_id, "function.lua", "def", nil, TEST_BRANCH)
                })

                local result, err = state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.SET_ATTRIBUTE,
                        payload = {
                            entry_id = entry_id,
                            attr_key = "status",
                            attr_value = "published",
                            branch = TEST_BRANCH
                        }
                    }
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(result.changes_made)
                test.eq(result.results[1].attr_key, "status")

                tx:commit()
                db:release()

                local reader = state_reader.for_branch(TEST_BRANCH)
                local entries, read_err = reader:with_entries(entry_id):include_attributes():all()
                test.is_nil(read_err)
                test.eq(#entries, 1)
                test.eq(entries[1].attributes["status"], "published")
            end)

            it("rejects attribute missing required fields", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.SET_ATTRIBUTE,
                        payload = { entry_id = "a:b", branch = TEST_BRANCH }
                    }
                })
                test.is_nil(result)
                test.not_nil(err)

                tx:rollback()
                db:release()
            end)
        end)

        describe("delete_attribute", function()
            it("removes an attribute from an entry", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local entry_id = make_entry_id("attr_del_" .. uuid.v4():sub(1, 8))

                state_ops.execute(tx, {
                    make_set_entry_cmd(entry_id, "function.lua", "def", nil, TEST_BRANCH)
                })
                state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.SET_ATTRIBUTE,
                        payload = {
                            entry_id = entry_id,
                            attr_key = "temp_flag",
                            attr_value = "true",
                            branch = TEST_BRANCH
                        }
                    }
                })
                tx:commit()
                db:release()

                db, db_err = get_db()
                test.is_nil(db_err)
                tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local result, err = state_ops.execute(tx, {
                    {
                        type = state_ops.COMMAND.DELETE_ATTRIBUTE,
                        payload = {
                            entry_id = entry_id,
                            attr_key = "temp_flag",
                            branch = TEST_BRANCH
                        }
                    }
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(result.changes_made)

                tx:commit()
                db:release()

                local reader = state_reader.for_branch(TEST_BRANCH)
                local entries, read_err = reader:with_entries(entry_id):include_attributes():all()
                test.is_nil(read_err)
                test.eq(#entries, 1)
                test.is_nil(entries[1].attributes["temp_flag"])
            end)
        end)

        describe("multiple commands", function()
            it("executes multiple commands in a single batch", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local entry_id_1 = make_entry_id("batch1_" .. uuid.v4():sub(1, 8))
                local entry_id_2 = make_entry_id("batch2_" .. uuid.v4():sub(1, 8))

                local result, err = state_ops.execute(tx, {
                    make_set_entry_cmd(entry_id_1, "function.lua", "def1", "content1", TEST_BRANCH),
                    make_set_entry_cmd(entry_id_2, "library.lua", "def2", "content2", TEST_BRANCH),
                    {
                        type = state_ops.COMMAND.SET_EDGE,
                        payload = {
                            source_id = entry_id_1,
                            target_id = entry_id_2,
                            edge_type = "imports",
                            branch = TEST_BRANCH
                        }
                    }
                })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(#result.results, 3)
                test.is_true(result.changes_made)

                tx:commit()
                db:release()

                local reader = state_reader.for_branch(TEST_BRANCH)
                local entries, read_err = reader:with_entries(entry_id_1, entry_id_2):all()
                test.is_nil(read_err)
                test.eq(#entries, 2)

                local edge_reader = state_reader.for_edges(TEST_BRANCH)
                local edges, edge_err = edge_reader:with_sources(entry_id_1):with_edge_types("imports"):all()
                test.is_nil(edge_err)
                test.eq(#edges, 1)
            end)

            it("rolls back all commands when one fails", function()
                local db, db_err = get_db()
                test.is_nil(db_err)
                local tx, tx_err = db:begin()
                test.is_nil(tx_err)

                local entry_id = make_entry_id("rollback_" .. uuid.v4():sub(1, 8))

                local result, err = state_ops.execute(tx, {
                    make_set_entry_cmd(entry_id, "function.lua", "def", nil, TEST_BRANCH),
                    { type = state_ops.COMMAND.SET_ENTRY, payload = { id = "test:x" } }
                })
                test.is_nil(result)
                test.not_nil(err)

                tx:rollback()
                db:release()
            end)
        end)

        describe("apply_commands", function()
            it("opens tx, executes, commits, releases on success", function()
                local entry_id = make_entry_id("apply_ok_" .. uuid.v4():sub(1, 8))
                local result, err = state_ops.apply_commands({
                    make_set_entry_cmd(entry_id, "function.lua", "def", nil, TEST_BRANCH),
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(result.changes_made)

                local reader = state_reader.for_branch(TEST_BRANCH)
                local rows, read_err = reader:with_entries(entry_id):all()
                test.is_nil(read_err)
                test.eq(#rows, 1)
            end)

            it("rolls back on execute failure", function()
                local entry_id = make_entry_id("apply_rb_" .. uuid.v4():sub(1, 8))
                local result, err = state_ops.apply_commands({
                    make_set_entry_cmd(entry_id, "function.lua", "def", nil, TEST_BRANCH),
                    { type = state_ops.COMMAND.SET_ENTRY, payload = { id = "test:x" } }
                })
                test.is_nil(result)
                test.not_nil(err)

                local reader = state_reader.for_branch(TEST_BRANCH)
                local rows, read_err = reader:with_entries(entry_id):all()
                test.is_nil(read_err)
                test.eq(#rows, 0)
            end)

            it("surfaces empty-commands error", function()
                local result, err = state_ops.apply_commands({})
                test.is_nil(result)
                test.not_nil(err)
                test.is_true(err:find("Command execution failed", 1, true) ~= nil)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
