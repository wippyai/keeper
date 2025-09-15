local test = require("test")
local ns = require("ns")
local ns_diff = require("ns_diff")

local function define_tests()
    describe("NS Diff Module", function()
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

        describe("basic entry comparison", function()
            it("should detect no changes for identical entries", function()
                local changes = ns_diff.compare_entries(sample_entries, sample_entries)

                expect(#changes).to_equal(0)
            end)

            it("should detect entry addition", function()
                local new_entries = {}
                for _, entry in ipairs(sample_entries) do
                    table.insert(new_entries, entry)
                end

                table.insert(new_entries, {
                    id = "keeper.demo:new_tool",
                    kind = "function.lua",
                    meta = {type = "tool", title = "New Tool"},
                    data = {source = "return {handler = function() end}"}
                })

                local changes = ns_diff.compare_entries(sample_entries, new_entries)

                expect(#changes).to_equal(1)
                expect(changes[1].type).to_equal("addition")
                expect(changes[1].entry_id).to_equal("keeper.demo:new_tool")
            end)

            it("should detect entry deletion", function()
                local reduced_entries = {sample_entries[1]} -- Only keep first entry

                local changes = ns_diff.compare_entries(sample_entries, reduced_entries)

                expect(#changes).to_equal(1)
                expect(changes[1].type).to_equal("deletion")
                expect(changes[1].entry_id).to_equal("keeper.demo:config_lib")
            end)

            it("should detect entry modification", function()
                local modified_entries = {}
                for _, entry in ipairs(sample_entries) do
                    if entry.id == "keeper.demo:hello_tool" then
                        local modified_entry = {
                            id = entry.id,
                            kind = entry.kind,
                            meta = {type = "tool", title = "Modified Hello Tool", description = "New description"},
                            data = entry.data
                        }
                        table.insert(modified_entries, modified_entry)
                    else
                        table.insert(modified_entries, entry)
                    end
                end

                local changes = ns_diff.compare_entries(sample_entries, modified_entries)

                expect(#changes).to_equal(1)
                expect(changes[1].type).to_equal("modification")
                expect(changes[1].entry_id).to_equal("keeper.demo:hello_tool")
                expect(#changes[1].differences).to_be_greater_than(0)
            end)
        end)

        describe("file:// reference handling", function()
            it("should handle metadata-only changes with file:// references", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                -- Generate YAML with file:// references
                local original_yaml, err = namespace:to_yaml()
                expect(err).to_be_nil()
                expect(original_yaml).to_contain("source: file://hello_tool.lua")

                -- Simulate agent editing YAML - only changing metadata
                local edited_yaml = [[
version: "1.0"
namespace: keeper.demo

entries:
  - name: hello_tool
    kind: function.lua
    meta:
      type: tool
      title: "Improved Hello Tool"
      description: "Now with better greetings"
    source: file://hello_tool.lua
    modules: ["json"]

  - name: config_lib
    kind: library.lua
    meta:
      comment: "Configuration library"
    source: file://config_lib.lua
]]

                local diff_result, err = ns_diff.compare_namespace_with_yaml(namespace, edited_yaml)
                expect(err).to_be_nil()
                expect(diff_result.change_count).to_equal(1)

                local change = diff_result.changes[1]
                expect(change.type).to_equal("modification")
                expect(change.entry_id).to_equal("keeper.demo:hello_tool")

                -- Verify source content was preserved
                expect(change.new_entry.data.source).to_contain("local function handler")
                expect(change.new_entry.data.source).not_to_contain("file://")

                -- Verify metadata changes
                expect(change.new_entry.meta.title).to_equal("Improved Hello Tool")
                expect(change.new_entry.meta.description).to_equal("Now with better greetings")
            end)

            it("should detect source content changes through file:// references", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                -- Edit YAML with new inline source content
                local edited_yaml = [[
version: "1.0"
namespace: keeper.demo

entries:
  - name: hello_tool
    kind: function.lua
    meta:
      type: tool
      title: "Hello Tool"
    source: "local function handler(params)\n    return 'Modified Hello World'\nend\nreturn {handler = handler}"
    modules: ["json"]

  - name: config_lib
    kind: library.lua
    meta:
      comment: "Configuration library"
    source: file://config_lib.lua
]]

                local diff_result, err = ns_diff.compare_namespace_with_yaml(namespace, edited_yaml)
                expect(err).to_be_nil()
                expect(diff_result.change_count).to_equal(1)

                local change = diff_result.changes[1]
                expect(change.type).to_equal("modification")
                expect(change.entry_id).to_equal("keeper.demo:hello_tool")

                -- Check that source change was detected
                local has_source_change = false
                for _, diff in ipairs(change.differences) do
                    if diff.path == "data.source" then
                        has_source_change = true
                        expect(diff.new_value).to_contain("Modified Hello World")
                        break
                    end
                end
                expect(has_source_change).to_be_true()
            end)

            it("should preserve existing file:// references when unchanged", function()
                local entries_with_refs = {
                    {
                        id = "keeper.demo:external_tool",
                        kind = "function.lua",
                        meta = {type = "tool", title = "External Tool"},
                        data = {source = "file://external_script.lua"}
                    }
                }

                local namespace = ns.new("keeper.demo", entries_with_refs)

                local edited_yaml = [[
version: "1.0"
namespace: keeper.demo

entries:
  - name: external_tool
    kind: function.lua
    meta:
      type: tool
      title: "Updated External Tool"
    source: file://external_script.lua
]]

                local diff_result, err = ns_diff.compare_namespace_with_yaml(namespace, edited_yaml)
                expect(err).to_be_nil()
                expect(diff_result.change_count).to_equal(1)

                local change = diff_result.changes[1]
                expect(change.new_entry.data.source).to_equal("file://external_script.lua")

                -- Should only detect metadata change
                local has_source_change = false
                for _, diff in ipairs(change.differences) do
                    if diff.path == "data.source" then
                        has_source_change = true
                        break
                    end
                end
                expect(has_source_change).to_be_false()
            end)
        end)

        describe("change analysis", function()
            it("should classify metadata-only changes correctly", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local metadata_only_yaml = [[
version: "1.0"
namespace: keeper.demo

entries:
  - name: hello_tool
    kind: function.lua
    meta:
      type: tool
      title: "Better Hello Tool"
      group: "utilities"
    source: file://hello_tool.lua
    modules: ["json"]

  - name: config_lib
    kind: library.lua
    meta:
      comment: "Enhanced configuration library"
      tags: ["config", "utils"]
    source: file://config_lib.lua
]]

                local diff_result, err = ns_diff.compare_namespace_with_yaml(namespace, metadata_only_yaml)
                expect(err).to_be_nil()

                expect(ns_diff.is_metadata_only_changes(diff_result)).to_be_true()

                local summary = ns_diff.get_change_summary(diff_result)
                expect(summary.metadata_only_changes).to_equal(2)
                expect(summary.source_content_changes).to_equal(0)
            end)

            it("should generate correct workspace operations", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local edited_yaml = [[
version: "1.0"
namespace: keeper.demo

entries:
  - name: hello_tool
    kind: function.lua
    meta:
      type: tool
      title: "Updated Hello Tool"
    source: file://hello_tool.lua
    modules: ["json"]

  - name: new_helper
    kind: library.lua
    meta:
      comment: "New helper library"
    source: "local helper = {}\nreturn helper"
]]

                local diff_result, err = ns_diff.compare_namespace_with_yaml(namespace, edited_yaml)
                expect(err).to_be_nil()

                local operations = ns_diff.generate_workspace_operations(diff_result)

                expect(#operations).to_equal(3) -- 1 modify, 1 add, 1 delete

                -- Check operation types
                local op_types = {}
                for _, op in ipairs(operations) do
                    op_types[op.operation] = (op_types[op.operation] or 0) + 1
                end

                expect(op_types.upsert_entry).to_equal(2) -- modify + add
                expect(op_types.delete_entry).to_equal(1) -- delete config_lib
            end)
        end)

        describe("complex scenarios", function()
            it("should handle mixed changes (add, modify, delete)", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local complex_yaml = [[
version: "1.0"
namespace: keeper.demo

entries:
  - name: hello_tool
    kind: function.lua
    meta:
      type: tool
      title: "Super Hello Tool"
      version: "2.0"
    source: "local function handler(params)\n    return 'Super Hello ' .. (params.name or 'Universe')\nend\nreturn {handler = handler}"
    modules: ["json", "text"]

  - name: math_utils
    kind: library.lua
    meta:
      comment: "Mathematical utilities"
    source: "local math_utils = {}\nmath_utils.add = function(a, b) return a + b end\nreturn math_utils"

  - name: validator
    kind: library.lua
    meta:
      comment: "Input validation"
    source: file://validator.lua
]]

                local diff_result, err = ns_diff.compare_namespace_with_yaml(namespace, complex_yaml)
                expect(err).to_be_nil()
                expect(diff_result.change_count).to_equal(4) -- modify hello_tool, delete config_lib, add math_utils, add validator

                local summary = ns_diff.get_change_summary(diff_result)
                expect(summary.additions).to_equal(2)
                expect(summary.modifications).to_equal(1)
                expect(summary.deletions).to_equal(1)
                expect(summary.source_content_changes).to_equal(1) -- hello_tool source changed
            end)

            it("should handle empty namespace scenarios", function()
                local empty_namespace = ns.new("keeper.demo", {})

                local changes = ns_diff.compare_entries({}, sample_entries)
                expect(#changes).to_equal(2) -- Both entries are additions

                for _, change in ipairs(changes) do
                    expect(change.type).to_equal("addition")
                end
            end)
        end)

        describe("error handling", function()
            it("should handle invalid YAML gracefully", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local invalid_yaml = "invalid: yaml: content: ["

                local diff_result, err = ns_diff.compare_namespace_with_yaml(namespace, invalid_yaml)
                expect(diff_result).to_be_nil()
                expect(err).to_match("Failed to resolve edited YAML")
            end)

            it("should handle namespace mismatch", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local wrong_namespace_yaml = [[
version: "1.0"
namespace: wrong.namespace
entries: []
]]

                local diff_result, err = ns_diff.compare_namespace_with_yaml(namespace, wrong_namespace_yaml)
                expect(diff_result).to_be_nil()
                expect(err).to_match("Namespace mismatch")
            end)

            it("should handle missing parameters", function()
                local diff_result, err = ns_diff.compare_namespace_with_yaml(nil, "some yaml")
                expect(diff_result).to_be_nil()
                expect(err).to_match("original_namespace is required")

                local namespace = ns.new("keeper.demo", sample_entries)
                diff_result, err = ns_diff.compare_namespace_with_yaml(namespace, "")
                expect(diff_result).to_be_nil()
                expect(err).to_match("Edited YAML content cannot be empty or whitespace only")
            end)
        end)

        describe("change summary analysis", function()
            it("should provide accurate change statistics", function()
                local namespace = ns.new("keeper.demo", sample_entries)

                local test_yaml = [[
version: "1.0"
namespace: keeper.demo

entries:
  - name: hello_tool
    kind: function.lua
    meta:
      type: tool
      title: "Hello Tool v2"
      description: "Updated version"
    source: file://hello_tool.lua
    modules: ["json"]

  - name: new_lib
    kind: library.lua
    meta:
      comment: "Brand new library"
    source: "local new_lib = {}\nreturn new_lib"
]]

                local diff_result, err = ns_diff.compare_namespace_with_yaml(namespace, test_yaml)
                expect(err).to_be_nil()

                local summary = ns_diff.get_change_summary(diff_result)

                expect(summary.total_changes).to_equal(3)
                expect(summary.additions).to_equal(1) -- new_lib
                expect(summary.modifications).to_equal(1) -- hello_tool
                expect(summary.deletions).to_equal(1) -- config_lib
                expect(summary.metadata_only_changes).to_equal(1) -- hello_tool metadata only
                expect(summary.source_content_changes).to_equal(0)
            end)
        end)

        describe("real-world editing flow", function()
            it("should demonstrate safe file:// editing workflow", function()
                -- Step 1: Start with entries containing inline source
                local original_entries = {
                    {
                        id = "myapp:main_tool",
                        kind = "function.lua",
                        meta = {type = "tool", title = "Main Tool", version = "1.0"},
                        data = {
                            source = "local function handler(params)\n    -- Original implementation\n    return 'original result'\nend\nreturn {handler = handler}",
                            modules = {"json"}
                        }
                    }
                }

                -- Step 2: Create namespace and generate YAML for agent
                local namespace = ns.new("myapp", original_entries)
                local agent_yaml, err = namespace:to_yaml()
                expect(err).to_be_nil()
                expect(agent_yaml).to_contain("source: file://main_tool.lua")
                expect(agent_yaml).not_to_contain("Original implementation")

                -- Step 3: Agent edits YAML (adds metadata, keeps file:// reference)
                local agent_edited_yaml = [[
version: "1.0"
namespace: myapp

entries:
  - name: main_tool
    kind: function.lua
    meta:
      type: tool
      title: "Enhanced Main Tool"
      version: "2.0"
      description: "Now with more features"
      tags: ["productivity", "utility"]
    source: file://main_tool.lua
    modules: ["json", "text"]
]]

                -- Step 4: Diff original vs edited
                local diff_result, err = ns_diff.compare_namespace_with_yaml(namespace, agent_edited_yaml)
                expect(err).to_be_nil()
                expect(diff_result.change_count).to_equal(1)

                local change = diff_result.changes[1]
                expect(change.type).to_equal("modification")

                -- Step 5: Verify source content was preserved
                expect(change.new_entry.data.source).to_contain("Original implementation")
                expect(change.new_entry.data.source).to_contain("original result")
                expect(change.new_entry.data.source).not_to_contain("file://")

                -- Step 6: Verify only metadata changed
                expect(change.new_entry.meta.title).to_equal("Enhanced Main Tool")
                expect(change.new_entry.meta.version).to_equal("2.0")
                expect(change.new_entry.meta.description).to_equal("Now with more features")

                -- Step 7: Confirm it's metadata-only change
                expect(ns_diff.is_metadata_only_changes(diff_result)).to_be_true()

                local summary = ns_diff.get_change_summary(diff_result)
                expect(summary.metadata_only_changes).to_equal(1)
                expect(summary.source_content_changes).to_equal(0)
            end)
        end)
    end)
end

return test.run_cases(define_tests)