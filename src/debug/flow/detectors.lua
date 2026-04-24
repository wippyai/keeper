local hash = require("hash")
local json = require("json")

local repo = require("repo")
local render = require("render")

local M = {}

local function decode(row)
    return repo.decode_content(row)
end

local function canonical(t)
    if type(t) ~= "table" then return tostring(t) end
    local keys = {}
    for k in pairs(t) do table.insert(keys, k) end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, k in ipairs(keys) do
        local v = t[k]
        if type(v) == "table" then
            table.insert(parts, tostring(k) .. "=" .. canonical(v))
        else
            table.insert(parts, tostring(k) .. "=" .. tostring(v))
        end
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function args_hash(tool_name, args)
    local key = tostring(tool_name) .. "|" .. canonical(args or {})
    local ok, h = pcall(hash.md5, key)
    if ok then return h end
    return key
end

function M.detect_iteration_exhaustion(nodes, findings)
    for _, n in ipairs(nodes) do
        if n.type == "userspace.dataflow.node.agent:node" and n.status == "failed" then
            local meta = n.metadata or {}
            local err_code = meta.error and meta.error.code
            local msg = meta.status_message or ""
            if err_code == "MAX_ITERATION" or err_code == "MAX_ITERATIONS"
                or msg:find("Maximum iterations", 1, true)
                or msg:find("iterations reached", 1, true) then
                table.insert(findings, {
                    type = "iteration_exhaustion",
                    severity = "high",
                    node_id = n.node_id,
                    title = render.node_title(n),
                    evidence = msg ~= "" and msg or "agent metadata.error.code=" .. tostring(err_code),
                    suggested = "inspect node_id=" .. n.node_id .. " view=conversation",
                })
            end
        end
    end
end

function M.detect_cycle_exhaustion(nodes, findings)
    for _, n in ipairs(nodes) do
        if n.type == "userspace.dataflow.node.cycle:cycle" and n.status == "failed" then
            local meta = n.metadata or {}
            local msg = meta.status_message or ""
            local err_code = meta.error and meta.error.code
            if err_code == "MAX_ITERATIONS_EXCEEDED" or msg:find("iterations", 1, true) then
                table.insert(findings, {
                    type = "cycle_exhaustion",
                    severity = "high",
                    node_id = n.node_id,
                    title = render.node_title(n),
                    evidence = msg ~= "" and msg or tostring(err_code),
                    suggested = "inspect node_id=" .. n.node_id .. " view=summary",
                })
            end
        end
    end
end

function M.detect_tool_failures(nodes, findings)
    for _, n in ipairs(nodes) do
        if n.type == "tool.call" and n.status == "failed" then
            local meta = n.metadata or {}
            local err_msg = meta.error_message or (meta.error and meta.error.message) or ""
            table.insert(findings, {
                type = "tool_failure",
                severity = "medium",
                node_id = n.node_id,
                parent_id = n.parent_node_id,
                title = (meta.title or "tool.call") .. ": " .. render.clip(err_msg, 120),
                evidence = render.clip(err_msg, 200),
                suggested = "inspect node_id=" .. n.node_id .. " view=tool_call",
            })
        end
    end
end

function M.detect_retry_loops(data_rows, findings)
    local actions_by_node = {}
    local obs_by_node = {}
    for _, row in ipairs(data_rows) do
        if row.type == "agent.action" then
            actions_by_node[row.node_id] = actions_by_node[row.node_id] or {}
            table.insert(actions_by_node[row.node_id], row)
        elseif row.type == "agent.observation" then
            obs_by_node[row.node_id] = obs_by_node[row.node_id] or {}
            table.insert(obs_by_node[row.node_id], row)
        end
    end

    for node_id, actions in pairs(actions_by_node) do
        local flat = {}
        for _, a in ipairs(actions) do
            local v = decode(a)
            if type(v) == "table" and v.tool_calls then
                for _, tc in ipairs(v.tool_calls) do
                    table.insert(flat, { name = tc.name, args = tc.arguments, action_row = a })
                end
            end
        end
        local counts = {}
        for _, f in ipairs(flat) do
            local h = args_hash(f.name, f.args)
            counts[h] = counts[h] or { count = 0, tool = f.name, args = f.args }
            counts[h].count = counts[h].count + 1
        end
        for _, c in pairs(counts) do
            if c.count >= 3 then
                table.insert(findings, {
                    type = "retry_loop",
                    severity = "high",
                    node_id = node_id,
                    title = c.tool .. " called " .. c.count .. "x with identical args",
                    evidence = render.clip(c.args, render.ARGS_PREVIEW),
                    suggested = "inspect node_id=" .. node_id .. " view=conversation",
                })
            end
        end
    end
end

local SEQUENCE_RULES = {
    { pattern = "Cannot modify main branch", hint = "call set_branch before edits" },
    { pattern = "No branch selected",        hint = "call set_branch first" },
    { pattern = "branch first",              hint = "set the active branch before this operation" },
    { pattern = "Invalid entry ID format",   hint = "entry id must be namespace:name" },
    { pattern = "not found",                 hint = "target entry/resource missing — verify id before call" },
}

function M.detect_sequence_violations(data_rows, findings)
    for _, row in ipairs(data_rows) do
        if row.type == "agent.observation" then
            local v = decode(row)
            local text
            if type(v) == "string" then
                text = v
            elseif type(v) == "table" then
                local ok, enc = pcall(json.encode, v)
                text = ok and enc or ""
            else
                text = tostring(v or "")
            end
            for _, rule in ipairs(SEQUENCE_RULES) do
                if text:find(rule.pattern, 1, true) then
                    table.insert(findings, {
                        type = "sequence_violation",
                        severity = "medium",
                        node_id = row.node_id,
                        title = "precondition missed: " .. rule.pattern,
                        evidence = render.clip(text, 200),
                        suggested = rule.hint .. " — inspect node_id=" .. (row.node_id or "") .. " view=conversation",
                    })
                    break
                end
            end
        end
    end
end

function M.analyze(nodes, data_rows)
    nodes = nodes or {}
    data_rows = data_rows or {}
    local findings = {}
    M.detect_iteration_exhaustion(nodes, findings)
    M.detect_cycle_exhaustion(nodes, findings)
    M.detect_tool_failures(nodes, findings)
    M.detect_retry_loops(data_rows, findings)
    M.detect_sequence_violations(data_rows, findings)

    local severity_rank = { high = 3, medium = 2, low = 1 }
    table.sort(findings, function(a, b)
        local sa = severity_rank[a.severity] or 0
        local sb = severity_rank[b.severity] or 0
        if sa ~= sb then return sa > sb end
        return (a.type or "") < (b.type or "")
    end)
    return findings
end

function M.run(dataflow_id)
    local nodes = repo.all_nodes(dataflow_id)
    local data_rows = repo.flow_data(dataflow_id, {
        types = { "agent.action", "agent.observation" },
    })
    return M.analyze(nodes, data_rows)
end

return M
