local http = require("http")
local security = require("security")

local token_store = require("mcp_tokens")

local function handler()
    local res = http.response()

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local tokens, err = token_store.list()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({ success = false, error = err })
        return
    end

    -- Show only first 8 chars as display token; full value in token_id for revoke.
    -- This endpoint is behind authenticated app:api so only admins see tokens.
    local masked = {}
    for _, t in ipairs(tokens or {}) do
        table.insert(masked, {
            token = t.token:sub(1, 8) .. "...",
            token_id = t.token,
            label = t.label,
            identity = t.identity,
            scopes = t.scopes,
            created_at = t.created_at,
            expires_at = t.expires_at,
            revoked = t.revoked,
        })
    end

    res:set_status(http.STATUS.OK)
    res:write_json({ success = true, tokens = masked, count = #masked })
end

return { handler = handler }
