local M = {}

local ERROR_KIND = {
    BAD_REQUEST = errors.INVALID,
    BAD_SERVICE = errors.INVALID,
    FENCE_INVALID = errors.INVALID,
    NOT_FOUND = errors.NOT_FOUND,
    CONFLICT = errors.CONFLICT,
    FENCE_OWNER_MISMATCH = errors.CONFLICT,
    SUPERVISOR_UNAVAILABLE = errors.UNAVAILABLE,
    SERVICE_UNAVAILABLE = errors.UNAVAILABLE,
    INSTALL_STATE_UNAVAILABLE = errors.UNAVAILABLE,
    QUIESCENCE_TIMEOUT = errors.TIMEOUT,
}

-- The scheduler reports live processes as running, ready, blocked, or
-- idle; only terminal states mean an instance is not up.
local TERMINAL_PROCESS_STATES = {
    exited = true,
    stopped = true,
    complete = true,
    unknown = true,
}

local function process_live(proc_state)
    return proc_state ~= nil and not TERMINAL_PROCESS_STATES[proc_state]
end

local function failure(code, message, info)
    local details = { code = code }
    if type(info) == "table" then
        for key, value in pairs(info) do details[key] = value end
    elseif info ~= nil then
        details.cause = tostring(info)
    end
    return errors.new({ kind = ERROR_KIND[code] or errors.INTERNAL,
        message = message, details = details })
end

