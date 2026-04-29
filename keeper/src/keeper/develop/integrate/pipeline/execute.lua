-- Integrate pipeline dispatcher. Runs each matched integration.handler in
-- meta.order order with a synchronous funcs.new():call — we intentionally do
-- NOT build a sub-flow here, because flow.run() yields control back to the
-- parent dataflow when invoked from inside one (integrate/run.lua) and that
-- defers handler execution past run.lua's own success check.

local funcs    = require("funcs")
local registry = require("registry")
local discovery = require("discovery")

local EXECUTE_HANDLER_ID = "keeper.develop.integrate.pipeline:execute_handler"

local function string_list(value)
    local out = {}
    if type(value) ~= "table" then return out end
    for _, item in ipairs(value) do
        if type(item) == "string" and item ~= "" then
            table.insert(out, item)
        end
    end
    return out
end

local function snapshot_entry(entry)
    local meta = entry.meta or {}
    local data = entry.data or {}
    return {
        id        = entry.id,
        kind      = entry.kind,
        method    = data.method or entry.method,
        source    = data.source or entry.source,
        meta_type = meta.type,
        target_db = meta.target_db,
    }
end

local function handler(params)
    local entry_ids = string_list(params.entry_ids)
    -- Raw filesystem paths from the changeset (e.g. frontend/** edits) that
    -- don't correspond to a registry entry but still need handler-chain
    -- reactions — notably build_handler for SPA rebuilds after Vue/TS edits.
    local fs_paths = string_list(params.fs_paths)
    local operation = params.operation or "up"

    if #entry_ids == 0 and #fs_paths == 0 then
        return {
            success = true,
            applied_ids = {},
            execution = { handlers = {} },
        }
    end

    local entries = {}
    local entry_by_id = {}
    for _, entry_id in ipairs(entry_ids) do
        local entry, err = registry.get(entry_id)
        if err then
            return nil, "Failed to load entry: " .. entry_id .. " - " .. err
        end
        table.insert(entries, entry)
        entry_by_id[entry_id] = entry
    end

    local sorted_handlers = discovery.match_handlers(entries, operation, fs_paths)
    if not sorted_handlers or #sorted_handlers == 0 then
        return {
            success = true,
            applied_ids = {},
            execution = { handlers = {} },
        }
    end

    for _, handler_node in ipairs(sorted_handlers) do
        local _, err = registry.get(handler_node.handler_id)
        if err then
            return nil, "Failed to load handler " .. handler_node.handler_id .. ": " .. err
        end
    end

    local handler_outputs = {}
    local applied_ids = {}
    local any_failed = false

    for _, handler_node in ipairs(sorted_handlers) do
        local input_entries = {}
        for _, entry_id in ipairs(handler_node.entries or {}) do
            local entry = entry_by_id[entry_id]
            if entry then
                table.insert(input_entries, snapshot_entry(entry))
            else
                table.insert(input_entries, { id = entry_id, missing = true })
            end
        end

        local executor = funcs.new()
        local ok, handler_result, call_err = pcall(executor.call, executor,
            EXECUTE_HANDLER_ID, {
                handler_id = handler_node.handler_id,
                entry_ids  = handler_node.entries,
                fs_paths   = handler_node.fs_paths or {},
                operation  = operation,
            })

        local wrapped
        if not ok then
            wrapped = {
                handler_id = handler_node.handler_id,
                entry_ids  = handler_node.entries,
                error      = "execute_handler panic: " .. tostring(handler_result),
            }
        elseif call_err then
            wrapped = {
                handler_id = handler_node.handler_id,
                entry_ids  = handler_node.entries,
                error      = tostring(call_err),
            }
        elseif type(handler_result) ~= "table" then
            wrapped = {
                handler_id = handler_node.handler_id,
                entry_ids  = handler_node.entries,
                error      = "execute_handler returned non-table: " .. type(handler_result),
            }
        else
            wrapped = handler_result
        end

        wrapped.input_snapshot = {
            operation = operation,
            entries   = input_entries,
            fs_paths  = handler_node.fs_paths or {},
        }

        table.insert(handler_outputs, wrapped)

        if wrapped.error ~= nil then
            any_failed = true
            break
        end

        if type(wrapped.result) == "table" then
            for _, row in ipairs(wrapped.result) do
                if row and row.success and row.id then
                    table.insert(applied_ids, row.id)
                end
            end
        end
    end

    return {
        success     = not any_failed,
        applied_ids = applied_ids,
        execution   = { handlers = handler_outputs },
    }
end

return { handler = handler }
