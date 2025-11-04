local registry = require("registry")

---------------------------
-- Main module
---------------------------
local pattern_registry = {}

-- Constants
pattern_registry.PATTERN_TYPE = "pattern"

---------------------------
-- Dependency Injection Support
---------------------------
pattern_registry._registry = nil

-- Internal: Get registry instance
local function get_registry()
    return pattern_registry._registry or registry
end

---------------------------
-- Helper Functions
---------------------------

-- Internal: Check if an entry is a valid pattern
local function is_valid_pattern(entry)
    return entry and entry.meta and entry.meta.type == pattern_registry.PATTERN_TYPE
end

-- Internal: Convert registry entry to pattern spec
local function entry_to_pattern_spec(entry)
    return {
        id = entry.id,
        title = (entry.meta and entry.meta.title) or "",
        comment = (entry.meta and entry.meta.comment) or "",
        class = (entry.meta and entry.meta.class) or {},
        tags = (entry.meta and entry.meta.tags) or {},
        content = (entry.data and entry.data.content) or ""
    }
end

-- Internal: Check if pattern matches any of the requested classes
local function matches_classes(pattern_classes, requested_classes)
    if not requested_classes or #requested_classes == 0 then
        return true
    end

    if not pattern_classes then
        return false
    end

    -- Convert single string to array for consistent processing
    local classes_array = pattern_classes
    if type(pattern_classes) == "string" then
        classes_array = { pattern_classes }
    end

    -- Check if ANY requested class matches ANY pattern class
    for _, requested in ipairs(requested_classes) do
        for _, pattern_class in ipairs(classes_array) do
            if pattern_class == requested then
                return true
            end
        end
    end

    return false
end

---------------------------
-- Public API Functions
---------------------------

function pattern_registry.get_by_id(pattern_id)
    if not pattern_id then
        return nil, "Pattern ID is required"
    end

    local reg = get_registry()
    local entry, err = reg.get(pattern_id)
    if not entry then
        return nil, "No pattern found with ID: " .. tostring(pattern_id) .. (err and ", error: " .. tostring(err) or "")
    end

    if not is_valid_pattern(entry) then
        return nil, "Entry is not a pattern: " .. tostring(pattern_id)
    end

    return entry_to_pattern_spec(entry)
end

function pattern_registry.list_by_classes(classes, opts)
    opts = opts or {}
    local reg = get_registry()

    -- First pass – get all patterns
    local query = {
        [".kind"] = "registry.entry",
        ["meta.type"] = pattern_registry.PATTERN_TYPE
    }

    local entries = reg.find(query) or {}

    -- Second pass – filter by classes
    local results = {}
    for _, entry in ipairs(entries) do
        if is_valid_pattern(entry) then
            local pattern_classes = entry.meta and entry.meta.class

            if matches_classes(pattern_classes, classes) then
                if opts.raw_entries then
                    table.insert(results, entry)
                else
                    table.insert(results, entry_to_pattern_spec(entry))
                end
            end
        end
    end

    return results
end

function pattern_registry.list_all(opts)
    opts = opts or {}
    local reg = get_registry()

    local query = {
        [".kind"] = "registry.entry",
        ["meta.type"] = pattern_registry.PATTERN_TYPE
    }

    local entries = reg.find(query) or {}
    local results = {}

    for _, entry in ipairs(entries) do
        if is_valid_pattern(entry) then
            if opts.raw_entries then
                table.insert(results, entry)
            else
                table.insert(results, entry_to_pattern_spec(entry))
            end
        end
    end

    return results
end

return pattern_registry
