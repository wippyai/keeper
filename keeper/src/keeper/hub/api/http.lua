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

local STATUS_BY_KIND = {
    [errors.INVALID] = http.STATUS.BAD_REQUEST,
    [errors.NOT_FOUND] = http.STATUS.NOT_FOUND,
    [errors.ALREADY_EXISTS] = 409,
    [errors.PERMISSION_DENIED] = http.STATUS.FORBIDDEN,
    [errors.CONFLICT] = 409,
    [errors.RATE_LIMITED] = 429,
    [errors.UNAVAILABLE] = 503,
    [errors.TIMEOUT] = 504,
    [errors.INTERNAL] = http.STATUS.INTERNAL_ERROR,
    [errors.UNKNOWN] = http.STATUS.INTERNAL_ERROR,
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

local function call_method(value, name)
    if value == nil then return nil end
    local ok, method = pcall(function() return value[name] end)
    if not ok or type(method) ~= "function" then return nil end
    local called, result = pcall(method, value)
    if called then return result end
    return nil
end

local function copy_without_code(details)
    if type(details) ~= "table" then return details end
    local out = {}
    for k, v in pairs(details) do
        if k ~= "code" then out[k] = v end
    end
    if out.value ~= nil then
        local count = 0
        for _ in pairs(out) do count = count + 1 end
        if count == 1 then return out.value end
    end
    return out
end

function M.write_service_error(res, service_err)
    local details = call_method(service_err, "details")
    if details == nil and type(service_err) == "table" then details = service_err.details end
    local code = nil
    if type(details) == "table" and type(details.code) == "string" then code = details.code end
    if not code and type(service_err) == "table" and type(service_err.code) == "string" then code = service_err.code end
    local kind = call_method(service_err, "kind")
    local message = call_method(service_err, "message")
        or (type(service_err) == "table" and (service_err.message or service_err.error))
        or tostring(service_err or "unknown error")
    local status = (code and STATUS_BY_CODE[code]) or STATUS_BY_KIND[kind] or http.STATUS.INTERNAL_ERROR
    res:set_status(status)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        success = false,
        code = code or tostring(kind or "INTERNAL"),
        error = message,
        details = copy_without_code(details),
    })
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
        local status, payload = mcp_auth.admin_failure(admin_err)
        res:set_status(status)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json(payload)
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
