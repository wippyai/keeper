local http = require("http")
local security = require("security")
local git_client = require("git_client")

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

    local body = req:body_json() or {}
    local snapshot, err = git_client.rebuild({
        mode               = body.mode,    -- "manual" | "ai" (default ai)
        model              = body.model,
        max_changes        = tonumber(body.max_changes),
        sync_first         = body.sync_first and true or false,
        tracked_dirs       = body.tracked_dirs,
        managed_namespaces = body.managed_namespaces,
        diff_base          = body.diff_base,
        untracked_mode     = body.untracked_mode,
        change_source      = body.change_source,
        changeset_id       = body.changeset_id,
        states             = body.states,
        kind               = body.kind,
        actor_id           = body.actor_id,
        session_id         = body.session_id,
        request_id         = body.request_id,
    })
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, snapshot = snapshot })
end

return { handler = handler }
