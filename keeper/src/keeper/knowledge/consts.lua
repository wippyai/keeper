local registry = require("registry")

local M = {}

local function config_default(name, fallback)
    local entry = registry.get("keeper.config:" .. name)
    local data = entry and entry.data or {}
    local value = data.default
    if value == nil or value == "" then return fallback end
    return tostring(value)
end

M.DB_ID = config_default("app_db", "app:db")

M.CENTRAL = "wippy.central"
M.TOPIC = "keeper.knowledge"

M.DEFAULT_KB_ID = "00000000-0000-0000-0000-000000000001"
M.DEFAULT_KB_NAME = "General"

M.NODE_TYPE = {
    PATTERN = "pattern",
    CONVENTION = "convention",
    LEARNING = "learning",
    ANTI_PATTERN = "anti_pattern",
}

M.SOURCE = {
    HUMAN = "human",
    SCAN = "scan",
    SEED = "seed",
    AGENT = "agent",
    WORKSPACE = "workspace",
}

M.EVENTS = {
    KB_CREATED = "kb.created",
    KB_UPDATED = "kb.updated",
    KB_DELETED = "kb.deleted",
    NODE_CREATED = "node.created",
    NODE_UPDATED = "node.updated",
    NODE_DELETED = "node.deleted",
    NODE_EMBEDDED = "node.embedded",
    SCAN_PROGRESS = "scan.progress",
    SCAN_COMPLETE = "scan.complete",
}

M.EMBED = {
    MODEL = "class:embed",
    DIMENSIONS = 512,
}

return M
