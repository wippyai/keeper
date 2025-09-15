local json = require("json")
local security = require("security")
local ctx = require("ctx")
local workspace = require("workspace")

-- Forward declarations
local format_workspace_info
local analyze_pattern_coverage
local format_dirty_entries
local format_workspace_context

-- Analyze what namespaces a pattern covers (simplified)
analyze_pattern_coverage = function(pattern)
    if pattern == "*" then
        return "all namespaces"
    elseif pattern:sub(-2) == ".*" then
        return pattern:sub(1, -3) .. " + subnamespaces"
    elseif pattern:find("*", 1, true) then
        return "pattern: " .. pattern
    else
        return "exact: " .. pattern
    end
end

-- Format dirty entries list
format_dirty_entries = function(dirty_entries)
    if not dirty_entries or #dirty_entries == 0 then
        return ""
    end

    local output = {}
    table.insert(output, "")
    table.insert(output, "Modified Entries:")

    -- Group by operation type for better organization
    local creates, updates, deletes = {}, {}, {}

    for _, entry in ipairs(dirty_entries) do
        if entry.operation_type == "create" then
            table.insert(creates, entry)
        elseif entry.operation_type == "update" then
            table.insert(updates, entry)
        elseif entry.operation_type == "delete" then
            table.insert(deletes, entry)
        end
    end

    -- Show creates
    if #creates > 0 then
        table.insert(output, "  New:")
        for _, entry in ipairs(creates) do
            table.insert(output, "    + " .. entry.entry_id .. " (" .. entry.entry_kind .. ")")
        end
    end

    -- Show updates
    if #updates > 0 then
        table.insert(output, "  Modified:")
        for _, entry in ipairs(updates) do
            table.insert(output, "    ~ " .. entry.entry_id .. " (" .. entry.entry_kind .. ")")
        end
    end

    -- Show deletes
    if #deletes > 0 then
        table.insert(output, "  Deleted:")
        for _, entry in ipairs(deletes) do
            table.insert(output, "    - " .. entry.entry_id .. " (" .. entry.entry_kind .. ")")
        end
    end

    return table.concat(output, "\n")
end

-- Format workspace context
format_workspace_context = function(context_entries, verbose)
    if not context_entries or #context_entries == 0 then
        return ""
    end

    local output = {}
    table.insert(output, "")
    table.insert(output, "Workspace Context:")

    for _, context in ipairs(context_entries) do
        local line = "  " .. context.label
        if context.content_type and context.content_type ~= "text/plain" then
            line = line .. " (" .. context.content_type .. ")"
        end

        if verbose and context.content then
            line = line .. ":"
            table.insert(output, line)
            -- Indent content lines
            for content_line in context.content:gmatch("[^\r\n]+") do
                table.insert(output, "    " .. content_line)
            end
        else
            table.insert(output, line)
        end
    end

    return table.concat(output, "\n")
end

-- Format workspace information in compact format
format_workspace_info = function(workspace_info, stats, dirty_entries, context_entries, include_entries, include_context, verbose)
    local output = {}

    -- Header line with essential info
    table.insert(output, "=== WORKSPACE ===")
    table.insert(output, workspace_info.workspace_id .. " | " ..
        (workspace_info.title or "Untitled") .. " | " ..
        (workspace_info.status or "draft"))

    if workspace_info.description then
        table.insert(output, workspace_info.description)
    end

    -- Permissions (only if they exist)
    if workspace_info.permissions and #workspace_info.permissions > 0 then
        table.insert(output, "")
        table.insert(output, "Permissions:")
        for _, perm in ipairs(workspace_info.permissions) do
            local line = "  " .. perm.permission_type .. ": " .. perm.namespace_pattern
            if verbose then
                line = line .. " → " .. analyze_pattern_coverage(perm.namespace_pattern)
            end
            table.insert(output, line)
        end
    end

    -- Context (if requested and exists)
    if include_context then
        local context_details = format_workspace_context(context_entries, verbose)
        if context_details ~= "" then
            table.insert(output, context_details)
        end
    end

    -- Changes summary (only if there are changes)
    local total = stats.total_entries or 0
    if total > 0 then
        table.insert(output, "")

        local changes = {}
        if (stats.creates or 0) > 0 then table.insert(changes, stats.creates .. " new") end
        if (stats.updates or 0) > 0 then table.insert(changes, stats.updates .. " modified") end
        if (stats.deletes or 0) > 0 then table.insert(changes, stats.deletes .. " deleted") end

        if #changes > 0 then
            table.insert(output, "Changes: " .. table.concat(changes, ", "))
            if stats.is_dirty then
                table.insert(output, "Status: Unsaved changes")
            end
        else
            table.insert(output, "Entries: " .. total .. " (no changes)")
        end

        -- Show detailed entry list if requested
        if include_entries then
            local entry_details = format_dirty_entries(dirty_entries)
            if entry_details ~= "" then
                table.insert(output, entry_details)
            end
        end
    end

    return table.concat(output, "\n")
end

-- Main handler function
local function handler(params)
    -- Get user context
    local actor = security.actor()
    if not actor then
        return nil, "Authentication required"
    end
    local user_id = actor:id()

    -- Handle context conflict detection
    local ctx_workspace_id, _ = ctx.get("workspace_id")
    local param_workspace_id = params.workspace_id

    if ctx_workspace_id and param_workspace_id and ctx_workspace_id ~= param_workspace_id then
        return nil, "Context conflict detected. Workspace '" .. ctx_workspace_id ..
            "' is active in context, but workspace_id parameter '" .. param_workspace_id ..
            "' was also provided. Context workspace takes precedence - remove workspace_id parameter."
    end

    -- Determine active workspace
    local active_workspace_id = ctx_workspace_id or param_workspace_id

    if not active_workspace_id then
        return nil, "No workspace specified. Either set workspace context or provide workspace_id parameter."
    end

    -- Open workspace session
    local session, err = workspace.open(active_workspace_id, user_id)
    if err then
        return nil, "Failed to open workspace session: " .. err
    end

    -- Get workspace info
    local workspace_info, info_err = session:get_workspace_info()
    if info_err then
        return nil, "Failed to get workspace info: " .. info_err
    end

    -- Get workspace stats
    local stats, stats_err = session:get_workspace_stats()
    if stats_err then
        return nil, "Failed to get workspace stats: " .. stats_err
    end

    -- Get dirty entries for detailed view
    local dirty_entries = {}
    local include_entries = params.include_entries ~= false
    if include_entries then
        local entries, entries_err = session:get_dirty_entries()
        if not entries_err and entries then
            dirty_entries = entries
        end
    end

    -- Get workspace context if requested
    local context_entries = {}
    local include_context = params.include_context == true
    if include_context then
        local context, context_err = session:get_workspace_context()
        if not context_err and context then
            context_entries = context
        end
    end

    -- Build output options
    local verbose = params.verbose == true

    return format_workspace_info(workspace_info, stats, dirty_entries, context_entries, include_entries, include_context, verbose), nil
end

return { handler = handler }