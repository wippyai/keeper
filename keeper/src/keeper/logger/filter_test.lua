local test = require("test")
local logger_filter = require("logger_filter")

local function matches(filter_text, entry)
    local program, err = logger_filter.compile(filter_text)
    test.is_nil(err)
    test.not_nil(program)
    local ok, run_err = program:run(entry)
    test.is_nil(run_err)
    return ok == true
end

local ENTRY = { level = 1, message = "job_worker lease expired", path = "gov.service", fields = {} }

local function define_tests()
    describe("logger filter", function()
        it("treats a bare token as a message substring match", function()
            test.is_true(matches("job_worker", ENTRY))
            test.is_true(matches("lease", ENTRY))
            test.is_true(matches("  worker  ", ENTRY))
            test.is_false(matches("absent_token", ENTRY))
        end)

        it("normalizes a bare token to a contains expression", function()
            test.eq(logger_filter.normalize("job_worker"), 'message contains "job_worker"')
            test.eq(logger_filter.normalize("gov.service"), 'message contains "gov.service"')
        end)

        it("leaves expressions untouched", function()
            test.eq(logger_filter.normalize('message contains "x"'), 'message contains "x"')
            test.eq(logger_filter.normalize("level >= 2"), "level >= 2")
            test.eq(logger_filter.normalize("true"), "true")
            test.eq(logger_filter.normalize("1"), "1")
        end)

        it("treats empty text as no filter", function()
            test.is_nil(logger_filter.normalize(""))
            test.is_nil(logger_filter.normalize("   "))
            local program, err = logger_filter.compile("")
            test.is_nil(program)
            test.not_nil(err)
        end)

        it("evaluates a valid expression", function()
            test.is_true(matches('message contains "lease expired"', ENTRY))
            test.is_true(matches('level >= 1 and path == "gov.service"', ENTRY))
            test.is_false(matches("level >= 2", ENTRY))
        end)

        it("rejects multi-word plain text with the syntax and an example", function()
            local program, err = logger_filter.compile("lease expired")
            test.is_nil(program)
            test.not_nil(err)
            test.is_true(err:find("substring", 1, true) ~= nil)
            test.is_true(err:find('message contains "lease expired"', 1, true) ~= nil)
        end)

        it("rejects an invalid expression with the syntax and an example", function()
            local program, err = logger_filter.compile("level >=")
            test.is_nil(program)
            test.not_nil(err)
            test.is_true(err:find("Examples:", 1, true) ~= nil)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
