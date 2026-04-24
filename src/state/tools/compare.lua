local audit = require("audit")
local state_reader = require("state_reader")
local materialize = require("materialize")
local entry_lib = require("entry_lib")
local summarize = require("summarize")

local extract_namespace = entry_lib.extract_namespace
local extract_name = entry_lib.extract_name

local function load_branch_entries(branches, namespace_filter, entry_ids)
    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, err
    end

    reader = reader:include_chunks():include_deleted()

    if namespace_filter then
        reader = reader:with_namespaces(namespace_filter)
    end

    if entry_ids and #entry_ids > 0 then
        reader = reader:with_entries(unpack(entry_ids))
    end

    local entries, err = reader:all()
    if err then
        return nil, err
    end

    local entry_map = {}
    for _, entry in ipairs(entries) do
        entry_map[entry.id] = entry
    end

    return entry_map, nil
end

local function classify_changes(source_map, target_map)
    local added = {}
    local deleted = {}
    local modified = {}
    local unchanged = {}

    for id, target_entry in pairs(target_map) do
        local source_entry = source_map[id]

        if target_entry.deleted == 1 then
            if source_entry and source_entry.deleted == 0 then
                table.insert(deleted, id)
            end
        elseif not source_entry or source_entry.deleted == 1 then
            table.insert(added, id)
        else
            local source_def, source_src = entry_lib.entry_content(source_entry)
            local target_def, target_src = entry_lib.entry_content(target_entry)

            local source_hash = entry_lib.content_hash(source_def, source_src)
            local target_hash = entry_lib.content_hash(target_def, target_src)

            if source_hash ~= target_hash then
                table.insert(modified, id)
            else
                table.insert(unchanged, id)
            end
        end
    end

    for id, source_entry in pairs(source_map) do
        if not target_map[id] and source_entry.deleted == 0 then
            table.insert(deleted, id)
        end
    end

    table.sort(added)
    table.sort(deleted)
    table.sort(modified)
    table.sort(unchanged)

    return {
        added = added,
        deleted = deleted,
        modified = modified,
        unchanged = unchanged
    }
end

