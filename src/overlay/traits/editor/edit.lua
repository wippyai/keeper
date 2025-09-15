local json = require("json")
local security = require("security")
local ctx = require("ctx")
local rfs = require("rfs")
local ns = require("ns")
local ns_diff = require("ns_diff")
local workspace = require("workspace")
local snapshot = require("snapshot")
local renderer = require("renderer")
local text = require("text")

-- Helper function to normalize path format (both slash and dot notation)
local function normalize_namespace_path(path)
    if not path or type(path) ~= "string" or path == "." then
        return path
    end

    -- Convert slash notation to dot notation for internal use
    return path:gsub("/", ".")
end

-- Helper function to check if path represents a namespace
local function path_to_namespace(path)
    if not path or type(path) ~= "string" then
        return nil
    end

    -- Convert path separators to namespace separators
    return normalize_namespace_path(path)
end

-- Helper function to get namespace entries efficiently
local function get_namespace_entries(namespace, session)
    return snapshot.get_namespace_snapshot(session, namespace)
end

-- Helper function to generate namespace tree output using renderer
local function generate_namespace_tree_output(session, namespace)
    -- Normalize the namespace path to handle both slash and dot notation
    local normalized_namespace = normalize_namespace_path(namespace)

    local reader = rfs.reader():from_workspace(session)
    local tree_result, tree_err = reader:get_tree(normalized_namespace)

    if tree_err then
        return nil, tree_err
    end

    if not tree_result or not tree_result.namespaces or #tree_result.namespaces == 0 then
        return nil, "Namespace not found: " .. namespace
    end

    -- Enhance tree_data with entries for each namespace (same as explore)
    for _, ns_info in ipairs(tree_result.namespaces) do
        local entries, entries_err = get_namespace_entries(ns_info.namespace, session)
        if not entries_err and entries then
            ns_info.entries = entries
        else
            ns_info.entries = {}
        end
    end

    return renderer.format_namespace_tree(tree_result, session, false), nil
end

-- String replacement using text module fuzzy matching
local function perform_text_replacement(content, old_str, new_str)
    -- Create a differ with fuzzy matching for AI-generated edits
    local differ, err = text.diff.new({
        diff_timeout = 5.0,
        match_threshold = 0.3,  -- Allow some fuzziness for AI edits
        match_distance = 1000,  -- Search within reasonable context
        patch_margin = 4        -- Context lines for better matching
    })
    if err then
        return nil, "Failed to create text differ: " .. err
    end

    -- First try exact match for performance and duplicate detection
    local exact_start, exact_end = content:find(old_str, 1, true)

    if exact_start then
        -- Check for exact duplicates
        local second_exact = content:find(old_str, exact_end + 1, true)
        if second_exact then
            return nil, "Text appears multiple times"
        end

        -- Use exact replacement
        local target_content = content:sub(1, exact_start - 1) .. new_str .. content:sub(exact_end + 1)
        return target_content, nil
    end

    -- No exact match found, create target content and use fuzzy patch application
    -- Hypothetically replace the old_str with new_str to create target
    local target_content = content:gsub(old_str:gsub("[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1"), new_str, 1)

    if target_content == content then
        return nil, "Text not found: " .. old_str
    end

    -- Generate patches from original to target
    local patches, err = differ:patch_make(content, target_content)
    if err then
        return nil, "Failed to create patches: " .. err
    end

    if not patches or #patches == 0 then
        return nil, "No changes detected"
    end

    -- Apply patches using text module's fuzzy matching
    local result, success = differ:patch_apply(patches, content)
    if not success then
        return nil, "Fuzzy patch application failed"
    end

    -- Verify something actually changed
    if result == content then
        return nil, "No actual changes made"
    end

    return result, nil
end

