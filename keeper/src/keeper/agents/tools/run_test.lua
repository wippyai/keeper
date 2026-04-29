local registry = require("registry")
local funcs = require("funcs")
local time = require("time")
local channel = require("channel")
local process = require("process")
local audit = require("audit")

local DEFAULT_TIMEOUT = "30s"

local M = {}

type CaseCounts = {
    passed: integer,
    failed: integer,
    skipped: integer,
}

local function wait_for(ch: channel.Channel, timeout: string): unknown?
    local result = channel.select {
        ch:case_receive(),
        time.after(timeout):case_receive(),
    }
    if result.channel == ch then
        return result.value
    end
    return nil
end

local function new_counts(passed: integer, failed: integer, skipped: integer): CaseCounts
    return { passed = passed, failed = failed, skipped = skipped }
end

local function ensure_case(per_case: {[string]: CaseCounts}, entry_id: string): CaseCounts
    local counts = per_case[entry_id]
    if not counts then
        counts = new_counts(0, 0, 0)
        per_case[entry_id] = counts
    end
    return counts
end

function M.filter_entries(all, params)
    all = all or {}

    local entry_ids = params.entry_ids
    if type(entry_ids) == "string" then entry_ids = { entry_ids } end
    if type(params.entry_id) == "string" and params.entry_id ~= "" then
        entry_ids = entry_ids or {}
        table.insert(entry_ids, params.entry_id)
    end

    if entry_ids and #entry_ids > 0 then
        local want = {}
        for _, id in ipairs(entry_ids) do want[id] = true end
        local out = {}
        local matched = {}
        for _, e in ipairs(all) do
            if want[e.id] then
                table.insert(out, e)
                matched[e.id] = true
            end
        end
        if #out == 0 then
            return nil, "entry_ids not found in registry (meta.type=test): " .. table.concat(entry_ids, ", ")
        end
        local missing = {}
        for _, id in ipairs(entry_ids) do
            if not matched[id] then table.insert(missing, id) end
        end
        if #missing > 0 then
            return out, nil, missing
        end
        return out, nil
    end

    local suite = params.suite
    if type(suite) == "string" and suite ~= "" then
        local out = {}
        for _, e in ipairs(all) do
            local m = e.meta or {}
            if m.suite == suite then table.insert(out, e) end
        end
        if #out == 0 then
            return nil, "no tests in suite: " .. suite
        end
        return out, nil
    end

    return nil, "run_test requires entry_ids, entry_id, or suite — refusing to run the entire catalog"
end

local function resolve_entries(params)
    local all, err = registry.find({ ["meta.type"] = "test" })
    if err then return nil, "registry.find failed: " .. tostring(err) end
    return M.filter_entries(all or {}, params)
end

local function run_one(executor, entry, failures, per_case, test_done_ch)
    local entry_id = tostring(entry.id)
    local meta = entry.meta or {}
    local suite = meta.suite or "other"
    local timeout = meta.timeout or DEFAULT_TIMEOUT

    local cmd, cmd_err = executor:async(entry_id, {
        pid = process.pid(),
        topic = "test:update",
        ref_id = entry_id,
    })

    if cmd_err then
        table.insert(failures, { id = entry_id, suite = suite, error = tostring(cmd_err) })
        per_case[entry_id] = new_counts(0, 1, 0)
        return
    end

    local response_ch = cmd:response() :: channel.Channel
    local response = wait_for(response_ch, tostring(timeout))
    if not response then
        local _, rerr = cmd:result()
        local emsg = rerr and tostring(rerr) or "test timed out"
        table.insert(failures, { id = entry_id, suite = suite, error = emsg })
        local counts = ensure_case(per_case, entry_id)
        counts.failed = counts.failed + 1
        return
    end

    -- Drain trailing BDD case events from the test that just returned.
    -- A BDD test emits a final test:complete event once all case events are flushed.
    wait_for(test_done_ch :: channel.Channel, "1s")

    local cs = per_case[entry_id]
    local has_events = cs and ((cs.passed or 0) + (cs.failed or 0) + (cs.skipped or 0)) > 0
    if has_events then return end

    local payload, rerr = cmd:result()
    if rerr then
        table.insert(failures, { id = entry_id, suite = suite, error = tostring(rerr) })
        per_case[entry_id] = new_counts(0, 1, 0)
    elseif payload and payload:data() == false then
        table.insert(failures, { id = entry_id, suite = suite, error = "test returned false" })
        per_case[entry_id] = new_counts(0, 1, 0)
    else
        per_case[entry_id] = new_counts(1, 0, 0)
    end
