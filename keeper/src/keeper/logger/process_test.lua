local test = require("test")
local events = require("events")
local time = require("time")
local logger_client = require("logger_client")

local function unique(prefix: string): string
    return prefix .. "_" .. tostring(time.now():unix_nano())
end

local function emit_and_wait(token: string, message: string)
    local ok, err = events.send("logs", "logs.entry", "keeper.logger.process_test", {
        entry = { level = 1, message = message, logger_name = "keeper.logger.process_test" },
        fields = {},
    })
    test.is_nil(err)
    test.not_nil(ok)
    for _ = 1, 50 do
        local result = logger_client.get_logs(10, 'message contains "' .. token .. '"', true, "5s")
        if result and #result.logs > 0 then return end
        time.sleep("100ms")
    end
    error("log entry never reached the logger buffer: " .. token)
end

local function define_tests()
    describe("logger process filter", function()
        local token = unique("lfproc")

        before_all(function()
            emit_and_wait(token, token .. " lease expired")
        end)

        it("matches a bare token as a message substring", function()
            local result, err = logger_client.get_logs(10, token, true, "5s")
            test.is_nil(err)
            test.eq(#result.logs, 1)
            test.is_true(result.filtered)
        end)

        it("returns no rows for a bare token that is absent", function()
            local result, err = logger_client.get_logs(10, "absent_" .. token, true, "5s")
            test.is_nil(err)
            test.eq(#result.logs, 0)
        end)

        it("fails multi-word plain text with the syntax and an example", function()
            local result, err = logger_client.get_logs(10, token .. " lease", true, "5s")
            test.is_nil(result)
            test.not_nil(err)
            test.is_true(err:find("Filter compilation failed", 1, true) ~= nil)
            test.is_true(err:find("Examples:", 1, true) ~= nil)
        end)

        it("fails an invalid expression through composition too", function()
            local result, err = logger_client.get_composition("level >=", "5s")
            test.is_nil(result)
            test.is_true(err:find("Examples:", 1, true) ~= nil)
        end)

        it("evaluates a valid expression", function()
            local result, err = logger_client.get_logs(10, 'message contains "' .. token .. ' lease"', true, "5s")
            test.is_nil(err)
            test.eq(#result.logs, 1)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
