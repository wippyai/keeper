-- Build handler. For every pushed view.page entry, resolves the component
-- that owns its source path and invokes keeper.components.tools:build_component.
-- Up = rebuild; Down = record intent (full artefact restore from keeper_fe_builds
-- history is wired when the rollback runner needs it).

local funcs = require("funcs")
local registry = require("registry")

local function string_list(value: unknown): {string}
    local out = {}
    if type(value) ~= "table" then return out end
    for _, item in ipairs(value) do
        if type(item) == "string" and item ~= "" then table.insert(out, item) end
    end
    return out
end

local function source_path(entry: unknown): string?
    local data = (entry and entry.data) or {}
    local src = data.source or ""
    if type(src) ~= "string" then return nil end
    if src:sub(1, 7) == "file://" then return src:sub(8) end
    return nil
end

local function resolve_components(paths)
    if #paths == 0 then return {}, nil end
    local executor, exec_err = funcs.new()
    if exec_err then return nil, "funcs.new failed: " .. tostring(exec_err) end
    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.components.tools:resolve_touched", { paths = paths })
    if not ok then return nil, "resolve_touched panic: " .. tostring(result) end
    if call_err then return nil, "resolve_touched: " .. tostring(call_err) end
    return (result and result.components) or {}, nil
end

local function build_one(component_id)
    local executor, exec_err = funcs.new()
    if exec_err then return nil, "funcs.new failed: " .. tostring(exec_err) end
    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.components.tools:build_component",
        { component_id = component_id, wait = true, timeout_s = 300 })
    if not ok then return nil, "build_component panic: " .. tostring(result) end
    if call_err then return nil, "build_component: " .. tostring(call_err) end
    return result, nil
end

local function build_error(result, call_error)
    if call_error and call_error ~= "" then return tostring(call_error) end
    if type(result) ~= "table" then return "build failed" end
    if result.error_output and result.error_output ~= "" then
        return tostring(result.error_output)
    end
    if result.error and result.error ~= "" then return tostring(result.error) end
    return "build failed"
end

local function handler(params)
    local entry_ids = string_list(params.entry_ids)
    -- Filesystem paths captured directly from the changeset (raw FS edits
    -- that don't correspond to a view.page registry entry). Without these
    -- build_handler is invisible to plain Vue/TS/router edits that ship
    -- entirely through the filesystem side of the changeset.
    local fs_paths = string_list(params.fs_paths)
    local operation = params.operation or "up"

    if #entry_ids == 0 and #fs_paths == 0 then return {} end

    if operation == "down" then
        local rows = {}
        for _, id in ipairs(entry_ids) do
            table.insert(rows, {
                id      = id,
                success = true,
                data    = { operation = "down", status = "noop",
                    description = "build rollback via keeper_fe_builds history not yet implemented" },
            })
        end
        return rows
    end

    local paths, path_index = {}, {}
    for _, id in ipairs(entry_ids) do
        local entry, gerr = registry.get(id)
        if gerr then
            return nil, "build_handler: failed to load " .. id .. ": " .. tostring(gerr)
        end
        local p = source_path(entry)
        if p then
            table.insert(paths, p)
            path_index[p] = id
        end
    end
    for _, p in ipairs(fs_paths) do
        if p and p ~= "" and not path_index[p] then
            table.insert(paths, p)
            path_index[p] = p
        end
    end

    local components, rerr = resolve_components(paths)
    if rerr then return nil, rerr end

    local rows, failed_any = {}, nil
    for _, component_id in ipairs(components) do
        local result, berr = build_one(component_id)
        local status  = result and result.status or "errored"
        local success = result and result.success == true
        if berr or not success then
            failed_any = {
                component_id = component_id,
                error        = build_error(result, berr),
            }
        end
        table.insert(rows, {
            id      = component_id,
            success = success == true,
            error   = (berr or not success) and build_error(result, berr) or nil,
            data    = {
                operation    = "up",
                status       = status,
                build_id     = result and result.build_id,
                duration_ms  = result and result.duration_ms,
                component_id = component_id,
                error_output = result and result.error_output,
            },
        })
    end

    -- Record an informational row for every source entry id AND every raw
    -- filesystem path so the trail can attribute the rebuild back to what
    -- triggered it (either a view.page entry or a frontend/ fs edit).
    for _, id in ipairs(entry_ids) do
        table.insert(rows, {
            id      = id,
            success = true,
            data    = {
                operation = "up",
                status    = "triggered_build",
                paths     = #paths,
                components = #components,
                source    = "entry",
            },
        })
    end
    for _, p in ipairs(fs_paths) do
        table.insert(rows, {
            id      = "fs://" .. p,
            success = true,
            data    = {
                operation = "up",
                status    = "triggered_build",
                paths     = #paths,
                components = #components,
                source    = "filesystem",
            },
        })
    end

    if failed_any then
        return nil, "build_handler: " .. failed_any.component_id ..
            " — " .. tostring(failed_any.error)
    end

    return rows
end

return {
    handler = handler,
    __test = {
        build_error = build_error,
        source_path = source_path,
    },
}
