local test = require("test")
local ns = require("ns")

local function define_tests()
    describe("NS Module", function()
        local sample_entries

        before_each(function()
            sample_entries = {
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
            }
        end)

        describe("file configuration", function()
            it("should get file config for function.lua", function()
                local entry = {kind = "function.lua"}
                local config = ns.get_file_config(entry)

                expect(config).not_to_be_nil()
                expect(config.source_field).to_equal("source")
                expect(config.extension).to_equal(".lua")
            end)

            it("should return nil for unsupported kinds", function()
                local entry = {kind = "unsupported.kind"}
                local config = ns.get_file_config(entry)

                expect(config).to_be_nil()
            end)
        end)

        describe("filename utilities", function()
            it("should extract filename from file:// URL", function()
                local filename = ns.extract_filename_from_url("file://hello_tool.lua")
                expect(filename).to_equal("hello_tool.lua")

                local no_filename = ns.extract_filename_from_url("not_a_file_url")
                expect(no_filename).to_be_nil()
            end)

            it("should generate filename from entry name and config", function()
                local config = {extension = ".lua"}
                local filename = ns.generate_filename("hello_tool", config)
                expect(filename).to_equal("hello_tool.lua")

                local filename_with_ext = ns.generate_filename("hello_tool.lua", config)
                expect(filename_with_ext).to_equal("hello_tool.lua")
            end)
        end)

        describe("namespace creation", function()
            it("should create namespace from entries", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                expect(namespace.name).to_equal("keeper.demo")
                expect(namespace.version).to_equal("1.0")
                expect(#namespace.entries).to_equal(2)
            end)

            it("should build file mappings", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local files = namespace:list_files()
                expect(files).to_contain("_index.yaml")
                expect(files).to_contain("hello_tool.lua")
                expect(files).to_contain("config_lib.lua")

                expect(namespace:get_file_owner("hello_tool.lua")).to_equal("hello_tool")
                expect(namespace:get_file_owner("config_lib.lua")).to_equal("config_lib")
            end)
        end)

        describe("file operations", function()
            it("should check file existence", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                expect(namespace:file_exists("_index.yaml")).to_be_true()
                expect(namespace:file_exists("hello_tool.lua")).to_be_true()
                expect(namespace:file_exists("nonexistent.lua")).to_be_false()
            end)

            it("should get source file content", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local content, err = namespace:get_file_content("hello_tool.lua")
                expect(err).to_be_nil()
                expect(content).to_contain("local function handler")
                expect(content).to_contain("Hello")
            end)

            it("should generate _index.yaml content", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local yaml_content, err = namespace:get_file_content("_index.yaml")
                expect(err).to_be_nil()
                expect(yaml_content).to_contain("namespace: keeper.demo")
                expect(yaml_content).to_contain("name: hello_tool")
                expect(yaml_content).to_contain("kind: function.lua")
            end)
        end)

        describe("YAML generation", function()
            it("should generate YAML with file:// references by default", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local yaml_content, err = namespace:to_yaml()
                expect(err).to_be_nil()
                expect(yaml_content).to_contain("source: file://hello_tool.lua")
                expect(yaml_content).to_contain("source: file://config_lib.lua")
                expect(yaml_content).not_to_contain("local function handler")
            end)

            it("should generate YAML with inline sources when requested", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local yaml_content, err = namespace:to_yaml({inline_sources = true})
                expect(err).to_be_nil()
                expect(yaml_content).to_contain("local function handler")
                expect(yaml_content).not_to_contain("file://")
            end)

            it("should preserve existing file:// references", function()
                local entries_with_refs = {
                    {
                        id = "keeper.demo:existing_tool",
                        kind = "function.lua",
                        meta = {type = "tool"},
                        data = {source = "file://existing_script.lua"}
                    }
                }

                local namespace = ns.new("keeper.demo", entries_with_refs)
                local yaml_content, err = namespace:to_yaml()

                expect(err).to_be_nil()
                expect(yaml_content).to_contain("source: file://existing_script.lua")
            end)
        end)

        describe("YAML resolution", function()
            it("should resolve edited YAML back to entries with content", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                -- Simulate agent editing YAML (changing title, adding description)
                local edited_yaml = [[
version: "1.0"
namespace: keeper.demo

entries:
  - name: hello_tool
    kind: function.lua
    meta:
      type: tool
      title: "Better Hello Tool"
      description: "An improved greeting tool"
    source: file://hello_tool.lua
    modules: ["json"]

  - name: config_lib
    kind: library.lua
    meta:
      comment: "Updated configuration library"
    source: file://config_lib.lua
]]

                local resolved_entries, err = namespace:resolve(edited_yaml)
                expect(err).to_be_nil()
                expect(#resolved_entries).to_equal(2)

                -- Check that metadata changes are preserved
                local hello_entry = resolved_entries[1]
                expect(hello_entry.meta.title).to_equal("Better Hello Tool")
                expect(hello_entry.meta.description).to_equal("An improved greeting tool")

                -- Check that source content is restored from original
                expect(hello_entry.data.source).to_contain("local function handler")
                expect(hello_entry.data.source).not_to_contain("file://")
            end)

            it("should handle namespace mismatch", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local wrong_yaml = [[
version: "1.0"
namespace: wrong.namespace
entries: []
]]

                local resolved_entries, err = namespace:resolve(wrong_yaml)
                expect(resolved_entries).to_be_nil()
                expect(err).to_match("Namespace mismatch")
            end)

            it("should handle invalid YAML", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local resolved_entries, err = namespace:resolve("invalid: yaml: content: [")
                expect(resolved_entries).to_be_nil()
                expect(err).to_match("Failed to parse YAML")
            end)

            it("should preserve inline content in edited YAML", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local edited_yaml = [[
version: "1.0"
namespace: keeper.demo

entries:
  - name: hello_tool
    kind: function.lua
    meta:
      type: tool
      title: "Hello Tool"
    source: "local function handler(params)\n    return 'Modified hello'\nend"
]]

                local resolved_entries, err = namespace:resolve(edited_yaml)
                expect(err).to_be_nil()

                local hello_entry = resolved_entries[1]
                expect(hello_entry.data.source).to_contain("Modified hello")
                expect(hello_entry.data.source).not_to_contain("file://")
            end)
        end)

        describe("statistics", function()
            it("should provide namespace statistics", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local stats = namespace:get_stats()
                expect(stats.name).to_equal("keeper.demo")
                expect(stats.version).to_equal("1.0")
                expect(stats.entry_count).to_equal(2)
                expect(stats.file_count).to_equal(3) -- _index.yaml + 2 source files
            end)
        end)

        describe("error handling", function()
            it("should handle missing source field gracefully", function()
                local entries_no_source_field = {
                    {
                        id = "keeper.demo:no_source_field",
                        kind = "function.lua",
                        meta = {type = "tool"},
                        data = {} -- No source field at all
                    }
                }

                local namespace = ns.new("keeper.demo", entries_no_source_field)
                local content, err = namespace:get_file_content("no_source_field.lua")

                expect(content).to_be_nil()
                expect(err).to_match("File not found")
            end)

            it("should handle entries with file:// references when getting content", function()
                local entries_with_refs = {
                    {
                        id = "keeper.demo:ref_tool",
                        kind = "function.lua",
                        meta = {type = "tool"},
                        data = {source = "file://external_script.lua"}
                    }
                }

                local namespace = ns.new("keeper.demo", entries_with_refs)
                local content, err = namespace:get_file_content("external_script.lua")

                expect(content).to_be_nil()
                expect(err).to_match("content not available")
            end)
        end)

        describe("entry lookup", function()
            it("should find entries by name", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local entry = namespace:get_entry("hello_tool")
                expect(entry).not_to_be_nil()
                expect(entry.kind).to_equal("function.lua")
                expect(entry.meta.title).to_equal("Hello Tool")

                local missing = namespace:get_entry("nonexistent")
                expect(missing).to_be_nil()
            end)
        end)
    end)
end

return test.run_cases(define_tests)