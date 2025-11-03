local logger = require("logger")
local ctx = require("ctx")
local state_reader = require("state_reader")
local materialize = require("materialize")
local consts = require("consts")

local log = logger:named("state.agent.explore")

local function get_active_branch_chain(params_branch)
    if params_branch then
        if params_branch == "main" then
            return {"main"}
        else
            return {params_branch, "main"}
        end
    end

    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return {overlay_branch, "main"}
    end

    return {"main"}
end

local function extract_namespace(entry_id)
    if not entry_id or entry_id == "" then
        return nil
    end
    local colon_pos = entry_id:find(":")
    if colon_pos then
        return entry_id:sub(1, colon_pos - 1)
    end
    return nil
end

local function extract_name(entry_id)
    if not entry_id or entry_id == "" then
        return nil
    end
    local colon_pos = entry_id:find(":")
    if colon_pos then
        return entry_id:sub(colon_pos + 1)
    end
    return entry_id
end

local function matches_prefix(namespace, prefix)
    if not prefix or prefix == "" or prefix == "." then
        return true
    end
    return namespace == prefix or namespace:find("^" .. prefix:gsub("%.", "%%.") .. "%.")
end

local function get_depth(namespace, root)
    if not root or root == "" or root == "." then
        local _, count = namespace:gsub("%.", "")
        return count
    end

    local root_depth = select(2, root:gsub("%.", ""))
    local ns_depth = select(2, namespace:gsub("%.", ""))
    return ns_depth - root_depth
end

local function namespace_operation(params)
    if not params.name or params.name == "" then
        return nil, "name is required for namespace operation"
    end

    local branches = get_active_branch_chain(params.branch)
    local namespace = params.name

    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, err
    end

    reader = reader:with_namespaces(namespace):include_chunks()

    local entries, err = reader:all()
    if err then
        return nil, "Failed to fetch namespace entries: " .. err
    end

    if #entries == 0 then
        return nil, "Namespace not found or empty: " .. namespace
    end

    table.sort(entries, function(a, b)
        local name_a = extract_name(a.id)
        local name_b = extract_name(b.id)
        return name_a < name_b
    end)

    local lines = {}
    table.insert(lines, "version: \"1.0\"")
    table.insert(lines, "namespace: " .. namespace)
    table.insert(lines, "")
    table.insert(lines, "entries:")

    for _, entry in ipairs(entries) do
        if entry.chunks then
            for _, chunk in ipairs(entry.chunks) do
                if chunk.type == "definition" then
                    local in_entries_section = false
                    local skip_next_comment = false

                    for line in chunk.content:gmatch("[^\n]+") do
                        if line:match("^entries:") then
                            in_entries_section = true
                            skip_next_comment = true
                        elseif in_entries_section then
                            if skip_next_comment and line:match("^%s*#") then
                                skip_next_comment = false
                            elseif line:match("^%s*%-") or line:match("^%s%s%s%s+") then
                                table.insert(lines, line)
                            end
                        end
                    end
                    break
                end
            end
        end
    end

    return table.concat(lines, "\n")
end

