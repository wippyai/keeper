local test = require("test")
local fixture = require("fixture")
local subject = require("subject")

local function define_tests()
    test.describe("knowledge embedding error boundary", function()
        test.before_each(fixture.reset)

        for _, native in ipairs({ false, true }) do
            test.it(native and "formats native embedding errors" or "retains legacy embedding errors", function()
                local failure = native and errors.new({kind = errors.UNAVAILABLE,
                    retryable = true, message = "embedding backend unavailable"}) or "embedding backend unavailable"
                fixture.responses = { {error = failure}, {error = failure} }
                local result, err = subject.embed({node_id = "node"})
                test.is_nil(result)
                test.eq(type(err), "string")
                test.eq(err, "Embedding failed: " .. tostring(failure))
                test.eq(#fixture.calls, 2)
                test.eq(#fixture.writes, 0)
                test.eq(fixture.notifications, 0)
            end)
        end

        test.it("retains the no-result failure when every model returns nothing", function()
            local result, err = subject.embed({node_id = "node"})
            test.is_nil(result)
            test.eq(err, "Embedding failed: no result")
            test.eq(#fixture.calls, 2)
            test.eq(#fixture.writes, 0)
        end)

        test.it("retains model order and stores a successful fallback", function()
            fixture.responses = {
                {error = errors.new({kind = errors.UNAVAILABLE, message = "primary unavailable"})},
                {result = {result = {{0.1, 0.2, 0.3}}}},
            }
            local result, err = subject.embed({node_id = "node", model = "requested-model"})
            test.is_nil(err)
            test.is_true(result.embedded)
            test.eq(result.model, "fallback")
            test.eq(fixture.calls[1].model, "requested-model")
            test.eq(fixture.calls[2].model, "fallback")
            test.eq(#fixture.writes, 3)
            test.eq(fixture.notifications, 1)
        end)

        test.it("formats native storage errors without marking the node embedded", function()
            fixture.responses = {{result = {result = {{0.1, 0.2, 0.3}}}}}
            fixture.insert_error = errors.new({kind = errors.UNAVAILABLE, message = "storage unavailable"})
            local result, err = subject.embed({node_id = "node"})
            test.is_nil(result)
            test.eq(type(err), "string")
            test.eq(err, "Failed to store embedding: " .. tostring(fixture.insert_error))
            test.eq(#fixture.calls, 1)
            test.eq(#fixture.writes, 2)
            test.eq(fixture.notifications, 0)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
