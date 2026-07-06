-- Integrate pipeline frontend. Loads the pushed entry_ids, matches them to
-- integration.handler entries via discovery:match_handlers in meta.order order,
-- then hands the ordered step list to the shared step_runner. The run stays
-- synchronous (step_runner uses funcs.new():call, not a sub-flow) because
-- flow.run() yields control back to the parent dataflow when invoked from
-- inside one (integrate/run.lua) and that defers handler execution past
-- run.lua's own success check.

local registry    = require("registry")
local discovery   = require("discovery")
local step_runner = require("step_runner")

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
    local data = params.data

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

    local steps = {}
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

        table.insert(steps, {
            handler_id = handler_node.handler_id,
            entry_ids  = handler_node.entries,
            fs_paths   = handler_node.fs_paths or {},
            operation  = operation,
            data       = data,
            input_snapshot = {
                operation = operation,
                entries   = input_entries,
                fs_paths  = handler_node.fs_paths or {},
            },
        })
    end

    return step_runner.run(steps)
end

return { handler = handler }
