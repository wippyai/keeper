local json = require("json")
local flow = require("flow")

local function handler(params)
    local test_scenario = params.test_scenario

    if not test_scenario or test_scenario == "" then
        return nil, "test_scenario required"
    end

    return flow.create()
        :with_input(test_scenario)

        :agent("keeper.integrate.test:test_agent", {
            arena = {
                prompt =
                "Execute the test scenario and verify integration. Report success or failure with clear details. Exit when done.",
                max_iterations = 20,
                tool_calling = "any",
                exit_schema = {
                    type = "object",
                    properties = {
                        success = { type = "boolean" },
                        details = { type = "string" }
                    },
                    required = { "success", "details" }
                }
            },
            metadata = {
                title = "Test Scenario",
                icon = "tabler:checkbox"
            }
        })
        :to("@success")
        :error_to("@fail")

        :run()
end

return { handler = handler }