local function inspect_services(items)
    local ids, seen = {}, {}
    local function inspect(row)
        if type(row) ~= "table" or row.status == "applied" then return end
        local meta = row.meta or {}
        local declared = meta.quiesce_services or row.quiesce_services
        if type(declared) == "string" then declared = { declared } end
        for _, id in ipairs(declared or {}) do
            if type(id) == "string" and id ~= "" and not seen[id] then
                seen[id] = true
                ids[#ids + 1] = id
            end
        end
        for _, nested in ipairs(row.entries or row.migrations or {}) do inspect(nested) end
    end
    for _, row in ipairs(items or {}) do inspect(row) end
    table.sort(ids)
    return ids
end

M.collect = inspect_services

-- Registry process refs are short names in their own namespace while the
-- runtime reports namespace-qualified process sources. A ref without a
-- namespace resolves against the service entry's namespace.
local function qualify_process(entry_id, source)
    if source:find(":", 1, true) then return source end
    local namespace = string.match(entry_id or "", "^([^:]+):")
    if namespace and namespace ~= "" then return namespace .. ":" .. source end
    return source
end

local function configured_process(registry, id)
    if not registry or type(registry.get) ~= "function" then
        return nil, failure("SUPERVISOR_UNAVAILABLE", "registry.get unavailable")
    end
    local entry, get_err = registry.get(id)
    if not entry or get_err then
        return nil, failure("SERVICE_UNAVAILABLE", "cannot read service " .. id, get_err)
    end
    if entry.kind ~= "process.service" then
        return nil, failure("BAD_SERVICE", id .. " is not a process.service")
    end
    local source = entry.data and entry.data.process or entry.process
    if type(source) ~= "string" or source == "" then
        return nil, failure("BAD_SERVICE", id .. " has no configured process")
    end
    return qualify_process(id, source), nil
end

local function observe(runtime, id, source)
    local system = runtime.system
    if not system or not system.supervisor or type(system.supervisor.state) ~= "function"
        or not system.hosts or type(system.hosts.list) ~= "function"
        or type(system.hosts.processes) ~= "function" then
        return nil, failure("SUPERVISOR_UNAVAILABLE", "supervisor and host inspection required")
    end
    local state, state_err = system.supervisor.state(id)
    if not state or state_err or type(state) ~= "table" then
        return nil, failure("INSPECTION_FAILED", "cannot inspect supervisor " .. id, state_err)
    end
    local hosts, hosts_err = system.hosts.list()
    if not hosts or hosts_err then
        return nil, failure("INSPECTION_FAILED", "cannot list process hosts", hosts_err)
    end
    local pids = {}
    for _, host in ipairs(hosts) do
        local host_id = type(host) == "table" and host.id or host
        if not host_id then return nil, failure("INSPECTION_FAILED", "host has no id") end
        local processes, process_err = system.hosts.processes(host_id)
        if not processes or process_err then
            return nil, failure("INSPECTION_FAILED", "cannot inspect host " .. tostring(host_id), process_err)
        end
        for _, proc in ipairs(processes) do
            if proc.source == source then
                if type(proc.pid) ~= "string" or proc.pid == "" then
                    return nil, failure("INSPECTION_FAILED", "process has no PID")
                end
                pids[proc.pid] = proc.state or "unknown"
            end
        end
    end
    return { state = state, pids = pids }, nil
end

local function wait_for(runtime, id, source, predicate, limit)
    local sleeper = runtime.time and runtime.time.sleep
    if type(sleeper) ~= "function" then
        return nil, failure("SUPERVISOR_UNAVAILABLE", "time.sleep required for acknowledgement")
    end
    local last
    for attempt = 1, limit or 100 do
        local snapshot, snapshot_err = observe(runtime, id, source)
        if not snapshot then return nil, snapshot_err end
        last = snapshot
        if predicate(snapshot) then return snapshot, nil end
        if attempt < (limit or 100) then
            -- The real time.sleep returns nothing on success; only a
            -- returned error means the wait itself failed.
            local _, sleep_err = sleeper("50ms")
            if sleep_err then
                return nil, failure("INSPECTION_FAILED", "acknowledgement wait failed", sleep_err)
            end
        end
    end
    return nil, failure("QUIESCENCE_TIMEOUT", "supervisor acknowledgement timed out for " .. id, last)
end

local function control(runtime, kind, id)
    if not runtime.events or type(runtime.events.send) ~= "function" then
        return nil, failure("SUPERVISOR_UNAVAILABLE", "events.send supervisor control unavailable")
    end
    local sent, send_err = runtime.events.send("supervisor", kind, id)
    if not sent or send_err then
        return nil, failure("SUPERVISOR_CONTROL_FAILED", "supervisor rejected " .. kind .. " for " .. id, send_err)
    end
    return true, nil
end

function M.acquire(runtime, db, token, candidate_hash, items)
    local services = inspect_services(items)
    if #services == 0 then return { services = {}, held = false }, nil end
    local state = runtime.install_state
    if not db or not state or type(state.record_fence) ~= "function" then
        return nil, failure("INSTALL_STATE_UNAVAILABLE", "durable install state required")
    end
    local records = {}
    for _, id in ipairs(services) do
        local source, source_err = configured_process(runtime.registry, id)
        if not source then return nil, source_err end
        local before, before_err = observe(runtime, id, source)
        if not before then return nil, before_err end
        records[id] = { source = source, old_pids = before.pids }
    end
    local fence = { candidate_hash = candidate_hash, services = services,
        records = records, held = true, status = "requested" }
    local saved, save_err = state.record_fence(db, token, fence)
    if not saved then return nil, failure("INSTALL_STATE_FAILED", "cannot persist fence intent", save_err) end
    for _, id in ipairs(services) do
        local sent, send_err = control(runtime, "service.stop", id)
        if not sent then return nil, send_err end
        local source = records[id].source
        local stopped, stop_err = wait_for(runtime, id, source, function(snapshot)
            if snapshot.state.desired ~= "stopped" then return false end
            -- A stopped service reports status stopped while its process
            -- shuts down and exited once the process is gone; either one
            -- with desired stopped proves the old instance is quiesced.
            if snapshot.state.status ~= "stopped" and snapshot.state.status ~= "exited" then
                return false
            end
            for pid in pairs(records[id].old_pids) do
                if snapshot.pids[pid] then return false end
            end
            for _, proc_state in pairs(snapshot.pids) do
                if proc_state ~= "exited" and proc_state ~= "stopped" then return false end
            end
            return true
        end)
        if not stopped then return nil, stop_err end
    end
    fence.status = "acknowledged"
    local acknowledged, ack_err = state.record_fence(db, token, fence)
    if not acknowledged then return nil, failure("INSTALL_STATE_FAILED", "cannot persist exit acknowledgement", ack_err) end
    return fence, nil
end

function M.start(runtime, db, token, fence)
    if not fence or not fence.held then return { started = true, fence = fence }, nil end
    local state = runtime.install_state
    if not db or not state or type(state.get_active_install) ~= "function" then
        return nil, failure("INSTALL_STATE_UNAVAILABLE", "durable install state required")
    end
    local active, active_err = state.get_active_install(db)
    if not active or active_err or active.lock_token ~= token then
        return nil, failure("FENCE_OWNER_MISMATCH", "only owning installer can release fence", active_err)
    end
    for _, id in ipairs(fence.services or {}) do
        local record = fence.records and fence.records[id]
        if not record then return nil, failure("FENCE_INVALID", "missing old instance record for " .. id) end
        local sent, send_err = control(runtime, "service.start", id)
        if not sent then return nil, send_err end
        local started, start_err = wait_for(runtime, id, record.source, function(snapshot)
            if snapshot.state.desired ~= "running" or snapshot.state.status ~= "running" then return false end
            for pid, proc_state in pairs(snapshot.pids) do
                if not record.old_pids[pid] and process_live(proc_state) then
                    record.new_pid = pid
                    return true
                end
            end
            return false
        end)
        if not started then return nil, start_err end
    end
    return { started = true, fence = fence }, nil
end

function M.release(runtime, db, token, fence)
    if not fence or not fence.held then return { released = true }, nil end
    local state = runtime.install_state
    local active, active_err = state.get_active_install(db)
    if not active or active_err or active.lock_token ~= token then
        return nil, failure("FENCE_OWNER_MISMATCH", "only owning installer can release fence", active_err)
    end
    for _, id in ipairs(fence.services or {}) do
        local record = fence.records and fence.records[id]
        if not record or not record.new_pid then
            return nil, failure("STARTUP_UNACKNOWLEDGED", "new PID missing for " .. id)
        end
        local snapshot, inspect_err = observe(runtime, id, record.source)
        if not snapshot then return nil, inspect_err end
        if snapshot.state.desired ~= "running" or snapshot.state.status ~= "running"
            or not process_live(snapshot.pids[record.new_pid]) then
            return nil, failure("STARTUP_UNACKNOWLEDGED", "new service instance not running for " .. id)
        end
    end
    local released, release_err = state.release_fence(db, token)
    if not released then return nil, failure("INSTALL_STATE_FAILED", "cannot persist fence release", release_err) end
    return { released = true, records = fence.records }, nil
end

return M