local function tree_operation(params)
    local root = params.root or "."
    local max_depth = params.depth or -1
    local show_entries = params.show_entries ~= false
    local branches = get_active_branch_chain(params.branch)

    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, err
    end

    if root and root ~= "." and root ~= "" then
        reader = reader:with_namespaces(root)
    end

    if params.kind then
        reader = reader:with_kinds(params.kind)
    end

    if params.attributes and type(params.attributes) == "table" then
        reader = reader:with_attributes(params.attributes):include_attributes()
    end

    local entries, err = reader:all()
    if err then
        return nil, err
    end

    local namespace_map = {}
    for _, entry in ipairs(entries) do
        local ns = extract_namespace(entry.id)
        if ns and matches_prefix(ns, root) then
            if max_depth < 0 or get_depth(ns, root) <= max_depth then
                if not namespace_map[ns] then
                    namespace_map[ns] = {
                        namespace = ns,
                        entries = {}
                    }
                end
                table.insert(namespace_map[ns].entries, entry)
            end
        end
    end

    local sorted_namespaces = {}
    for _, data in pairs(namespace_map) do
        table.sort(data.entries, function(a, b)
            return extract_name(a.id) < extract_name(b.id)
        end)
        table.insert(sorted_namespaces, data)
    end
    table.sort(sorted_namespaces, function(a, b)
        return a.namespace < b.namespace
    end)

    local branch_display = table.concat(branches, " > ")
    local lines = {}

    local filter_parts = {}
    if params.kind then
        table.insert(filter_parts, "kind=" .. params.kind)
    end
    if params.attributes then
        for k, v in pairs(params.attributes) do
            table.insert(filter_parts, k .. "=" .. v)
        end
    end
    local filter_desc = #filter_parts > 0 and (", filters: " .. table.concat(filter_parts, ", ")) or ""

    table.insert(lines, "State Tree (" .. #entries .. " entries, " .. #sorted_namespaces .. " namespaces, branches: " .. branch_display .. filter_desc .. ")")
    table.insert(lines, "")

    for _, ns_data in ipairs(sorted_namespaces) do
        table.insert(lines, ns_data.namespace .. " [" .. #ns_data.entries .. "]")

        if show_entries then
            for _, entry in ipairs(ns_data.entries) do
                table.insert(lines, "  " .. entry.id .. " (" .. entry.kind .. ")")
            end
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

local function entries_operation(params)
    if not params.ids or #params.ids == 0 then
        return nil, "ids array is required for entries operation"
    end

    local branches = get_active_branch_chain(params.branch)

    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, err
    end

    reader = reader:with_entries(unpack(params.ids)):include_chunks()

    local entries, err = reader:all()
    if err then
        return nil, err
    end

    table.sort(entries, function(a, b)
        return a.id < b.id
    end)

    if #entries == 0 then
        return "No entries found matching the specified IDs."
    end

    local lines = {}

    for i, entry in ipairs(entries) do
        if i > 1 then
            table.insert(lines, "")
        end

        table.insert(lines, "=== " .. entry.id .. " ===")
        table.insert(lines, "")

        local formatted = materialize.format_entry_structured(entry, false)
        if formatted then
            table.insert(lines, formatted)
        end
    end

    return table.concat(lines, "\n")
end

local function search_operation(params)
    local branches = get_active_branch_chain(params.branch)
    local limit = params.limit or 100

    local reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return nil, err
    end

    if params.query and params.query ~= "" then
        reader = reader:with_search(params.query)
    end

    reader = reader:limit(limit)

    if params.namespace then
        reader = reader:with_namespaces(params.namespace)
    end

    if params.kind then
        reader = reader:with_kinds(params.kind)
    end

    if params.attributes and type(params.attributes) == "table" then
        reader = reader:with_attributes(params.attributes):include_attributes()
    end

    local entries, err = reader:all()
    if err then
        return nil, "Search failed: " .. err
    end

    table.sort(entries, function(a, b)
        return a.id < b.id
    end)

    local lines = {}
    local query_display = params.query and params.query ~= "" and ("\"" .. params.query .. "\"") or "(all)"

    local filter_parts = {}
    if params.namespace then
        table.insert(filter_parts, "namespace=" .. params.namespace)
    end
    if params.kind then
        table.insert(filter_parts, "kind=" .. params.kind)
    end
    if params.attributes then
        for k, v in pairs(params.attributes) do
            table.insert(filter_parts, k .. "=" .. v)
        end
    end
    local filter_display = #filter_parts > 0 and (", filters: " .. table.concat(filter_parts, ", ")) or ""

    table.insert(lines, "Search: " .. query_display .. " (" .. #entries .. " results" .. filter_display .. ")")
    table.insert(lines, "")

    if #entries == 0 then
        table.insert(lines, "No matches")
    else
        for _, entry in ipairs(entries) do
            table.insert(lines, entry.id .. " (" .. entry.kind .. ")")

            if entry.snippet and entry.snippet ~= "" then
                for line in entry.snippet:gmatch("[^\n]+") do
                    table.insert(lines, "  " .. line)
                end
            end
            table.insert(lines, "")
        end
    end

    return table.concat(lines, "\n")
end

local function graph_operation(params)
    if not params.id or params.id == "" then
        return nil, "id is required for graph operation"
    end

    local branches = get_active_branch_chain(params.branch)
    local direction = params.direction or "both"
    local depth = params.depth or 1

    if depth < 1 then depth = 1 end
    if depth > 5 then depth = 5 end

    local function query_edges(entry_id, dir)
        local reader, err = state_reader.for_edges(unpack(branches))
        if err then
            return nil, err
        end

        if dir == "both" then
            local out_reader = reader:with_sources(entry_id)
            if params.edge_type and params.edge_type ~= "" then
                out_reader = out_reader:with_edge_types(params.edge_type)
            end
            local outgoing, err1 = out_reader:all()

            local in_reader = state_reader.for_edges(unpack(branches)):with_targets(entry_id)
            if params.edge_type and params.edge_type ~= "" then
                in_reader = in_reader:with_edge_types(params.edge_type)
            end
            local incoming, err2 = in_reader:all()

            if err1 or err2 then
                return nil, err1 or err2
            end

            local combined = {}
            for _, e in ipairs(outgoing) do
                table.insert(combined, e)
            end
            for _, e in ipairs(incoming) do
                table.insert(combined, e)
            end
            return combined
        elseif dir == "outgoing" then
            reader = reader:with_sources(entry_id)
        elseif dir == "incoming" then
            reader = reader:with_targets(entry_id)
        end

        if params.edge_type and params.edge_type ~= "" then
            reader = reader:with_edge_types(params.edge_type)
        end

        return reader:all()
    end

    local function traverse(entry_id, dir, current_depth, visited)
        if current_depth > depth then
            return { outgoing = {}, incoming = {} }
        end

        visited = visited or {}
        if visited[entry_id] then
            return { outgoing = {}, incoming = {} }
        end
        visited[entry_id] = true

        local edges, err = query_edges(entry_id, dir)
        if err then
            log:error("Failed to query edges", { error = err, id = entry_id })
            return { outgoing = {}, incoming = {} }
        end

        local result = { outgoing = {}, incoming = {} }

        for _, edge in ipairs(edges) do
            if edge.source_id == entry_id and (dir == "outgoing" or dir == "both") then
                local child = {
                    target_id = edge.target_id,
                    edge_type = edge.edge_type,
                    metadata = edge.metadata or {}
                }
                if current_depth < depth then
                    local sub = traverse(edge.target_id, "outgoing", current_depth + 1, visited)
                    if sub.outgoing and #sub.outgoing > 0 then
                        child.children = sub.outgoing
                    end
                end
                table.insert(result.outgoing, child)
            end

            if edge.target_id == entry_id and (dir == "incoming" or dir == "both") then
                local parent = {
                    source_id = edge.source_id,
                    edge_type = edge.edge_type,
                    metadata = edge.metadata or {}
                }
                if current_depth < depth then
                    local sub = traverse(edge.source_id, "incoming", current_depth + 1, visited)
                    if sub.incoming and #sub.incoming > 0 then
                        parent.parents = sub.incoming
                    end
                end
                table.insert(result.incoming, parent)
            end
        end

        return result
    end

    local graph_data = traverse(params.id, direction, 1, {})

    local lines = {}
    table.insert(lines, "Graph: " .. params.id .. " (depth: " .. depth .. ")")
    table.insert(lines, "")

    if direction == "outgoing" or direction == "both" then
        local count = #graph_data.outgoing
        table.insert(lines, "Outgoing (" .. count .. "):")
        if count > 0 then
            for _, edge in ipairs(graph_data.outgoing) do
                table.insert(lines, "  → " .. edge.target_id .. " [" .. edge.edge_type .. "]")
                if edge.children then
                    for _, child in ipairs(edge.children) do
                        table.insert(lines, "    → " .. child.target_id .. " [" .. child.edge_type .. "]")
                        if child.children then
                            for _, grandchild in ipairs(child.children) do
                                table.insert(lines, "      → " .. grandchild.target_id .. " [" .. grandchild.edge_type .. "]")
                            end
                        end
                    end
                end
            end
        else
            table.insert(lines, "  (none)")
        end
        table.insert(lines, "")
    end

    if direction == "incoming" or direction == "both" then
        local count = #graph_data.incoming
        table.insert(lines, "Incoming (" .. count .. "):")
        if count > 0 then
            for _, edge in ipairs(graph_data.incoming) do
                table.insert(lines, "  ← " .. edge.source_id .. " [" .. edge.edge_type .. "]")
                if edge.parents then
                    for _, parent in ipairs(edge.parents) do
                        table.insert(lines, "    ← " .. parent.source_id .. " [" .. parent.edge_type .. "]")
                        if parent.parents then
                            for _, grandparent in ipairs(parent.parents) do
                                table.insert(lines, "      ← " .. grandparent.source_id .. " [" .. grandparent.edge_type .. "]")
                            end
                        end
                    end
                end
            end
        else
            table.insert(lines, "  (none)")
        end
    end

    return table.concat(lines, "\n")
end

local function handler(params)
    if not params or not params.operation then
        return nil, "operation is required (tree, namespace, entries, search, graph)"
    end

    local valid_operations = { tree = true, namespace = true, entries = true, search = true, graph = true }
    if not valid_operations[params.operation] then
        return nil, "Invalid operation. Use: tree, namespace, entries, search, graph"
    end

    if params.operation == "tree" then
        return tree_operation(params)
    elseif params.operation == "namespace" then
        return namespace_operation(params)
    elseif params.operation == "entries" then
        return entries_operation(params)
    elseif params.operation == "search" then
        return search_operation(params)
    elseif params.operation == "graph" then
        return graph_operation(params)
    end
end

return { handler = handler }