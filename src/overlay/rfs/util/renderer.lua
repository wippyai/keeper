local consts = require("consts")
local ns = require("ns")

local renderer = {}

-- ============================================================================
-- CONTEXT AND HEADER FORMATTING
-- ============================================================================

function renderer.format_context_header(session, show_original)
    if show_original then
        return "Context: Registry (no workspace)"
    elseif session then
        local workspace_info, _ = session:get_workspace_info()
        local workspace_id = workspace_info and workspace_info.workspace_id or "unknown"
        return "Context: Workspace " .. workspace_id
    else
        return "Context: Registry (no workspace)"
    end
end

-- ============================================================================
-- STATUS UTILITIES
-- ============================================================================

function renderer.get_entry_status(entry_id, session)
    if not session then
        return ""
    end

    if session:has_override(entry_id) then
        local workspace_entry, _ = session:get_workspace(entry_id)
        if workspace_entry and workspace_entry._deleted then
            return " -deleted"
        else
            local original, _ = session:get_original(entry_id)
            return original and " ~modified" or " +new"
        end
    end

    return ""
end

function renderer.get_file_status(namespace, filename, session)
    if not session then
        return ""
    end

    local dirty_entries, err = session:get_dirty_entries()
    if err or not dirty_entries then
        return ""
    end

    for _, dirty in ipairs(dirty_entries) do
        local entry_ns, entry_name = dirty.entry_id:match("([^:]+):(.+)")
        if entry_ns == namespace then
            -- Check if this file belongs to this entry
            local config = ns.get_file_config({kind = dirty.entry_kind})
            if config then
                local expected_filename = ns.generate_filename(entry_name, config)
                if expected_filename == filename then
                    if dirty.operation_type == "delete" then
                        return " -deleted"
                    elseif dirty.operation_type == "create" then
                        return " +new"
                    else
                        return " ~modified"
                    end
                end
            end
        end
    end

    return ""
end

function renderer.format_status_counts(entries, dirty_entries)
    local active_count = 0
    local new_count = 0
    local deleted_count = 0

    -- Count active entries
    for _, entry in ipairs(entries) do
        active_count = active_count + 1
    end

    -- Count workspace changes
    if dirty_entries then
        for _, dirty in ipairs(dirty_entries) do
            if dirty.operation_type == "create" then
                new_count = new_count + 1
            elseif dirty.operation_type == "delete" then
                deleted_count = deleted_count + 1
                active_count = active_count - 1 -- adjust for deleted
            end
        end
    end

    local parts = {tostring(active_count) .. " active"}
    if new_count > 0 then
        table.insert(parts, tostring(new_count) .. " new")
    end
    if deleted_count > 0 then
        table.insert(parts, tostring(deleted_count) .. " deleted")
    end

    return table.concat(parts, " + ")
end

-- ============================================================================
-- NAMESPACE TREE FORMATTING
-- ============================================================================

function renderer.format_namespace_tree(tree_data, session, show_original)
    local output = {}

    -- Context header
    table.insert(output, renderer.format_context_header(session, show_original))
    table.insert(output, "")

    local total_files = 0
    local total_namespaces = 0

    for _, ns_info in ipairs(tree_data.namespaces) do
        local namespace = ns_info.namespace
        local entry_count = ns_info.entry_count or 0
        local files = ns_info.files or {}
        local entries = ns_info.entries or {}

        total_namespaces = total_namespaces + 1
        total_files = total_files + #files

        local display_name = namespace:gsub("%.", "/") .. "/"

        -- Get status counts
        local dirty_entries = session and session:get_dirty_entries() or {}
        local status_summary = renderer.format_status_counts(entries, dirty_entries)

        -- Check if read-only
        local readonly_marker = ""
        if session then
            local workspace_info, _ = session:get_workspace_info()
            local is_readonly = true
            if workspace_info and workspace_info.permissions then
                for _, perm in ipairs(workspace_info.permissions) do
                    if perm.permission_type == "write" then
                        local pattern = "^" .. perm.namespace_pattern:gsub("%*", ".*") .. "$"
                        if namespace:match(pattern) then
                            is_readonly = false
                            break
                        end
                    end
                end
            end
            if is_readonly then
                readonly_marker = ", read-only"
            end
        end

        table.insert(output, display_name .. " [" .. entry_count .. " entries: " .. status_summary .. readonly_marker .. "]")

        -- Always show _index.yaml first
        local index_status = renderer.get_file_status(namespace, "_index.yaml", session)
        table.insert(output, "  _index.yaml" .. index_status)

        -- Show entries under _index.yaml
        for _, entry in ipairs(entries) do
            local entry_ns, entry_name = entry.id:match("([^:]+):(.+)")
            if entry_name then
                local entry_status = renderer.get_entry_status(entry.id, session)
                table.insert(output, "    * " .. entry_name .. " (" .. entry.kind .. ")" .. entry_status)
            end
        end

        -- Show deleted entries
        if session then
            local dirty_entries_list, _ = session:get_dirty_entries()
            if dirty_entries_list then
                for _, dirty in ipairs(dirty_entries_list) do
                    local entry_ns = dirty.entry_id:match("([^:]+):")
                    if entry_ns == namespace and dirty.operation_type == "delete" then
                        local _, entry_name = dirty.entry_id:match("([^:]+):(.+)")
                        table.insert(output, "    * " .. entry_name .. " (" .. dirty.entry_kind .. ") -deleted")
                    end
                end
            end
        end

        -- Show separate source files
        for _, filename in ipairs(files) do
            if filename ~= "_index.yaml" then
                local file_status = renderer.get_file_status(namespace, filename, session)
                table.insert(output, "  " .. filename .. file_status)
            end
        end

        table.insert(output, "")
    end

    table.insert(output, total_namespaces .. " namespaces, " .. total_files .. " files")

    return table.concat(output, "\n")
