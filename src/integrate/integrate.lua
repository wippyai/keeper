local json = require("json")
local flow = require("flow")
local ctx = require("ctx")
local client = require("client")

local function build_common_flow(branch, test_scenario, has_testing)
    local f = flow.create()
        :with_title("Integration Pipeline")
        :with_input({ test_scenario = test_scenario, branch = branch })
            :to("version")
            :to("analyze", "workflow_data")

        :func("keeper.integrate:get_version", {
            metadata = {
                title = "Save Current State",
                icon = "tabler:versions"
            }
        })
        :as("version")
        :to("rollback_version", "original_version")

        :func("keeper.state.traits.explore:compare", {
            args = { mode = "summary", source = "main" },
            input_transform = { target = "inputs.workflow_data.branch" },
            metadata = {
                title = "Review Changes",
                icon = "tabler:git-compare"
            }
        })
        :as("analyze")
        :to("@success", nil, [[{
            "success": true,
            "message": "No changes detected",
            "diff": output
        }]]):when("output contains 'No changes detected'")
        :to("push", "diff"):when("!(output contains 'No changes detected')")
        :to("exit_join", "diff")

    if has_testing then
        f = f:to("test_execute", "diff")
    end

    return f:func("keeper.state.traits.publish:push", {
            metadata = {
                title = "Apply Changes",
                icon = "tabler:upload"
            }
        })
        :as("push")
        :to("@success", nil, [[{
            "success": true,
            "message": "No changes to integrate",
            "push": output,
            "diff": inputs.diff
        }]]):when("len(output.entry_ids) == 0")
        :to("execute_pipeline", "push_result"):when("len(output.entry_ids) > 0")
        :to("exit_join", "push_result")
        :error_to("exit_join", "push_result")
        :error_to("exit_join", "trigger", '{"success": false}')
end

local function build_with_testing(f, test_scenario, branch)
    return f
        :with_data({ test_scenario = test_scenario, branch = branch }):as("original_data")
            :to("test_execute", "original_input")

        :func("keeper.integrate.pipeline:execute", {
            inputs = { required = { "push_result" } },
            input_transform = {
                entry_ids = "inputs.push_result.entry_ids",
                operation = "up"
            },
            metadata = {
                title = "Run Integration",
                icon = "tabler:rocket"
            }
        })
        :as("execute_pipeline")
        :to("rollback_pipeline", "execute_pipeline")
        :to("exit_join", "execute_pipeline")
        :to("test_execute"):when("output.success == true")
        :to("rollback_pipeline", "trigger"):when("output.success == false")
        :error_to("rollback_pipeline", "trigger")

        :func("keeper.integrate.test:execute", {
            inputs = { required = { "original_input", "diff" } },
            input_transform = {
                test_scenario = "inputs.original_input.test_scenario + '\\n\\nChanges made:\\n' + string(inputs.diff)"
            },
            metadata = {
                title = "Run Tests",
                icon = "tabler:checkbox"
            }
        })
        :as("test_execute")
        :to("exit_join", "test_result")
        :to("exit_join", "trigger", '{"success": true}'):when("output.success == true")
        :to("rollback_pipeline", "trigger"):when("output.success == false")
        :error_to("rollback_pipeline", "trigger")

        :func("keeper.integrate.pipeline:rollback", {
            inputs = { required = { "execute_pipeline", "trigger" } },
            input_transform = {
                execution = "inputs.execute_pipeline.execution ?? []"
            },
            metadata = {
                title = "Undo Integration",
                icon = "tabler:arrow-back"
            }
        })
        :as("rollback_pipeline")
        :to("rollback_version", "trigger")
        :to("exit_join", "rollback_pipeline")
        :error_to("rollback_version", "trigger")

        :func("keeper.integrate:rollback_version", {
            inputs = { required = { "original_version", "trigger" } },
            input_transform = "inputs.original_version",
            metadata = {
                title = "Restore State",
                icon = "tabler:arrow-back-up"
            }
        })
        :as("rollback_version")
        :to("exit_join", "rollback_version")
        :to("exit_join", "trigger", '{"success": false}')

        :join({
            inputs = { required = { "trigger" } },
            metadata = {
                title = "Summary",
                icon = "tabler:flag"
            }
        })
        :as("exit_join")
        :to("@success", nil, [[{
            "success": true,
            "message": "Integration and tests completed successfully",
            "push": output.push_result,
            "pipeline": output.execute_pipeline,
            "test": output.test_result,
            "diff": output.diff
        }]]):when("output.trigger.success == true")
        :to("@fail", nil, [[{
            "success": false,
            "message": "Integration failed and rolled back",
            "push": output.push_result,
            "pipeline": output.execute_pipeline,
            "rollback": {
                "pipeline": output.rollback_pipeline,
                "version": output.rollback_version
            },
            "test": output.test_result,
            "diff": output.diff
        }]]):when("output.trigger.success == false")