local function handler(params)
    local actor = security.actor()
    if not actor then
        return nil, "Authentication required"
    end
    local user_id = actor:id()

    local workspace_id, err = ctx.get("workspace_id")
    if err then
        return nil, "Cannot access workspace context: " .. err
    end
    if not workspace_id or workspace_id == "" then
        return nil, "No active workspace"
    end

    local session, err = workspace.open(workspace_id, user_id)
    if err then
        return nil, "Cannot access workspace: " .. err
    end

    if not params.command or params.command == "" then
        return nil, "Missing command (view, str_replace, create, insert)"
    end
    if not params.path or params.path == "" then
        return nil, "Missing path"
    end

    local valid_commands = { view = true, str_replace = true, create = true, insert = true }
    if not valid_commands[params.command] then
        return nil, "Invalid command: " .. params.command
    end

    if params.command == "str_replace" then
        if not params.old_str then
            return nil, "Missing old_str for str_replace"
        end
        if params.new_str == nil then
            return nil, "Missing new_str for str_replace"
        end
    elseif params.command == "insert" then
        if not params.insert_line then
            return nil, "Missing insert_line for insert"
        end
        if not params.new_str and not params.insert_text then
            return nil, "Missing new_str or insert_text for insert"
        end
    end

    local parts = {}
    for part in params.path:gmatch("[^/]+") do
        table.insert(parts, part)
    end

    if #parts < 1 then
        return nil, "Invalid path format: " .. params.path
    end

    -- Handle the case where path might be just a namespace
    if #parts == 1 or params.command == "view" then
        local potential_namespace = path_to_namespace(params.path)

        -- For view command, always try namespace tree first if file parsing fails
        if params.command == "view" then
            if #parts < 2 then
                -- Definitely a namespace path
                return generate_namespace_tree_output(session, potential_namespace)
            else
                -- Try as file first, fallback to namespace if file doesn't exist
                local reader = rfs.reader():from_workspace(session)
                local result = reader:read_file(params.path)

                if result.error then
                    -- Check if we can find the namespace
                    local namespace_result, namespace_err = generate_namespace_tree_output(session, potential_namespace)
                    if not namespace_err then
                        return namespace_result, nil
                    end

                    -- If namespace also fails, return the original file error
                    return nil, "Cannot read file: " .. result.error
                end

                -- File read succeeded, continue with normal view logic
                local content = result.content
                if params.view_range and type(params.view_range) == "table" and #params.view_range == 2 then
                    local start_line = tonumber(params.view_range[1])
                    local end_line = tonumber(params.view_range[2])

                    if start_line and end_line and start_line > 0 then
                        local lines = {}
                        local line_num = 1
                        for line in (content .. "\n"):gmatch("([^\n]*)\n") do
                            if line_num >= start_line and (end_line == -1 or line_num <= end_line) then
                                table.insert(lines, line_num .. ": " .. line)
                            end
                            line_num = line_num + 1
                            if end_line ~= -1 and line_num > end_line then
                                break
                            end
                        end
                        return table.concat(lines, "\n"), nil
                    end
                end

                local lines = {}
                local line_num = 1
                for line in (content .. "\n"):gmatch("([^\n]*)\n") do
                    table.insert(lines, line_num .. ": " .. line)
                    line_num = line_num + 1
                end

                return table.concat(lines, "\n"), nil
            end
        end
    end

    -- For non-view commands or when we have enough parts, continue with file operations
    if #parts < 2 then
        return nil, "Invalid path format for file operation: " .. params.path
    end

    local filename = parts[#parts]
    table.remove(parts, #parts)
    local namespace = table.concat(parts, ".")

    if params.command == "str_replace" then
        local reader = rfs.reader():from_workspace(session)
        local result = reader:read_file(params.path)
        if result.error then
            return nil, "Cannot read file: " .. result.error
        end

        local content = result.content

        local new_content, replace_err = perform_text_replacement(content, params.old_str, params.new_str)
        if replace_err then
            return nil, replace_err
        end

        local save_err = save_file_content(session, namespace, filename, new_content)
        if save_err then
            return nil, "Save failed: " .. save_err
        end

        return "Replaced text in " .. filename, nil

    elseif params.command == "create" then
        -- Allow empty file creation - default to empty string if file_text not provided
        local content = params.file_text or ""

        local save_err = save_file_content(session, namespace, filename, content)
        if save_err then
            return nil, "Create failed: " .. save_err
        end

        if content == "" then
            return "Created " .. params.path .. " (empty content)", nil
        else
            return "Created " .. params.path, nil
        end

    elseif params.command == "insert" then
        local text_to_insert = params.new_str or params.insert_text
        local reader = rfs.reader():from_workspace(session)
        local result = reader:read_file(params.path)
        if result.error then
            return nil, "Cannot read file: " .. result.error
        end

        local content = result.content
        local lines = {}
        for line in (content .. "\n"):gmatch("([^\n]*)\n") do
            table.insert(lines, line)
        end

        local insert_pos = tonumber(params.insert_line)
        if not insert_pos or insert_pos < 0 or insert_pos > #lines then
            return nil, "Invalid line number: " .. (params.insert_line or "nil")
        end

        local new_lines = {}
        for line in (text_to_insert .. "\n"):gmatch("([^\n]*)\n") do
            table.insert(new_lines, line)
        end

        for i = #new_lines, 1, -1 do
            table.insert(lines, insert_pos + 1, new_lines[i])
        end

        local new_content = table.concat(lines, "\n"):gsub("\n$", "")
        local save_err = save_file_content(session, namespace, filename, new_content)
        if save_err then
            return nil, "Insert failed: " .. save_err
        end

        return "Inserted at line " .. params.insert_line .. " in " .. filename, nil
    end
end

function save_file_content(session, namespace, filename, content)
    if filename == "_index.yaml" then
        local entries, err = snapshot.get_namespace_snapshot(session, namespace)
        if err then
            entries = {}
        end

        local namespace_obj = ns.new(namespace, entries)
        local diff_result, err = ns_diff.compare_namespace_with_yaml(namespace_obj, content)
        if err then
            return "YAML processing failed: " .. err
        end

        local operations = ns_diff.generate_workspace_operations(diff_result)

        -- Create a lookup map of original entries for data.kind restoration
        local original_entry_map = {}
        for _, entry in ipairs(entries) do
            original_entry_map[entry.id] = entry
        end

        -- Patch data.kind for template.jet entries
        for i, op in ipairs(operations) do
            if op.operation == "upsert_entry" then
                local entry_kind = nil
                for _, change in ipairs(diff_result.changes) do
                    if change.entry_id == op.entry_id then
                        if change.type == "addition" and change.entry then
                            entry_kind = change.entry.kind
                        elseif change.type == "modification" and change.new_entry then
                            entry_kind = change.new_entry.kind
                        end
                        break
                    end
                end

                -- If this is a template.jet entry, ensure data.kind exists
                if entry_kind == "template.jet" and op.entry_data then
                    local original_entry = original_entry_map[op.entry_id]
                    if original_entry and original_entry.data and original_entry.data.kind then
                        op.entry_data.kind = entry_kind
                    end
                end
            end
        end

        for i, op in ipairs(operations) do
            if op.operation == "upsert_entry" then
                -- Find the entry_kind from the diff_result changes
                local entry_kind = nil
                for _, change in ipairs(diff_result.changes) do
                    if change.entry_id == op.entry_id then
                        if change.type == "addition" and change.entry then
                            entry_kind = change.entry.kind
                        elseif change.type == "modification" and change.new_entry then
                            entry_kind = change.new_entry.kind
                        end
                        break
                    end
                end

                if not entry_kind then
                    return "Could not determine entry_kind for: " .. op.entry_id
                end

                local entry_info = {
                    kind = entry_kind,
                    data = op.entry_data,
                    meta = op.entry_meta
                }
                local result, upsert_err = session:upsert_entry(op.entry_id, entry_info)
                if upsert_err then
                    return "Entry upsert failed: " .. upsert_err
                end

            elseif op.operation == "delete_entry" then
                -- Check if entry exists in main registry
                local original_entry, _ = session:get_original(op.entry_id)

                if original_entry then
                    -- Entry exists in main registry, mark it as deleted
                    local result, delete_err = session:delete_entry(op.entry_id)
                    if delete_err then
                        return "Entry delete failed: " .. delete_err
                    end
                else
                    -- Entry doesn't exist in main registry (was created in workspace)
                    -- Reset it instead of deleting
                    local result, reset_err = session:reset_entry(op.entry_id)
                    if reset_err then
                        return "Entry reset failed: " .. reset_err
                    end
                end
            end
        end

        return nil

    else
        local entries, err = snapshot.get_namespace_snapshot(session, namespace)
        if err then
            return "Cannot get namespace: " .. err
        end

        local namespace_obj = ns.new(namespace, entries)
        local entry_name = namespace_obj:get_file_owner(filename)
        if not entry_name then
            return "File not owned by any entry: " .. filename
        end

        local entry = namespace_obj:get_entry(entry_name)
        if not entry then
            return "Entry not found: " .. entry_name
        end

        local config = ns.get_file_config(entry)
        if not config then
            return "Entry kind unsupported: " .. entry.kind
        end

        -- Prepare properly formatted entry data for workspace operations
        local workspace_entry_data = {}
        if entry.data then
            for k, v in pairs(entry.data) do
                workspace_entry_data[k] = v
            end
        end

        -- Update the source content
        workspace_entry_data[config.source_field] = content

        -- Extract entry meta (clean copy, no workspace contamination)
        local workspace_entry_meta = nil
        if entry.meta and next(entry.meta) then
            workspace_entry_meta = {}
            for k, v in pairs(entry.meta) do
                workspace_entry_meta[k] = v
            end
        end

        -- Call upsert_entry with correct format that workspace expects
        local entry_info = {
            kind = entry.kind,
            data = workspace_entry_data,
            meta = workspace_entry_meta
        }
        local result, upsert_err = session:upsert_entry(entry.id, entry_info)
        if upsert_err then
            return "Entry upsert failed: " .. upsert_err
        end

        return nil
    end
end

return { handler = handler }