local function generate_unified_diff(old_text: string, new_text: string, context_lines: number?)
    context_lines = context_lines or 3

    local old_lines: any = {}
    for line in (old_text .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(old_lines, line)
    end

    local new_lines: any = {}
    for line in (new_text .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(new_lines, line)
    end

    local old_line_map = {}
    for i, line in ipairs(old_lines) do
        if not old_line_map[line] then
            old_line_map[line] = {}
        end
        table.insert(old_line_map[line], i)
    end

    local new_line_map = {}
    for i, line in ipairs(new_lines) do
        if not new_line_map[line] then
            new_line_map[line] = {}
        end
        table.insert(new_line_map[line], i)
    end

    local matches = {}
    for i, line in ipairs(new_lines) do
        if old_line_map[line] then
            for _, j in ipairs(old_line_map[line]) do
                table.insert(matches, {old_idx = j, new_idx = i})
            end
        end
    end

    table.sort(matches, function(a, b)
        if a.old_idx == b.old_idx then
            return a.new_idx < b.new_idx
        end
        return a.old_idx < b.old_idx
    end)

    local lcs = {}
    for _, match in ipairs(matches) do
        local can_add = true
        for _, existing in ipairs(lcs) do
            if match.old_idx <= existing.old_idx or match.new_idx <= existing.new_idx then
                can_add = false
                break
            end
        end
        if can_add then
            table.insert(lcs, match)
        end
    end

    local hunks = {}
    local current_hunk = nil

    local old_idx = 1
    local new_idx = 1

    for _, match in ipairs(lcs) do
        while old_idx < match.old_idx or new_idx < match.new_idx do
            if not current_hunk then
                current_hunk = {
                    old_start = old_idx,
                    new_start = new_idx,
                    lines = {}
                }
            end

            if old_idx < match.old_idx and new_idx < match.new_idx then
                table.insert(current_hunk.lines, {type = "remove", text = old_lines[old_idx]})
                old_idx = old_idx + 1
                table.insert(current_hunk.lines, {type = "add", text = new_lines[new_idx]})
                new_idx = new_idx + 1
            elseif old_idx < match.old_idx then
                table.insert(current_hunk.lines, {type = "remove", text = old_lines[old_idx]})
                old_idx = old_idx + 1
            elseif new_idx < match.new_idx then
                table.insert(current_hunk.lines, {type = "add", text = new_lines[new_idx]})
                new_idx = new_idx + 1
            end
        end

        if current_hunk then
            current_hunk.old_end = old_idx - 1
            current_hunk.new_end = new_idx - 1
            table.insert(hunks, current_hunk)
            current_hunk = nil
        end

        old_idx = match.old_idx + 1
        new_idx = match.new_idx + 1
    end

    while old_idx <= #old_lines or new_idx <= #new_lines do
        if not current_hunk then
            current_hunk = {
                old_start = old_idx,
                new_start = new_idx,
                lines = {}
            }
        end

        if old_idx <= #old_lines and new_idx <= #new_lines then
            table.insert(current_hunk.lines, {type = "remove", text = old_lines[old_idx]})
            old_idx = old_idx + 1
            table.insert(current_hunk.lines, {type = "add", text = new_lines[new_idx]})
            new_idx = new_idx + 1
        elseif old_idx <= #old_lines then
            table.insert(current_hunk.lines, {type = "remove", text = old_lines[old_idx]})
            old_idx = old_idx + 1
        elseif new_idx <= #new_lines then
            table.insert(current_hunk.lines, {type = "add", text = new_lines[new_idx]})
            new_idx = new_idx + 1
        end
    end

    if current_hunk then
        current_hunk.old_end = old_idx - 1
        current_hunk.new_end = new_idx - 1
        table.insert(hunks, current_hunk)
    end

    local output_lines = {}

    for _, hunk in ipairs(hunks) do
        local context_start_old = math.max(1, hunk.old_start - context_lines)
        local context_end_old = math.min(#old_lines, hunk.old_end + context_lines)
        local context_start_new = math.max(1, hunk.new_start - context_lines)
        local context_end_new = math.min(#new_lines, hunk.new_end + context_lines)

        for i = context_start_old, hunk.old_start - 1 do
            table.insert(output_lines, " " .. old_lines[i])
        end

        for _, line in ipairs(hunk.lines) do
            if line.type == "remove" then
                table.insert(output_lines, "-" .. line.text)
            elseif line.type == "add" then
                table.insert(output_lines, "+" .. line.text)
            end
        end

        for i = hunk.old_end + 1, context_end_old do
            if i <= #old_lines then
                table.insert(output_lines, " " .. old_lines[i])
            end
        end
    end

    return table.concat(output_lines, "\n")
end

local function summary_mode(params)
    local source_branch = params.source or "main"
    local target_branch = params.target
    local namespace_filter = params.namespace

    if not target_branch or target_branch == "" then
        return nil, "target branch is required"
    end

    local source_branches = source_branch == "main" and {"main"} or {source_branch, "main"}
    local target_branches = target_branch == "main" and {"main"} or {target_branch, "main"}

    local source_map, err = load_branch_entries(source_branches, namespace_filter, nil)
    if err then
        return nil, "Failed to load source branch: " .. err
    end

    local target_map, err = load_branch_entries(target_branches, namespace_filter, nil)
    if err then
        return nil, "Failed to load target branch: " .. err
    end

    local changes = classify_changes(source_map, target_map)

    local lines = {}
    table.insert(lines, "Branch Comparison: " .. source_branch .. " -> " .. target_branch)
    table.insert(lines, "")

    if #changes.added > 0 then
        table.insert(lines, "=== ADDED (" .. #changes.added .. ") ===")
        for _, id in ipairs(changes.added) do
            local entry = target_map[id]
            table.insert(lines, id .. " (" .. entry.kind .. ")")
        end
        table.insert(lines, "")
    end

    if #changes.modified > 0 then
        table.insert(lines, "=== MODIFIED (" .. #changes.modified .. ") ===")
        for _, id in ipairs(changes.modified) do
            local entry = target_map[id]
            table.insert(lines, id .. " (" .. entry.kind .. ")")
        end
        table.insert(lines, "")
    end

    if #changes.deleted > 0 then
        table.insert(lines, "=== DELETED (" .. #changes.deleted .. ") ===")
        for _, id in ipairs(changes.deleted) do
            local entry = source_map[id]
            table.insert(lines, id .. " (" .. entry.kind .. ")")
        end
        table.insert(lines, "")
    end

    if #changes.added == 0 and #changes.deleted == 0 and #changes.modified == 0 then
        table.insert(lines, "No changes detected")
    end

    return table.concat(lines, "\n")
end

local function tree_mode(params)
    local source_branch = params.source or "main"
    local target_branch = params.target
    local namespace_filter = params.namespace

    if not target_branch or target_branch == "" then
        return nil, "target branch is required"
    end

    local source_branches = source_branch == "main" and {"main"} or {source_branch, "main"}
    local target_branches = target_branch == "main" and {"main"} or {target_branch, "main"}

    local source_map, err = load_branch_entries(source_branches, namespace_filter, nil)
    if err then
        return nil, "Failed to load source branch: " .. err
    end

    local target_map, err = load_branch_entries(target_branches, namespace_filter, nil)
    if err then
        return nil, "Failed to load target branch: " .. err
    end

    local changes = classify_changes(source_map, target_map)

    local namespace_stats = {}

    for _, id in ipairs(changes.added) do
        local ns = extract_namespace(id)
        if ns then
            if not namespace_stats[ns] then
                namespace_stats[ns] = {added = 0, deleted = 0, modified = 0}
            end
            namespace_stats[ns].added = (namespace_stats[ns].added or 0) + 1
        end
    end

    for _, id in ipairs(changes.deleted) do
        local ns = extract_namespace(id)
        if ns then
            if not namespace_stats[ns] then
                namespace_stats[ns] = {added = 0, deleted = 0, modified = 0}
            end
            namespace_stats[ns].deleted = (namespace_stats[ns].deleted or 0) + 1
        end
    end

    for _, id in ipairs(changes.modified) do
        local ns = extract_namespace(id)
        if ns then
            if not namespace_stats[ns] then
                namespace_stats[ns] = {added = 0, deleted = 0, modified = 0}
            end
            namespace_stats[ns].modified = (namespace_stats[ns].modified or 0) + 1
        end
    end

    local sorted_namespaces = {}
    for ns, stats in pairs(namespace_stats) do
        table.insert(sorted_namespaces, {namespace = ns, stats = stats})
    end
    table.sort(sorted_namespaces, function(a, b)
        return a.namespace < b.namespace
    end)

    local lines = {}
    table.insert(lines, "Branch Comparison: " .. source_branch .. " -> " .. target_branch)
    table.insert(lines, "")
    table.insert(lines, "Summary:")
    table.insert(lines, "  Added:    " .. #changes.added)
    table.insert(lines, "  Deleted:  " .. #changes.deleted)
    table.insert(lines, "  Modified: " .. #changes.modified)
    table.insert(lines, "")

    if #sorted_namespaces > 0 then
        table.insert(lines, "Changes by Namespace:")
        table.insert(lines, "")

        for _, ns_data in ipairs(sorted_namespaces) do
            local ns = ns_data.namespace
            local stats = ns_data.stats

            local status_parts = {}
            if stats.added > 0 then
                table.insert(status_parts, "+" .. stats.added)
            end
            if stats.deleted > 0 then
                table.insert(status_parts, "-" .. stats.deleted)
            end
            if stats.modified > 0 then
                table.insert(status_parts, "~" .. stats.modified)
            end

            local status_str = " [" .. table.concat(status_parts, ", ") .. "]"
            table.insert(lines, "  " .. ns .. status_str)
        end
    else
        table.insert(lines, "No changes detected")
    end

    return table.concat(lines, "\n")
end

local function entries_mode(params)
    local source_branch = params.source or "main"
    local target_branch = params.target
    local namespace_filter = params.namespace
    local entry_ids = params.ids
    local show_unchanged = params.show_unchanged or false

    if not target_branch or target_branch == "" then
        return nil, "target branch is required"
    end

    local source_branches = source_branch == "main" and {"main"} or {source_branch, "main"}
    local target_branches = target_branch == "main" and {"main"} or {target_branch, "main"}

    local source_map, err = load_branch_entries(source_branches, namespace_filter, entry_ids)
    if err then
        return nil, "Failed to load source branch: " .. err
    end

    local target_map, err = load_branch_entries(target_branches, namespace_filter, entry_ids)
    if err then
        return nil, "Failed to load target branch: " .. err
    end

    local changes = classify_changes(source_map, target_map)

    local lines = {}
    table.insert(lines, "Branch Comparison: " .. source_branch .. " -> " .. target_branch)
    table.insert(lines, "")

    if #changes.added > 0 then
        table.insert(lines, "=== ADDED (" .. #changes.added .. ") ===")
        table.insert(lines, "")
        for _, id in ipairs(changes.added) do
            local entry = target_map[id]
            table.insert(lines, "Entry: " .. id .. " (" .. entry.kind .. ")")
            table.insert(lines, "")

            local formatted = materialize.format_entry_structured(entry, false)
            if formatted then
                table.insert(lines, formatted)
            end
            table.insert(lines, "")
        end
        table.insert(lines, "")
    end

    if #changes.deleted > 0 then
        table.insert(lines, "=== DELETED (" .. #changes.deleted .. ") ===")
        table.insert(lines, "")
        for _, id in ipairs(changes.deleted) do
            local entry = source_map[id]
            table.insert(lines, "Entry: " .. id .. " (" .. entry.kind .. ")")
            table.insert(lines, "")

            local formatted = materialize.format_entry_structured(entry, false)
            if formatted then
                table.insert(lines, formatted)
            end
            table.insert(lines, "")
        end
        table.insert(lines, "")
    end

    if #changes.modified > 0 then
        table.insert(lines, "=== MODIFIED (" .. #changes.modified .. ") ===")
        table.insert(lines, "")
        for _, id in ipairs(changes.modified) do
            local source_entry = source_map[id]
            local target_entry = target_map[id]

            table.insert(lines, "Entry: " .. id .. " (" .. target_entry.kind .. ")")
            table.insert(lines, "")

            local source_def, source_src = entry_lib.entry_content(source_entry)
            local target_def, target_src = entry_lib.entry_content(target_entry)

            if source_def ~= target_def then
                table.insert(lines, "--- Definition (source)")
                table.insert(lines, "+++ Definition (target)")
                table.insert(lines, "")
                local diff = generate_unified_diff(source_def, target_def, 3)
                table.insert(lines, diff)
                table.insert(lines, "")
            end

            if source_src ~= target_src then
                table.insert(lines, "--- Source (source)")
                table.insert(lines, "+++ Source (target)")
                table.insert(lines, "")
                local diff = generate_unified_diff(source_src, target_src, 3)
                table.insert(lines, diff)
                table.insert(lines, "")
            end
        end
    end

    if show_unchanged and #changes.unchanged > 0 then
        table.insert(lines, "=== UNCHANGED (" .. #changes.unchanged .. ") ===")
        table.insert(lines, "")
    end

    if #changes.added == 0 and #changes.deleted == 0 and #changes.modified == 0 then
        table.insert(lines, "No changes detected")
    end

    return table.concat(lines, "\n")
end

local function do_handler(params)
    if not params or not params.mode then
        return nil, "mode is required (tree, summary, entries)"
    end

    local result, err
    if params.mode == "tree" then
        result, err = tree_mode(params)
    elseif params.mode == "summary" then
        result, err = summary_mode(params)
    elseif params.mode == "entries" then
        result, err = entries_mode(params)
    else
        return nil, "Invalid mode: " .. params.mode .. " (use: tree, summary, entries)"
    end

    if not err and result and type(result) == "string" and params.full ~= true then
        local goal = params.goal
        if not goal or goal == "" then
            goal = "Changes between " .. (params.source or "main") ..
                " and " .. (params.target or "?") .. " (" .. params.mode .. " view)"
        end
        local compressed, _sum_err, was_summarized = summarize.summarize(result, goal, {
            tool = "compare_state_branches:" .. params.mode,
        })
        if was_summarized then
            result = compressed
        end
    end

    return result, err
end

local function handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "compare",
        discriminator = "compare." .. (params.mode or "?"),
        target        = (params.target or "?") .. " vs " .. (params.source or "main"),
        params        = {
            mode           = params.mode,
            source         = params.source,
            target         = params.target,
            namespace      = params.namespace,
            ids            = params.ids,
            show_unchanged = params.show_unchanged,
        },
        summarise = function(_result, err)
            if err then return "compare failed: " .. tostring(err) end
            return "compared " .. (params.target or "?") .. " vs " .. (params.source or "main")
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }