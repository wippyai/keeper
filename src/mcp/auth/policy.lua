local registry = require("registry")

local M = {}

local PRESET_META_TYPE = "mcp.preset"
local SCOPE_META_TYPE = "mcp.scope"

local function data_of(e)
    local d = e.data
    if type(d) ~= "table" then return {} end
    return d
end

local function meta_of(e)
    local m = e.meta
    if type(m) ~= "table" then return {} end
    return m
end

-- Registry entries carry fully-qualified ids like "keeper.mcp.presets:root".
-- Returns the trailing segment ("root") so the API exposes short preset keys.
local function short_name(entry_id)
    if type(entry_id) ~= "string" then return entry_id end
    return entry_id:match(":(.+)$") or entry_id
end

local function normalize_preset(e)
    local data = data_of(e)
    local meta = meta_of(e)
    return {
        id = short_name(e.id),
        registry_id = e.id,
        label = meta.title or short_name(e.id),
        description = meta.comment,
        icon = meta.icon,
        access_mode = data.access_mode or "tools_only",
        scopes = data.scopes or {},
        trait_filter = data.trait_filter,
        tool_filter = data.tool_filter,
        default_active = data.default_active or {},
    }
end

local function normalize_scope(e)
    local data = data_of(e)
    local meta = meta_of(e)
    return {
        id = data.id or short_name(e.id),
        registry_id = e.id,
        label = meta.title or short_name(e.id),
        description = meta.comment,
    }
end

M._normalize_preset = normalize_preset
M._normalize_scope = normalize_scope
M._short_name = short_name

function M.list_presets()
    local entries = registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = PRESET_META_TYPE,
    }) or {}
    local result = {}
    for _, e in ipairs(entries) do
        table.insert(result, normalize_preset(e))
    end
    table.sort(result, function(a, b) return a.id < b.id end)
    return result
end

-- Accepts either a full registry id ("keeper.mcp.presets:root") or a short
-- name ("root"). Short names scan the catalog; full ids go through registry.get
-- directly.
function M.get_preset(key)
    if type(key) ~= "string" or key == "" then
        return nil, "preset key required"
    end
    if key:find(":") then
        local e, err = registry.get(key)
        if not e then return nil, err or ("preset not found: " .. key) end
        if meta_of(e).type ~= PRESET_META_TYPE then
            return nil, "entry is not a preset: " .. key
        end
        return normalize_preset(e)
    end
    for _, p in ipairs(M.list_presets()) do
        if p.id == key then return p end
    end
    return nil, "preset not found: " .. key
end

function M.list_scopes()
    local entries = registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = SCOPE_META_TYPE,
    }) or {}
    local result = {}
    for _, e in ipairs(entries) do
        table.insert(result, normalize_scope(e))
    end
    table.sort(result, function(a, b) return a.id < b.id end)
    return result
end

-- Set-of-valid-scope-ids helper for validation paths.
function M.known_scope_set()
    local set = {}
    for _, s in ipairs(M.list_scopes()) do set[s.id] = true end
    return set
end

return M
