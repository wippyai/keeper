local registry = require("registry")
local json = require("json")

local discovery = {}

discovery.HANDLER_TYPE = "integration.handler"

local function kind_matches(entry_kind, pattern)
    if not entry_kind or not pattern then
        return false
    end

    if entry_kind == pattern then
        return true
    end

    if type(pattern) == "string" then
        local success, result = pcall(string.match, entry_kind, pattern)
        if success and result then
            return true
        end
    end

    if type(pattern) == "table" then
        for _, p in ipairs(pattern) do
            if kind_matches(entry_kind, p) then
                return true
            end
        end
    end

    return false
end

local function meta_value_matches(value, pattern)
    if pattern == nil then
        return true
    end

    if value == nil then
        return false
    end

    if value == pattern then
        return true
    end

    if type(value) == "string" and type(pattern) == "string" then
        local success, result = pcall(string.match, value, pattern)
        if success and result then
            return true
        end
    end

    return false
end

local function entry_matches_handler(entry, handler)
    local handles = handler.meta and handler.meta.handles
    if not handles then
        return false
    end

    for key, pattern in pairs(handles) do
        if key:sub(1, 5) == "meta." then
            local meta_key = key:sub(6)
            local entry_value = entry.meta and entry.meta[meta_key]

            if not meta_value_matches(entry_value, pattern) then
                return false
            end
        elseif key == "kind" then
            if not kind_matches(entry.kind, pattern) then
                return false
            end
        end
    end

    return true
end

function discovery.list_handlers()
    return registry.find({
        [".kind"] = "function.lua",
        ["meta.type"] = discovery.HANDLER_TYPE
    }) or {}
end

function discovery.get_handler(handler_id)
    if not handler_id or handler_id == "" then
        return nil, "Handler ID required"
    end

    local entry, err = registry.get(handler_id)
    if err then
        return nil, "Failed to get handler: " .. err
    end

    if not entry then
        return nil, "Handler not found: " .. handler_id
    end

    if entry.meta.type ~= discovery.HANDLER_TYPE then
        return nil, "Entry is not a handler: " .. handler_id
    end

    return entry
end

function discovery.match_handlers(entries, operation)
    if not entries or #entries == 0 then
        return {}
    end

    operation = operation or "up"

    local handlers = discovery.list_handlers()
    local handler_map = {}
    local handler_data = {}

    for _, entry in ipairs(entries) do
        for _, handler in ipairs(handlers) do
            local operations = handler.meta and handler.meta.operations or {}
            local supports_op = false
            for _, op in ipairs(operations) do
                if op == operation then
                    supports_op = true
                    break
                end
            end

            if supports_op and entry_matches_handler(entry, handler) then
                handler_map[handler.id] = handler_map[handler.id] or {}
                table.insert(handler_map[handler.id], entry.id)

                if not handler_data[handler.id] then
                    handler_data[handler.id] = {
                        order = handler.meta and handler.meta.order or 999,
                        meta = handler.meta
                    }
                end
            end
        end
    end

    local sorted_handlers = {}
    for handler_id, entry_ids in pairs(handler_map) do
        table.insert(sorted_handlers, {
            handler_id = handler_id,
            entries = entry_ids,
            order = handler_data[handler_id].order,
            meta = handler_data[handler_id].meta
        })
    end

    table.sort(sorted_handlers, function(a, b)
        return a.order < b.order
    end)

    return sorted_handlers
end

function discovery.validate_handler(handler)
    if not handler.meta then
        return false, "Missing metadata"
    end

    if handler.meta.type ~= discovery.HANDLER_TYPE then
        return false, "Invalid type"
    end

    if not handler.meta.handles then
        return false, "Missing handles"
    end

    local operations = handler.meta.operations or {}
    if #operations == 0 then
        return false, "No operations declared"
    end

    for _, op in ipairs(operations) do
        if op ~= "up" and op ~= "down" and op ~= "final" then
            return false, "Invalid operation: " .. op
        end
    end

    return true
end

return discovery
