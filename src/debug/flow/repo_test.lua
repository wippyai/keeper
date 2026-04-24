local test = require("test")
local json = require("json")
local repo = require("repo")

local function define_tests()
    describe("Flow repo pure helpers", function()

        describe("decode_content", function()
            it("returns nil when content is absent", function()
                test.is_nil(repo.decode_content({}))
            end)

            it("decodes JSON when content_type is application/json", function()
                local out = repo.decode_content({
                    content_type = "application/json",
                    content      = json.encode({ a = 1 }),
                })
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
                test.eq(chain[1].node_id, "leaf")
                test.eq(chain[2].node_id, "mid")
                test.eq(chain[3].node_id, "root")
            end)

            it("handles root-only node", function()
                local chain = repo.ancestors(nodes, "root")
                test.eq(#chain, 1)
            end)

            it("stops on empty-string parent", function()
                local chain = repo.ancestors(nodes, "orphan")
                test.eq(#chain, 1)
                test.eq(chain[1].node_id, "orphan")
            end)

            it("returns empty when node_id is unknown", function()
                local chain = repo.ancestors(nodes, "ghost")
                test.eq(#chain, 0)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
