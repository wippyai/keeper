local registry = require("registry")

local M = {}

local DEFAULTS = {
    app_db = "app:db",
    admin_scope = "app.security:admin",
    process_host = "app:processes",
}

local function read_default(name)
    local entry, err = registry.get("keeper.config:" .. name)
    if err or not entry then return DEFAULTS[name] end
    local data = entry.data or {}
    local value = data.default
    if value == nil or value == "" then return DEFAULTS[name] end
    return tostring(value)
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

return M