end

local function build_without_testing(f)
    return f
        :func("keeper.integrate.pipeline:execute", {
            inputs = { required = { "push_result" } },
            input_transform = {
                entry_ids = "inputs.push_result.entry_ids",
                operation = "up"
            },
            metadata = {
                title = "Run Integration",
                icon = "tabler:rocket"
            }
        })
        :as("execute_pipeline")
        :to("rollback_pipeline", "execute_pipeline")
        :to("exit_join", "execute_pipeline")
        :to("exit_join", "trigger", '{"success": true}'):when("output.success == true")
        :to("rollback_pipeline", "trigger"):when("output.success == false")
        :error_to("rollback_pipeline", "trigger")

        :func("keeper.integrate.pipeline:rollback", {
            inputs = { required = { "execute_pipeline", "trigger" } },
            input_transform = {
                execution = "inputs.execute_pipeline.execution ?? []"
            },
            metadata = {
                title = "Undo Integration",
                icon = "tabler:arrow-back"
            }
        })
        :as("rollback_pipeline")
        :to("rollback_version", "trigger")
        :to("exit_join", "rollback_pipeline")
        :error_to("rollback_version", "trigger")

        :func("keeper.integrate:rollback_version", {
            inputs = { required = { "original_version", "trigger" } },
            input_transform = "inputs.original_version",
            metadata = {
                title = "Restore State",
                icon = "tabler:arrow-back-up"
            }
        })
        :as("rollback_version")
        :to("exit_join", "rollback_version")
        :to("exit_join", "trigger", '{"success": false}')

        :join({
            inputs = { required = { "trigger" } },
            metadata = {
                title = "Summary",
                icon = "tabler:flag"
            }
        })
        :as("exit_join")
        :to("@success", nil, [[{
            "success": true,
            "message": "Integration completed successfully",
            "push": output.push_result,
            "pipeline": output.execute_pipeline,
            "diff": output.diff
        }]]):when("output.trigger.success == true")
        :to("@fail", nil, [[{
            "success": false,
            "message": "Integration failed and rolled back",
            "push": output.push_result,
            "pipeline": output.execute_pipeline != null ? {
                "success": output.execute_pipeline.success ?? false,
                "applied_ids": output.execute_pipeline.applied_ids ?? [],
                "error": output.execute_pipeline.error,
                "execution": output.execute_pipeline.execution ?? {}
            } : null,
            "rollback": {
                "pipeline_reverted": output.rollback_pipeline != null ? (output.rollback_pipeline.success ?? false) : false,
                "version_restored": output.rollback_version != null,
                "message": output.rollback_version != null ? (output.rollback_version.message ?? "Rollback completed") : "No rollback needed",
                "execution": output.rollback_pipeline != null ? (output.rollback_pipeline.execution ?? {}) : {}
            },
            "test": output.test_result,
            "diff": output.diff
        }]]):when("output.trigger.success == false")
end

local function handler(params)
    local branch = ctx.get("overlay_branch")
    if not branch then
        return nil, "Working branch not set"
    end

    local test_scenario = params.test_scenario
    local has_testing = test_scenario and test_scenario ~= ""

    local f = build_common_flow(branch, test_scenario, has_testing)

    if has_testing then
        f = build_with_testing(f, test_scenario, branch)
    else
        f = build_without_testing(f)
    end

    return f:run()
end

return { handler = handler }