local http = require("http")
local system = require("system")
local security = require("security")
local function handler()
    local res = http.response()
    if not res then return nil, "failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local hosts, hosts_err = system.hosts.list()
    if hosts_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = tostring(hosts_err) })
        return
    end

    local process_hosts = {}
    for _, host in ipairs(hosts) do
        local procs, procs_err = system.hosts.processes(host.id)
        if procs_err then
            res:set_status(http.STATUS.INTERNAL_ERROR)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({ success = false, error = tostring(procs_err) })
            return
        end

        local process_list = {}
        for _, p in ipairs(procs) do
            table.insert(process_list, {
                pid = p.pid,
                host = p.host,
                source = p.source,
                state = p.state,
                steps = p.steps,
                started_at = p.started_at,
                parent = p.parent,
                actor_id = p.actor_id,
                stats = p.stats,
            })
        end

        table.insert(process_hosts, {
            host_id = host.id,
            workers = host.workers,
            process_count = host.processes,
            executed = host.executed,
            stolen = host.stolen,
            queue_depth = host.queue_depth,
            processes = process_list,
        })
    end

    local services_data, svc_err = system.supervisor.states()
    if svc_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = tostring(svc_err) })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, processes = process_hosts,
        services = services_data, })
end

return { handler = handler }
