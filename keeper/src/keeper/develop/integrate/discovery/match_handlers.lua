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

local function fs_path_matches_handler(path, handler)
    local handles = handler.meta and handler.meta.handles
    if not handles then return false end

    local prefixes = handles.fs_prefix
    if prefixes then
        if type(prefixes) == "string" then prefixes = { prefixes } end
        for _, prefix in ipairs(prefixes) do
            if type(prefix) == "string"
                and type(path) == "string"
                and path:sub(1, #prefix) == prefix then
                return true
            end
        end
    end

    local patterns = handles.fs_pattern
    if patterns then
        if type(patterns) == "string" then patterns = { patterns } end
        for _, pattern in ipairs(patterns) do
            if type(pattern) == "string" and type(path) == "string" then
                local ok, result = pcall(string.match, path, pattern)
                if ok and result then return true end
            end
        end
    end
    return false
end

function M.match_handlers(entries, operation, fs_paths)
    entries = entries or {}
    fs_paths = fs_paths or {}
    if #entries == 0 and #fs_paths == 0 then return {} end
    operation = operation or "up"

    local handlers = M.list_handlers()
    local handler_map = {}
    local handler_data = {}
    local handler_fs = {}

    local function register(handler_id, handler_meta)
        if not handler_data[handler_id] then
            handler_data[handler_id] = {
                order = (handler_meta and handler_meta.order) or 999,
                meta  = handler_meta,
            }
        end
    end

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
                register(handler.id, handler.meta)
            end
        end
    end

    for _, path in ipairs(fs_paths) do
        for _, handler in ipairs(handlers) do
            local operations = (handler.meta and handler.meta.operations) or {}
            local supports_op = false
            for _, op in ipairs(operations) do
                if op == operation then supports_op = true; break end
            end
            if supports_op and fs_path_matches_handler(path, handler) then
                handler_fs[handler.id] = handler_fs[handler.id] or {}
                table.insert(handler_fs[handler.id], path)
                register(handler.id, handler.meta)
            end
        end
    end

    local sorted = {}
    local seen = {}
    for handler_id, entry_ids in pairs(handler_map) do
        seen[handler_id] = true
        local data = handler_data[handler_id] or { order = 0, meta = {} }
        table.insert(sorted, {
            handler_id = handler_id,
            entries    = entry_ids,
            fs_paths   = handler_fs[handler_id] or {},
            order      = data.order,
            meta       = data.meta,
        })
    end
    for handler_id, paths in pairs(handler_fs) do
        if not seen[handler_id] then
            local data = handler_data[handler_id] or { order = 0, meta = {} }
            table.insert(sorted, {
                handler_id = handler_id,
                entries    = {},
                fs_paths   = paths,
                order      = data.order,
                meta       = data.meta,
            })
        end
    end
    table.sort(sorted, function(a, b) return a.order < b.order end)
    return sorted
end

return M
