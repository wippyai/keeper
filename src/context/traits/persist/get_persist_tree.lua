local ctx = require("ctx")
local state_reader = require("state_reader")

local CONSTS = table.freeze({
    TARGET_MODULE = "sql",
    EDGE_TYPE = "uses"
})

local function get_active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return { overlay_branch, "main" }
    end
    return { "main" }
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

local function handler()
    local branches = get_active_branch()

    local edges_reader, err = state_reader.for_edges(unpack(branches))
    if err then
        return "Error: " .. err
    end

    edges_reader = edges_reader:with_targets(CONSTS.TARGET_MODULE):with_edge_types(CONSTS.EDGE_TYPE)

    local edges, err = edges_reader:all()
    if err then
        return "Error: " .. err
    end

    local entry_ids = {}
    for _, edge in ipairs(edges) do
        table.insert(entry_ids, edge.source_id)
    end

    if #entry_ids == 0 then
        return "No persist layer entries found"
    end

    local entries_reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return "Error: " .. err
    end

    entries_reader = entries_reader:with_entries(unpack(entry_ids)):include_attributes()

    local entries, err = entries_reader:all()
    if err then
        return "Error: " .. err
    end

    local ns_map = {}

    for _, entry in ipairs(entries) do
        local is_test = entry.attributes and entry.attributes["meta.type"] == "test"
        if not is_test then
            local ns = extract_namespace(entry.id)
            if ns then
                if not ns_map[ns] then
                    ns_map[ns] = { namespace = ns, entries = {} }
                end

                local comment = entry.attributes and entry.attributes["meta.comment"] or ""

                table.insert(ns_map[ns].entries, {
                    id = entry.id,
                    kind = entry.kind,
                    comment = comment
                })
            end
        end
    end

    local sorted_namespaces = {}
    for _, ns_data in pairs(ns_map) do
        table.sort(ns_data.entries, function(a, b)
            return a.id < b.id
        end)
        table.insert(sorted_namespaces, ns_data)
    end
    table.sort(sorted_namespaces, function(a, b)
        return a.namespace < b.namespace
    end)

    local lines = {}
    table.insert(lines, "PERSIST LAYER")
    table.insert(lines, "")

    for _, ns_data in ipairs(sorted_namespaces) do
        table.insert(lines, ns_data.namespace .. " [" .. #ns_data.entries .. "]")
        table.insert(lines, "")

        for _, entry in ipairs(ns_data.entries) do
            local info = "[" .. entry.kind .. "]"
            if entry.comment ~= "" then
                info = info .. " " .. entry.comment
            end
            table.insert(lines, "  " .. entry.id)
            table.insert(lines, "    " .. info)
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

return { handler = handler }