function run(args)
    local results = args.results or {}
    local tasks = args.tasks or {}

    -- Map tasks by iteration index (1-based, matches parallel iterations)
    local task_map = table.create(0, #tasks)
    for i, task in ipairs(tasks) do
        task_map[i] = task
    end

    local passed = 0
    local failed = 0
    local tests = table.create(#results, 0)

    for idx, item in ipairs(results) do
        local iteration = item.iteration or idx
        local task = task_map[iteration]

        local result = item.result or {}
        local err = item.error

        -- Prefer result.success, fallback to item.success if present
        local ok = result.success
        if ok == nil then
            if item.success ~= nil then
                ok = not not item.success
            else
                ok = err == nil
            end
        end

        if ok then
            passed = passed + 1
        else
            failed = failed + 1
        end

        tests[#tests + 1] = {
            id = task and task.id or nil,
            title = task and task.title or nil,
            iteration = iteration,
            success = ok,
            -- keep full details from the tester
            result = result,
            -- propagate error object if there was one
            error = err,
        }
    end

    local total = passed + failed

    return {
        success = failed == 0,
        passed = passed,
        failed = failed,
        total = total,
        details = string.format("Tests: %d passed, %d failed", passed, failed),
        tests = tests,
    }
end

return { run = run }
