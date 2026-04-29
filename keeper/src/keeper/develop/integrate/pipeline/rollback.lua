-- Inverse of pipeline:execute. Walks the original execute result in reverse
-- and invokes each handler with operation="down" synchronously. Same reason
-- as execute.lua — flow builder yields when called from inside a dataflow
-- and silently skips work.

local funcs    = require("funcs")

local EXECUTE_HANDLER_ID = "keeper.develop.integrate.pipeline:execute_handler"

local function handler(params)
    local execution = params.execution or {}

    if type(execution) == "table" and execution.handlers then
        execution = execution.handlers
    end

    if not execution or #execution == 0 then
        return {
            success = true,
            applied_ids = {},
            execution = { handlers = {} },
        }
    end

    local handler_outputs = {}
    local applied_ids = {}
    local any_failed = false

    for i = #execution, 1, -1 do
        local original_result = execution[i] or {}
        local handler_id = original_result.handler_id

        local wrapped
        if not handler_id or handler_id == "" then
            wrapped = {
                handler_id = handler_id,
                entry_ids  = original_result.entry_ids or {},
                fs_paths   = original_result.fs_paths or {},
                error      = "rollback execution row missing handler_id",
            }
        else
            local executor = funcs.new()
            local ok, handler_result, call_err = pcall(executor.call, executor,
                EXECUTE_HANDLER_ID, {
                    handler_id     = handler_id,
                    entry_ids      = original_result.entry_ids or {},
                    fs_paths       = original_result.fs_paths or {},
                    operation      = "down",
                    execute_result = original_result.result,
                })

            if not ok then
                wrapped = {
                    handler_id = handler_id,
                    entry_ids  = original_result.entry_ids or {},
                    fs_paths   = original_result.fs_paths or {},
                    error      = "execute_handler panic: " .. tostring(handler_result),
                }
            elseif call_err then
                wrapped = {
                    handler_id = handler_id,
                    entry_ids  = original_result.entry_ids or {},
                    fs_paths   = original_result.fs_paths or {},
                    error      = tostring(call_err),
                }
            elseif type(handler_result) ~= "table" then
                wrapped = {
                    handler_id = handler_id,
                    entry_ids  = original_result.entry_ids or {},
                    fs_paths   = original_result.fs_paths or {},
                    error      = "execute_handler returned non-table: " .. type(handler_result),
                }
            else
                wrapped = handler_result
            end
        end

        table.insert(handler_outputs, wrapped)

        if wrapped.error ~= nil then
            any_failed = true
        elseif type(wrapped.result) == "table" then
            for _, row in ipairs(wrapped.result) do
                if row and row.success and row.id then
                    table.insert(applied_ids, row.id)
                end
            end
        elseif type(wrapped.entry_ids) == "table" then
            for _, id in ipairs(wrapped.entry_ids) do
                table.insert(applied_ids, id)
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
