local registry = require("registry")
local json = require("json")
local logger = require("logger")

local log = logger:named("linters.discovery")

-- Main module
local linters = {}

-- Constants
linters.LINTER_TYPE = "linter"

---------------------------
-- Dependency Injection Support
---------------------------
linters._registry = nil

-- Internal: Get registry instance
local function get_registry()
    return linters._registry or registry
end

---------------------------
-- Helper Functions
---------------------------

-- Internal: Check if an entry is a valid linter
local function is_valid_linter(entry)
    if not entry or not entry.meta or entry.meta.type ~= linters.LINTER_TYPE then
        return false
    end

    -- Must have level and priority
    if not entry.meta.level or not entry.meta.priority then
        return false
    end

    return true
end

-- Internal: Convert registry entry to linter info
local function entry_to_linter_info(entry)
    return {
        id = entry.id,
        name = (entry.meta and entry.meta.name) or "",
        comment = (entry.meta and entry.meta.comment) or "",
        description = (entry.meta and entry.meta.description) or "",
        level = entry.meta.level,
        priority = entry.meta.priority,
        tags = entry.meta.tags or {},
        namespace = entry.namespace,
        kind = entry.kind
    }
end

---------------------------
-- Public API Functions
---------------------------

function linters.get_by_id(linter_id)
    if not linter_id then
        return nil, "Linter ID is required"
    end

    local reg = get_registry()
    local entry, err = reg.get(linter_id)
    if not entry then
        return nil, "No linter found with ID: " .. tostring(linter_id) .. (err and ", error: " .. tostring(err) or "")
    end

    if not is_valid_linter(entry) then
        return nil, "Entry is not a valid linter: " .. tostring(linter_id)
    end

    return entry_to_linter_info(entry)
end

function linters.list_all(opts)
    opts = opts or {}
    local reg = get_registry()

    local query = {
        ["meta.type"] = linters.LINTER_TYPE
    }

    local entries = reg.find(query) or {}
    local results = {}

    for _, entry in ipairs(entries) do
        if is_valid_linter(entry) then
            if opts.raw_entries then
                table.insert(results, entry)
            else
                table.insert(results, entry_to_linter_info(entry))
            end
        end
    end

    -- Sort by priority (lowest first)
    table.sort(results, function(a, b)
        local a_priority = opts.raw_entries and a.meta.priority or a.priority
        local b_priority = opts.raw_entries and b.meta.priority or b.priority
        return a_priority < b_priority
    end)

    return results
end

function linters.list_by_level(level, opts)
    if not level then
        return nil, "Level is required"
    end

    opts = opts or {}
    local reg = get_registry()

    local query = {
        ["meta.type"] = linters.LINTER_TYPE,
        ["meta.level"] = level
    }

    local entries = reg.find(query) or {}
    local results = {}

    for _, entry in ipairs(entries) do
        if is_valid_linter(entry) then
            if opts.raw_entries then
                table.insert(results, entry)
            else
                table.insert(results, entry_to_linter_info(entry))
            end
        end
    end

    -- Sort by priority (lowest first)
    table.sort(results, function(a, b)
        local a_priority = opts.raw_entries and a.meta.priority or a.priority
        local b_priority = opts.raw_entries and b.meta.priority or b.priority
        return a_priority < b_priority
    end)

    return results
end

function linters.list_by_priority_range(min_priority, max_priority, opts)
    if not min_priority or not max_priority then
        return nil, "Both min_priority and max_priority are required"
    end

    opts = opts or {}
    local all_linters = linters.list_all(opts)
    local results = {}

    for _, linter in ipairs(all_linters) do
        local priority = opts.raw_entries and linter.meta.priority or linter.priority
        if priority >= min_priority and priority <= max_priority then
            table.insert(results, linter)
        end
    end

    return results
end

function linters.find_linters(criteria)
    criteria = criteria or {}
    local reg = get_registry()

    local query = {
        ["meta.type"] = linters.LINTER_TYPE
    }

    -- Add criteria to query
    if criteria.namespace then
        query[".ns"] = criteria.namespace
    end

    if criteria.tags and #criteria.tags > 0 then
        query["meta.tags"] = criteria.tags
    end

    if criteria.level then
        query["meta.level"] = criteria.level
    end

    local entries = reg.find(query) or {}
    local results = {}

    for _, entry in ipairs(entries) do
        if is_valid_linter(entry) then
            local linter_info = entry_to_linter_info(entry)

            -- Apply additional filters
            local matches = true

            if criteria.min_level and linter_info.level < criteria.min_level then
                matches = false
            end

            if criteria.max_level and linter_info.level > criteria.max_level then
                matches = false
            end

            if criteria.min_priority and linter_info.priority < criteria.min_priority then
                matches = false
            end

            if criteria.max_priority and linter_info.priority > criteria.max_priority then
                matches = false
            end

            if matches then
                table.insert(results, linter_info)
            end
        end
    end

    -- Sort by priority (lowest first)
    table.sort(results, function(a, b)
        return a.priority < b.priority
    end)

    return results
end

function linters.get_available_levels()
    local all_linters = linters.list_all()
    local levels = {}
    local level_set = {}

    for _, linter in ipairs(all_linters) do
        if not level_set[linter.level] then
            level_set[linter.level] = true
            table.insert(levels, linter.level)
        end
    end

    table.sort(levels)
    return levels
end

function linters.get_stats()
    local all_linters = linters.list_all()
    local stats = {
        total_count = #all_linters,
        by_level = {},
        by_namespace = {},
        level_range = { min = nil, max = nil },
        priority_range = { min = nil, max = nil }
    }

    for _, linter in ipairs(all_linters) do
        -- Count by level
        if not stats.by_level[linter.level] then
            stats.by_level[linter.level] = 0
        end
        stats.by_level[linter.level] = stats.by_level[linter.level] + 1

        -- Count by namespace
        if not stats.by_namespace[linter.namespace] then
            stats.by_namespace[linter.namespace] = 0
        end
        stats.by_namespace[linter.namespace] = stats.by_namespace[linter.namespace] + 1

        -- Track level range
        if not stats.level_range.min or linter.level < stats.level_range.min then
            stats.level_range.min = linter.level
        end
        if not stats.level_range.max or linter.level > stats.level_range.max then
            stats.level_range.max = linter.level
        end

        -- Track priority range
        if not stats.priority_range.min or linter.priority < stats.priority_range.min then
            stats.priority_range.min = linter.priority
        end
        if not stats.priority_range.max or linter.priority > stats.priority_range.max then
            stats.priority_range.max = linter.priority
        end
    end

    return stats
end

function linters.build_chain(chain_config)
    if not chain_config or not chain_config.linters then
        return nil, "Chain config with linters array is required"
    end

    local chain = {}
    local reg = get_registry()

    for _, linter_spec in ipairs(chain_config.linters) do
        if not linter_spec.id then
            return nil, "Linter spec missing required 'id' field"
        end

        local entry, err = reg.get(linter_spec.id)
        if not entry then
            return nil, "Linter not found: " .. linter_spec.id .. (err and ", error: " .. err or "")
        end

        if not is_valid_linter(entry) then
            return nil, "Invalid linter: " .. linter_spec.id
        end

        local chain_entry = {
            id = entry.id,
            linter_info = entry_to_linter_info(entry),
            options = linter_spec.options or {},
            enabled = linter_spec.enabled ~= false -- Default to enabled unless explicitly disabled
        }

        table.insert(chain, chain_entry)
    end

    -- Sort chain by priority (lowest first)
    table.sort(chain, function(a, b)
        return a.linter_info.priority < b.linter_info.priority
    end)

    return chain
end

return linters
