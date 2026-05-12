local test = require("test")
local uuid = require("uuid")
local sql = require("sql")
local json = require("json")
local kb_repo = require("kb_repo")
local kb_consts = require("kb_consts")

local function define_tests()
    describe("Knowledge Base Repository", function()
        local test_ws_id = "ws-" .. uuid.v7()
        local test_kb_name = "test-kb-" .. uuid.v7()
        local created_node_ids = {}
        local created_kb_ids = {}

        before_all(function()
            local n1, err1 = kb_repo.create({
                title = "Test Pattern Alpha",
                content = "Use dependency injection for services",
                node_type = "pattern",
                source = "human",
                workspace_id = test_ws_id,
                confidence = 0.9,
                metadata = { origin = "test" },
            })
            test.is_nil(err1)
            test.not_nil(n1)
            table.insert(created_node_ids, n1.id)

            local n2, err2 = kb_repo.create({
                title = "Test Convention Beta",
                content = "All modules must export a table",
                node_type = "convention",
                source = "scan",
                workspace_id = test_ws_id,
                confidence = 0.8,
            })
            test.is_nil(err2)
            test.not_nil(n2)
            table.insert(created_node_ids, n2.id)

            local n3, err3 = kb_repo.create({
                title = "Test Learning Gamma",
                content = "Avoid global state in Lua modules",
                node_type = "learning",
                source = "agent",
            })
            test.is_nil(err3)
            test.not_nil(n3)
            table.insert(created_node_ids, n3.id)
        end)

        after_all(function()
            for _, id in ipairs(created_node_ids) do
                kb_repo.delete(id)
            end
            for _, id in ipairs(created_kb_ids) do
                local db = sql.get(kb_consts.db_id())
                if db then
                    sql.builder.delete("keeper_kbs")
                        :where("id = ?", id)
                        :run_with(db)
                        :exec()
                    db:release()
                end
            end
        end)

        describe("node CRUD lifecycle", function()
            it("creates a node with correct fields", function()
                local node, err = kb_repo.create({
                    title = "Lifecycle Node",
                    content = "Test content for lifecycle",
                    node_type = "pattern",
                    source = "human",
                    workspace_id = test_ws_id,
                })
                test.is_nil(err)
                test.not_nil(node)
                test.not_nil(node.id)
                test.eq(node.title, "Lifecycle Node")
                test.eq(node.node_type, "pattern")
                test.eq(node.source, "human")
                test.eq(node.workspace_id, test_ws_id)
                test.not_nil(node.created_at)
                table.insert(created_node_ids, node.id)
            end)

            it("gets a node by id", function()
                local id = created_node_ids[1]
                local node = kb_repo.get(id)
                test.not_nil(node)
                test.eq(node.id, id)
                test.eq(node.title, "Test Pattern Alpha")
                test.eq(node.content, "Use dependency injection for services")
                test.eq(node.node_type, "pattern")
                test.eq(node.source, "human")
                test.eq(node.confidence, 0.9)
                test.eq(node.embedded, false)
            end)

            it("preserves metadata as a table", function()
                local id = created_node_ids[1]
                local node = kb_repo.get(id)
                test.not_nil(node)
                test.not_nil(node.metadata)
                test.eq(node.metadata.origin, "test")
            end)

            it("updates a node", function()
                local id = created_node_ids[1]
                local result, err = kb_repo.update(id, {
                    title = "Updated Pattern Alpha",
                    content = "Updated content for DI",
                    confidence = 0.95,
                })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(result.id, id)
                test.not_nil(result.updated_at)

                local node = kb_repo.get(id)
                test.not_nil(node)
                test.eq(node.title, "Updated Pattern Alpha")
                test.eq(node.content, "Updated content for DI")
                test.eq(node.confidence, 0.95)
            end)

            it("deletes a node", function()
                local node, err = kb_repo.create({
                    title = "To Be Deleted",
                    content = "Temporary node",
                    node_type = "learning",
                })
                test.is_nil(err)
                test.not_nil(node)

                local result, del_err = kb_repo.delete(node.id)
                test.is_nil(del_err)
                test.not_nil(result)
                test.eq(result.deleted, true)

                local fetched = kb_repo.get(node.id)
                test.is_nil(fetched)
            end)
        end)

        describe("node edge cases", function()
            it("returns nil for nonexistent node", function()
                local node = kb_repo.get("00000000-0000-0000-0000-000000000000")
                test.is_nil(node)
            end)

            it("returns error when updating with no fields", function()
                local id = created_node_ids[1]
                local _, err = kb_repo.update(id, {})
                test.not_nil(err)
                test.eq(err, "No fields to update")
            end)

            it("delete on nonexistent node does not error", function()
                local result, err = kb_repo.delete("00000000-0000-0000-0000-000000000000")
                test.is_nil(err)
                test.not_nil(result)
                test.eq(result.deleted, true)
            end)

            it("creates a node with default values", function()
                local node, err = kb_repo.create({})
                test.is_nil(err)
                test.not_nil(node)
                test.eq(node.node_type, "pattern")
                test.eq(node.source, "human")
                test.eq(node.title, "")
                test.eq(node.content, "")
                table.insert(created_node_ids, node.id)
            end)
        end)

        describe("list with filters", function()
            it("lists all nodes", function()
                local nodes, err = kb_repo.list({})
                test.is_nil(err)
                test.not_nil(nodes)
                test.is_true(#nodes >= 3)
            end)

            it("filters by node_type", function()
                local nodes, err = kb_repo.list({ node_type = "convention" })
                test.is_nil(err)
                test.not_nil(nodes)
                test.is_true(#nodes >= 1)
                for _, n in ipairs(nodes) do
                    test.eq(n.node_type, "convention")
                end
            end)

            it("filters by source", function()
                local nodes, err = kb_repo.list({ source = "scan" })
                test.is_nil(err)
                test.not_nil(nodes)
                test.is_true(#nodes >= 1)
                for _, n in ipairs(nodes) do
                    test.eq(n.source, "scan")
                end
            end)

            it("filters by workspace_id", function()
                local nodes, err = kb_repo.list({ workspace_id = test_ws_id })
                test.is_nil(err)
                test.not_nil(nodes)
                test.is_true(#nodes >= 2)
                for _, n in ipairs(nodes) do
                    test.eq(n.workspace_id, test_ws_id)
                end
            end)

            it("respects limit", function()
                local nodes, err = kb_repo.list({ limit = 1 })
                test.is_nil(err)
                test.not_nil(nodes)
                test.eq(#nodes, 1)
            end)

            it("returns empty for non-matching filter", function()
                local nodes, err = kb_repo.list({ source = "nonexistent-source-" .. uuid.v7() })
                test.is_nil(err)
                test.not_nil(nodes)
                test.eq(#nodes, 0)
            end)
        end)

        describe("search_text", function()
            it("finds nodes by title keyword", function()
                local nodes, err = kb_repo.search_text("Pattern Alpha", {})
                test.is_nil(err)
                test.not_nil(nodes)
                test.is_true(#nodes >= 1)
            end)

            it("finds nodes by content keyword", function()
                local nodes, err = kb_repo.search_text("dependency injection", {})
                test.is_nil(err)
                test.not_nil(nodes)
                test.is_true(#nodes >= 1)
            end)

            it("returns empty for unmatched query", function()
                local nodes, err = kb_repo.search_text("zzzznonexistent" .. uuid.v7(), {})
                test.is_nil(err)
                test.not_nil(nodes)
                test.eq(#nodes, 0)
            end)

            it("respects limit parameter", function()
                local nodes, err = kb_repo.search_text("test", { limit = 1 })
                test.is_nil(err)
                test.not_nil(nodes)
                test.is_true(#nodes <= 1)
            end)
        end)

        describe("search_by_embedding", function()
            it("uses legacy and canonical embedding class aliases by default", function()
                local models = kb_consts.embedding_models()
                test.eq(models[1], "class:embed")
                test.eq(models[2], "class:embedding")
            end)

            it("respects an explicit embedding model override", function()
                local models = kb_consts.embedding_models("app.models:custom-embed")
                test.eq(#models, 1)
                test.eq(models[1], "app.models:custom-embed")
            end)

            it("finds embedded nodes using the configured vector backend", function()
                local vector = {}
                for i = 1, 512 do vector[i] = 0 end
                vector[1] = 1

                local node, err = kb_repo.create({
                    title = "Embedding fallback target",
                    content = "portable semantic search target",
                    node_type = "learning",
                })
                test.is_nil(err)
                test.not_nil(node)
                table.insert(created_node_ids, node.id)

                local db = sql.get(kb_consts.db_id())
                test.not_nil(db)
                local _, delete_err = sql.builder.delete("keeper_kb_embeddings")
                    :where("node_id = ?", node.id)
                    :run_with(db)
                    :exec()
                test.is_nil(delete_err)
                local _, insert_err = sql.builder.insert("keeper_kb_embeddings")
                    :set_map({
                        node_id = node.id,
                        embedding = json.encode(vector),
                        title = node.title,
                        content_preview = node.content,
                    })
                    :run_with(db)
                    :exec()
                test.is_nil(insert_err)
                local _, update_err = sql.builder.update("keeper_kb_nodes")
                    :set("embedded", 1)
                    :where("id = ?", node.id)
                    :run_with(db)
                    :exec()
                test.is_nil(update_err)
                db:release()

                local results, search_err = kb_repo.search_by_embedding(vector, { limit = 3 })
                test.is_nil(search_err)
                test.not_nil(results)
                local found = false
                for _, result in ipairs(results) do
                    if result.id == node.id then
                        found = true
                        test.not_nil(result.distance)
                    end
                end
                test.is_true(found)
            end)
        end)

        describe("delete_by_workspace", function()
            it("deletes all nodes in a workspace", function()
                local ws_id = "ws-delete-" .. uuid.v7()
                local n1, _ = kb_repo.create({ title = "WS Node 1", workspace_id = ws_id })
                local n2, _ = kb_repo.create({ title = "WS Node 2", workspace_id = ws_id })
                test.not_nil(n1)
                test.not_nil(n2)

                local result = kb_repo.delete_by_workspace(ws_id)
                test.not_nil(result)
                test.eq(result.workspace_id, ws_id)
                test.eq(result.deleted, 2)

                local remaining, err = kb_repo.list({ workspace_id = ws_id })
                test.is_nil(err)
                test.eq(#remaining, 0)
            end)

            it("returns zero for empty workspace", function()
                local result = kb_repo.delete_by_workspace("ws-empty-" .. uuid.v7())
                test.not_nil(result)
                test.eq(result.deleted, 0)
            end)
        end)

        describe("stats", function()
            it("returns aggregate statistics", function()
                local stats, err = kb_repo.stats({})
                test.is_nil(err)
                test.not_nil(stats)
                test.is_true(stats.total >= 3)
                test.not_nil(stats.by_type)
                test.not_nil(stats.by_source)
                test.not_nil(stats.embedded)
                test.not_nil(stats.workspace_linked)
            end)

            it("counts by type correctly", function()
                local stats, err = kb_repo.stats({})
                test.is_nil(err)
                test.not_nil(stats.by_type)
                test.is_true((stats.by_type["pattern"] or 0) >= 1)
                test.is_true((stats.by_type["convention"] or 0) >= 1)
            end)

            it("counts by source correctly", function()
                local stats, err = kb_repo.stats({})
                test.is_nil(err)
                test.not_nil(stats.by_source)
                test.is_true((stats.by_source["human"] or 0) >= 1)
                test.is_true((stats.by_source["scan"] or 0) >= 1)
            end)
        end)

        describe("KB management", function()
            it("creates a knowledge base", function()
                local kb, err = kb_repo.create_kb({
                    name = test_kb_name,
                    description = "Test KB for repo tests",
                })
                test.is_nil(err)
                test.not_nil(kb)
                test.not_nil(kb.id)
                test.eq(kb.name, test_kb_name)
                test.eq(kb.description, "Test KB for repo tests")
                test.not_nil(kb.created_at)
                table.insert(created_kb_ids, kb.id)
            end)

            it("rejects KB with empty name", function()
                local _, err = kb_repo.create_kb({ name = "" })
                test.not_nil(err)
                test.eq(err, "KB name is required")
            end)

            it("rejects duplicate KB name", function()
                local _, err = kb_repo.create_kb({ name = test_kb_name })
                test.not_nil(err)
                test.is_true(err:find("already exists") ~= nil)
            end)

            it("lists knowledge bases", function()
                local kbs, err = kb_repo.list_kbs()
                test.is_nil(err)
                test.not_nil(kbs)
                test.is_true(#kbs >= 1)

                local found = false
                for _, kb in ipairs(kbs) do
                    if kb.name == test_kb_name then
                        found = true
                        break
                    end
                end
                test.is_true(found)
            end)

            it("resolves KB by name", function()
                local kb = kb_repo.resolve_kb(test_kb_name)
                test.not_nil(kb)
                test.eq(kb.name, test_kb_name)
            end)

            it("resolves KB by id", function()
                local id = created_kb_ids[1]
                local kb = kb_repo.resolve_kb(id)
                test.not_nil(kb)
                test.eq(kb.id, id)
            end)

            it("resolve returns nil for unknown name", function()
                local kb = kb_repo.resolve_kb("nonexistent-kb-" .. uuid.v7())
                test.is_nil(kb)
            end)

            it("resolve returns nil for empty string", function()
                local kb = kb_repo.resolve_kb("")
                test.is_nil(kb)
            end)

            it("deletes a knowledge base", function()
                local temp_name = "temp-kb-" .. uuid.v7()
                local kb, _ = kb_repo.create_kb({ name = temp_name })
                test.not_nil(kb)

                local result, err = kb_repo.delete_kb(kb.id)
                test.is_nil(err)
                test.not_nil(result)
                test.eq(result.deleted, true)
                test.eq(result.name, temp_name)

                local resolved = kb_repo.resolve_kb(temp_name)
                test.is_nil(resolved)
            end)

            it("cannot delete nonexistent KB", function()
                local _, err = kb_repo.delete_kb("00000000-0000-0000-0000-000000000000")
                test.not_nil(err)
                test.eq(err, "KB not found")
            end)

            it("cannot delete the default KB", function()
                local _, err = kb_repo.delete_kb("00000000-0000-0000-0000-000000000001")
                test.not_nil(err)
                test.eq(err, "Cannot delete the default knowledge base")
            end)
        end)

        describe("KB-scoped nodes", function()
            it("creates a node in a specific KB", function()
                local kb_id = created_kb_ids[1]
                if not kb_id then return end

                local node, err = kb_repo.create({
                    kb_id = kb_id,
                    title = "KB-scoped node",
                    content = "Belongs to test KB",
                    node_type = "pattern",
                })
                test.is_nil(err)
                test.not_nil(node)
                test.eq(node.kb_id, kb_id)
                table.insert(created_node_ids, node.id)

                local fetched = kb_repo.get(node.id)
                test.not_nil(fetched)
                test.eq(fetched.kb_id, kb_id)
            end)

            it("lists nodes filtered by kb_id", function()
                local kb_id = created_kb_ids[1]
                if not kb_id then return end

                local nodes, err = kb_repo.list({ kb_id = kb_id })
                test.is_nil(err)
                test.not_nil(nodes)
                test.is_true(#nodes >= 1)
                for _, n in ipairs(nodes) do
                    test.eq(n.kb_id, kb_id)
                end
            end)

            it("stats can filter by kb_id", function()
                local kb_id = created_kb_ids[1]
                if not kb_id then return end

                local stats, err = kb_repo.stats({ kb_id = kb_id })
                test.is_nil(err)
                test.not_nil(stats)
                test.is_true(stats.total >= 1)
            end)
        end)

        describe("find_by_title and duplicate prevention", function()
            local default_kb_id = "00000000-0000-0000-0000-000000000001"

            it("find_by_title returns existing node in default KB", function()
                local unique_title = "Find By Title Target " .. uuid.v7()
                local created, err = kb_repo.create({
                    title = unique_title,
                    content = "target content",
                    node_type = "pattern",
                    source = "agent",
                })
                test.is_nil(err)
                test.not_nil(created)
                table.insert(created_node_ids, created.id)

                local found = kb_repo.find_by_title(default_kb_id, unique_title)
                test.not_nil(found)
                test.eq(found.id, created.id)
                test.eq(found.title, unique_title)
            end)

            it("find_by_title returns nil when no match exists", function()
                local missing_title = "Missing Title " .. uuid.v7()
                local found, err = kb_repo.find_by_title(default_kb_id, missing_title)
                test.is_nil(err)
                test.is_nil(found)
            end)

            it("find_by_title returns nil for empty title", function()
                local found = kb_repo.find_by_title(default_kb_id, "")
                test.is_nil(found)
            end)

            it("find_by_title returns nil for nil kb_id", function()
                local found = kb_repo.find_by_title(nil, "Test Pattern Alpha")
                test.is_nil(found)
            end)

            it("find_by_title is scoped to kb_id (no cross-KB match)", function()
                local other_kb_id = created_kb_ids[1]
                if not other_kb_id then return end

                local title = "KB Scope Check " .. uuid.v7()
                local node, err = kb_repo.create({
                    kb_id = other_kb_id,
                    title = title,
                    content = "only in other KB",
                    node_type = "pattern",
                })
                test.is_nil(err)
                test.not_nil(node)
                table.insert(created_node_ids, node.id)

                local found_default = kb_repo.find_by_title(default_kb_id, title)
                test.is_nil(found_default)

                local found_scoped = kb_repo.find_by_title(other_kb_id, title)
                test.not_nil(found_scoped)
                test.eq(found_scoped.id, node.id)
            end)

            it("find_by_title returns first match when multiple duplicates exist", function()
                local dup_title = "Dup Title " .. uuid.v7()
                local n1, _ = kb_repo.create({
                    title = dup_title,
                    content = "first",
                    node_type = "pattern",
                })
                local n2, _ = kb_repo.create({
                    title = dup_title,
                    content = "second",
                    node_type = "pattern",
                })
                test.not_nil(n1)
                test.not_nil(n2)
                table.insert(created_node_ids, n1.id)
                table.insert(created_node_ids, n2.id)

                local found = kb_repo.find_by_title(default_kb_id, dup_title)
                test.not_nil(found)
                test.is_true(found.id == n1.id or found.id == n2.id)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
