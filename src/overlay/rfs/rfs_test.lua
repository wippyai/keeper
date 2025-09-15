local test = require("test")
local rfs = require("rfs")

local function define_tests()
    describe("RFS Module", function()
        local original_deps

        before_each(function()
            -- Save original deps and replace with comprehensive mocks
            original_deps = rfs._deps
            rfs._deps = {
                registry = {
                    snapshot = function()
                        return {
                            entries = function()
                                return {
                                    {
                                        id = "keeper.demo:hello_tool",
                                        kind = "function.lua",
                                        meta = {type = "tool", title = "Hello Tool"},
                                        data = {
                                            source = "local function handler(params)\n    return 'Hello ' .. (params.name or 'World')\nend\nreturn {handler = handler}",
                                            modules = {"json"}
                                        }
                                    },
                                    {
                                        id = "keeper.demo:config_lib",
                                        kind = "library.lua",
                                        meta = {comment = "Configuration library"},
                                        data = {
                                            source = "local config = {}\nconfig.default_timeout = 30\nreturn config"
                                        }
                                    }
                                }, nil
                            end
                        }, nil
                    end,
                    get = function(entry_id)
                        if entry_id == "keeper.demo:hello_tool" then
                            return {
                                id = "keeper.demo:hello_tool",
                                kind = "function.lua",
                                meta = {type = "tool", title = "Hello Tool"},
                                data = {source = "registry hello content"}
                            }, nil
                        end
                        return nil, "Entry not found"
                    end
                },
                snapshot = {
                    get_namespace_snapshot = function(session, namespace)
                        if namespace == "keeper.demo" then
                            return {
                                {
                                    id = "keeper.demo:hello_tool",
                                    kind = "function.lua",
                                    meta = {type = "tool", title = "Hello Tool"},
                                    data = {source = "workspace hello content"}
                                }
                            }, nil
                        end
                        return nil, "Namespace not found: " .. namespace
                    end,
                    get_full_snapshot = function(session)
                        return {
                            ["keeper.demo"] = {
                                {
                                    id = "keeper.demo:hello_tool",
                                    kind = "function.lua",
                                    meta = {type = "tool", title = "Hello Tool"},
                                    data = {source = "workspace hello content"}
                                }
                            }
                        }, nil
                    end
                },
                ns = {
                    new = function(namespace, entries)
                        return {
                            list_files = function()
                                return {"_index.yaml", "hello_tool.lua", "config_lib.lua"}
                            end,
                            to_yaml = function()
                                return "version: \"1.0\"\nnamespace: " .. namespace .. "\n\nentries:\n  - name: hello_tool\n    kind: function.lua", nil
                            end,
                            file_exists = function(self, filename)
                                local files = {"_index.yaml", "hello_tool.lua", "config_lib.lua"}
                                for _, file in ipairs(files) do
                                    if file == filename then return true end
                                end
                                return false
                            end
                        }
                    end,
                    get_file_config = function(entry)
                        if entry.kind == "function.lua" or entry.kind == "library.lua" then
                            return {source_field = "source", extension = ".lua"}
                        end
                        return nil
                    end,
                    generate_filename = function(entry_name, config)
                        return entry_name .. config.extension
                    end,
                    extract_filename_from_url = function(url)
                        return url:match("^file://(.+)$")
                    end,
                    extract_source_content = function(entry)
                        if entry.data and entry.data.source then
                            return entry.data.source, nil
                        end
                        return nil, "No source content"
                    end
                },
                consts = {
                    RFS = {
                        FILE_STATUS = {
                            CLEAN = "clean",
                            MODIFIED = "modified",
                            NEW = "new",
                            DELETED = "deleted"
                        },
                        PATH = {
                            INDEX_FILENAME = "_index.yaml",
                            NAMESPACE_SEPARATOR = ".",
                            PATH_SEPARATOR = "/",
                            FILE_PROTOCOL = "file://"
                        },
                        RFS_ERROR = {
                            INVALID_PATH_FORMAT = "Invalid path format, expected: namespace/filename",
                            NAMESPACE_NOT_FOUND = "Namespace not found",
                            FILE_NOT_FOUND = "File not found"
                        }
                    },
                    ENTRY_OPERATION_TYPE = {
                        CREATE = "create",
                        UPDATE = "update",
                        DELETE = "delete"
                    },
                    ERROR = {
                        DB_CONNECTION_FAILED = "Failed to connect to database",
                        DB_OPERATION_FAILED = "Database operation failed"
                    }
                }
            }
        end)

        after_each(function()
            -- Restore original deps
            rfs._deps = original_deps
        end)

        describe("fluent API", function()
            it("should create reader with default settings", function()
                local reader = rfs.reader()

                expect(reader._session).to_be_nil()
                expect(reader._include_meta).to_be_true()
                expect(reader._include_status).to_be_true()
            end)

            it("should chain configuration methods immutably", function()
                local mock_session = {
                    get_dirty_entries = function() return {}, nil end,
                    get_workspace = function() return nil, nil end
                }

                local base = rfs.reader()
                local workspace = base:from_workspace(mock_session)
                local no_meta = workspace:include_meta(false)
                local no_status = no_meta:include_status(false)

                -- Original should be unchanged
                expect(base._session).to_be_nil()
                expect(base._include_meta).to_be_true()
                expect(base._include_status).to_be_true()

                -- Workspace reader should have session
                expect(workspace._session).to_equal(mock_session)
                expect(workspace._include_meta).to_be_true()
                expect(workspace._include_status).to_be_true()

                -- No meta reader should have session but no meta
                expect(no_meta._session).to_equal(mock_session)
                expect(no_meta._include_meta).to_be_false()
                expect(no_meta._include_status).to_be_true()

                -- Final reader should have all modifications
                expect(no_status._session).to_equal(mock_session)
                expect(no_status._include_meta).to_be_false()
                expect(no_status._include_status).to_be_false()
            end)

            it("should switch between workspace and registry modes", function()
                local mock_session = {
                    get_dirty_entries = function() return {}, nil end
                }

                local workspace_reader = rfs.reader():from_workspace(mock_session)
                local registry_reader = workspace_reader:from_registry()

                expect(workspace_reader._session).to_equal(mock_session)
                expect(registry_reader._session).to_be_nil()
            end)
        end)

        describe("path parsing", function()
            it("should parse simple namespace/filename paths correctly", function()
                local reader = rfs.reader()
                local result = reader:read_file("keeper.demo/hello_tool.lua")

                expect(result).not_to_be_nil()
                expect(result.error).to_be_nil()
                expect(result.content).to_contain("Hello")
                expect(result.entry_id).to_equal("keeper.demo:hello_tool")
            end)

            it("should handle nonexistent namespace gracefully", function()
                local reader = rfs.reader()
                local result = reader:read_file("keeper.overlay.agents/chat_agent.lua")

                expect(result).not_to_be_nil()
                expect(result.error).to_match("Namespace not found")
            end)

            it("should reject invalid path formats", function()
                local reader = rfs.reader()

                local invalid_paths = {
                    "no_slash",
                    "",
                    "just_filename.lua"
                }

                for _, invalid_path in ipairs(invalid_paths) do
                    local result = reader:read_file(invalid_path)
                    expect(result.error).to_match("Invalid path format")
                end
            end)
        end)

        describe("file reading operations", function()
            it("should read single file with complete metadata", function()
                local reader = rfs.reader():include_meta(true)
                local result = reader:read_file("keeper.demo/hello_tool.lua")

                expect(result.content).to_contain("Hello")
                expect(result.status).to_equal("clean")
                expect(result.writable).to_be_false() -- registry mode = read-only
                expect(result.entry_id).to_equal("keeper.demo:hello_tool")
                expect(result.entry_kind).to_equal("function.lua")
                expect(result.entry_meta.type).to_equal("tool")
                expect(result.entry_meta.title).to_equal("Hello Tool")
            end)

            it("should read _index.yaml files", function()
                local reader = rfs.reader()
                local result = reader:read_file("keeper.demo/_index.yaml")

                expect(result.content).to_contain("namespace: keeper.demo")
                expect(result.entry_id).to_be_nil() -- _index.yaml doesn't map to single entry
                expect(result.entry_kind).to_be_nil()
            end)

            it("should handle missing files", function()
                local reader = rfs.reader()
                local result = reader:read_file("keeper.demo/nonexistent.lua")

                expect(result.error).to_match("File not found")
            end)
        end)

        describe("workspace vs registry modes", function()
            it("should use workspace content when session provided", function()
                local mock_session = {
                    get_dirty_entries = function() return {}, nil end,
                    get_workspace = function() return nil, nil end
                }

                local workspace_reader = rfs.reader():from_workspace(mock_session)
                local registry_reader = rfs.reader():from_registry()

                local ws_result = workspace_reader:read_file("keeper.demo/hello_tool.lua")
                local reg_result = registry_reader:read_file("keeper.demo/hello_tool.lua")

                expect(ws_result.content).to_equal("workspace hello content")
                expect(ws_result.writable).to_be_true() -- workspace mode = writable
                expect(reg_result.content).to_contain("Hello")
                expect(reg_result.writable).to_be_false() -- registry mode = read-only
            end)
        end)

        describe("file operations", function()
            it("should list files in namespace", function()
                local reader = rfs.reader()
                local result = reader:list_files("keeper.demo")

                expect(result).not_to_be_nil()
                expect(result.namespace).to_equal("keeper.demo")
                expect(#result.files).to_equal(3) -- Check length using # operator

                local file_names = {}
                for _, file in ipairs(result.files) do
                    file_names[file.name] = true
                end
                expect(file_names["_index.yaml"]).to_be_true()
                expect(file_names["hello_tool.lua"]).to_be_true()
                expect(file_names["config_lib.lua"]).to_be_true()
            end)

            it("should check if file exists", function()
                local reader = rfs.reader()

                local exists1, err1 = reader:file_exists("keeper.demo/hello_tool.lua")
                local exists2, err2 = reader:file_exists("keeper.demo/nonexistent.lua")

                expect(exists1).to_be_true()
                expect(err1).to_be_nil()
                expect(exists2).to_be_false()
                expect(err2).to_be_nil()
            end)

            it("should check if namespace exists", function()
                local reader = rfs.reader()

                local exists1, err1 = reader:namespace_exists("keeper.demo")
                local exists2, err2 = reader:namespace_exists("nonexistent.namespace")

                expect(exists1).to_be_true()
                expect(err1).to_be_nil()
                expect(exists2).to_be_false()
                expect(err2).not_to_be_nil()
            end)

            it("should get tree structure for workspace", function()
                local mock_session = {
                    get_dirty_entries = function() return {}, nil end
                }

                local reader = rfs.reader():from_workspace(mock_session)
                local tree, err = reader:get_tree("keeper")

                expect(err).to_be_nil()
                expect(tree.root).to_equal("keeper")
                expect(#tree.namespaces).to_equal(1) -- Check length using # operator
                expect(tree.namespaces[1].namespace).to_equal("keeper.demo")
                expect(tree.namespaces[1].entry_count).to_equal(1)

                local has_index = false
                for _, file in ipairs(tree.namespaces[1].files) do
                    if file == "_index.yaml" then
                        has_index = true
                        break
                    end
                end
                expect(has_index).to_be_true()
            end)

            it("should get root tree for registry", function()
                local reader = rfs.reader()
                local tree, err = reader:get_tree()

                expect(err).to_be_nil()
                expect(tree.root).to_equal(".")
                expect(type(tree.namespaces)).to_equal("table")
            end)
        end)

        describe("configuration options", function()
            it("should respect include_meta setting", function()
                local reader_with_meta = rfs.reader():include_meta(true)
                local reader_without_meta = rfs.reader():include_meta(false)

                local result1 = reader_with_meta:read_file("keeper.demo/hello_tool.lua")
                local result2 = reader_without_meta:read_file("keeper.demo/hello_tool.lua")

                expect(result1.entry_meta.title).to_equal("Hello Tool")
                expect(#result2.entry_meta).to_equal(0) -- Check that meta is empty table
            end)

            it("should allow independent configuration chains", function()
                local base = rfs.reader()

                local config1 = base:include_meta(false):include_status(false)
                local config2 = base:include_meta(true):include_status(true)

                expect(base._include_meta).to_be_true()
                expect(base._include_status).to_be_true()
                expect(config1._include_meta).to_be_false()
                expect(config1._include_status).to_be_false()
                expect(config2._include_meta).to_be_true()
                expect(config2._include_status).to_be_true()
            end)
        end)

        describe("error handling", function()
            it("should handle missing namespaces", function()
                local reader = rfs.reader()
                local result = reader:read_file("nonexistent.namespace/file.lua")

                expect(result.error).to_match("Namespace not found")
            end)

            it("should validate parameters", function()
                local reader = rfs.reader()

                local result1 = reader:list_files(nil)
                local result2 = reader:list_files("")

                expect(result1).to_be_nil()
                expect(result2).to_be_nil()
            end)
        end)

        describe("integration scenarios", function()
            it("should maintain consistent structure across operations", function()
                local reader = rfs.reader()

                local single = reader:read_file("keeper.demo/hello_tool.lua")
                local multiple = reader:read_files({"keeper.demo/hello_tool.lua"})

                local single_result = multiple["keeper.demo/hello_tool.lua"]

                -- Should have same structure
                expect(single.content).to_equal(single_result.content)
                expect(single.status).to_equal(single_result.status)
                expect(single.entry_id).to_equal(single_result.entry_id)
                expect(single.entry_kind).to_equal(single_result.entry_kind)
            end)
        end)
    end)
end

return test.run_cases(define_tests)