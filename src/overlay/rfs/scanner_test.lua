local test = require("test")
local scanner = require("scanner")

local function define_tests()
    describe("Scanner Module", function()
        local mock_rfs_reader

        before_each(function()
            -- Create comprehensive mock RFS reader
            mock_rfs_reader = {
                get_tree = function()
                    return {
                        namespaces = {
                            {
                                namespace = "keeper.demo",
                                files = {"_index.yaml", "hello_tool.lua", "config_lib.lua"}
                            },
                            {
                                namespace = "keeper.utils",
                                files = {"_index.yaml", "string_utils.lua"}
                            }
                        }
                    }, nil
                end,

                read_file = function(_self, file_path)
                    -- Ensure file_path is a string
                    if type(file_path) ~= "string" then
                        return {error = "Invalid file_path type: expected string, got " .. type(file_path)}
                    end

                    local mock_files = {
                        ["keeper/demo/_index.yaml"] = {
                            content = [[version: "1.0"
namespace: keeper.demo

entries:
  - name: hello_tool
    kind: function.lua
    meta:
      type: tool
      title: "Hello Tool"
      description: "A simple greeting tool"
    source: file://hello_tool.lua
    modules: ["json"]

  - name: config_lib
    kind: library.lua
    meta:
      comment: "Configuration library"
    source: file://config_lib.lua]],
            status = "clean",
            writable = false,
            entry_id = nil,
            entry_kind = nil,
            entry_meta = {}
                        },

                        ["keeper/demo/hello_tool.lua"] = {
                            content = [[local function handler(params)
    -- TODO: Add input validation
    return 'Hello ' .. (params.name or 'World')
end

function setup_config()
    local config = require("config")
    return config.default_timeout
end

return {handler = handler, setup = setup_config}]],
                            status = "clean",
                            writable = false,
                            entry_id = "keeper.demo:hello_tool",
                            entry_kind = "function.lua",
                            entry_meta = {}
                        },

                        ["keeper/demo/config_lib.lua"] = {
                            content = [[local config = {}

-- Default configuration values
config.default_timeout = 30
config.max_retries = 3
config.debug_mode = false

function config.validate()
    -- FIXME: Implement proper validation
    return true
end

return config]],
                            status = "clean",
                            writable = false,
                            entry_id = "keeper.demo:config_lib",
                            entry_kind = "library.lua",
                            entry_meta = {}
                        },

                        ["keeper/utils/_index.yaml"] = {
                            content = [[version: "1.0"
namespace: keeper.utils

entries:
  - name: string_utils
    kind: library.lua
    meta:
      comment: "String utility functions"
    source: file://string_utils.lua]],
                            status = "clean",
                            writable = false,
                            entry_id = nil,
                            entry_kind = nil,
                            entry_meta = {}
                        },

                        ["keeper/utils/string_utils.lua"] = {
                            content = [[local string_utils = {}

function string_utils.trim(str)
    return str:match("^%s*(.-)%s*$")
end

function string_utils.split(str, delimiter)
    local result = {}
    for token in str:gmatch("[^" .. delimiter .. "]+") do
        table.insert(result, token)
    end
    return result
end

return string_utils]],
                            status = "clean",
                            writable = false,
                            entry_id = "keeper.utils:string_utils",
                            entry_kind = "library.lua",
                            entry_meta = {}
                        }
                    }

                    local file_data = mock_files[file_path]
                    if file_data then
                        return file_data
                    else
                        return {error = "File not found: " .. tostring(file_path)}
                    end
                end
            }
        end)

        describe("scanner creation and initialization", function()
            it("should create scanner with RFS reader", function()
                local scan, err = scanner.new(mock_rfs_reader)

                expect(err).to_be_nil()
                expect(scan).not_to_be_nil()
                expect(scan:is_built()).to_be_false()
            end)

            it("should require RFS reader", function()
                local scan, err = scanner.new(nil)

                expect(scan).to_be_nil()
                expect(err).to_equal("RFS reader is required")
            end)
        end)

        describe("index building", function()
            it("should build index from all files in RFS reader", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()

                local result, build_err = scan:build_index()
                expect(build_err).to_be_nil()
                expect(result).to_equal(scan)
                expect(scan:is_built()).to_be_true()

                local stats = scan:get_stats()
                expect(stats.built).to_be_true()
                expect(stats.total_files).to_equal(5) -- 2 _index.yaml + 3 source files
                expect(stats.total_lines).to_be_greater_than(0)
            end)

            it("should handle rebuild gracefully", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()

                scan:build_index()
                local first_stats = scan:get_stats()

                scan:rebuild_index()
                local second_stats = scan:get_stats()

                expect(first_stats.total_files).to_equal(second_stats.total_files)
                expect(scan:is_built()).to_be_true()
            end)

            it("should return self for method chaining", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()

                local result, build_err = scan:build_index()
                expect(build_err).to_be_nil()
                expect(result).to_equal(scan)
            end)
        end)

        describe("literal string search", function()
            it("should find exact string matches", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local results, search_err = scan:search({
                    hello_text = "Hello",
                    function_keyword = "function",
                    config_word = "config"
                })
                expect(search_err).to_be_nil()

                expect(results.hello_text).not_to_be_nil()
                expect(#results.hello_text).to_be_greater_than(0)

                -- Find the match in hello_tool.lua (not necessarily first due to sorting)
                local hello_tool_match = nil
                for _, match in ipairs(results.hello_text) do
                    if match.file_path == "keeper/demo/hello_tool.lua" then
                        hello_tool_match = match
                        break
                    end
                end
                expect(hello_tool_match).not_to_be_nil()
                expect(hello_tool_match.match_text).to_equal("Hello")
                expect(hello_tool_match.line).to_equal(3)

                expect(#results.function_keyword).to_be_greater_than(0)
                expect(#results.config_word).to_be_greater_than(0)
            end)

            it("should find matches in YAML files", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local results, search_err = scan:search({
                    yaml_version = 'version: "1.0"',
                    tool_type = "type: tool"
                })
                expect(search_err).to_be_nil()

                expect(#results.yaml_version).to_equal(2) -- Both _index.yaml files
                expect(#results.tool_type).to_equal(1) -- Only hello_tool has type: tool

                local tool_match = results.tool_type[1]
                expect(tool_match.file_path).to_equal("keeper/demo/_index.yaml")
                expect(tool_match.match_text).to_equal("type: tool")
            end)

            it("should provide context around matches", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local results, search_err = scan:search({
                    todo_comment = "TODO:"
                })
                expect(search_err).to_be_nil()

                expect(#results.todo_comment).to_equal(1)
                local match = results.todo_comment[1]

                -- Now do the actual checks
                expect(match.context:find("TODO:")).not_to_be_nil()
                expect(match.context:find("Add input validation")).not_to_be_nil()
                expect(match.context:find("return")).not_to_be_nil()
            end)
        end)

        describe("regex pattern search", function()
            it("should find regex pattern matches", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local results, search_err = scan:search({
                    function_definitions = {regex = "function%s+%w+"},  -- Lua pattern syntax
                    comments = {regex = "%-%-.*"},                      -- Lua pattern syntax
                    yaml_keys = {regex = "%w+:"}                       -- Lua pattern syntax
                })
                expect(search_err).to_be_nil()

                expect(#results.function_definitions).to_be_greater_than(0)
                expect(#results.comments).to_be_greater_than(0)
                expect(#results.yaml_keys).to_be_greater_than(0)

                -- Check function definition match
                local func_match = nil
                for _, match in ipairs(results.function_definitions) do
                    if match.match_text:find("function handler") then
                        func_match = match
                        break
                    end
                end
                expect(func_match).not_to_be_nil()
                expect(func_match.file_path).to_equal("keeper/demo/hello_tool.lua")
            end)

            it("should handle complex regex patterns", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local results, search_err = scan:search({
                    require_statements = {regex = 'require%(".-"%)'}, -- Lua pattern syntax
                    variable_assignments = {regex = "%w+%s*=%s*%w+"}, -- Lua pattern syntax
                    fixme_comments = {regex = "FIXME:.*"}
                })
                expect(search_err).to_be_nil()

                expect(#results.require_statements).to_be_greater_than(0)
                expect(#results.variable_assignments).to_be_greater_than(0)
                expect(#results.fixme_comments).to_equal(1)

                local fixme_match = results.fixme_comments[1]
                expect(fixme_match.file_path).to_equal("keeper/demo/config_lib.lua")
                expect(fixme_match.match_text:find("FIXME: Implement proper validation")).not_to_be_nil()
            end)
        end)

        describe("multiple searches on same index", function()
            it("should reuse index for multiple search calls", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                -- First search
                local results1, err1 = scan:search({
                    first_search = "function"
                })
                expect(err1).to_be_nil()

                -- Second search
                local results2, err2 = scan:search({
                    second_search = "config"
                })
                expect(err2).to_be_nil()

                -- Third search with multiple queries
                local results3, err3 = scan:search({
                    functions = {regex = "function%s+%w+"},
                    comments = "--"
                })
                expect(err3).to_be_nil()

                expect(#results1.first_search).to_be_greater_than(0)
                expect(#results2.second_search).to_be_greater_than(0)
                expect(#results3.functions).to_be_greater_than(0)
                expect(#results3.comments).to_be_greater_than(0)
            end)

            it("should maintain consistent results across searches", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local results1, err1 = scan:search({test_query = "Hello"})
                expect(err1).to_be_nil()
                local results2, err2 = scan:search({test_query = "Hello"})
                expect(err2).to_be_nil()

                expect(#results1.test_query).to_equal(#results2.test_query)
                if #results1.test_query > 0 then
                    expect(results1.test_query[1].line).to_equal(results2.test_query[1].line)
                    expect(results1.test_query[1].file_path).to_equal(results2.test_query[1].file_path)
                end
            end)
        end)

        describe("search result structure", function()
            it("should return results with correct structure", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local results, search_err = scan:search({
                    test_search = "function"
                })
                expect(search_err).to_be_nil()

                expect(results.test_search).not_to_be_nil()
                expect(type(results.test_search)).to_equal("table")

                if #results.test_search > 0 then
                    local match = results.test_search[1]
                    expect(match.file_path).not_to_be_nil()
                    expect(match.line).not_to_be_nil()
                    expect(match.match_text).not_to_be_nil()
                    expect(match.context).not_to_be_nil()
                    expect(type(match.line)).to_equal("number")
                end
            end)

            it("should sort results by file path and line number", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local results, search_err = scan:search({
                    common_word = "config" -- appears in multiple files
                })
                expect(search_err).to_be_nil()

                local matches = results.common_word
                expect(#matches).to_be_greater_than(1)

                -- Check sorting
                for i = 2, #matches do
                    local prev_match = matches[i-1]
                    local curr_match = matches[i]

                    if prev_match.file_path == curr_match.file_path then
                        expect(prev_match.line).to_be_less_than_or_equal(curr_match.line)
                    else
                        expect(prev_match.file_path < curr_match.file_path).to_be_true()
                    end
                end
            end)
        end)

        describe("error handling", function()
            it("should require index to be built before searching", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()

                local results, search_err = scan:search({test = "something"})
                expect(results).to_be_nil()
                expect(search_err).to_match("Index must be built before searching")
            end)

            it("should validate search query format", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local results1, err1 = scan:search("invalid_format")
                expect(results1).to_be_nil()
                expect(err1).to_match("Queries must be a table")

                local results2, err2 = scan:search({invalid_query = {not_regex = "pattern"}})
                expect(results2).to_be_nil()
                expect(err2).to_match("Invalid query pattern")
            end)

            it("should handle empty search results gracefully", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local results, search_err = scan:search({
                    nonexistent = "this_text_does_not_exist_anywhere"
                })
                expect(search_err).to_be_nil()

                expect(results.nonexistent).not_to_be_nil()
                expect(#results.nonexistent).to_equal(0)
            end)
        end)

        describe("integration scenarios", function()
            it("should handle mixed literal and regex queries", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local results, search_err = scan:search({
                    literal_hello = "Hello",
                    regex_functions = {regex = "function%s+%w+"},
                    literal_config = "config",
                    regex_comments = {regex = "%-%-.*TODO.*"}
                })
                expect(search_err).to_be_nil()

                expect(#results.literal_hello).to_be_greater_than(0)
                expect(#results.regex_functions).to_be_greater_than(0)
                expect(#results.literal_config).to_be_greater_than(0)
                expect(#results.regex_comments).to_be_greater_than(0)
            end)

            it("should provide useful statistics", function()
                local scan, err = scanner.new(mock_rfs_reader)
                expect(err).to_be_nil()
                scan:build_index()

                local stats = scan:get_stats()
                expect(stats.built).to_be_true()
                expect(stats.total_files).to_be_greater_than(0)
                expect(stats.total_lines).to_be_greater_than(0)
            end)
        end)
    end)
end

return test.run_cases(define_tests)