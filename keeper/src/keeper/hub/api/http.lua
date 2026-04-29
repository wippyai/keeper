local http = require("http")
local json = require("json")
local security = require("security")
local mcp_auth = require("mcp_auth")

local M = {}

local STATUS_BY_CODE = {
    BAD_REQUEST = http.STATUS.BAD_REQUEST,
    UNAUTHORIZED = http.STATUS.UNAUTHORIZED,
    FORBIDDEN = http.STATUS.FORBIDDEN,
    NOT_FOUND = http.STATUS.NOT_FOUND,
    CONFLICT = 409,
    REQUIREMENTS_MISSING = 409,
    MIGRATIONS_APPLIED = 409,
    INTERNAL = http.STATUS.INTERNAL_ERROR,
}

local function merge_success(payload)
    local out = { success = true }
    for k, v in pairs(payload or {}) do out[k] = v end
    return out
end

function M.write_ok(res, payload)
    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json(merge_success(payload))
end

function M.write_error(res, code, message, details)
    local status = STATUS_BY_CODE[code] or http.STATUS.INTERNAL_ERROR
    res:set_status(status)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success = false,
        code = code,
        error = message,
        details = details,
    })
end

function M.write_service_error(res, service_err)
    service_err = service_err or {}
    M.write_error(res,
        service_err.code or "INTERNAL",
        service_err.message or "unknown error",
        service_err.details)
end

function M.require_actor(res)
    local actor = security.actor()
    if not actor then
        M.write_error(res, "UNAUTHORIZED", "Authentication required")
        return nil
    end
    return actor
end

function M.require_admin_actor(res)
    local actor = M.require_actor(res)
    if not actor then return nil end

    local ok, admin_err = mcp_auth.verify_admin_user(actor:id())
    if not ok then
        M.write_error(res, "FORBIDDEN", "Admin required", admin_err)
        return nil
    end
    return actor
end

function M.json_body(req)
    local body = req:body()
    if not body or body == "" then return {}, nil end
    body = tostring(body)
    local decoded, decode_err = json.decode(body)
    if decode_err or type(decoded) ~= "table" then
        return nil, "Invalid JSON body"
    end
    return decoded, nil
end

function M.query_bool(req, name, default)
    local value = req:query(name)
    if value == nil or value == "" then return default end
    value = tostring(value):lower()
    if value == "1" or value == "true" or value == "yes" or value == "on" then return true end
    if value == "0" or value == "false" or value == "no" or value == "off" then return false end
    return default
end

return M
