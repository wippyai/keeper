local test = require("test")
local async_task = require("async_task")

local cases = {
    {
        name = "execute relays finished payload and calls success hook",
        fn = function()
            local events = {}
            local success_called = false
            local ok, payload = async_task._execute({
                finished_event = "finished",
                failed_event = "failed",
                relay = function(event, data)
                    table.insert(events, { event = event, data = data })
                end,
                work = function()
                    return true, { value = 7 }
                end,
                on_success = function()
                    success_called = true
                end,
            }, "req-1")

            test.is_true(ok)
            test.eq(payload.request_id, "req-1")
            test.is_true(success_called)
            test.eq(#events, 1)
            local event = events[1]
            if not event then error("missing relay event") end
            test.eq(event.event, "finished")
            test.eq(event.data.value, 7)
        end,
    },
    {
        name = "execute catches thrown work errors and calls failure hook",
        fn = function()
            local events = {}
            local failure = { called = false }
            local ok, payload = async_task._execute({
                started_event = "started",
                finished_event = "finished",
                failed_event = "failed",
                relay = function(event, data)
                    table.insert(events, { event = event, data = data })
                end,
                log = { warn = function() end },
                work = function()
                    error("boom")
                end,
                on_failure = function()
                    failure.called = true
                end,
            }, "req-2")

            if ok ~= false then
                error("expected ok=false, got " .. tostring(ok))
            end
            if type(payload) ~= "table" then
                error("expected table payload, got " .. type(payload))
            end
            if payload.request_id ~= "req-2" then
                error("expected request_id=req-2, got " .. tostring(payload.request_id))
            end
            if type(payload.error) ~= "string" then
                error("expected string payload.error, got " .. type(payload.error) .. " payload=" .. tostring(payload))
            end
            if payload.error == "" then
                error("expected non-empty payload.error")
            end
            if not failure.called then
                error("failure hook was not called")
            end
            if #events ~= 1 then
                error("expected 1 relay event, got " .. tostring(#events))
            end
            local event = events[1]
            if not event then error("missing relay event") end
            if event.event ~= "failed" then
                error("expected failed event, got " .. tostring(event.event))
            end
            if event.data.error ~= payload.error then
                error("event error did not match payload error")
            end
        end,
    },
    {
        name = "execute relays explicit work failures without rewriting payload",
        fn = function()
            local events = {}
            local failure_called = false
            local ok, payload = async_task._execute({
                started_event = "started",
                finished_event = "finished",
                failed_event = "failed",
                relay = function(event, data)
                    table.insert(events, { event = event, data = data })
                end,
                log = { warn = function() end },
                work = function()
                    return false, { error = "boom", code = "expected_failure" }
                end,
                on_failure = function()
                    failure_called = true
                end,
            }, "req-3")

            test.is_false(ok)
            test.eq(payload.request_id, "req-3")
            test.eq(payload.error, "boom")
            test.eq(payload.code, "expected_failure")
            test.is_true(failure_called)
            test.eq(#events, 1)
            local event = events[1]
            if not event then error("missing relay event") end
            test.eq(event.event, "failed")
            test.eq(event.data.error, "boom")
        end,
    },
    {
        name = "execute gives failed work a default error payload",
        fn = function()
            local events = {}
            local ok, payload = async_task._execute({
                started_event = "started",
                finished_event = "finished",
                failed_event = "failed",
                relay = function(event, data)
                    table.insert(events, { event = event, data = data })
                end,
                work = function()
                    return false
                end,
            }, "req-4")

            test.is_false(ok)
            test.eq(payload.request_id, "req-4")
            test.eq(payload.error, "work failed")
            test.eq(#events, 1)
            local event = events[1]
            if not event then error("missing relay event") end
            test.eq(event.event, "failed")
            test.eq(event.data.error, "work failed")
        end,
    },
}

local function define_tests()
    describe("keeper.git.service:async_task", function()
        for _, case in ipairs(cases) do it(case.name, case.fn) end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