end

local function do_handler(params)
    params = params or {}

    local entries, err, missing = resolve_entries(params)
    if err then return nil, err end
    if #entries == 0 then
        return { passed = 0, failed = 0, skipped = 0, total = 0, summary = "No tests matched scope", failures = {} }
    end

    local inbox = process.listen("test:update")
    local per_case: {[string]: CaseCounts} = {}
    local failures = {}

    local done_ch = channel.new()
    local processor_done = channel.new(1)
    local test_done_ch = channel.new(1)

    coroutine.spawn(function()
        while true do
            local result = channel.select {
                inbox:case_receive(),
                done_ch:case_receive(),
            }
            if not result.ok then break end
            if result.channel == done_ch then break end

            local msg = result.value
            local mtype = tostring(msg.type)
            local data = msg.data or {}

            if mtype == "test:complete" then
                test_done_ch:send(msg)
                goto continue
            end

            local ref_id = tostring(data.ref_id or "")
            if ref_id == "" then goto continue end

            local counts = ensure_case(per_case, ref_id)

            if mtype == "test:case:pass" then
                counts.passed = counts.passed + 1
            elseif mtype == "test:case:fail" then
                counts.failed = counts.failed + 1
                table.insert(failures, {
                    id = ref_id,
                    suite = tostring(data.suite or ""),
                    test = tostring(data.test or ""),
                    error = tostring(data.error or "unknown"),
                })
            elseif mtype == "test:case:skip" then
                counts.skipped = counts.skipped + 1
            end

            ::continue::
        end
        processor_done:send(true)
    end)

    local executor = funcs.new():with_context({
        parent_pid = process.pid(),
        test_topic = "test:update",
    })

    for _, e in ipairs(entries) do
        run_one(executor, e, failures, per_case, test_done_ch)
    end

    done_ch:close()
    wait_for(processor_done :: channel.Channel, "2s")

    local totals = { passed = 0, failed = 0, skipped = 0 }
    for _, cs in pairs(per_case) do
        totals.passed = totals.passed + (cs.passed or 0)
        totals.failed = totals.failed + (cs.failed or 0)
        totals.skipped = totals.skipped + (cs.skipped or 0)
    end
    local total = totals.passed + totals.failed + totals.skipped

    local summary
    if totals.failed == 0 then
        summary = string.format("PASSED %d/%d (skipped %d)", totals.passed, total, totals.skipped)
    else
        summary = string.format("FAILED %d passed, %d failed, %d skipped (total %d)",
            totals.passed, totals.failed, totals.skipped, total)
    end

    local content = summary
    if #failures > 0 then
        local lines = { summary, "", "Failures:" }
        for _, f in ipairs(failures) do
            table.insert(lines, string.format("  [%s] %s :: %s — %s",
                f.suite or "", f.id or "", f.test or "", f.error or ""))
        end
        content = table.concat(lines, "\n")
    end

    local result = {
        passed  = totals.passed,
        failed  = totals.failed,
        skipped = totals.skipped,
        total   = total,
        summary = summary,
        failures = failures,
        entries = (function()
            local ids = {}
            for _, e in ipairs(entries) do table.insert(ids, e.id) end
            return ids
        end)(),
    }
    if missing and #missing > 0 then
        result.missing = missing
        result.summary = summary ..
            " (" .. #missing .. " entry_id" .. (#missing == 1 and "" or "s") .. " not found: " ..
            table.concat(missing, ", ") .. ")"
    end
    return result
end

function M.handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "run_test",
        discriminator = "run_test",
        target        = params.suite or (params.entry_ids and (#params.entry_ids .. " entries")) or params.entry_id,
        params        = { suite = params.suite, entry_id = params.entry_id, entry_ids = params.entry_ids },
        summarise = function(result, err)
            if err then return "run_test failed: " .. tostring(err) end
            if type(result) == "table" then return tostring(result.summary) end
            return "run_test"
        end,
    }, function()
        return do_handler(params)
    end)
end

return M
