local test = require("test")
local json = require("json")
local sql = require("sql")
local uuid = require("uuid")
local repo = require("repo")
local config = require("keeper_config")

local function define_tests()
    describe("Flow repo pure helpers", function()
        local function must_row(rows, index)
            local row = rows[index]
            if not row then error("row missing at index " .. tostring(index)) end
            return row
        end

        describe("decode_content", function()
            it("returns nil when content is absent", function()
                test.is_nil(repo.decode_content({}))
            end)

            it("decodes JSON when content_type is application/json", function()
                local out = repo.decode_content({
                    content_type = "application/json",
                    content      = json.encode({ a = 1 }),
                })
                if type(out) ~= "table" then error("expected decoded table") end
                test.eq(out.a, 1)
            end)

            it("returns raw content for non-JSON type", function()
                local out = repo.decode_content({
                    content_type = "text/plain",
                    content      = "hello",
                })
                test.eq(out, "hello")
            end)
        end)

        describe("adjacency", function()
            it("builds parent->children map with roots list", function()
                local nodes = {
                    { node_id = "r1" },
                    { node_id = "c1", parent_node_id = "r1" },
                    { node_id = "c2", parent_node_id = "r1" },
                    { node_id = "g1", parent_node_id = "c1" },
                    { node_id = "r2", parent_node_id = "" },
                }
                local adj = repo.adjacency(nodes)

                test.eq(#adj.roots, 2)
                local roots = { [adj.roots[1]] = true, [adj.roots[2]] = true }
                test.is_true(roots["r1"])
                test.is_true(roots["r2"])

                test.eq(#adj.children["r1"], 2)
                test.eq(#adj.children["c1"], 1)
                test.eq(adj.children["c1"][1], "g1")

                test.eq(adj.by_id["g1"].parent_node_id, "c1")
            end)

            it("handles an empty node list", function()
                local adj = repo.adjacency({})
                test.eq(#adj.roots, 0)
            end)
        end)

        describe("ancestors", function()
            local nodes = {
                { node_id = "root" },
                { node_id = "mid", parent_node_id = "root" },
                { node_id = "leaf", parent_node_id = "mid" },
                { node_id = "orphan", parent_node_id = "" },
            }

            it("walks from leaf to root", function()
                local chain = repo.ancestors(nodes, "leaf")
                test.eq(#chain, 3)
                test.eq(must_row(chain, 1).node_id, "leaf")
                test.eq(must_row(chain, 2).node_id, "mid")
                test.eq(must_row(chain, 3).node_id, "root")
            end)

            it("handles root-only node", function()
                local chain = repo.ancestors(nodes, "root")
                test.eq(#chain, 1)
            end)

            it("stops on empty-string parent", function()
                local chain = repo.ancestors(nodes, "orphan")
                test.eq(#chain, 1)
                test.eq(must_row(chain, 1).node_id, "orphan")
            end)

            it("returns empty when node_id is unknown", function()
                local chain = repo.ancestors(nodes, "ghost")
                test.eq(#chain, 0)
            end)
        end)
    end)

    describe("Flow repo reference rows", function()
        local dataflow_id, node_id, answer_id = uuid.v7(), uuid.v7(), uuid.v7()

        local function must_db()
            local db, err = sql.get(config.app_db())
            if err then error("db: " .. tostring(err)) end
            if not db then error("db unavailable") end
            return db
        end

        local function must_exec(db, statement, params)
            local _, err = db:execute(statement, params)
            if err then error(statement .. ": " .. tostring(err)) end
        end

        local prepared = false
        local created = false

        local function prepare()
            if prepared then return end
            created = true

            local now = os.time()
            local db = must_db()
            must_exec(db,
                "INSERT INTO dataflows (dataflow_id, actor_id, type, status, created_at, updated_at) " ..
                "VALUES (?, ?, ?, ?, ?, ?)",
                { dataflow_id, "keeper.test", "test_workflow", "completed", now, now }
            )
            must_exec(db,
                "INSERT INTO dataflow_nodes (node_id, dataflow_id, type, status, created_at, updated_at) " ..
                "VALUES (?, ?, ?, ?, ?, ?)",
                { node_id, dataflow_id, "userspace.dataflow.node.agent:node", "completed", now, now }
            )
            must_exec(db,
                "INSERT INTO dataflow_data " ..
                "(data_id, dataflow_id, node_id, type, key, content, content_type, created_at) " ..
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                { answer_id, dataflow_id, node_id, "agent.delegation", "delegation_result_1",
                  "the delegate's answer", "text/plain", now }
            )
            must_exec(db,
                "INSERT INTO dataflow_data " ..
                "(data_id, dataflow_id, node_id, type, key, content, content_type, created_at) " ..
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                { uuid.v7(), dataflow_id, node_id, "agent.observation", answer_id, "",
                  "dataflow/reference", now }
            )
            db:release()
            prepared = true
        end

        after_all(function()
            if not created then return end
            local db = must_db()
            db:execute("DELETE FROM dataflow_data WHERE dataflow_id = ?", { dataflow_id })
            db:execute("DELETE FROM dataflow_nodes WHERE dataflow_id = ?", { dataflow_id })
            db:execute("DELETE FROM dataflows WHERE dataflow_id = ?", { dataflow_id })
            db:release()
        end)

        it("node_data resolves a delegation observation to the child's content", function()
            prepare()
            local rows = repo.node_data(dataflow_id, node_id, { types = { "agent.observation" } })
            test.eq(#rows, 1)
            test.eq(rows[1].content, "the delegate's answer")
        end)

        it("flow_data resolves a delegation observation to the child's content", function()
            prepare()
            local rows = repo.flow_data(dataflow_id, { types = { "agent.observation" } })
            test.eq(#rows, 1)
            test.eq(rows[1].content, "the delegate's answer")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
