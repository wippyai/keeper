local registry = require("registry")
local logger = require("logger")
local funcs = require("funcs")

local log = logger:named("gov.service.discovery.observers")

-- Main module
local observers = {}

-- Constants
observers.OBSERVER_TYPE = "registry.observer"
observers.PHASE_BEFORE_APPLY = "before_apply"
observers.OPERATIONS = {
    ["entry.create"] = true,
    ["entry.update"] = true,
    ["entry.delete"] = true,
}

---------------------------
-- Dependency Injection Support
---------------------------
observers._registry = nil
observers._funcs = nil

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

function observers.is_before_apply(entry)
    return type(entry) == "table" and type(entry.meta) == "table"
        and entry.meta.phase == observers.PHASE_BEFORE_APPLY
end
local is_before_apply = observers.is_before_apply

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

-- Describe an observer failure. An observer reports a failure as a call
-- error, or as a result table with success = false.
function observers.failure_message(call_result, call_err)
    if call_err ~= nil then return tostring(call_err) end
    if type(call_result) == "table" and call_result.success == false then
        return tostring(call_result.message or call_result.error or "observer reported a failure")
    end
    return nil
end

-- Run all observers with changeset and result data. Returns one warning per
-- failed observer; the changeset is already applied, so a failure does not
-- change the result.
function observers.run_observers(changeset, result, request_id, user_id)
    local warnings = {}
    log:debug("Running observers for changeset", {
        changeset_count = #changeset,
        request_id = request_id,
        user_id = user_id
    })

    local observer_list = {}
    for _, observer in ipairs(observers.list_all({ raw_entries = true }) or {}) do
        if not is_before_apply(observer) then table.insert(observer_list, observer) end
    end
    if #observer_list == 0 then
        log:debug("No observers found, skipping notification", {
            request_id = request_id,
            user_id = user_id
        })
        return warnings
    end

    local executor = (observers._funcs or funcs).new()
    if not executor then
        log:error("Failed to create function executor", {
            request_id = request_id,
            user_id = user_id
        })
        table.insert(warnings, { message = "registry observers did not run: no function executor" })
        return warnings
    end

    for _, observer in ipairs(observer_list) do
        log:debug("Running observer", {
            observer = observer.id,
            changeset_count = #changeset,
            request_id = request_id,
            user_id = user_id
        })

        local call_result, err = executor:call(tostring(observer.id), {
            changeset = changeset,
            result = result,
            request_id = request_id,
            user_id = user_id
        })

        local message = observers.failure_message(call_result, err)
        if message then
            log:error("Observer error", {
                observer = observer.id,
                error = message,
                request_id = request_id,
                user_id = user_id
            })
            table.insert(warnings, { observer = tostring(observer.id), message = message })
        end
    end
    return warnings
end

function observers.list_before_apply()
    local result = {}
    for _, observer in ipairs(observers.list_all({ raw_entries = true }) or {}) do
        if is_before_apply(observer) then table.insert(result, observer) end
    end
    return result
end

local function planned_entry_id(entry)
    if type(entry) ~= "table" then return nil end
    if type(entry.id) == "string" and entry.id ~= "" then return entry.id end
    if type(entry.namespace) == "string" and type(entry.name) == "string" then
        return entry.namespace .. ":" .. entry.name
    end
    return nil
end
observers.planned_entry_id = planned_entry_id

local function wanted_kinds(observer)
    local kinds = observer.meta.kinds
    if type(kinds) ~= "table" or #kinds == 0 then return nil end
    local set = {}
    for _, kind in ipairs(kinds) do set[tostring(kind)] = true end
    return set
end

-- Select the planned operations an observer reads. A delete carries only the
-- entry identity; create and update carry the entry when its kind matches.
function observers.select_planned(planned, kinds)
    local selected = {}
    for _, op in ipairs(planned or {}) do
        local entry = type(op) == "table" and op.entry or nil
        local id = planned_entry_id(entry)
        if id and (kinds == nil or kinds[tostring(entry.kind)]) then
            if op.op == "delete" then
                table.insert(selected, { op = "delete", entry = { id = id, kind = entry.kind } })
            else
                table.insert(selected, { op = op.op, entry = entry })
            end
        end
    end
    return selected
end

local function valid_operation(op)
    if type(op) ~= "table" or not observers.OPERATIONS[op.kind] then return false end
    if not planned_entry_id(op.entry) then return false end
    if op.kind ~= "entry.delete" and (type(op.entry.kind) ~= "string" or op.entry.kind == "") then return false end
    return true
end

-- Run the before_apply observers against the planned changeset. Each one
-- returns { ops = {...} } with extra registry operations that land in the same
-- registry version. Operations on entries that the changeset already touches
-- are refused. Returns the accepted operations and one warning per failure.
function observers.run_before_apply(changeset, planned, request_id, user_id)
    local ops, warnings = {}, {}
    local observer_list = observers.list_before_apply()
    if #observer_list == 0 then return ops, warnings end

    local executor = (observers._funcs or funcs).new()
    if not executor then
        table.insert(warnings, { message = "before_apply observers did not run: no function executor" })
        return ops, warnings
    end

    local touched = {}
    for _, op in ipairs(planned or {}) do
        local id = planned_entry_id(type(op) == "table" and op.entry or nil)
        if id then touched[id] = true end
    end

    for _, observer in ipairs(observer_list) do
        local call_result, err = executor:call(tostring(observer.id), {
            phase = observers.PHASE_BEFORE_APPLY,
            changeset = changeset,
            planned = observers.select_planned(planned, wanted_kinds(observer)),
            request_id = request_id,
            user_id = user_id,
        })
        local message = observers.failure_message(call_result, err)
        if not message and type(call_result) == "table" and call_result.ops ~= nil
            and type(call_result.ops) ~= "table" then
            message = "before_apply observer returned ops that are not a list"
        end
        if message then
            log:error("before_apply observer error", {
                observer = observer.id, error = message, request_id = request_id, user_id = user_id,
            })
            table.insert(warnings, { observer = tostring(observer.id), message = message })
        else
            for _, op in ipairs(type(call_result) == "table" and call_result.ops or {}) do
                local id = valid_operation(op) and planned_entry_id(op.entry) or nil
                if not id then
                    table.insert(warnings, { observer = tostring(observer.id),
                        message = "before_apply observer returned an invalid operation" })
                elseif touched[id] then
                    table.insert(warnings, { observer = tostring(observer.id),
                        message = "before_apply observer operation on " .. id .. " conflicts with the changeset" })
                else
                    touched[id] = true
                    table.insert(ops, op)
                end
            end
        end
    end
    return ops, warnings
end

return observers
