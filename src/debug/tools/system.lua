-- keeper.debug.tools:system
--
-- System-level debug tool. Reads host/process state via the `system` module
-- and the logger service. All actions return markdown. Read-only.

local system = require("system")
local json = require("json")

local logger_client = require("logger_client")
local render = require("render")

local M = {}

local ACTIONS = {}

local function mcp_text(text)
    return { _mcp_content = { { type = "text", text = text } } }
end

function M.fmt_bytes(n)
    n = (tonumber(n) or 0) * 1.0
    local units = { "B", "KB", "MB", "GB", "TB" }
    local i = 1
    while n >= 1024 and i < #units do n = n / 1024; i = i + 1 end
    return string.format("%.1f%s", n, units[i])
end
local fmt_bytes = M.fmt_bytes

-- ---------------------------------------------------------------------------
-- processes
-- ---------------------------------------------------------------------------

function ACTIONS.processes(params)
    local hosts, err = system.hosts.list()
    if err then return nil, "hosts.list: " .. tostring(err) end

    local filter_state = params.state   -- optional: running, paused, etc
    local filter_host = params.host     -- optional: host id substring
    local filter_source = params.source -- optional: source (entry id) substring
    local limit_per_host = tonumber(params.limit) or 50

    local out = {}
    table.insert(out, "# Processes")
    table.insert(out, "")

    -- Host rollup table
    table.insert(out, "## Hosts")
    table.insert(out, render.table_header({
        "host_id", "workers", "procs", "executed", "stolen", "queue_depth",
    }))
    for _, h in ipairs(hosts) do
        if not filter_host or h.id:find(filter_host, 1, true) then
            table.insert(out, render.table_row({
                h.id,
                h.workers or 0,
                h.processes or 0,
                h.executed or 0,
                h.stolen or 0,
                h.queue_depth or 0,
            }))
        end
    end

    -- Processes per host
    for _, h in ipairs(hosts) do
        if not filter_host or h.id:find(filter_host, 1, true) then
            local procs, perr = system.hosts.processes(h.id)
            if perr then
                table.insert(out, "")
                table.insert(out, "### " .. h.id .. " — processes (ERROR: " .. tostring(perr) .. ")")
            else
                local rows = {}
                for _, p in ipairs(procs or {}) do
                    local pass = true
                    if filter_state and p.state ~= filter_state then pass = false end
                    if filter_source and not (p.source and p.source:find(filter_source, 1, true)) then pass = false end
                    if pass then table.insert(rows, p) end
                end
                table.insert(out, "")
                table.insert(out, "### " .. h.id .. " — processes (" .. #rows .. ")")
                if #rows > 0 then
                    table.insert(out, render.table_header({
                        "pid", "state", "steps", "source", "actor_id", "started_at",
                    }))
                    local shown = 0
                    for _, p in ipairs(rows) do
                        if shown >= limit_per_host then
                            table.insert(out, string.format("... %d more (use limit= to extend)", #rows - shown))
                            break
                        end
                        table.insert(out, render.table_row({
                            p.pid or "",
                            p.state or "",
                            p.steps or 0,
                            render.clip(tostring(p.source or ""), 50),
                            render.clip(tostring(p.actor_id or ""), 30),
                            p.started_at or "",
                        }))
                        shown = shown + 1
                    end
                end
            end
        end
    end

    table.insert(out, "")
    table.insert(out, "Next: `action=services` for supervisor state, `action=info` for memory/cpu, or `action=logs filter=<expr>`.")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- services
-- ---------------------------------------------------------------------------

function ACTIONS.services(params)
    local states, err = system.supervisor.states()
    if err then return nil, "supervisor.states: " .. tostring(err) end

    local out = {}
    table.insert(out, "# Services (supervisor)")
    table.insert(out, "")

    if type(states) == "table" then
        local list = {}
        if states[1] then
            for _, s in ipairs(states) do table.insert(list, s) end
        else
            for k, v in pairs(states) do
                if type(v) == "table" then
                    v.id = v.id or k
                    table.insert(list, v)
                else
                    table.insert(list, { id = k, state = v })
                end
            end
        end
        table.insert(out, render.table_header({ "id", "state", "host", "restarts" }))
        for _, s in ipairs(list) do
            table.insert(out, render.table_row({
                tostring(s.id or ""),
                tostring(s.state or s.status or ""),
                tostring(s.host or ""),
                tostring(s.restarts or s.restart_count or 0),
            }))
        end
    else
        table.insert(out, "(unexpected supervisor.states() shape)")
    end
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- info (memory / cpu / runtime)
-- ---------------------------------------------------------------------------

function ACTIONS.info(params)
    local out = {}
    table.insert(out, "# System info")
    table.insert(out, "")

    local mem_ok, mem = pcall(function() return system.memory.stats() end)
    if mem_ok and type(mem) == "table" then
        table.insert(out, "## Memory")
        table.insert(out, render.table_header({ "metric", "value" }))
        for k, v in pairs(mem) do
            if type(v) == "number" and k:find("bytes") then
                table.insert(out, render.table_row({ k, fmt_bytes(v) }))
            else
                table.insert(out, render.table_row({ k, tostring(v) }))
            end
        end
    end

    local cpu_ok, cpu = pcall(function() return (system :: any).cpu.info() end)
    if cpu_ok and type(cpu) == "table" then
        table.insert(out, "")
        table.insert(out, "## CPU")
        table.insert(out, render.table_header({ "metric", "value" }))
        for k, v in pairs(cpu) do
            table.insert(out, render.table_row({ k, tostring(v) }))
        end
    end

    local rt_ok, rt = pcall(function() return (system :: any).runtime.info() end)
    if rt_ok and type(rt) == "table" then
        table.insert(out, "")
        table.insert(out, "## Runtime")
        table.insert(out, render.table_header({ "metric", "value" }))
        for k, v in pairs(rt) do
            table.insert(out, render.table_row({ k, tostring(v) }))
        end
    end

    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- logs
-- ---------------------------------------------------------------------------

function M.format_log_entry(e)
    local ts = e.timestamp or e.time or ""
    local level = e.level or e.severity or "INFO"
    local src = e.source or e.logger or ""
    local msg = e.message or e.msg or ""
    if type(msg) == "table" then
        local ok, enc = pcall(json.encode, msg)
        msg = ok and enc or ""
    end
    return string.format("[%s] %s (%s) %s",
        tostring(ts), tostring(level), render.clip(tostring(src), 40), render.clip(tostring(msg), 500))
end
local format_log_entry = M.format_log_entry

function ACTIONS.logs(params)
    local count = tonumber(params.limit) or 100
    local filter = params.filter
    if filter == "" then filter = nil end
    local reverse = params.reverse ~= false
    local timeout = params.timeout or "10s"

    local result, err = logger_client.get_logs(count, filter, reverse, timeout)
    if err then return nil, "logs: " .. tostring(err) end

    local out = {}
    table.insert(out, string.format("# Logs (total=%s filtered=%s shown=%d filter=%s)",
        tostring(result.total_count or "?"),
        tostring(result.filtered or "?"),
        #(result.logs or {}),
        tostring(filter or "(none)")))
    table.insert(out, "")
    table.insert(out, "```")
    for _, e in ipairs(result.logs or {}) do
        table.insert(out, format_log_entry(e))
    end
    table.insert(out, "```")

    table.insert(out, "")
    table.insert(out, "Filter syntax is the logger expression language — use `action=log_composition` to see which sources/levels exist.")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- log_stats
-- ---------------------------------------------------------------------------

function ACTIONS.log_stats(params)
    local stats, err = logger_client.get_stats(params.timeout or "5s")
    if err then return nil, "log_stats: " .. tostring(err) end

    local out = {}
    table.insert(out, "# Log buffer stats")
    table.insert(out, "")

    local uptime_ns = 0
    local total_received = 0
    if type(stats) == "table" then
        uptime_ns = tonumber(stats.uptime_ns) or 0
        total_received = tonumber(stats.total_received) or 0
        table.insert(out, render.table_header({ "metric", "value" }))
        for k, v in pairs(stats) do
            if type(v) == "table" then
                local ok, enc = pcall(json.encode, v)
                table.insert(out, render.table_row({ k, render.clip(ok and enc or "", 200) }))
            else
                table.insert(out, render.table_row({ k, tostring(v) }))
            end
        end
    end

    local counters, cerr = logger_client.get_counters(params.timeout or "5s")
    if not cerr and type(counters) == "table" then
        if total_received == 0 then
            total_received = tonumber(counters.total_received) or 0
        end
        table.insert(out, "")
        table.insert(out, "## Counters")
        table.insert(out, render.table_header({ "metric", "value" }))
        table.insert(out, render.table_row({ "total_received", counters.total_received or 0 }))
        table.insert(out, render.table_row({ "stored_count", counters.stored_count or 0 }))
        if type(counters.counters) == "table" then
            for k, v in pairs(counters.counters) do
                table.insert(out, render.table_row({ "counter." .. tostring(k), tostring(v) }))
            end
        end
    end

    if total_received == 0 and uptime_ns > 60 * 1e9 then
        table.insert(out, "")
        table.insert(out, "## Warning")
        table.insert(out, string.format(
            "Logger service has been up for %.0fs but received 0 log events.",
            uptime_ns / 1e9))
        table.insert(out, "The subscription (`events.subscribe(\"logs\", \"logs.entry\")`) is not")
        table.insert(out, "delivering entries — the host log system is either not publishing")
        table.insert(out, "events, or publishing under a different system/kind.")
        table.insert(out, "Do not treat an empty buffer as \"no logs happened\".")
    end

    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- log_composition
-- ---------------------------------------------------------------------------

function ACTIONS.log_composition(params)
    local filter = params.filter
    if filter == "" then filter = nil end
    local result, err = logger_client.get_composition(filter, params.timeout or "5s")
    if err then return nil, "log_composition: " .. tostring(err) end

    local out = {}
    table.insert(out, "# Log composition" .. (filter and (" filter=" .. filter) or ""))
    table.insert(out, "")
    local comp = result and result.composition
    if type(comp) == "table" then
        -- Composition is typically { by_source = {...}, by_level = {...} } or a map.
        for section, rows in pairs(comp) do
            table.insert(out, "## " .. tostring(section))
            if type(rows) == "table" then
                table.insert(out, render.table_header({ "key", "count" }))
                for k, v in pairs(rows) do
                    table.insert(out, render.table_row({ tostring(k), tostring(v) }))
                end
            else
                table.insert(out, tostring(rows))
            end
            table.insert(out, "")
        end
    else
        table.insert(out, "(empty composition)")
    end
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
