-- Test handler. Invokes keeper.debug.tools:run_test on every pushed entry
-- whose meta.type == test. Up = execute; Down = record no-op (tests are
-- non-destructive so there is nothing to reverse).

local funcs = require("funcs")

local function handler(params)
    local entry_ids = params.entry_ids or {}
    local operation = params.operation or "up"
    if #entry_ids == 0 then return {} end

    if operation == "down" then
        local rows = {}
        for _, id in ipairs(entry_ids) do
            table.insert(rows, {
                id      = id,
                success = true,
                data    = { operation = "down", status = "noop",
                    description = "tests are non-destructive; nothing to reverse" },
            })
        end
        return rows
    end

    local executor, exec_err = funcs.new()
    if exec_err then return nil, "funcs.new failed: " .. tostring(exec_err) end

    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.debug.tools:run_test", { entry_ids = entry_ids })
    if not ok then
        return nil, "run_test panic: " .. tostring(result)
    end
    if call_err then
        return nil, "run_test: " .. tostring(call_err)
    end
    if type(result) ~= "table" then
        return nil, "run_test returned unexpected shape: " .. type(result)
    end

    local per_id = {}
    for _, fail in ipairs(result.failures or {}) do
        per_id[fail.id or fail.entry_id or ""] = {
            success = false,
            error   = (fail.test and (fail.test .. ": ") or "") .. tostring(fail.error or "failed"),
        }
    end

    local rows = {}
    for _, id in ipairs(entry_ids) do
        local failure = per_id[id]
        table.insert(rows, {
            id      = id,
            success = failure == nil,
            error   = failure and failure.error or nil,
            data    = {
                operation = "up",
                status    = failure and "failed" or "passed",
                total     = result.total,
                passed    = result.passed,
                failed    = result.failed,
                skipped   = result.skipped,
            },
        })
    end

    if (result.failed or 0) > 0 then
        return nil, "test_handler: " .. tostring(result.failed) ..
            " test(s) failed — " .. tostring(result.summary or "")
    end

    return rows
end

return { handler = handler }
