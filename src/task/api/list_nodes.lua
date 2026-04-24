-- GET /api/tasks/:id/nodes — unified task event/payload stream from keeper_task_nodes.
--
-- Query params:
--   visibility   = "user" (default) | "user,debug" | "all"
--   types        = csv of type names (e.g. "spec,finding,tool_call")
--   since_seq    = integer; returns rows with seq > since_seq (for incremental polling)
--   limit        = integer (default 1000)
--   parent       = node_id; returns direct children of that node (for tree expansion)
--
-- Response: { success, nodes[], count, max_seq }

local http   = require("http")
local reader = require("nodes_reader")

local function csv(s)
    if not s or s == "" then return nil end
    local out = {}
    for v in string.gmatch(s, "[^,]+") do
        local t = (v:gsub("^%s+", ""):gsub("%s+$", ""))
        if t ~= "" then table.insert(out, t) end
    end
    return (#out > 0 and out) or nil
end

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local task_id = req:param("id") or req:query("id")
    if not task_id or task_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "task id required" })
        return
    end

    local opts = {
        visibility = req:query("visibility") or "user",
        since_seq  = tonumber(req:query("since_seq")),
        types      = csv(req:query("types")),
        limit      = tonumber(req:query("limit")) or 1000,
    }

    local nodes, err
    local parent = req:query("parent")
    if parent and parent ~= "" then
        nodes, err = reader.children(parent)
    else
        nodes, err = reader.list(task_id, opts)
    end

    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    local max_seq = 0
    for _, n in ipairs(nodes or {}) do
        local s = tonumber(n.seq) or 0
        if s > max_seq then max_seq = s end
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success = true,
        nodes   = nodes or {},
        count   = #(nodes or {}),
        max_seq = max_seq,
    })
end

return { handler = handler }
