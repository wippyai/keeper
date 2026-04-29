local test = require("test")
local funcs = require("funcs")

local FN_ID = "keeper.develop.context:prepare_context"

local function call_fn(args)
    return funcs.new():call(FN_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.context:prepare_context", function()
        test.it("errors when agent_id is missing", function()
            local out, err = call_fn({ prompt = "anything" })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(err:find("agent_id required") ~= nil)
        end)

        test.it("errors when agent_id is empty string", function()
            local out, err = call_fn({ agent_id = "", prompt = "anything" })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(err:find("agent_id required") ~= nil)
        end)

        test.it("errors when prompt is missing", function()
            local out, err = call_fn({ agent_id = "keeper.develop.context:test_target" })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(err:find("prompt required") ~= nil)
        end)

        test.it("errors when prompt is empty string", function()
            local out, err = call_fn({
                agent_id = "keeper.develop.context:test_target",
                prompt   = "",
            })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(err:find("prompt required") ~= nil)
        end)

        test.it("errors with clear message when agent_id does not resolve", function()
            local out, err = call_fn({
                agent_id = "app.fake:does_not_exist_agent",
                prompt   = "test",
            })
            test.is_nil(out)
            test.not_nil(err)
            test.is_true(
                err:find("Agent not found") ~= nil
                    or err:find("Failed to load agent") ~= nil,
                "error should say agent not found / failed to load"
            )
        end)

        test.it("returns empty string when agent has no context_chain", function()
            -- keeper.develop.context:context_router is an agent with no meta.context_chain.
            local out, err = call_fn({
                agent_id = "keeper.develop.context:context_router",
                prompt   = "test",
            })
            test.is_nil(err)
            test.eq(out, "")
        end)
    end)
end

return { define_tests = define_tests }
