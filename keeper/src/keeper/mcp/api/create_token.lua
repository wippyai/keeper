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
    local issuer_id = actor:id()
    local issuer_ok, issuer_err = auth.verify_admin_user(issuer_id)
    if not issuer_ok then
        local status, payload = auth.admin_failure(issuer_err)
        if payload.error == "Admin required" then
            payload.error = "MCP token issuance requires an active admin user"
        end
        res:set_status(status)
        res:write_json(payload)
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
    local known = policy.known_scope_set()
    local wants_root = false
    for _, scope in ipairs(scopes) do
        if not known[scope] then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:write_json({ success = false, error = "Unknown MCP scope: " .. tostring(scope) })
            return
        end
        if scope == "mcp.root" then wants_root = true end
    end
    if wants_root then
        local admin_ok, admin_err = auth.verify_admin_user(issuer_id)
        if not admin_ok then
            local status, payload = auth.admin_failure(admin_err)
            if payload.error == "Admin required" then
                payload.error = "mcp.root tokens require the current actor to be an active admin"
            end
            res:set_status(status)
            res:write_json(payload)
            return
        end
        scopes = { "mcp.root" }
        access_mode = "any"
        trait_filter = nil
        tool_filter = nil
    end

    local token_data, err = token_store.create({
        label = params.label,
        identity = issuer_id,
        scopes = scopes,
        access_mode = access_mode,
        trait_filter = trait_filter,
        tool_filter = tool_filter,
        default_active = default_active,
        expires_at = params.expires_at,
        issued_by = issuer_id,
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
