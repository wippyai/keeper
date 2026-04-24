-- Integration handler discovery. Registers all `function.lua` entries whose
-- meta.type == "integration.handler" and matches each pushed entry to the
-- right handler based on the handler's `meta.handles` (kind or meta.* filter).
--
-- Mirrors the old keeper's keeper.develop.integrate.discovery:registry (kept the
-- same meta contract: {handles, operations, order, mode}).

local registry = require("registry")

local M = {}

M.HANDLER_TYPE = "integration.handler"

local function kind_matches(entry_kind, pattern)
    if not entry_kind or not pattern then return false end
    if entry_kind == pattern then return true end
    if type(pattern) == "string" then
        local ok, result = pcall(string.match, entry_kind, pattern)
        if ok and result then return true end
    end
    if type(pattern) == "table" then
        for _, p in ipairs(pattern) do
            if kind_matches(entry_kind, p) then return true end
        end
    end
    return false
end

local function meta_value_matches(value, pattern)
    if pattern == nil then return true end
    if value == nil then return false end
    if value == pattern then return true end
    if type(value) == "string" and type(pattern) == "string" then
        local ok, result = pcall(string.match, value, pattern)
        if ok and result then return true end
    end
    return false
end

local function entry_matches_handler(entry, handler)
    local handles = handler.meta and handler.meta.handles
    if not handles then return false end
    for key, pattern in pairs(handles) do
        if key:sub(1, 5) == "meta." then
            local meta_key = key:sub(6)
            local entry_value = entry.meta and entry.meta[meta_key]
            if not meta_value_matches(entry_value, pattern) then return false end
        elseif key == "kind" then
            if not kind_matches(entry.kind, pattern) then return false end
        end
    end
    return true
end

function M.list_handlers()
    return registry.find({
        [".kind"]      = "function.lua",
        ["meta.type"]  = M.HANDLER_TYPE,
    }) or {}
end

function M.match_handlers(entries, operation)
    if not entries or #entries == 0 then return {} end
    operation = operation or "up"

    local handlers = M.list_handlers()
    local handler_map = {}
    local handler_data = {}

    for _, entry in ipairs(entries) do
        for _, handler in ipairs(handlers) do
            local operations = (handler.meta and handler.meta.operations) or {}
            local supports_op = false
            for _, op in ipairs(operations) do
                if op == operation then supports_op = true; break end
            end
            if supports_op and entry_matches_handler(entry, handler) then
                handler_map[handler.id] = handler_map[handler.id] or {}
                table.insert(handler_map[handler.id], entry.id)
                if not handler_data[handler.id] then
                    handler_data[handler.id] = {
                        order = (handler.meta and handler.meta.order) or 999,
                        meta  = handler.meta,
                    }
                end
            end
        end
    end

    local sorted = {}
    for handler_id, entry_ids in pairs(handler_map) do
        table.insert(sorted, {
            handler_id = handler_id,
            entries    = entry_ids,
            order      = handler_data[handler_id].order,
            meta       = handler_data[handler_id].meta,
        })
    end
    table.sort(sorted, function(a, b) return a.order < b.order end)
    return sorted
end

return M
