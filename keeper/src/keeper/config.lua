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

function M.read_default(name: string): (string?, unknown?)
    local entry, err = registry.get("keeper.config:" .. name)
    if err or not entry then return nil, config_error(name, "missing", err) end
    local data = entry.data or {}
    local value = data.default
    if value == nil or value == "" then return nil, config_error(name, "empty") end
    return tostring(value), nil
end

local function read_default(name: string): string
    local value, err = M.read_default(name)
    if not value then error(M.error_message(err)) end
    return value
end

function M.app_db(): string
    return read_default("app_db")
end

function M.admin_scope(): string
    return read_default("admin_scope")
end

function M.auth_token_store(): string
    local value, err = M.read_default("auth_token_store")
    if not value or value == "undefined" then
        error(M.error_message(err or config_error("auth_token_store", "empty", "set keeper:auth_token_store")))
    end
    return tostring(value)
end

function M.process_host(): string
    return read_default("process_host")
end

function M.mcp_route(): string
    return read_default("mcp_route")
end

return M
