local test = require("test")

local kb_read = require("kb_read")
local kb_write = require("kb_write")

local function define_tests()
    describe("Knowledge Tools", function()
        describe("kb_read", function()
            it("requires action parameter", function()
                local result, err = kb_read.handler({})
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects unknown action", function()
                local result, err = kb_read.handler({ action = "invalid" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("search action requires query", function()
                local result, err = kb_read.handler({ action = "search" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("search action rejects empty query", function()
                local result, err = kb_read.handler({ action = "search", query = "" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("semantic action requires query", function()
                local result, err = kb_read.handler({ action = "semantic" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("semantic action uses embedding service and formats distances", function()
                local captured
                local old = kb_read._set_deps({
                    kb_repo = {},
                    kb_service = {
                        search_semantic = function(params)
                            captured = params
                            return {
                                model = "text-embedding-test",
                                nodes = {
                                    {
                                        id = "12345678-aaaa-bbbb-cccc-123456789abc",
                                        title = "Context inheritance",
                                        node_type = "pattern",
                                        content = "Arena context becomes config.context.",
                                        refs = { "keeper.task:scope" },
                                        distance = 0.12,
                                    },
                                },
                            }
                        end,
                    },
                    summarize = {
                        summarize = function(result)
                            return result, nil, false
                        end,
                    },
                })
                local result, err = kb_read.handler({
                    action = "semantic",
                    query = "agent context",
                    kb = "Keeper",
                    limit = 3,
                    full = true,
                })
                kb_read._set_deps(old)

                test.is_nil(err)
                test.eq(captured.query, "agent context")
                test.eq(captured.kb, "Keeper")
                test.eq(captured.limit, 3)
                test.is_true(result:find("Semantic search results", 1, true) ~= nil)
                test.is_true(result:find("distance:0.12", 1, true) ~= nil)
                test.is_true(result:find("text-embedding-test", 1, true) ~= nil)
            end)

            it("get action requires node_id", function()
                local result, err = kb_read.handler({ action = "get" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("list_kbs returns result", function()
                local result, err = kb_read.handler({ action = "list_kbs" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
            end)

            it("list returns result", function()
                local result, err = kb_read.handler({ action = "list" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
            end)
        end)

        describe("kb_write", function()
            it("requires action parameter", function()
                local result, err = kb_write.handler({})
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects unknown action", function()
                local result, err = kb_write.handler({ action = "invalid" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("create requires title", function()
                local result, err = kb_write.handler({ action = "create", node_type = "pattern" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("create requires node_type", function()
                local result, err = kb_write.handler({ action = "create", title = "Test" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("create rejects empty title", function()
                local result, err = kb_write.handler({ action = "create", title = "", node_type = "pattern" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("update requires node_id", function()
                local result, err = kb_write.handler({ action = "update", title = "Updated" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("delete requires node_id", function()
                local result, err = kb_write.handler({ action = "delete" })
                test.is_nil(result)
                test.not_nil(err)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
