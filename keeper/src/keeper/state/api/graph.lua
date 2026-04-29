local http = require("http")
local state_reader = require("state_reader")
local security = require("security")
local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local ns = req:query("namespace")

    local entry_reader, err = state_reader.for_branch("main")
    if err or not entry_reader then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Reader failed: " .. tostring(err) })
        return
    end

    if ns and ns ~= "" then
        entry_reader = entry_reader:with_namespaces(ns)
    end

    local entries, entries_err = entry_reader:all()
    if entries_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Entries failed: " .. tostring(entries_err) })
        return
    end

    local nodes = {}
    local node_set = {}
    for _, e in ipairs(entries or {}) do
        table.insert(nodes, { id = e.id, kind = e.kind })
        node_set[e.id] = true
    end

    local edge_reader, edge_reader_err = state_reader.for_edges("main")
    if edge_reader_err or not edge_reader then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Edge reader failed: " .. tostring(edge_reader_err) })
        return
    end

    local raw_edges, raw_edges_err = edge_reader:all()
    if raw_edges_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Edges failed: " .. tostring(raw_edges_err) })
        return
    end

    local edges = {}
    for _, e in ipairs(raw_edges or {}) do
        local src = e.source_id
        local tgt = e.target_id
        if not tgt:find(":") then goto continue end
        if not src:find(":") then goto continue end
        if ns and ns ~= "" then
            if node_set[src] and node_set[tgt] then
                table.insert(edges, { source = src, target = tgt, type = e.edge_type })
            end
        else
            if node_set[src] or node_set[tgt] then
                table.insert(edges, { source = src, target = tgt, type = e.edge_type })
                if not node_set[src] then
                    table.insert(nodes, { id = src, kind = "external" })
                    node_set[src] = true
                end
                if not node_set[tgt] then
                    table.insert(nodes, { id = tgt, kind = "external" })
                    node_set[tgt] = true
                end
            end
        end
        ::continue::
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, nodes = nodes,
        edges = edges,
        count = { nodes = #nodes, edges = #edges }, })
end

return { handler = handler }
