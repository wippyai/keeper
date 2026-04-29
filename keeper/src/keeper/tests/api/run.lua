local http = require("http")
local funcs = require("funcs")
local time = require("time")
local registry = require("registry")

type TestEvent = unknown
type TestMessage = {
    type: string,
    data: TestEvent,
}
type TestEntry = {
    id: string,
    name: string?,
    group: string?,
}

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then
        return nil, "Failed to create HTTP context"
    end

    res:set_transfer(http.TRANSFER.CHUNKED)
    res:set_status(200)
    res:set_content_type("application/json")

    local test_id = req:query("test_id")
    local group = req:query("group")

    local function write_event(type: string, data: TestEvent)
        res:write_json({ type = type, data = data })
        res:write("\n")
        res:flush()
    end

    local options = { ["meta.type"] = "test" }
    if test_id and test_id ~= "" then options.id = test_id end
    if group and group ~= "" then options.group = group end

    local all_tests, err = registry.find(options)
    if err or not all_tests or #all_tests == 0 then
        write_event("test:error", { message = err or "No tests found", timestamp = time.now():unix() })
        return
    end

    local tests = all_tests
    if test_id then
        tests = {}
        for _, t in ipairs(all_tests) do
            if t.id == test_id then table.insert(tests, t) end
        end
    end

    if #tests == 0 then
        write_event("test:error", { message = "No matching tests after filter", timestamp = time.now():unix() })
        return
    end

    write_event("test:discover", { tests = tests })

    local inbox = process.listen("test:update")
    if not inbox then
        write_event("test:error", { message = "Failed to create inbox", timestamp = time.now():unix() })
        return
    end

    local done_ch = channel.new()
    local test_done_ch = channel.new(1)
    local wait = channel.new(1)

    coroutine.spawn(function()
        while true do
            local result = channel.select {
                inbox:case_receive(),
                done_ch:case_receive()
            }
            if not result.ok then break end
            local msg = result.value :: TestMessage
            if msg.type == "test:complete" then
                test_done_ch:send(msg)
            end
            write_event(msg.type, msg.data)
        end
        wait:send(true)
    end)

    local executor = funcs.new()
    local tests_completed = 0
    local tests_failed = 0

    for _, test_info in ipairs(tests) do
        local test_entry = test_info :: TestEntry
        write_event("test:suite:start", {
            id = test_entry.id,
            name = test_entry.name,
            group = test_entry.group,
            time = time.now():unix()
        })

        local test_options = {
            pid = process.pid(),
            topic = "test:update",
            ref_id = test_info.id
        }

        local cmd, err = executor:async(test_info.id, test_options)
        if err then
            write_event("test:error", { message = "Failed to start: " .. err, context = test_info.id, timestamp = time.now():unix() })
            tests_failed = tests_failed + 1
        else
            local function wait_ch(ch, timeout)
                local result = channel.select { ch:case_receive(), time.after(timeout):case_receive() }
                if result.channel == ch then return result.value end
                return false
            end

            local ok = wait_ch(cmd:response(), "15m")
            if not ok then
                local _, err = cmd:result()
                write_event("test:error", { message = tostring(err or "Timeout"), context = test_info.id, timestamp = time.now():unix() })
                tests_failed = tests_failed + 1
            else
                wait_ch(test_done_ch, "1s")
            end
        end

        tests_completed = tests_completed + 1
    end

    done_ch:close()

    local result = channel.select { wait:case_receive(), time.after("100ms"):case_receive() }

    write_event("test:summary", {
        total = #tests,
        completed = tests_completed,
        failed = tests_failed,
        status = tests_failed > 0 and "failed" or "passed",
        timestamp = time.now():unix()
    })
end

return { handler = handler }
