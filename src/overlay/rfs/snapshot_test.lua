local test = require("test")
local snapshot = require("snapshot")

-- Mock dependencies for testing
local function create_mock_deps()
    return {
        registry = {
            snapshot = function()
                return {
                    entries = function()
                        return {
                            {
                                id = "keeper.demo:hello_tool",
                                kind = "function.lua",
                                meta = { type = "tool", title = "Hello Tool" },
                                data = { source = "original hello content" }
                            },
                            {
                                id = "keeper.demo:config_lib",
                                kind = "library.lua",
                                meta = { comment = "Config library" },
                                data = { source = "original config content" }
                            },
                            {
                                id = "keeper.demo.agents:chat_agent",
                                kind = "function.lua",
                                meta = { type = "agent", title = "Chat Agent" },
                                data = { source = "chat agent content" }
                            },
                            {
                                id = "keeper.overlay:workspace",
                                kind = "library.lua",
                                meta = { comment = "Workspace library" },
                                data = { source = "workspace lib content" }
                            },
                            {
                                id = "acme.prod:api_tool",
                                kind = "function.lua",
                                meta = { type = "api", title = "API Tool" },
                                data = { source = "api tool content" }
                            }
                        }, nil
                    end
                }, nil
            end,
            -- Add debugging to the mock registry.get function
            get = function(entry_id)
                local entries = {
                    ["keeper.demo:hello_tool"] = {
                        id = "keeper.demo:hello_tool",
                        kind = "function.lua",
                        meta = { type = "tool", title = "Hello Tool" },
                        data = { source = "original hello content" }
                    },
                    ["keeper.demo:config_lib"] = {
                        id = "keeper.demo:config_lib",
                        kind = "library.lua",
                        meta = { comment = "Config library" },
                        data = { source = "original config content" }
                    },
                    ["keeper.demo.agents:chat_agent"] = {
                        id = "keeper.demo.agents:chat_agent",
                        kind = "function.lua",
                        meta = { type = "agent", title = "Chat Agent" },
                        data = { source = "chat agent content" }
                    },
                    ["keeper.overlay:workspace"] = {
                        id = "keeper.overlay:workspace",
                        kind = "library.lua",
                        meta = { comment = "Workspace library" },
                        data = { source = "workspace lib content" }
                    },
                    ["acme.prod:api_tool"] = {
                        id = "acme.prod:api_tool",
                        kind = "function.lua",
                        meta = { type = "api", title = "API Tool" },
                        data = { source = "api tool content" }
                    }
                }

                local entry = entries[entry_id]
                if entry then
                    return entry, nil
                else
                    return nil, "entry not found: " .. entry_id
                end
            end
        }
    }
end

-- Mock workspace session
local function create_mock_session(workspace_info, dirty_entries, workspace_entries)
    return {
        get_workspace_info = function()
            return workspace_info, nil
        end,
        get_dirty_entries = function()
            return dirty_entries or {}, nil
        end,
        get_workspace = function(self, entry_id)
            if workspace_entries and workspace_entries[entry_id] then
                return workspace_entries[entry_id], nil
            end
            return nil, nil
        end
    }
end

