local http = require("http")
local json = require("json")
local security = require("security")

local token_store = require("mcp_tokens")

local function handler()
    local res = http.response()
    local req = http.request()

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local body = req:body()
    if not body or body == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ success = false, error = "Request body required" })
        return
    end

    local params, decode_err = json.decode(body)
    if decode_err or not params then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ success = false, error = "Invalid JSON body" })
        return
    end

    if not params.token then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ success = false, error = "Token ID is required" })
        return
    end

    local ok, err = token_store.revoke(params.token)
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:write_json({ success = true, revoked = ok })
end

return { handler = handler }
