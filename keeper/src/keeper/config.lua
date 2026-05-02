local registry = require("registry")

local M = {}

local function config_error(name, reason, detail)
    return {
        code = "KEEPER_CONFIG_" .. string.upper(reason),
        key = name,
        requirement = "keeper:" .. name,
        entry = "keeper.config:" .. name,
        detail = detail,
        message = "Keeper configuration " .. reason .. ": " .. tostring(name) ..
            " (fill requirement keeper:" .. tostring(name) .. ")",
    }
end

function M.is_error(err)
    return type(err) == "table" and type(err.code) == "string" and
        err.code:find("KEEPER_CONFIG_", 1, true) == 1
end

function M.error_message(err)
    if M.is_error(err) then return tostring(err.message or err.code) end
    return tostring(err)
end

function M.read_default(name)
    local entry, err = registry.get("keeper.config:" .. name)
    if err or not entry then return nil, config_error(name, "missing", err) end
    local data = entry.data or {}
    local value = data.default
    if value == nil or value == "" then return nil, config_error(name, "empty") end
    return tostring(value), nil
end

local function read_default(name)
    local value, err = M.read_default(name)
    if not value then error(M.error_message(err)) end
    return value
end

function M.app_db()
    return read_default("app_db")
end

function M.admin_scope()
    return read_default("admin_scope")
end

function M.process_host()
    return read_default("process_host")
end

function M.mcp_route()
    return read_default("mcp_route")
end

return M
