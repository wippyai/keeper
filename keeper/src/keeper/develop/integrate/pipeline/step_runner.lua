-- Shared declarative step engine for the integrate pipeline and the keeper hub.
--
-- run() executes an ordered list of step descriptors, stops at the first
-- failure, and returns an execution ledger of the shape pipeline:execute has
-- always produced: { success, applied_ids, execution = { handlers = {...} } }.
-- Each ledger row may carry an `inverse` descriptor recorded from the step;
-- reverse() replays those inverses (or, absent an inverse, the original handler
-- with operation=down) to undo the run.
--
-- Two callers share this engine:
--   * integrate — steps name a registry integration.handler (handler_id) and
--     run through pipeline:execute_handler via funcs (the default executor).
--   * hub install/uninstall — steps name a service operation (op) and run
--     through a caller-supplied executor bound to the hub Service, so the
--     dependency injection the hub unit tests rely on is honoured and the
--     atomic single governance.publish / lockfile commit stay in-process.

local funcs = require("funcs")

local M = {}

local EXECUTE_HANDLER_ID = "keeper.develop.integrate.pipeline:execute_handler"

-- Forward default executor: dispatch a step to a registry integration.handler
-- through pipeline:execute_handler, wrapping panics and errors into a ledger row
-- with the same shape pipeline:execute historically produced.
local function funcs_execute(step, ctx)
    local executor = (ctx.funcs or funcs).new()
    local ok, handler_result, call_err = pcall(executor.call, executor,
        EXECUTE_HANDLER_ID, {
            handler_id     = step.handler_id,
            entry_ids      = step.entry_ids or {},
            fs_paths       = step.fs_paths or {},
            operation      = step.operation or "up",
            data           = step.data,
            execute_result = step.execute_result,
        })

    if not ok then
        return {
            handler_id = step.handler_id,
            entry_ids  = step.entry_ids or {},
            fs_paths   = step.fs_paths or {},
            error      = "execute_handler panic: " .. tostring(handler_result),
        }
    elseif call_err then
        return {
            handler_id = step.handler_id,
            entry_ids  = step.entry_ids or {},
            fs_paths   = step.fs_paths or {},
            error      = tostring(call_err),
        }
    elseif type(handler_result) ~= "table" then
        return {
            handler_id = step.handler_id,
            entry_ids  = step.entry_ids or {},
            fs_paths   = step.fs_paths or {},
            error      = "execute_handler returned non-table: " .. type(handler_result),
        }
    end
    return handler_result
end

local function applied_from_result(applied_ids, wrapped)
    for _, row in ipairs(wrapped.result) do
        if row and row.success and row.id then
            table.insert(applied_ids, row.id)
        end
    end
end

function M.run(steps, ctx)
    ctx = ctx or {}
    steps = steps or {}
    local execute = ctx.execute or function(step) return funcs_execute(step, ctx) end

    local handler_outputs = {}
    local applied_ids = {}
    local any_failed = false

    for _, step in ipairs(steps) do
        local wrapped = execute(step)
        if type(wrapped) ~= "table" then
            wrapped = { error = "step executor returned non-table: " .. type(wrapped) }
        end
        if wrapped.label == nil and step.label ~= nil then wrapped.label = step.label end
        if wrapped.op == nil and step.op ~= nil then wrapped.op = step.op end
        if wrapped.inverse == nil and step.inverse ~= nil then wrapped.inverse = step.inverse end
        if step.input_snapshot ~= nil then wrapped.input_snapshot = step.input_snapshot end

        table.insert(handler_outputs, wrapped)

        if wrapped.error ~= nil then
            any_failed = true
            break
        end
        if type(wrapped.result) == "table" then
            applied_from_result(applied_ids, wrapped)
        end
    end

    return {
        success     = not any_failed,
        applied_ids = applied_ids,
        execution   = { handlers = handler_outputs },
    }
end

-- Reverse default executor: replay a ledger row's inverse, or, absent an
-- inverse, the original handler with operation=down, through
-- pipeline:execute_handler.
local function funcs_reverse(ctx)
    local funcs_mod = ctx.funcs or funcs
    return function(row)
        local inverse = row.inverse
        local handler_id, operation, entry_ids, fs_paths, data
        if type(inverse) == "table" then
            handler_id = inverse.handler_id or row.handler_id
            operation  = inverse.operation or "down"
            entry_ids  = inverse.entry_ids or row.entry_ids or {}
            fs_paths   = inverse.fs_paths or row.fs_paths or {}
            data       = inverse.data
        else
            handler_id = row.handler_id
            operation  = "down"
            entry_ids  = row.entry_ids or {}
            fs_paths   = row.fs_paths or {}
        end

        if not handler_id or handler_id == "" then
            return {
                handler_id = handler_id,
                entry_ids  = entry_ids,
                fs_paths   = fs_paths,
                error      = "rollback execution row missing handler_id",
            }
        end

        local executor = funcs_mod.new()
        local ok, handler_result, call_err = pcall(executor.call, executor,
            EXECUTE_HANDLER_ID, {
                handler_id     = handler_id,
                entry_ids      = entry_ids,
                fs_paths       = fs_paths,
                operation      = operation,
                data           = data,
                execute_result = row.result,
            })

        if not ok then
            return { handler_id = handler_id, entry_ids = entry_ids, fs_paths = fs_paths,
                error = "execute_handler panic: " .. tostring(handler_result) }
        elseif call_err then
            return { handler_id = handler_id, entry_ids = entry_ids, fs_paths = fs_paths,
                error = tostring(call_err) }
        elseif type(handler_result) ~= "table" then
            return { handler_id = handler_id, entry_ids = entry_ids, fs_paths = fs_paths,
                error = "execute_handler returned non-table: " .. type(handler_result) }
        end
        return handler_result
    end
end

-- Walks a ledger in reverse and runs each row's undo. Best-effort: a failing
-- undo marks the result failed but does not stop the remaining undos, matching
-- pipeline:rollback's original continue-on-error contract. A caller-supplied
-- executor may return nil to skip a row (e.g. the step that failed and applied
-- nothing).
function M.reverse(execution, ctx)
    ctx = ctx or {}
    if type(execution) == "table" and execution.handlers then
        execution = execution.handlers
    end
    if not execution or #execution == 0 then
        return { success = true, applied_ids = {}, execution = { handlers = {} } }
    end

    local execute = ctx.execute or funcs_reverse(ctx)
    local handler_outputs = {}
    local applied_ids = {}
    local any_failed = false

    for i = #execution, 1, -1 do
        local row = execution[i] or {}
        local wrapped = execute(row)
        if wrapped ~= nil then
            if type(wrapped) ~= "table" then
                wrapped = { error = "rollback executor returned non-table: " .. type(wrapped) }
            end
            table.insert(handler_outputs, wrapped)
            if wrapped.error ~= nil then
                any_failed = true
            elseif type(wrapped.result) == "table" then
                applied_from_result(applied_ids, wrapped)
            elseif type(wrapped.entry_ids) == "table" then
                for _, id in ipairs(wrapped.entry_ids) do
                    table.insert(applied_ids, id)
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

return M
