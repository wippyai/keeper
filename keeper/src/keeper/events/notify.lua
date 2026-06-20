local consts = require("events_consts")

-- Internal SDK keeper modules use to publish a realtime admin event. The event
-- is handed to the events relay (a single governance-scoped process that owns the
-- bus) which broadcasts it to every subscribed admin user hub, which fans it to
-- that admin's browser tabs. Non-subscribers (and thus non-admins, who are never
-- instructed to join) receive nothing.
--
-- Publishing is scope-independent: callers only send to the relay process, so any
-- keeper code (governance supervisors, the logger, HTTP-invoked libraries) may
-- publish without holding pg.open rights on the bus. The relay pid is cached per
-- process and re-resolved if the relay restarts.
local M = {}

local _pid: string? = nil

local function relay_pid(): (string?, string?)
    if _pid then return _pid, nil end
    local pid = process.registry.lookup(consts.RELAY)
    if not pid then
        return nil, "events relay not registered"
    end
    _pid = pid
    return pid, nil
end

-- publish delivers payload to every subscribed admin hub under topic.
-- topic is the wire topic clients subscribe to; payload is delivered verbatim.
-- Best-effort: a missing relay drops the event rather than failing the caller.
function M.publish(topic: string, payload: any): (boolean, string?)
    local pid, err = relay_pid()
    if not pid then return false, err end
    local ok, serr = pcall(function()
        process.send(pid, topic, payload)
    end)
    if not ok then
        _pid = nil
        return false, tostring(serr)
    end
    return true, nil
end

return M
