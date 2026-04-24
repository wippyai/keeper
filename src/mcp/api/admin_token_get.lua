local http = require("http")
local env = require("env")
local security = require("security")

local TOKEN_VAR = "keeper.mcp:access_token"

local function require_admin(res)
    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return false
    end
    return true
end

local function handle_get()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end
    if not require_admin(res) then return end

    local value = env.get(TOKEN_VAR) or ""
    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true, token = value })
end

local function handle_post()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end
    if not require_admin(res) then return end

    local body = req:body_json()
    if type(body) ~= "table" or type(body.token) ~= "string" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "token field required" })
        return
    end

    local ok, err = env.set(TOKEN_VAR, body.token)
    if not ok then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Failed to set env: " .. tostring(err) })
        return
    end

    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({ success = true })
end

return {
    handle_get = handle_get,
    handle_post = handle_post,
}
