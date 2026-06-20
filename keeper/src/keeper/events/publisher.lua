local pg = require("pg")
local consts = require("events_consts")

-- Internal SDK keeper modules use to publish a realtime admin event. The event
-- is broadcast over the keeper events pg bus to every admin user hub currently
-- subscribed, which fans it to that admin's browser tabs. Non-subscribers (and
-- thus non-admins, who are never instructed to join) receive nothing.
--
-- Callers must already run under a scope allowed to pg.open the bus (the keeper
-- governance supervisors do). The opened scope is cached per process.
local M = {}

local _bus: any = nil

local function bus(): (any, any)
    if _bus then return _bus, nil end
    local scope, err = pg.open(consts.BUS)
    if err or not scope then
        return nil, err or "failed to open keeper events bus"
    end
    _bus = scope
    return scope, nil
end

-- publish delivers payload to every subscribed admin hub under topic.
-- topic must be one of consts.TOPICS.*; payload is delivered to clients verbatim.
function M.publish(topic: string, payload: any): (boolean, any)
    local scope, err = bus()
    if not scope then return false, err end
    local ok, berr = scope:broadcast(consts.GROUP, topic, payload)
    return (ok :: boolean), berr
end

return M