local function define_tests()
    describe("Snapshot Module", function()
        local original_deps

        before_each(function()
            original_deps = snapshot._deps
            snapshot._deps = create_mock_deps()
        end)

        after_each(function()
            snapshot._deps = original_deps
        end)

        describe("pattern type compatibility", function()
            it("should support colon wildcard patterns (:*) for exact namespace matching", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "read" }
                    }
                }
                local session = create_mock_session(workspace_info)

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(err).to_be_nil()
                expect(#entries).to_equal(2) -- Only keeper.demo:* entries, not keeper.demo.agents:*

                local entry_ids = {}
                for _, entry in ipairs(entries) do
                    entry_ids[entry.id] = true
                end

                expect(entry_ids["keeper.demo:hello_tool"]).to_be_true()
                expect(entry_ids["keeper.demo:config_lib"]).to_be_true()

                -- Test that sub-namespace entries are NOT included with :* pattern
                local sub_entries, sub_err = snapshot.get_namespace_snapshot(session, "keeper.demo.agents")
                expect(sub_err).to_be_nil()
                expect(#sub_entries).to_equal(0) -- Should NOT match keeper.demo.agents:* with keeper.demo:* pattern
            end)

            it("should support dot wildcard patterns (.*) for hierarchical namespace matching", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo.*", permission_type = "read" }
                    }
                }
                local session = create_mock_session(workspace_info)

                -- Get full snapshot to see all accessible namespaces
                local namespace_snapshots, err = snapshot.get_full_snapshot(session)
                expect(err).to_be_nil()

                -- Should include both keeper.demo and keeper.demo.agents namespaces
                expect(namespace_snapshots["keeper.demo"]).not_to_be_nil()
                expect(#namespace_snapshots["keeper.demo"]).to_equal(2)

                expect(namespace_snapshots["keeper.demo.agents"]).not_to_be_nil()
                expect(#namespace_snapshots["keeper.demo.agents"]).to_equal(1)
                expect(namespace_snapshots["keeper.demo.agents"][1].id).to_equal("keeper.demo.agents:chat_agent")
            end)

            it("should distinguish between :* and .* patterns correctly", function()
                -- Test with :* pattern - exact namespace only
                local colon_workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "read" }
                    }
                }
                local colon_session = create_mock_session(colon_workspace_info)

                local colon_snapshots, err = snapshot.get_full_snapshot(colon_session)
                expect(err).to_be_nil()
                expect(colon_snapshots["keeper.demo"]).not_to_be_nil()
                expect(colon_snapshots["keeper.demo.agents"]).to_be_nil() -- Should not be accessible

                -- Test with .* pattern - hierarchical matching
                local dot_workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo.*", permission_type = "read" }
                    }
                }
                local dot_session = create_mock_session(dot_workspace_info)

                local dot_snapshots, err = snapshot.get_full_snapshot(dot_session)
                expect(err).to_be_nil()
                expect(dot_snapshots["keeper.demo"]).not_to_be_nil()
                expect(dot_snapshots["keeper.demo.agents"]).not_to_be_nil() -- Should be accessible
            end)

            it("should handle mixed pattern types in same workspace", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*",    permission_type = "read" }, -- Exact namespace
                        { namespace_pattern = "keeper.overlay.*", permission_type = "write" } -- Hierarchical
                    }
                }
                local session = create_mock_session(workspace_info)

                local namespace_snapshots, err = snapshot.get_full_snapshot(session)
                expect(err).to_be_nil()

                -- Should have keeper.demo (from keeper.demo:*)
                expect(namespace_snapshots["keeper.demo"]).not_to_be_nil()
                expect(#namespace_snapshots["keeper.demo"]).to_equal(2)

                -- Should have keeper.overlay (from keeper.overlay.*)
                expect(namespace_snapshots["keeper.overlay"]).not_to_be_nil()
                expect(#namespace_snapshots["keeper.overlay"]).to_equal(1)

                -- Should NOT have keeper.demo.agents (not covered by keeper.demo:*)
                expect(namespace_snapshots["keeper.demo.agents"]).to_be_nil()
            end)
        end)

        describe("workspace permission filtering", function()
            it("should filter entries by workspace permissions", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*",    permission_type = "write" },
                        { namespace_pattern = "keeper.overlay:*", permission_type = "read" }
                    }
                }
                local session = create_mock_session(workspace_info)

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(err).to_be_nil()
                expect(#entries).to_equal(2) -- hello_tool and config_lib

                local entry_ids = {}
                for _, entry in ipairs(entries) do
                    entry_ids[entry.id] = true
                end

                expect(entry_ids["keeper.demo:hello_tool"]).to_be_true()
                expect(entry_ids["keeper.demo:config_lib"]).to_be_true()
            end)

            it("should reject entries outside workspace permissions", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "write" }
                    }
                }
                local session = create_mock_session(workspace_info)

                local entries, err = snapshot.get_namespace_snapshot(session, "acme.prod")
                expect(err).to_be_nil()
                expect(#entries).to_equal(0) -- No acme.prod entries should be accessible
            end)

            it("should handle empty permissions", function()
                local workspace_info = { permissions = {} }
                local session = create_mock_session(workspace_info)

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(err).to_be_nil()
                expect(#entries).to_equal(0)
            end)

            it("should handle missing permissions", function()
                local workspace_info = {}
                local session = create_mock_session(workspace_info)

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(err).to_be_nil()
                expect(#entries).to_equal(0)
            end)
        end)

        describe("workspace overlay operations", function()
            it("should apply CREATE operations", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "write" }
                    }
                }
                local dirty_entries = {
                    {
                        entry_id = "keeper.demo:new_tool",
                        operation_type = "create"
                    }
                }
                -- Workspace entries should be in registry format
                local workspace_entries = {
                    ["keeper.demo:new_tool"] = {
                        kind = "function.lua",
                        meta = { type = "tool", title = "New Tool" },
                        data = { source = "new tool content" }
                    }
                }
                local session = create_mock_session(workspace_info, dirty_entries, workspace_entries)

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(err).to_be_nil()
                expect(#entries).to_equal(3) -- 2 registry + 1 new

                -- Find the new entry
                local new_entry = nil
                for _, entry in ipairs(entries) do
                    if entry.id == "keeper.demo:new_tool" then
                        new_entry = entry
                        break
                    end
                end

                expect(new_entry).not_to_be_nil()
                expect(new_entry.kind).to_equal("function.lua")
                expect(new_entry.meta.title).to_equal("New Tool")
                expect(new_entry.data.source).to_equal("new tool content")
            end)

            it("should apply UPDATE operations", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "write" }
                    }
                }
                local dirty_entries = {
                    {
                        entry_id = "keeper.demo:hello_tool",
                        operation_type = "update"
                    }
                }
                -- Workspace entries should be in registry format
                local workspace_entries = {
                    ["keeper.demo:hello_tool"] = {
                        kind = "function.lua",
                        meta = { type = "tool", title = "Updated Hello Tool" },
                        data = { source = "updated hello content" }
                    }
                }
                local session = create_mock_session(workspace_info, dirty_entries, workspace_entries)

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(err).to_be_nil()
                expect(#entries).to_equal(2)

                -- Find the updated entry
                local updated_entry = nil
                for _, entry in ipairs(entries) do
                    if entry.id == "keeper.demo:hello_tool" then
                        updated_entry = entry
                        break
                    end
                end

                expect(updated_entry).not_to_be_nil()
                expect(updated_entry.meta.title).to_equal("Updated Hello Tool")
                expect(updated_entry.data.source).to_equal("updated hello content")
            end)

            it("should apply DELETE operations", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "write" }
                    }
                }
                local dirty_entries = {
                    {
                        entry_id = "keeper.demo:hello_tool",
                        operation_type = "delete"
                    }
                }
                local session = create_mock_session(workspace_info, dirty_entries)

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(err).to_be_nil()
                expect(#entries).to_equal(1) -- Only config_lib should remain

                -- Verify deleted entry is not present
                for _, entry in ipairs(entries) do
                    expect(entry.id).not_to_equal("keeper.demo:hello_tool")
                end
            end)

            it("should handle mixed operations", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "write" }
                    }
                }
                local dirty_entries = {
                    { entry_id = "keeper.demo:hello_tool", operation_type = "update" },
                    { entry_id = "keeper.demo:config_lib", operation_type = "delete" },
                    { entry_id = "keeper.demo:new_tool",   operation_type = "create" }
                }
                -- Workspace entries should be in registry format
                local workspace_entries = {
                    ["keeper.demo:hello_tool"] = {
                        kind = "function.lua",
                        meta = { type = "tool", title = "Updated Hello" },
                        data = { source = "updated content" }
                    },
                    ["keeper.demo:new_tool"] = {
                        kind = "function.lua",
                        meta = { type = "tool", title = "New Tool" },
                        data = { source = "new content" }
                    }
                }
                local session = create_mock_session(workspace_info, dirty_entries, workspace_entries)

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(err).to_be_nil()
                expect(#entries).to_equal(2) -- updated hello_tool + new_tool

                local entry_ids = {}
                for _, entry in ipairs(entries) do
                    entry_ids[entry.id] = entry
                end

                expect(entry_ids["keeper.demo:hello_tool"]).not_to_be_nil()
                expect(entry_ids["keeper.demo:hello_tool"].meta.title).to_equal("Updated Hello")
                expect(entry_ids["keeper.demo:new_tool"]).not_to_be_nil()
                expect(entry_ids["keeper.demo:config_lib"]).to_be_nil() -- deleted
            end)
        end)

        describe("get_full_snapshot", function()
            it("should return all accessible namespaces", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.*", permission_type = "read" }
                    }
                }
                local session = create_mock_session(workspace_info)

                local namespace_snapshots, err = snapshot.get_full_snapshot(session)
                expect(err).to_be_nil()
                expect(namespace_snapshots).not_to_be_nil()

                expect(namespace_snapshots["keeper.demo"]).not_to_be_nil()
                expect(#namespace_snapshots["keeper.demo"]).to_equal(2)

                expect(namespace_snapshots["keeper.overlay"]).not_to_be_nil()
                expect(#namespace_snapshots["keeper.overlay"]).to_equal(1)

                expect(namespace_snapshots["acme.prod"]).to_be_nil() -- Not accessible
            end)

            it("should include workspace changes in full snapshot", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "write" }
                    }
                }
                local dirty_entries = {
                    { entry_id = "keeper.demo:new_tool", operation_type = "create" }
                }
                -- Workspace entries should be in registry format
                local workspace_entries = {
                    ["keeper.demo:new_tool"] = {
                        kind = "function.lua",
                        meta = { type = "tool" },
                        data = { source = "new content" }
                    }
                }
                local session = create_mock_session(workspace_info, dirty_entries, workspace_entries)

                local namespace_snapshots, err = snapshot.get_full_snapshot(session)
                expect(err).to_be_nil()

                expect(namespace_snapshots["keeper.demo"]).not_to_be_nil()
                expect(#namespace_snapshots["keeper.demo"]).to_equal(3) -- 2 original + 1 new

                -- Verify new entry is included
                local has_new_tool = false
                for _, entry in ipairs(namespace_snapshots["keeper.demo"]) do
                    if entry.id == "keeper.demo:new_tool" then
                        has_new_tool = true
                        break
                    end
                end
                expect(has_new_tool).to_be_true()
            end)
        end)

        describe("get_entry_snapshot", function()
            it("should return entry with workspace overlay applied", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "write" }
                    }
                }
                -- Workspace entries should be in registry format
                local workspace_entries = {
                    ["keeper.demo:hello_tool"] = {
                        kind = "function.lua",
                        meta = { type = "tool", title = "Workspace Hello" },
                        data = { source = "workspace content" }
                    }
                }
                local session = create_mock_session(workspace_info, {}, workspace_entries)

                local entry, err = snapshot.get_entry_snapshot(session, "keeper.demo:hello_tool")
                expect(err).to_be_nil()
                expect(entry).not_to_be_nil()
                expect(entry.meta.title).to_equal("Workspace Hello")
                expect(entry.data.source).to_equal("workspace content")
            end)

            it("should return nil for deleted entries", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "write" }
                    }
                }
                local workspace_entries = {
                    ["keeper.demo:hello_tool"] = { _deleted = true }
                }
                local session = create_mock_session(workspace_info, {}, workspace_entries)

                local entry, err = snapshot.get_entry_snapshot(session, "keeper.demo:hello_tool")
                expect(err).to_be_nil()
                expect(entry).to_be_nil()
            end)

            it("should fallback to registry for unmodified entries", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "read" }
                    }
                }
                local session = create_mock_session(workspace_info)

                local entry, err = snapshot.get_entry_snapshot(session, "keeper.demo:hello_tool")
                expect(err).to_be_nil()
                expect(entry).not_to_be_nil()
                expect(entry.meta.title).to_equal("Hello Tool") -- Original registry value
                expect(entry.data.source).to_equal("original hello content")
            end)

            it("should reject access to entries outside permissions", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "read" }
                    }
                }
                local session = create_mock_session(workspace_info)

                local entry, err = snapshot.get_entry_snapshot(session, "acme.prod:api_tool")
                expect(entry).to_be_nil()
                expect(err).to_match("Entry not accessible in workspace")
            end)
        end)

        describe("existence checks", function()
            it("should check entry existence with workspace overlays", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "read" }
                    }
                }
                local session = create_mock_session(workspace_info)

                -- Entry exists in registry
                local exists1 = snapshot.entry_exists(session, "keeper.demo:hello_tool")
                expect(exists1).to_be_true()

                -- Entry doesn't exist
                local exists2 = snapshot.entry_exists(session, "keeper.demo:nonexistent")
                expect(exists2).to_be_false()

                -- Entry outside permissions
                local exists3 = snapshot.entry_exists(session, "acme.prod:api_tool")
                expect(exists3).to_be_false()
            end)

            it("should check namespace existence", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "read" }
                    }
                }
                local session = create_mock_session(workspace_info)

                local exists1 = snapshot.namespace_exists(session, "keeper.demo")
                expect(exists1).to_be_true()

                local exists2 = snapshot.namespace_exists(session, "nonexistent.namespace")
                expect(exists2).to_be_false()
            end)
        end)

        describe("error handling", function()
            it("should handle missing workspace session", function()
                local entries, err = snapshot.get_namespace_snapshot(nil, "keeper.demo")
                expect(entries).to_be_nil()
                expect(err).to_match("workspace_session")
            end)

            it("should handle missing target namespace", function()
                local session = create_mock_session({ permissions = {} })
                local entries, err = snapshot.get_namespace_snapshot(session, "")
                expect(entries).to_be_nil()
                expect(err).to_match("target_namespace")
            end)

            it("should handle workspace info retrieval failure", function()
                local session = {
                    get_workspace_info = function()
                        return nil, "Workspace info failed"
                    end
                }

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(entries).to_be_nil()
                expect(err).to_match("Failed to get workspace info")
            end)

            it("should handle registry snapshot failure", function()
                -- Mock registry failure
                snapshot._deps.registry.snapshot = function()
                    return nil, "Registry unavailable"
                end

                local workspace_info = { permissions = {} }
                local session = create_mock_session(workspace_info)

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(entries).to_be_nil()
                expect(err).to_match("Failed to get registry snapshot")
            end)

            it("should handle dirty entries retrieval failure", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "read" }
                    }
                }
                local session = {
                    get_workspace_info = function()
                        return workspace_info, nil
                    end,
                    get_dirty_entries = function()
                        return nil, "Failed to get dirty entries"
                    end
                }

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(entries).to_be_nil()
                expect(err).to_match("Failed to get workspace overrides")
            end)
        end)

        describe("entry sorting and consistency", function()
            it("should sort entries by ID for consistent ordering", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.demo:*", permission_type = "read" }
                    }
                }
                local session = create_mock_session(workspace_info)

                local entries, err = snapshot.get_namespace_snapshot(session, "keeper.demo")
                expect(err).to_be_nil()
                expect(#entries).to_equal(2)

                -- Verify sorting
                expect(entries[1].id).to_equal("keeper.demo:config_lib")
                expect(entries[2].id).to_equal("keeper.demo:hello_tool")
            end)

            it("should maintain consistent namespace structure in full snapshot", function()
                local workspace_info = {
                    permissions = {
                        { namespace_pattern = "keeper.*", permission_type = "read" }
                    }
                }
                local session = create_mock_session(workspace_info)

                local namespace_snapshots, err = snapshot.get_full_snapshot(session)
                expect(err).to_be_nil()

                -- Check each namespace has sorted entries
                for namespace, entries in pairs(namespace_snapshots) do
                    for i = 2, #entries do
                        expect(entries[i - 1].id < entries[i].id).to_be_true()
                    end
                end
            end)
        end)
    end)
end

return test.run_cases(define_tests)
