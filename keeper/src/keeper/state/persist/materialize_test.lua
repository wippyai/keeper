local test = require("test")
local materialize = require("materialize")

local function define_tests()
    describe("State Materialize", function()
        -- Factory functions: materialize.entry() mutates its input (replaces
        -- inline source with file:// reference), so each test needs a fresh copy.
        local function simple_entry()
            return {
                id = "test.ns:my_func",
                kind = "function.lua",
                meta = { type = "handler", comment = "Test function" },
                data = {
                    source = "print('hello')",
                    method = "run",
                    modules = { "json" },
                    imports = {
                        helper = "test.ns:helper_lib",
                    },
                },
            }
        end

        local function bare_entry()
            return {
                id = "test.ns:bare",
                kind = "library.lua",
                meta = {},
                data = {
                    source = "return {}",
                },
            }
        end

        describe("entry", function()
            it("produces valid state entry with required fields", function()
                local result, err = materialize.entry(simple_entry())
                test.is_nil(err)
                test.not_nil(result)
                test.eq(result.id, "test.ns:my_func")
                test.eq(result.kind, "function.lua")
                test.not_nil(result.definition)
                test.not_nil(result.definition_hash)
            end)

            it("extracts inline source as content", function()
                local result, err = materialize.entry(simple_entry())
                test.is_nil(err)
                test.not_nil(result)
                test.not_nil(result.content)
                test.eq(result.content, "print('hello')")
                test.not_nil(result.content_hash)
            end)

            it("populates attributes from meta", function()
                local result, err = materialize.entry(simple_entry())
                test.is_nil(err)
                test.not_nil(result)
                test.not_nil(result.attributes)
                test.eq(result.attributes["meta.type"], "handler")
                test.eq(result.attributes["meta.comment"], "Test function")
            end)

            it("handles entry with empty meta", function()
                local entry = {
                    id = "test.ns:no_meta",
                    kind = "library.lua",
                    meta = {},
                    data = { source = "return {}" },
                }
                local result, err = materialize.entry(entry)
                test.is_nil(err)
                test.not_nil(result)
                test.not_nil(result.definition)
            end)

            it("returns error for nil entry", function()
                local result, err = materialize.entry(nil)
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("returns error for entry missing id", function()
                local result, err = materialize.entry({ kind = "library.lua" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("returns error for invalid id format", function()
                local result, err = materialize.entry({ id = "nocolon", kind = "library.lua" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("does not extract content when source is file:// reference", function()
                local entry = {
                    id = "test.ns:file_ref",
                    kind = "function.lua",
                    data = { source = "file://file_ref.lua" },
                }
                local result, err = materialize.entry(entry)
                test.is_nil(err)
                test.not_nil(result)
                test.is_nil(result.content)
                test.is_nil(result.content_hash)
            end)
        end)

        describe("extract_edges", function()
            it("extracts imports edges", function()
                local edges = materialize.extract_edges(simple_entry())
                test.not_nil(edges)

                local found_import = false
                for _, edge in ipairs(edges) do
                    if edge.edge_type == "imports" and edge.target_id == "test.ns:helper_lib" then
                        found_import = true
                        test.eq(edge.source_id, "test.ns:my_func")
                    end
                end
                test.is_true(found_import)
            end)

            it("extracts uses edges for modules", function()
                local edges = materialize.extract_edges(simple_entry())
                test.not_nil(edges)

                local found_module = false
                for _, edge in ipairs(edges) do
                    if edge.edge_type == "uses" and edge.target_id == "json" then
                        found_module = true
                    end
                end
                test.is_true(found_module)
            end)

            it("returns empty for entry with no dependencies", function()
                local entry = {
                    id = "test.ns:lonely",
                    kind = "library.lua",
                    meta = {},
                    data = {},
                }
                local edges = materialize.extract_edges(entry)
                test.not_nil(edges)
                test.eq(#edges, 0)
            end)

            it("returns empty for nil entry", function()
                local edges = materialize.extract_edges(nil)
                test.not_nil(edges)
                test.eq(#edges, 0)
            end)

            it("resolves local imports to full namespace", function()
                local entry = {
                    id = "myapp.core:service",
                    kind = "function.lua",
                    data = {
                        imports = {
                            util = "myapp.core:util",
                            remote = "other.ns:lib",
                        },
                    },
                }
                local edges = materialize.extract_edges(entry)
                local targets = {}
                for _, edge in ipairs(edges) do
                    if edge.edge_type == "imports" then
                        targets[edge.target_id] = true
                    end
                end
                test.is_true(targets["myapp.core:util"])
                test.is_true(targets["other.ns:lib"])
            end)
        end)

        describe("edges_to_commands", function()
            it("produces set_edge commands", function()
                local edges = {
                    {
                        source_id = "a:b",
                        target_id = "c:d",
                        edge_type = "imports",
                        metadata = {},
                    },
                }
                local cmds = materialize.edges_to_commands(edges, "main")
                test.not_nil(cmds)
                test.eq(#cmds, 1)
                test.eq(cmds[1].type, "set_edge")
                test.eq(cmds[1].payload.source_id, "a:b")
                test.eq(cmds[1].payload.target_id, "c:d")
                test.eq(cmds[1].payload.edge_type, "imports")
                test.eq(cmds[1].payload.branch, "main")
            end)

            it("skips edges with empty fields", function()
                local edges = {
                    { source_id = "", target_id = "c:d", edge_type = "imports", metadata = {} },
                    { source_id = "a:b", target_id = "", edge_type = "imports", metadata = {} },
                    { source_id = "a:b", target_id = "c:d", edge_type = "", metadata = {} },
                }
                local cmds = materialize.edges_to_commands(edges, "main")
                test.not_nil(cmds)
                test.eq(#cmds, 0)
            end)

            it("returns empty for empty edges list", function()
                local cmds = materialize.edges_to_commands({}, "main")
                test.not_nil(cmds)
                test.eq(#cmds, 0)
            end)
        end)

        describe("format_entry_structured", function()
            it("returns a string for entry with chunks", function()
                local entry = {
                    id = "test.ns:formatted",
                    kind = "function.lua",
                    chunks = {
                        {
                            type = "definition",
                            content = "version: \"1.0\"\nnamespace: test.ns\n\nentries:\n  # test.ns:formatted\n  - name: formatted\n    kind: function.lua\n    source: file://formatted.lua",
                        },
                        {
                            type = "content",
                            content = "return 42",
                        },
                    },
                }
                local result = materialize.format_entry_structured(entry, true)
                test.not_nil(result)
                test.eq(type(result), "string")
                test.is_true(result:find("definition") ~= nil)
                test.is_true(result:find("source") ~= nil)
                test.is_true(result:find("return 42") ~= nil)
            end)

            it("returns nil for nil entry", function()
                local result = materialize.format_entry_structured(nil)
                test.is_nil(result)
            end)

            it("returns nil for entry without id", function()
                local result = materialize.format_entry_structured({ kind = "library.lua" })
                test.is_nil(result)
            end)
        end)

        describe("state_entry_to_registry", function()
            it("round-trips basic fields", function()
                local state, err = materialize.entry(bare_entry())
                test.is_nil(err)
                test.not_nil(state)

                local state_with_chunks = {
                    id = state.id,
                    kind = state.kind,
                    chunks = {
                        { type = "definition", content = state.definition },
                    },
                }
                if state.content then
                    table.insert(state_with_chunks.chunks, {
                        type = "content",
                        content = state.content,
                    })
                end

                local registry_entry, rt_err = materialize.state_entry_to_registry(state_with_chunks)
                test.is_nil(rt_err)
                test.not_nil(registry_entry)
                test.eq(registry_entry.id, "test.ns:bare")
                test.eq(registry_entry.kind, "library.lua")
            end)

            it("restores source content from chunks", function()
                local state, err = materialize.entry(simple_entry())
                test.is_nil(err)
                test.not_nil(state)

                local state_with_chunks = {
                    id = state.id,
                    kind = state.kind,
                    chunks = {
                        { type = "definition", content = state.definition },
                        { type = "content", content = state.content },
                    },
                }

                local registry_entry, rt_err = materialize.state_entry_to_registry(state_with_chunks)
                test.is_nil(rt_err)
                test.not_nil(registry_entry)
                test.eq((registry_entry :: any).data.source, state.content)
            end)

            it("puts non-meta YAML fields under entry.data", function()
                local registry_entry, rt_err = materialize.state_entry_to_registry({
                    id = "test.ns:probe.endpoint",
                    kind = "http.endpoint",
                    chunks = {
                        { type = "definition", content = [[
version: "1.0"
namespace: test.ns
entries:
  - name: probe.endpoint
    kind: http.endpoint
    meta:
      router: app:api
    method: POST
    path: /probe
    func: probe
]] },
                    },
                })
                test.is_nil(rt_err)
                test.not_nil(registry_entry)
                test.eq((registry_entry :: any).meta.router, "app:api")
                test.eq((registry_entry :: any).data.method, "POST")
                test.eq((registry_entry :: any).data.path, "/probe")
                test.eq((registry_entry :: any).data.func, "probe")
                test.is_nil((registry_entry :: any).method)
                test.is_nil((registry_entry :: any).path)
            end)

            it("returns error for nil state entry", function()
                local result, err = materialize.state_entry_to_registry(nil)
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("returns error for state entry without definition chunk", function()
                local result, err = materialize.state_entry_to_registry({
                    id = "x:y",
                    kind = "library.lua",
                    chunks = {},
                })
                test.is_nil(result)
                test.not_nil(err)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
