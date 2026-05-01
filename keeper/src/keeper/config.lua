local registry = require("registry")

local M = {}

local function read_default(name)
    local entry, err = registry.get("keeper.config:" .. name)
    if err or not entry then error("keeper config missing: " .. tostring(name)) end
    local data = entry.data or {}
    local value = data.default
    if value == nil or value == "" then error("keeper config empty: " .. tostring(name)) end
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

function M.mcp_route()
    return read_default("mcp_route")
end

return M
