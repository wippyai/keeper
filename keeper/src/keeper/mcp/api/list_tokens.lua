local http = require("http")
local security = require("security")

local auth = require("mcp_auth")
local token_store = require("mcp_tokens")

local function handler()
    local res = http.response()

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end
    local admin_ok, admin_err = auth.verify_admin_user(actor:id())
    if not admin_ok then
        local status, payload = auth.admin_failure(admin_err)
        res:set_status(status)
        res:write_json(payload)
        return
    end

    local tokens, err = token_store.list()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({ success = false, error = err })
        return
    end

    -- Raw tokens are not recoverable after creation; expose the hash as token_id
    -- for revoke and a short display prefix for the UI.
    local masked = {}
    for _, t in ipairs(tokens or {}) do
        local token_id = t.token_hash
        table.insert(masked, {
            token = token_id and (token_id:sub(1, 8) .. "...") or "",
            token_id = token_id,
            label = t.label,
            identity = t.identity,
            issued_by = t.issued_by,
            access_mode = t.access_mode,
            scopes = t.scopes,
            trait_filter = t.trait_filter,
            tool_filter = t.tool_filter,
            default_active = t.default_active,
            created_at = t.created_at,
            expires_at = t.expires_at,
            revoked = t.revoked,
            revoked_at = t.revoked_at,
            revoked_by = t.revoked_by,
        })
    end

    res:set_status(http.STATUS.OK)
    res:write_json({ success = true, tokens = masked, count = #masked })
end

return { handler = handler }
