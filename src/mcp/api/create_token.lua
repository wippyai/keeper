local http = require("http")
local json = require("json")
local security = require("security")

local token_store = require("mcp_tokens")
local policy = require("mcp_policy")
local auth = require("mcp_auth")

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

    if not params.label or params.label == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ success = false, error = "Label is required" })
        return
    end

    if not params.identity or params.identity == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ success = false,
            error = "identity is required (app_users.user_id in app.security:admin group)" })
        return
    end

    local admin_ok, admin_err = auth.verify_admin_user(params.identity)
    if not admin_ok then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ success = false, error = admin_err })
        return
    end

    local access_mode = params.access_mode
    local scopes = params.scopes
    local trait_filter = params.trait_filter
    local tool_filter = params.tool_filter
    local default_active = params.default_active

    if params.preset then
        local preset, perr = policy.get_preset(params.preset)
        if not preset then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:write_json({ success = false, error = perr or ("unknown preset: " .. tostring(params.preset)) })
            return
        end
        access_mode = access_mode or preset.access_mode
        scopes = scopes or preset.scopes
        if trait_filter == nil then trait_filter = preset.trait_filter end
        if tool_filter == nil then tool_filter = preset.tool_filter end
        default_active = default_active or preset.default_active
    end

    if not scopes or #scopes == 0 then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ success = false, error = "At least one scope is required (supply scopes or preset)" })
        return
    end

    local token_data, err = token_store.create({
        label = params.label,
        identity = params.identity or "root",
        scopes = scopes,
        access_mode = access_mode,
        trait_filter = trait_filter,
        tool_filter = tool_filter,
        default_active = default_active,
        expires_at = params.expires_at,
    })

    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({ success = false, error = err })
        return
    end

    res:set_status(http.STATUS.OK)
    res:write_json({ success = true, token = token_data })
end

return { handler = handler }
