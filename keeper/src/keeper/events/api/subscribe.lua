local http = require("http")
local security = require("security")

local auth = require("mcp_auth")
local events_consts = require("events_consts")

-- Subscription control for the keeper admin event bus. Admin status is the gate:
-- the endpoint verifies the caller is an active admin (authoritative DB check),
-- then instructs that user's relay hub to join or leave the bus group. The hub
-- itself only honors this instruction from an in-runtime process, never from a
-- ws client, so the admin check here is the trust boundary.

local function require_admin(res: any): string?
    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({ success = false, error = "Authentication required" })
        return nil
    end
    local admin_ok, admin_err = auth.verify_admin_user(actor:id())
    if not admin_ok then
        local status, payload = auth.admin_failure(admin_err)
        res:set_status(status)
        res:write_json(payload)
        return nil
    end
    return actor:id()
end

local function hub_pid(user_id: string): string?
    return process.registry.lookup(events_consts.HUB.PREFIX .. user_id)
end

local function subscribe()
    local res = http.response()
    local user_id = require_admin(res)
    if not user_id then return end

    local pid = hub_pid(user_id)
    if not pid then
        res:write_json({ success = true, subscribed = false, reason = "no active realtime connection" })
        return
    end

    process.send(pid, events_consts.HUB.SUBSCRIBE, {
        scope = events_consts.BUS,
        group = events_consts.GROUP,
    })
    res:write_json({ success = true, subscribed = true, topics = events_consts.TOPICS })
end

local function unsubscribe()
    local res = http.response()
    local user_id = require_admin(res)
    if not user_id then return end

    local pid = hub_pid(user_id)
    if pid then
        process.send(pid, events_consts.HUB.UNSUBSCRIBE, {
            group = events_consts.GROUP,
        })
    end
    res:write_json({ success = true, subscribed = false })
end

return { subscribe = subscribe, unsubscribe = unsubscribe }
