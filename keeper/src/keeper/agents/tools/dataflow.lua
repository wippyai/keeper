-- keeper.agents.tools:dataflow
--
-- Action-dispatched dataflow debug tool. Every action returns a markdown
-- string via _mcp_content so the LLM reads formatted text instead of
-- re-parsing JSON. Pointer-first: each action nudges toward the next call.

local json = require("json")

local repo = require("repo")
local render = require("render")
local detectors = require("detectors")

local M = {}

type ActionFn = (unknown?) -> (unknown?, string?)
type ToolCallEntry = {
    call: {[string]: unknown},
    call_row: unknown,
    observation?: unknown,
}

local ACTIONS: {[string]: ActionFn} = {}

local function mcp_text(text: string)
    return { _mcp_content = { { type = "text", text = text } } }
end

-- ---------------------------------------------------------------------------
-- overview
-- ---------------------------------------------------------------------------

function ACTIONS.overview(params)
    local filters = {
        status = params.status,
        has_failures = params.has_failures == true,
        has_running = params.has_running == true,
        min_nodes = tonumber(params.min_nodes),
        since = params.since,
    }
    local limit = math.min(math.max(tonumber(params.limit) or 20, 1), 50)
    local rows = repo.overview(filters, limit)

    local lines = {}
    table.insert(lines, string.format("# Dataflows (%d, newest first)", #rows))
    if #rows == 0 then
        table.insert(lines, "")
        table.insert(lines, "No flows match filters.")
        return mcp_text(table.concat(lines, "\n"))
    end

    table.insert(lines, "")
    table.insert(lines, render.table_header({
        "flow_id", "status", "nodes", "failed", "running", "agents", "tool_calls", "title",
    }))

    for _, r in ipairs(rows) do
        local title = r.metadata and (r.metadata.title or r.metadata.name) or ""
        if type(title) ~= "string" then title = "" end
        table.insert(lines, render.table_row({
            r.dataflow_id,
            render.status_marker(r.status),
            r.node_count,
            r.failed_nodes,
            r.running_nodes,
            r.agent_nodes,
            r.tool_calls,
            render.clip(title, 60),
        }))
    end

    table.insert(lines, "")
    table.insert(lines, "Next: `action=tree flow_id=<id>` for hierarchy, or `action=anomalies flow_id=<id>` for findings.")
    return mcp_text(table.concat(lines, "\n"))
end

-- ---------------------------------------------------------------------------
-- tree
-- ---------------------------------------------------------------------------

function M.collapse_siblings(children_ids, by_id)
    -- Group consecutive-sibling sequences of tool.call with same status into
    -- "tool.call x N (status)" pseudo rows. Returns list of { kind, ... }.
    local groups = {}
    local i = 1
    while i <= #children_ids do
        local n = by_id[children_ids[i]]
        if not n then i = i + 1; goto cont end
        if n.type == "tool.call" then
            local j = i
            local same_status = n.status
            while j <= #children_ids do
                local m = by_id[children_ids[j]]
                if not m or m.type ~= "tool.call" or m.status ~= same_status then break end
                j = j + 1
            end
            local count = j - i
            if count >= 5 then
                -- Collapse into a group. Keep first + "... N more" summary for agent.
                table.insert(groups, {
                    kind = "collapsed",
                    status = same_status,
                    count = count,
                    first = n,
                    ids = { unpack(children_ids, i, j - 1) },
                })
                i = j
                goto cont
            end
        end
        table.insert(groups, { kind = "node", node = n })
        i = i + 1
        ::cont::
    end
    return groups
end
local collapse_siblings = M.collapse_siblings

local function walk_tree(node_id, adj, out, depth, opts, counter)
    if counter.count >= render.TREE_CAP then
        if not counter.truncated then
            table.insert(out, string.format("... (truncated at %d rows)", render.TREE_CAP))
            counter.truncated = true
        end
        return
    end
    local node = adj.by_id[node_id]
    if not node then return end

    local indent = string.rep("  ", math.floor(depth))
    local meta = node.metadata or {}
    local title = render.node_title(node)
    local iter = meta.iteration and (" i=" .. meta.iteration) or ""
    local line = string.format("%s- [%s] `%s` %s %s%s",
        indent,
        render.status_marker(node.status),
        render.short_type(node.type),
        render.shorten(node.node_id),
        render.clip(title, 80),
        iter)
    local err = render.node_error(node)
    if err and node.status == "failed" then
        line = line .. " -- " .. render.clip(err, 140)
    end
    table.insert(out, line)
    counter.count = counter.count + 1

    local children_ids = adj.children[node_id] or {}
    -- Failure highlight: expand failed children fully, collapse completed siblings aggressively
    local expand_all = opts.highlight == nil or opts.highlight == "failures" and false

    if opts.highlight == "failures" then
        -- Show failed children + running; collapse completed into a summary.
        local failed = {}
        local other = {}
        for _, cid in ipairs(children_ids) do
            local c = adj.by_id[cid]
            if c and (c.status == "failed" or c.status == "running") then
                table.insert(failed, cid)
            else
                table.insert(other, cid)
            end
        end
        for _, cid in ipairs(failed) do
            walk_tree(cid, adj, out, depth + 1, opts, counter)
            if counter.truncated then return end
        end
        if #other > 0 then
            -- Summarize others by status
            local by_status = {}
            for _, cid in ipairs(other) do
                local c = adj.by_id[cid]
                if c then by_status[c.status] = (by_status[c.status] or 0) + 1 end
            end
            local parts = {}
            for s, n in pairs(by_status) do table.insert(parts, n .. " " .. s) end
            table.sort(parts)
            table.insert(out, string.rep("  ", depth + 1) ..
                string.format("- ... %d siblings collapsed (%s)", #other, table.concat(parts, ", ")))
            counter.count = counter.count + 1
        end
    else
        -- Default: collapse dense tool.call groups, show everything else.
        local groups = collapse_siblings(children_ids, adj.by_id)
        for _, g in ipairs(groups) do
            if g.kind == "collapsed" then
                table.insert(out, string.rep("  ", depth + 1) ..
                    string.format("- [%s] tool.call x %d collapsed (first: %s)",
                        render.status_marker(g.status), g.count, render.shorten(g.first.node_id)))
                counter.count = counter.count + 1
            else
                walk_tree(g.node.node_id, adj, out, depth + 1, opts, counter)
                if counter.truncated then return end
            end
        end
    end
end

function ACTIONS.tree(params)
    if type(params.flow_id) ~= "string" or params.flow_id == "" then
        return nil, "flow_id is required for tree"
    end
    local flow, err = repo.get_flow(params.flow_id)
    if err then return nil, err end

    local nodes = repo.all_nodes(params.flow_id)
    local adj = repo.adjacency(nodes)

    local counts = {}
    for _, n in ipairs(nodes) do counts[n.status] = (counts[n.status] or 0) + 1 end
    local count_parts = {}
    for s, c in pairs(counts) do table.insert(count_parts, s .. "=" .. c) end
    table.sort(count_parts)

    local out = {}
    table.insert(out, "# Flow `" .. flow.dataflow_id .. "`")
    table.insert(out, string.format("status=%s type=%s nodes=%d  %s",
        flow.status, flow.type, #nodes, table.concat(count_parts, " ")))
    table.insert(out, "")

    local opts = { highlight = params.highlight }
    local counter = { count = 0, truncated = false }

    if params.path and params.path ~= "" then
        -- Start from a subtree.
        walk_tree(params.path, adj, out, 0, opts, counter)
    else
        for _, rid in ipairs(adj.roots) do
            walk_tree(rid, adj, out, 0, opts, counter)
            if counter.truncated then break end
        end
    end

    table.insert(out, "")
    table.insert(out, "Legend: [OK ] completed, [FAIL] failed, [RUN ] running, [WAIT] pending.")
    table.insert(out, "Next: `action=inspect flow_id=<id> node_id=<id> view=summary|conversation|tool_call|io|yields`")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- inspect
-- ---------------------------------------------------------------------------

local function render_summary(flow, node, nodes)
    local out = {}
    table.insert(out, "# Node `" .. node.node_id .. "`")
    table.insert(out, string.format("flow=%s  type=%s  status=%s",
        flow.dataflow_id, node.type, render.status_marker(node.status)))
    local meta = node.metadata or {}
    if meta.title then table.insert(out, "title: " .. tostring(meta.title)) end
    if meta.iteration then table.insert(out, "iteration: " .. tostring(meta.iteration)) end
    if meta.status_message then table.insert(out, "status_message: " .. tostring(meta.status_message)) end
    if meta.state and type(meta.state) == "table" then
        table.insert(out, "state:")
        for _, k in ipairs({ "agent_id", "model", "current_iteration", "max_iterations", "tool_calls" }) do
            if meta.state[k] ~= nil then
                table.insert(out, "  " .. k .. ": " .. tostring(meta.state[k]))
            end
        end
    end
    local err = render.node_error(node)
    if err then
        table.insert(out, "")
        table.insert(out, "## Error")
        table.insert(out, "```")
        table.insert(out, render.clip(err, 800))
        table.insert(out, "```")
    end

    -- Ancestor chain
    local chain = repo.ancestors(nodes, node.node_id)
    if #chain > 1 then
        table.insert(out, "")
        table.insert(out, "## Ancestors (root -> self)")
        for i = #chain, 1, -1 do
            local a = chain[i]
            if a then
                table.insert(out, string.format("  %s [%s] `%s` %s %s",
                    string.rep("  ", #chain - i),
                    render.status_marker(a.status),
                    render.short_type(a.type),
                    render.shorten(a.node_id),
                    render.clip(render.node_title(a), 60)))
            end
        end
    end

    -- Child rollup
    local child_count, failed_children = 0, 0
    for _, c in ipairs(nodes) do
        if c.parent_node_id == node.node_id then
            child_count = child_count + 1
            if c.status == "failed" then failed_children = failed_children + 1 end
        end
    end
    if child_count > 0 then
        table.insert(out, "")
        table.insert(out, string.format("children: %d (%d failed)", child_count, failed_children))
    end

    table.insert(out, "")
    table.insert(out, "Next views: `view=conversation` (actions/observations), `view=io` (inputs/outputs), `view=tool_call index=N`.")
    return table.concat(out, "\n")
end

local function render_conversation(flow, node, opts)
    local rows = repo.node_data(flow.dataflow_id, node.node_id, {
        types = { "agent.action", "agent.observation", "node.input", "node.yield", "node.result" },
    })
    local out = {}
    table.insert(out, "# Conversation `" .. node.node_id .. "`")
    table.insert(out, "flow=" .. flow.dataflow_id .. "  type=" .. node.type)
    table.insert(out, "")

    local count = 0
    local cap = opts.limit and math.min(opts.limit, render.TRANSCRIPT_CAP) or render.TRANSCRIPT_CAP
    local tool_call_index = 0

    for _, r in ipairs(rows) do
        if count >= cap then
            table.insert(out, string.format("... (truncated at %d entries — use view=tool_call index=N for specific calls)", cap))
            break
        end
        local v = repo.decode_content(r)
        if r.type == "agent.action" and type(v) == "table" and v.tool_calls then
            for _, tc in ipairs(v.tool_calls) do
                tool_call_index = tool_call_index + 1
                local args_s
                do
                    local ok, enc = pcall(json.encode, tc.arguments)
                    args_s = ok and enc or tostring(tc.arguments)
                end
                table.insert(out, string.format("## [%d] CALL %s (registry=%s)",
                    tool_call_index, tc.name or "?", tc.registry_id or "?"))
                table.insert(out, "```json")
                table.insert(out, render.clip(args_s, render.ARGS_PREVIEW))
                table.insert(out, "```")
                count = count + 1
            end
        elseif r.type == "agent.observation" then
            local text
            if type(v) == "string" then text = v
            else
                local ok, enc = pcall(json.encode, v)
                text = ok and enc or tostring(v or "")
            end
            table.insert(out, "> RESULT: " .. render.clip(text, render.OBS_PREVIEW))
            table.insert(out, "")
            count = count + 1
        elseif r.type == "node.yield" and opts.show_yields then
            table.insert(out, "-- yield --")
            count = count + 1
        elseif r.type == "node.input" then
            local text
            if type(v) == "string" then text = v
            else
                local ok, enc = pcall(json.encode, v)
                text = ok and enc or ""
            end
            table.insert(out, "INPUT (" .. (r.discriminator or "default") .. "): " .. render.clip(text, 400))
            table.insert(out, "")
            count = count + 1
        elseif r.type == "node.result" then
            local text
            if type(v) == "string" then text = v
            else
                local ok, enc = pcall(json.encode, v)
                text = ok and enc or ""
            end
            table.insert(out, "FINAL (" .. (r.discriminator or "") .. "): " .. render.clip(text, 400))
            count = count + 1
        end
    end

    table.insert(out, "")
    table.insert(out,
        "Legend: CALL = agent tool call, RESULT = observation fed back to agent. Use `view=tool_call index=N` for full args+result.")
    return table.concat(out, "\n")
end

local function render_tool_call(flow, node, index)
    local call_index = math.floor(tonumber(index) or 1)
    if call_index < 1 then call_index = 1 end

    local rows = repo.node_data(flow.dataflow_id, node.node_id, {
        types = { "agent.action", "agent.observation" },
    })

    -- Build aligned list of (call, obs) by iteration.
    local calls: {[integer]: ToolCallEntry} = {}
    for _, r in ipairs(rows) do
        if r.type == "agent.action" then
            local v = repo.decode_content(r)
            if type(v) == "table" and v.tool_calls then
                for _, tc in ipairs(v.tool_calls) do
                    table.insert(calls, { call = tc, call_row = r, observation = nil })
                end
            end
        elseif r.type == "agent.observation" then
            for i = #calls, 1, -1 do
                if not calls[i].observation then
                    calls[i].observation = r
                    break
                end
            end
        end
    end

    local out = {}
    table.insert(out, string.format("# Tool call #%d of %d", call_index, #calls))
    if call_index > #calls then
        table.insert(out, "")
        table.insert(out, "Index out of range.")
        return table.concat(out, "\n")
    end

    local c = calls[call_index]
    if not c then
        table.insert(out, "")
        table.insert(out, "Index out of range.")
        return table.concat(out, "\n")
    end
    local call = c.call or {}
    table.insert(out, "node=" .. node.node_id)
    table.insert(out, "")
    table.insert(out, "## Call")
    table.insert(out, "name: `" .. tostring(call.name or "?") .. "`")
    table.insert(out, "registry_id: `" .. tostring(call.registry_id or "?") .. "`")
    if call.id then
        table.insert(out, "id: `" .. tostring(call.id) .. "`")
    end
    table.insert(out, "")
    table.insert(out, "### Arguments")
    local args_s
    do
        local ok, enc = pcall(json.encode, call.arguments)
        args_s = ok and enc or tostring(call.arguments)
    end
    table.insert(out, "```json")
    table.insert(out, args_s)
    table.insert(out, "```")
    table.insert(out, "")
    table.insert(out, "### Result")
    if c.observation then
        local v = repo.decode_content(c.observation)
        local text
        if type(v) == "string" then text = v
        else
            local ok, enc = pcall(json.encode, v)
            text = ok and enc or tostring(v or "")
        end
        table.insert(out, "```")
        table.insert(out, render.clip(text, 1500))
        table.insert(out, "```")
    else
        table.insert(out, "(no observation recorded)")
    end

    -- Show neighbors.
    table.insert(out, "")
    table.insert(out, "## Neighbors")
    for i = math.max(1, index - 2), math.min(#calls, index + 2) do
        local n = calls[i]
        local marker = i == index and " <<< this" or ""
        table.insert(out, string.format("  %d. %s%s", i, tostring(n.call.name or "?"), marker))
    end
    return table.concat(out, "\n")
end

local function render_io(flow, node)
    local rows = repo.node_data(flow.dataflow_id, node.node_id, {
        types = { "node.input", "node.output", "node.result" },
    })
    local out = {}
    table.insert(out, "# IO `" .. node.node_id .. "`")
    for _, r in ipairs(rows) do
        table.insert(out, "")
        table.insert(out, "## " .. r.type .. (r.discriminator and (" (" .. r.discriminator .. ")") or ""))
        local v = repo.decode_content(r)
        local text
        if type(v) == "string" then text = v
        else
            local ok, enc = pcall(json.encode, v)
            text = ok and enc or ""
        end
        table.insert(out, "```")
        table.insert(out, render.clip(text, 1500))
        table.insert(out, "```")
    end
    return table.concat(out, "\n")
end

local function render_yields(flow, node)
    local rows = repo.node_data(flow.dataflow_id, node.node_id, {
        types = { "node.yield", "node.yield.result" },
    })
    local out = {}
    table.insert(out, "# Yields `" .. node.node_id .. "`")
    table.insert(out, render.table_header({ "ix", "type", "data_id", "created_at", "preview" }))
    for i, r in ipairs(rows) do
        local v = repo.decode_content(r)
        local text
        if type(v) == "string" then text = v
        else
            local ok, enc = pcall(json.encode, v)
            text = ok and enc or ""
        end
        table.insert(out, render.table_row({
            i,
            r.type,
            render.shorten(r.data_id),
            r.created_at or "",
            render.clip(text, 120),
        }))
    end
    return table.concat(out, "\n")
end

local function render_flow_summary(flow, nodes)
    local out = {}
    table.insert(out, "# Flow `" .. flow.dataflow_id .. "`")
    table.insert(out, string.format("status=%s  type=%s  nodes=%d",
        flow.status, flow.type, #nodes))

    local counts: {[string]: integer} = {}
    for _, n in ipairs(nodes) do
        if type(n.status) == "string" then
            counts[n.status] = (counts[n.status] or 0) + 1
        end
    end
    local count_parts = {}
    for s, c in pairs(counts) do table.insert(count_parts, s .. "=" .. c) end
    table.sort(count_parts)
    if #count_parts > 0 then
        table.insert(out, "status_counts: " .. table.concat(count_parts, " "))
    end

    local meta = flow.metadata or {}
    if type(meta) == "table" then
        if meta.title then table.insert(out, "title: " .. tostring(meta.title)) end
        if meta.created_at then table.insert(out, "created_at: " .. tostring(meta.created_at)) end
        if meta.updated_at then table.insert(out, "updated_at: " .. tostring(meta.updated_at)) end
    end

    local roots = {}
    for _, n in ipairs(nodes) do
        if not n.parent_node_id or n.parent_node_id == "" then
            table.insert(roots, n)
        end
    end
    if #roots > 0 then
        table.insert(out, "")
        table.insert(out, "## Roots")
        for _, r in ipairs(roots) do
            table.insert(out, string.format("  [%s] `%s` %s %s",
                render.status_marker(r.status),
                render.short_type(r.type),
                render.shorten(r.node_id),
                render.clip(render.node_title(r), 60)))
        end
    end

    local failed = {}
    for _, n in ipairs(nodes) do
        if n.status == "failed" then table.insert(failed, n) end
    end
    if #failed > 0 then
        table.insert(out, "")
        table.insert(out, string.format("## Failed nodes (%d)", #failed))
        for i, n in ipairs(failed) do
            if i > 10 then
                table.insert(out, string.format("  ... %d more", #failed - 10))
                break
            end
            local err = render.node_error(n)
            table.insert(out, string.format("  [FAIL] `%s` %s %s%s",
                render.short_type(n.type),
                render.shorten(n.node_id),
                render.clip(render.node_title(n), 60),
                err and (" -- " .. render.clip(err, 140)) or ""))
        end
    end

    table.insert(out, "")
    table.insert(out, "Next: `action=tree flow_id=" .. flow.dataflow_id .. " highlight=failures` for the full hierarchy,")
    table.insert(out, "or `action=inspect flow_id=" .. flow.dataflow_id .. " node_id=<id> view=summary` for a specific node.")
    return table.concat(out, "\n")
end

function ACTIONS.inspect(params)
    if type(params.flow_id) ~= "string" or params.flow_id == "" then
        return nil, "flow_id is required for inspect"
    end
    local flow, err = repo.get_flow(params.flow_id)
    if err then return nil, err end

    local view = params.view or "summary"

    if (type(params.node_id) ~= "string" or params.node_id == "") then
        if view == "summary" then
            local nodes = repo.all_nodes(params.flow_id)
            return mcp_text(render_flow_summary(flow, nodes))
        end
        return nil, "node_id is required for inspect view=" .. view
    end

    local node = repo.get_node(params.flow_id, params.node_id)
    if not node then return nil, "node not found: " .. params.node_id end

    if view == "summary" then
        local nodes = repo.all_nodes(params.flow_id)
        return mcp_text(render_summary(flow, node, nodes))
    elseif view == "conversation" then
        return mcp_text(render_conversation(flow, node, {
            limit = tonumber(params.limit),
            show_yields = params.show_yields == true,
        }))
    elseif view == "tool_call" then
        return mcp_text(render_tool_call(flow, node, params.index))
    elseif view == "io" then
        return mcp_text(render_io(flow, node))
    elseif view == "yields" then
        return mcp_text(render_yields(flow, node))
    else
        return nil, "unknown view: " .. tostring(view)
    end
end

-- ---------------------------------------------------------------------------
-- anomalies
-- ---------------------------------------------------------------------------

function ACTIONS.anomalies(params)
    if type(params.flow_id) ~= "string" or params.flow_id == "" then
        return nil, "flow_id is required for anomalies"
    end
    local flow, err = repo.get_flow(params.flow_id)
    if err then return nil, err end

    local findings = detectors.run(params.flow_id)
    local out = {}
    table.insert(out, "# Anomalies `" .. flow.dataflow_id .. "`")
    table.insert(out, string.format("status=%s  findings=%d", flow.status, #findings))
    table.insert(out, "")

    if #findings == 0 then
        table.insert(out, "No anomalies detected.")
        table.insert(out, "")
        table.insert(out, "Next: `action=tree flow_id=" .. flow.dataflow_id .. "` to inspect structure manually.")
        return mcp_text(table.concat(out, "\n"))
    end

    table.insert(out, render.table_header({ "sev", "type", "node_id", "summary", "next_call" }))
    for _, f in ipairs(findings) do
        table.insert(out, render.table_row({
            f.severity or "?",
            f.type,
            render.shorten(f.node_id or ""),
            render.clip(f.title or "", 80),
            f.suggested or "",
        }))
    end
    table.insert(out, "")
    table.insert(out, "## Evidence")
    for i, f in ipairs(findings) do
        table.insert(out, string.format("### [%d] %s on `%s`", i, f.type, f.node_id or ""))
        table.insert(out, "> " .. render.clip(f.evidence or "(none)", 400))
        table.insert(out, "")
    end
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- timeline
-- ---------------------------------------------------------------------------

function ACTIONS.timeline(params)
    if type(params.flow_id) ~= "string" or params.flow_id == "" then
        return nil, "flow_id is required for timeline"
    end
    local flow, err = repo.get_flow(params.flow_id)
    if err then return nil, err end

    local nodes = repo.all_nodes(params.flow_id)
    local flow_start = render.to_ms(flow.created_at or 0)

    local entries = {}
    for _, n in ipairs(nodes) do
        local start_ms = render.to_ms(n.created_at)
        local end_ms = render.to_ms(n.updated_at or n.created_at)
        table.insert(entries, {
            node = n,
            start_ms = start_ms,
            duration_ms = math.max(0, end_ms - start_ms),
            rel_ms = math.max(0, start_ms - flow_start),
        })
    end

    -- Focus modes
    if params.focus == "failures" then
        local filtered = {}
        for _, e in ipairs(entries) do
            if e.node.status == "failed" then table.insert(filtered, e) end
        end
        entries = filtered
    elseif params.focus == "slow" then
        table.sort(entries, function(a, b) return a.duration_ms > b.duration_ms end)
        local top = math.min(#entries, tonumber(params.limit) or 20)
        local head = {}
        for i = 1, top do table.insert(head, entries[i]) end
        entries = head
    else
        table.sort(entries, function(a, b) return a.start_ms < b.start_ms end)
    end

    local cap = math.min(#entries, tonumber(params.limit) or 50)
    local out = {}
    table.insert(out, "# Timeline `" .. flow.dataflow_id .. "` (focus=" .. (params.focus or "default") .. ")")
    table.insert(out, "")
    table.insert(out, render.table_header({ "+t", "dur", "status", "type", "node", "title" }))
    for i = 1, cap do
        local e = entries[i]
        table.insert(out, render.table_row({
            render.fmt_duration_ms(e.rel_ms),
            render.fmt_duration_ms(e.duration_ms),
            render.status_marker(e.node.status),
            render.short_type(e.node.type),
            render.shorten(e.node.node_id),
            render.clip(render.node_title(e.node), 60),
        }))
    end
    if #entries > cap then
        table.insert(out, string.format("... %d more (use limit= to extend)", #entries - cap))
    end
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- diff
-- ---------------------------------------------------------------------------

function M.node_signature(n)
    return render.short_type(n.type) .. "|" .. (n.status or "?")
end
local node_signature = M.node_signature

function ACTIONS.diff(params)
    if type(params.a) ~= "string" or params.a == "" then
        return nil, "a (flow_id) is required for diff"
    end
    if type(params.b) ~= "string" or params.b == "" then
        return nil, "b (flow_id) is required for diff"
    end
    local fa, ea = repo.get_flow(params.a)
    if ea then return nil, "a: " .. ea end
    local fb, eb = repo.get_flow(params.b)
    if eb then return nil, "b: " .. eb end

    local na = repo.all_nodes(params.a)
    local nb = repo.all_nodes(params.b)

    local out = {}
    table.insert(out, "# Diff A=`" .. fa.dataflow_id .. "`  B=`" .. fb.dataflow_id .. "`")
    table.insert(out, "")
    table.insert(out, render.table_header({ "field", "a", "b" }))
    table.insert(out, render.table_row({ "status", fa.status, fb.status }))
    table.insert(out, render.table_row({ "node_count", #na, #nb }))

    local function counts(nodes)
        local c: {[string]: integer} = { completed = 0, failed = 0, running = 0, pending = 0 }
        for _, n in ipairs(nodes) do
            if type(n.status) == "string" then
                c[n.status] = (c[n.status] or 0) + 1
            end
        end
        return c
    end
    local ca, cb = counts(na), counts(nb)
    for _, k in ipairs({ "completed", "failed", "running", "pending" }) do
        table.insert(out, render.table_row({ k, ca[k] or 0, cb[k] or 0 }))
    end

    -- Compare action streams at the first root agent node in each flow.
    local function first_agent(nodes)
        for _, n in ipairs(nodes) do
            if n.type == "userspace.dataflow.node.agent:node" then return n end
        end
        return nil
    end
    local aa, ab = first_agent(na), first_agent(nb)
    table.insert(out, "")
    if aa and ab then
        local rows_a = repo.node_data(fa.dataflow_id, aa.node_id, { types = { "agent.action" } })
        local rows_b = repo.node_data(fb.dataflow_id, ab.node_id, { types = { "agent.action" } })

        local function flatten(rows)
            local seq = {}
            for _, r in ipairs(rows) do
                local v = repo.decode_content(r)
                if type(v) == "table" and v.tool_calls then
                    for _, tc in ipairs(v.tool_calls) do
                        table.insert(seq, tc.name or "?")
                    end
                end
            end
            return seq
        end
        local sa, sb = flatten(rows_a), flatten(rows_b)
        table.insert(out, "## First-agent action sequence")
        table.insert(out, render.table_header({ "ix", "a", "b", "match" }))
        local max_len = math.max(#sa, #sb)
        local diverged_at
        for i = 1, math.min(max_len, 60) do
            local va = sa[i] or "-"
            local vb = sb[i] or "-"
            local m = (va == vb) and "=" or "X"
            if m == "X" and not diverged_at then diverged_at = i end
            table.insert(out, render.table_row({ i, va, vb, m }))
        end
        if diverged_at then
            table.insert(out, "")
            table.insert(out, "First divergence at step " .. diverged_at .. ".")
            table.insert(out, "Next: `inspect flow_id=" .. fa.dataflow_id .. " node_id=" .. aa.node_id
                .. " view=tool_call index=" .. diverged_at .. "` (and same for B).")
        end
    else
        table.insert(out, "(no agent node found in one of the flows — skipped action stream diff)")
    end
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- search
-- ---------------------------------------------------------------------------

function ACTIONS.search(params)
    if type(params.query) ~= "string" or params.query == "" then
        return nil, "query is required for search"
    end
    local types
    if type(params.types) == "string" and params.types ~= "" then
        types = {}
        for t in params.types:gmatch("[^,%s]+") do table.insert(types, t) end
    end
    local hits = repo.search_content(params.query, {
        types = types,
        since = params.since,
        limit = tonumber(params.limit),
    })

    local out = {}
    table.insert(out, string.format("# Search `%s` — %d hits", params.query, #hits))
    if #hits == 0 then
        table.insert(out, "")
        table.insert(out, "No matches. Try a shorter substring or different `types`.")
        return mcp_text(table.concat(out, "\n"))
    end
    table.insert(out, "")
    table.insert(out, render.table_header({ "flow_id", "node_id", "type", "created_at", "snippet" }))
    for _, h in ipairs(hits) do
        table.insert(out, render.table_row({
            render.shorten(h.dataflow_id),
            render.shorten(h.node_id or ""),
            h.type or "",
            h.created_at or "",
            render.clip(h.snippet or "", 160),
        }))
    end
    table.insert(out, "")
    table.insert(out, "Next: `action=inspect flow_id=<id> node_id=<id> view=conversation` on a hit.")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- stats
-- ---------------------------------------------------------------------------

function M.percent(n)
    return string.format("%.1f%%", (tonumber(n) or 0) * 100.0)
end
local percent = M.percent

function ACTIONS.stats(params)
    local since = params.since
    if not since and params.window_hours then
        -- Build an ISO8601 offset from now.
        local h = tonumber(params.window_hours) or 24
        local now = os.time()
        since = os.date("!%Y-%m-%dT%H:%M:%SZ", now - h * 3600)
    end

    local flow_agg = repo.flow_stats({ since = since })
    local agents = repo.agent_stats({ since = since })
    local tools = repo.tool_stats({ since = since })

    local out = {}
    table.insert(out, "# Stats" .. (since and (" since=" .. since) or ""))
    table.insert(out, "")

    -- Flow rollup
    table.insert(out, "## Flows")
    table.insert(out, render.table_header({ "metric", "value" }))
    table.insert(out, render.table_row({ "total_flows", flow_agg.total }))
    for _, s in ipairs({ "completed", "failed", "running", "pending", "cancelled", "terminated" }) do
        if flow_agg.by_status[s] then
            table.insert(out, render.table_row({ "flows." .. s, flow_agg.by_status[s] }))
        end
    end
    table.insert(out, render.table_row({ "total_nodes", flow_agg.total_nodes }))
    table.insert(out, render.table_row({
        "avg_nodes_per_flow",
        string.format("%.1f", flow_agg.avg_nodes_per_flow),
    }))

    -- Top agents
    table.insert(out, "")
    table.insert(out, "## Agents (top 15 by volume)")
    table.insert(out, render.table_header({ "agent_id", "total", "ok", "fail", "run", "success", "avg_iter" }))
    for i = 1, math.min(15, #agents) do
        local a = agents[i]
        table.insert(out, render.table_row({
            a.agent,
            a.total,
            a.completed,
            a.failed,
            a.running,
            percent(a.success_rate),
            string.format("%.1f", a.avg_iter),
        }))
    end

    -- Top failing tools
    table.insert(out, "")
    table.insert(out, "## Tools (top 15 by failures)")
    table.insert(out, render.table_header({ "tool", "total", "failed", "fail_rate" }))
    for i = 1, math.min(15, #tools) do
        local t = tools[i]
        table.insert(out, render.table_row({
            render.clip(t.tool, 50),
            t.total,
            t.failed,
            percent(t.fail_rate),
        }))
    end

    table.insert(out, "")
    table.insert(out, "Next: `action=search query=<error>` for matching rows, or `overview has_failures=true` to drill in.")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- commits
-- ---------------------------------------------------------------------------

function M.command_summary(payload)
    if type(payload) ~= "table" then return tostring(payload or "") end
    local ops = payload.commands or payload.ops or payload.operations or {}
    if type(ops) ~= "table" or #ops == 0 then
        -- Payload may itself be a single command.
        if payload.type then return payload.type end
        return "(empty)"
    end
    local counts = {}
    for _, c in ipairs(ops) do
        local t = (type(c) == "table") and (c.type or c.command or c.op) or tostring(c)
        counts[t] = (counts[t] or 0) + 1
    end
    local parts = {}
    for k, v in pairs(counts) do table.insert(parts, k .. "=" .. v) end
    table.sort(parts)
    return table.concat(parts, " ")
end
local command_summary = M.command_summary

function ACTIONS.commits(params)
    if type(params.flow_id) ~= "string" or params.flow_id == "" then
        return nil, "flow_id is required for commits"
    end
    local limit = math.min(math.max(tonumber(params.limit) or 100, 1), 500)
    local offset = math.max(tonumber(params.offset) or 0, 0)
    local commits = repo.commits(params.flow_id, { limit = limit, offset = offset })

    local out = {}
    table.insert(out, "# Commits `" .. params.flow_id .. "` (offset=" .. offset .. " limit=" .. limit .. ")")
    table.insert(out, "")
    table.insert(out, render.table_header({ "ix", "commit_id", "created_at", "summary" }))
    for i, c in ipairs(commits) do
        table.insert(out, render.table_row({
            offset + i,
            render.shorten(c.commit_id),
            c.created_at or "",
            render.clip(command_summary(c.payload), 120),
        }))
    end
    if #commits == limit then
        table.insert(out, "")
        table.insert(out, "... paginate with offset=" .. (offset + limit))
    end
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- learn — cross-flow pattern synthesis from detectors
-- ---------------------------------------------------------------------------

function ACTIONS.learn(params)
    local since = params.since
    if not since and params.window_hours then
        local h = tonumber(params.window_hours) or 168  -- default 1 week
        since = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time() - h * 3600)
    end
    local scan_limit = math.min(math.max(tonumber(params.scan) or 30, 1), 100)

    -- Pull the most recent flows with failures.
    local rows = repo.overview({ has_failures = true, since = since }, scan_limit)

    local by_type = {}  -- finding type -> { count, examples = { {flow, node, evidence} } }
    local flows_scanned = 0
    for _, f in ipairs(rows) do
        flows_scanned = flows_scanned + 1
        local ok, findings = pcall(detectors.run, f.dataflow_id)
        if ok then
            for _, finding in ipairs(findings) do
                local t = finding.type or "unknown"
                local bucket = by_type[t]
                if not bucket then
                    bucket = { type = t, count = 0, flow_set = {}, examples = {} }
                    by_type[t] = bucket
                end
                bucket.count = bucket.count + 1
                if not bucket.flow_set[f.dataflow_id] then
                    bucket.flow_set[f.dataflow_id] = true
                    if #bucket.examples < 3 then
                        table.insert(bucket.examples, {
                            flow_id = f.dataflow_id,
                            node_id = finding.node_id,
                            title = finding.title,
                            evidence = finding.evidence,
                        })
                    end
                end
            end
        end
    end

    local list = {}
    for _, b in pairs(by_type) do
        b.affected_flows = 0
        for _ in pairs(b.flow_set) do b.affected_flows = b.affected_flows + 1 end
        b.flow_set = nil
        table.insert(list, b)
    end
    table.sort(list, function(a, b)
        if a.affected_flows ~= b.affected_flows then return a.affected_flows > b.affected_flows end
        return a.count > b.count
    end)

    local out = {}
    table.insert(out, "# Learn — patterns across " .. flows_scanned .. " failing flows"
        .. (since and (" since " .. since) or ""))
    table.insert(out, "")
    if #list == 0 then
        table.insert(out, "No detector patterns matched. Either the window is clean or the detectors need extending.")
        return mcp_text(table.concat(out, "\n"))
    end

    table.insert(out, render.table_header({ "pattern", "flows", "findings" }))
    for _, b in ipairs(list) do
        table.insert(out, render.table_row({ b.type, b.affected_flows, b.count }))
    end

    table.insert(out, "")
    table.insert(out, "## Examples")
    for _, b in ipairs(list) do
        table.insert(out, "")
        table.insert(out, "### `" .. b.type .. "` — " .. b.affected_flows .. " flows")
        for _, ex in ipairs(b.examples) do
            table.insert(out, string.format("- flow=`%s` node=`%s` — %s",
                ex.flow_id, ex.node_id or "", render.clip(ex.title or "", 100)))
            if ex.evidence and ex.evidence ~= "" then
                table.insert(out, "  > " .. render.clip(ex.evidence, 200))
            end
        end
    end

    table.insert(out, "")
    table.insert(out, "Next: `action=inspect flow_id=<example> node_id=<example> view=conversation` to study one.")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- dispatcher
-- ---------------------------------------------------------------------------

local function handler(params)
    params = params or {}
    local action = params.action
    if type(action) ~= "string" or action == "" then
        return nil, "action is required"
    end
    local fn = ACTIONS[action]
    if not fn then return nil, "unknown action: " .. tostring(action) end

    local result, err = fn(params)
    if err then return nil, err end

    return result
end

M.handler = handler
return M
