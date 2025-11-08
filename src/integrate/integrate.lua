local json = require("json")
local flow = require("flow")
local ctx = require("ctx")
local client = require("client")

local function handler(params)
    local branch = ctx.get("overlay_branch")
    if not branch then
        return nil, "Working branch not set"
    end

    local f = flow.create()
        :with_title("Integration Pipeline")
        :with_input({ branch = branch })
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

        :func("keeper.state.traits.publish:push", {
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
            "diff": output.diff
        }]]):when("output.trigger.success == false")

    return f:run()
end

return { handler = handler }