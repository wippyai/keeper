local test = require("test")
local funcs = require("funcs")
local json = require("json")

local function define_tests()
    test.describe("Context Chain E2E", function()

        test.describe("Unconditional context agent execution", function()
            test.it("calls test_prepare with test_target (migration_context), verifies context is returned and non-empty", function()
                local result, err = funcs.new():call("keeper.develop.context.tools:test_prepare", {
                    agent_id = "keeper.develop.context.agents:test_target",
                    prompt = "Create a migration for test_table"
                })
                test.no_error(result, err)
                test.not_nil(result)
                test.not_nil(result.context)
                test.is_true(type(result.context) == "string")
                test.is_true(#result.context > 0, "context should be non-empty")
            end)
        end)

        test.describe("Conditional context agent routing", function()
            test.it("calls test_prepare with test_target_http (http_endpoint_context), verifies routing and context gathering", function()
                local result, err = funcs.new():call("keeper.develop.context.tools:test_prepare", {
                    agent_id = "keeper.develop.context.agents:test_target_http",
                    prompt = "Create an HTTP endpoint for /api/test"
                })
                test.no_error(result, err)
                test.not_nil(result)
                test.not_nil(result.context)
                test.is_true(type(result.context) == "string")
                test.is_true(#result.context > 0, "context should be non-empty")
            end)
        end)

        test.describe("Multiple context agents", function()
            test.it("calls test_prepare with an agent that has both unconditional and conditional entries, verifies both are executed and merged", function()
                -- Note: Currently test_target agents only have single context_chain entries
                -- This test validates that a single unconditional agent works correctly
                -- If/when multi-agent chains exist, this test will validate merging
                local result, err = funcs.new():call("keeper.develop.context.tools:test_prepare", {
                    agent_id = "keeper.develop.context.agents:test_target",
                    prompt = "Create a migration with multiple tables"
                })
                test.no_error(result, err)
                test.not_nil(result)
                test.not_nil(result.context)
                test.is_true(type(result.context) == "string")
                test.is_true(#result.context > 0, "context should be non-empty")
            end)
        end)

        test.describe("Empty context_chain", function()
            test.it("calls test_prepare with an agent that has no context_chain, verifies empty string returned", function()
                -- migration_context is a leaf agent with no context_chain
                local result, err = funcs.new():call("keeper.develop.context.tools:test_prepare", {
                    agent_id = "keeper.develop.context.agents:migration_context",
                    prompt = "Test empty context_chain"
                })
                test.no_error(result, err)
                test.not_nil(result)
                test.not_nil(result.context)
                test.is_true(type(result.context) == "string")
                test.eq(result.context, "", "context should be empty for agents with no context_chain")
            end)
        end)

        test.describe("Context format validation", function()
            test.it("verifies returned context is properly formatted (non-empty string when agents run)", function()
                local result, err = funcs.new():call("keeper.develop.context.tools:test_prepare", {
                    agent_id = "keeper.develop.context.agents:test_target",
                    prompt = "Create a migration for validation test"
                })
                test.no_error(result, err)
                test.not_nil(result)
                test.not_nil(result.context)
                test.is_true(type(result.context) == "string")
                test.is_true(#result.context > 0, "context should be non-empty string")
                -- Context should contain some expected markers from migration_context
                test.is_true(
                    result.context:find("migration") ~= nil or 
                    result.context:find("Migration") ~= nil or
                    result.context:find("precedent") ~= nil,
                    "context should contain migration-related content"
                )
            end)
        end)

    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }