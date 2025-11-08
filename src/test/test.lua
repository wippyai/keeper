local flow = require("flow")

local function run(args)
    local test_spec = args.test_spec
    local test_context = args.test_context or ""

    if not test_spec or test_spec == "" then
        return nil, "test_spec required"
    end

    return flow.create()
        :with_title("Test Execution")
        :with_input(test_spec)
        :to("decomposer", "test_spec")

        :with_data(test_context):as("context")
        :to("decomposer", "test_context")

        :agent("keeper.test.agents:decomposer", {
            inputs = { required = { "test_spec", "test_context" } },
            arena = {
                prompt = "Analyze test requirements and create test plan",
                max_iterations = 5,
                tool_calling = "any",
                exit_schema = {
                    type = "object",
                    properties = {
                        tasks = {
                            type = "array",
                            items = {
                                type = "object",
                                properties = {
                                    id = { type = "string" },
                                    specialist_id = { type = "string" },
                                    title = { type = "string" },
                                    test_task = { type = "string" }
                                },
                                required = { "id", "specialist_id", "title", "test_task" }
                            }
                        }
                    },
                    required = { "tasks" }
                }
            },
            metadata = {
                title = "Plan Tests",
                icon = "tabler:brain"
            }
        })
        :as("decomposer")
        :to("@success", nil, "{success: true, passed: 0, failed: 0, details: 'No tests created'}"):when(
            "len(output.tasks) == 0")
        :to("executor", "tasks", "output.tasks")
        :to("executor", "test_context")
        :to("consolidator", "tasks", "output.tasks")

        :parallel({
            inputs = { required = { "tasks", "test_context" } },
            source_array_key = "tasks",
            iteration_input_key = "task",
            passthrough_keys = { "test_context" },
            batch_size = 5,
            on_error = "continue",
            filter = "all",
            unwrap = false,
            template = flow.template()
                :agent("", {
                    inputs = { required = { "task", "test_context" } },
                    input_transform = {
                        agent_id = "inputs.task.specialist_id",
                        test_task = "inputs.task.test_task",
                        test_context = "inputs.test_context"
                    },
                    arena = {
                        prompt = "Execute test task",
                        max_iterations = 12,
                        tool_calling = "any",
                        exit_schema = {
                            type = "object",
                            properties = {
                                success = { type = "boolean" },
                                details = { type = "string" }
                            },
                            required = { "success", "details" }
                        }
                    }
                })
                :to("@success")
                :error_to("@fail")
        })
        :as("executor")
        :to("consolidator", "results")

        :func("keeper.test:consolidate_results", {
            inputs = { required = { "results", "tasks" } },
            metadata = {
                title = "Consolidate Results",
                icon = "tabler:checklist"
            }
        })
        :as("consolidator")
        :to("@success")

        :run()
end

return { run = run }
