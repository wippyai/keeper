local registry = require("registry")
local logger = require("logger")
local funcs = require("funcs")

local log = logger:named("gov.service.discovery.observers")

-- Main module
local observers = {}

-- Constants
observers.OBSERVER_TYPE = "registry.observer"

---------------------------
-- Dependency Injection Support
---------------------------
observers._registry = nil

-- Internal: Get registry instance
local function get_registry()
    return observers._registry or registry
end

---------------------------
-- Helper Functions
---------------------------

function observers.is_valid_observer(entry)
    if type(entry) ~= "table" then return false end
    if type(entry.meta) ~= "table" then return false end
    if entry.meta.type ~= observers.OBSERVER_TYPE then return false end
    if not entry.meta.priority then return false end
    return true
end
local is_valid_observer = observers.is_valid_observer

function observers.entry_to_observer_info(entry)
    return {
        id = entry.id,
        name = (entry.meta and entry.meta.name) or "",
        comment = (entry.meta and entry.meta.comment) or "",
        description = (entry.meta and entry.meta.description) or "",
        priority = entry.meta.priority,
        tags = entry.meta.tags or {},
        namespace = entry.namespace,
        kind = entry.kind
    }
end
local entry_to_observer_info = observers.entry_to_observer_info

-- Pure reduce over a list of observer info rows. Returns { total_count,
-- by_namespace, priority_range = { min, max } }. Callers hand in the
-- already-filtered observer list (raw_entries=false form from list_all).
function observers.aggregate_stats(observer_list)
    local stats = {
        total_count    = 0,
        by_namespace   = {},
        priority_range = { min = nil, max = nil },
    }
    if type(observer_list) ~= "table" then return stats end

    for _, observer in ipairs(observer_list) do
        stats.total_count = stats.total_count + 1

        local ns = observer.namespace or "unknown"
        stats.by_namespace[ns] = (stats.by_namespace[ns] or 0) + 1

        local p = observer.priority
        if p ~= nil then
            if stats.priority_range.min == nil or p < stats.priority_range.min then
                stats.priority_range.min = p
            end
            if stats.priority_range.max == nil or p > stats.priority_range.max then
                stats.priority_range.max = p
            end
        end
    end

    return stats
end

---------------------------
-- Public API Functions
---------------------------

function observers.get_by_id(observer_id)
    if not observer_id then
        return nil, "Observer ID is required"
    end

    local reg = get_registry()
    if not reg then
        return nil, "Registry is not available"
    end

    local entry, err = reg.get(tostring(observer_id))
    if not entry then
        return nil, "No observer found with ID: " .. tostring(observer_id) .. (err and ", error: " .. tostring(err) or "")
    end

    if not is_valid_observer(entry) then
        return nil, "Entry is not a valid observer: " .. tostring(observer_id)
    end

    return entry_to_observer_info(entry)
end

function observers.list_all(opts)
    opts = opts or {}
    local reg = get_registry()

    local query = {
        ["meta.type"] = observers.OBSERVER_TYPE
    }

    local entries = reg.find(query) or {}
    local results = {}

    for _, entry in ipairs(entries) do
        if is_valid_observer(entry) then
            if opts.raw_entries then
                table.insert(results, entry)
            else
                table.insert(results, entry_to_observer_info(entry))
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

function observers.list_by_priority_range(min_priority, max_priority, opts)
    if not min_priority or not max_priority then
        return nil, "Both min_priority and max_priority are required"
    end

    opts = opts or {}
    local all_observers = observers.list_all(opts)
    local results = {}

    for _, observer in ipairs(all_observers) do
        local priority = opts.raw_entries and observer.meta.priority or observer.priority
        if priority >= min_priority and priority <= max_priority then
            table.insert(results, observer)
        end
    end

    return results
end

function observers.find_observers(criteria)
    criteria = criteria or {}
    local reg = get_registry()

    local query = {
        ["meta.type"] = observers.OBSERVER_TYPE
    }

    -- Add criteria to query
    if criteria.namespace then
        query[".ns"] = criteria.namespace
    end

    if criteria.tags and #criteria.tags > 0 then
        query["meta.tags"] = criteria.tags
    end

    local entries = reg.find(query) or {}
    local results = {}

    for _, entry in ipairs(entries) do
        if is_valid_observer(entry) then
            local observer_info = entry_to_observer_info(entry)

            -- Apply additional filters
            local matches = true

            if criteria.min_priority and observer_info.priority < criteria.min_priority then
                matches = false
            end

            if criteria.max_priority and observer_info.priority > criteria.max_priority then
                matches = false
            end

            if matches then
                table.insert(results, observer_info)
            end
        end
    end

    -- Sort by priority (lowest first)
    table.sort(results, function(a, b)
        return a.priority < b.priority
    end)

    return results
end

function observers.get_stats()
    return observers.aggregate_stats(observers.list_all())
end

-- Run all observers with changeset and result data
function observers.run_observers(changeset, result, request_id, user_id)
    log:debug("Running observers for changeset", {
        changeset_count = #changeset,
        request_id = request_id,
        user_id = user_id
    })

    -- Get all observers
    local observer_list = observers.list_all({ raw_entries = true })
    if not observer_list or #observer_list == 0 then
        log:debug("No observers found, skipping notification", {
            request_id = request_id,
            user_id = user_id
        })
        return
    end

    local executor = funcs.new()
    if not executor then
        log:error("Failed to create function executor", {
            request_id = request_id,
            user_id = user_id
        })
        return
    end

    -- Run each observer with entire batch
    for _, observer in ipairs(observer_list) do
        log:debug("Running observer", {
            observer = observer.id,
            changeset_count = #changeset,
            request_id = request_id,
            user_id = user_id
        })

        -- Call the observer without waiting for response
        local _, err = executor:call(tostring(observer.id), {
            changeset = changeset,
            result = result,
            request_id = request_id,
            user_id = user_id
        })

        if err ~= nil then
            log:error("Observer error", {
                observer = observer.id,
                error = err,
                request_id = request_id,
                user_id = user_id
            })
        end
    end
end

return observers