end

-- ============================================================================
-- FILE LISTING FORMATTING
-- ============================================================================

function renderer.format_file_listing(results, session, show_original)
    local output = {}
    table.insert(output, "=== FILE CONTENTS ===")

    table.insert(output, renderer.format_context_header(session, show_original))
    table.insert(output, "")

    for path, result in pairs(results) do
        if result and result.content then
            local status_indicator = ""
            if session and result.status then
                if result.status == "new" then
                    status_indicator = " +new"
                elseif result.status == "modified" then
                    status_indicator = " ~modified"
                elseif result.status == "deleted" then
                    status_indicator = " -deleted"
                end
            end

            table.insert(output, "--- " .. path .. status_indicator .. " ---")
            table.insert(output, result.content)
            table.insert(output, "")
        else
            table.insert(output, "--- " .. path .. " ---")
            table.insert(output, "Error: " .. (result and result.error or "File not found"))

            -- For missing files, try to suggest alternatives
            if result and result.error and result.error:match("not found") then
                local namespace, filename = path:match("([^/]+)/(.+)")
                if namespace then
                    table.insert(output, "")
                    table.insert(output, "Available in " .. namespace .. ":")
                    table.insert(output, "- Use 'tree' operation to see full namespace structure")
                end
            end

            table.insert(output, "")
        end
    end

    table.insert(output, "=== END ===")
    return table.concat(output, "\n")
end

-- ============================================================================
-- SEARCH RESULTS FORMATTING
-- ============================================================================

function renderer.format_search_results(search_results, query, search_type, session, show_original)
    local matches = search_results.main or {}
    local total_matches = #matches
    local shown_matches = math.min(10, total_matches)

    local output = {}
    table.insert(output, "=== SEARCH RESULTS ===")
    table.insert(output, "Query: \"" .. query .. "\" (" .. search_type .. ")")

    table.insert(output, renderer.format_context_header(session, show_original))

    table.insert(output, "Showing 1-" .. shown_matches .. " of " .. total_matches .. " matches")
    table.insert(output, "")

    for i = 1, shown_matches do
        local match = matches[i]

        local status_indicator = ""
        if session then
            local namespace, filename = match.file_path:match("([^/]+)/(.+)")
            if namespace and filename then
                local entry_name = filename:match("([^%.]+)")
                if entry_name and entry_name ~= "_index" then
                    local entry_id = namespace .. ":" .. entry_name
                    status_indicator = renderer.get_entry_status(entry_id, session)
                end
            end
        end

        table.insert(output, i .. ". " .. match.file_path .. ":" .. match.line .. status_indicator)

        -- Format context with line numbers
        local context_lines = {}
        for line in match.context:gmatch("[^\n]+") do
            table.insert(context_lines, line)
        end

        local context_count = #context_lines
        local lines_before = math.floor(context_count / 2)
        local match_line_pos = lines_before + 1
        local start_line = match.line - lines_before

        for j = 1, context_count do
            local line_num = start_line + j - 1
            local line_content = context_lines[j]
            local prefix = (j == match_line_pos) and ">> " or "   "
            table.insert(output, prefix .. line_num .. ": " .. line_content)
        end

        table.insert(output, "")
    end

    if total_matches > shown_matches then
        table.insert(output, "Use limit=" .. (10 + 10) .. " to see remaining " .. (total_matches - shown_matches) .. " results")
    end

    return table.concat(output, "\n")
end

return renderer