local json = require("json")
local design_writer = require("design_writer")
local design_reader = require("design_reader")

local function run(inputs)
    local passed = inputs.passed
    local feedback = inputs.feedback
    local branch_id = inputs.branch_id
    local collector_output = inputs.collector_output
    local workspace_id = inputs.workspace_id

    if passed == nil then
        return nil, "passed required"
    end

    if not branch_id then
        return nil, "branch_id required"
    end

    if not workspace_id then
        return nil, "workspace_id required"
    end

    if not collector_output then
        return nil, "collector_output required"
    end

    print(string.format("\n=== FINALIZE REVIEW ==="))
    print(string.format("Passed: %s", tostring(passed)))

    local ws = design_writer.existing_workspace(workspace_id)

    if passed then
        print("→ STOP: Review passed")
        print("========================\n")

        local reader = design_reader.for_workspace(workspace_id)
        local current_design = reader
            :with_type("design_version")
            :with_parent_direct(branch_id)
            :with_statuses("current")
            :one()

        local design_content = nil
        local design_version = nil
        if current_design then
            design_content = current_design.content
            design_version = (current_design.metadata or {}).version
        end

        ws:update_data(branch_id, { status = "ready_for_review" })

        if feedback and feedback ~= "" then
            ws:data({
                type = "feedback",
                discriminator = "review",
                parent_data_id = branch_id,
                content = feedback,
                content_type = "text/plain",
                status = "active",
                metadata = {
                    feedback_type = "review",
                    review_passed = true,
                    title = "Review Feedback"
                }
            })
        end

        local exec_result, exec_err = ws:execute()
        if exec_err then
            return nil, "Failed to update status: " .. exec_err
        end

        return {
            state = collector_output.state,
            result = {
                should_stop = true,
                status = "ready_for_review",
                stop_reason = "review_passed",
                iterations_run = collector_output.state.iterations_run,
                design_spec = design_content,
                design_version = design_version
            },
            continue = false
        }
    else
        print("→ CONTINUE: Review failed")
        if feedback then
            print(string.format("Feedback: %s", feedback))
        end
        print("========================\n")

        ws:update_data(branch_id, { status = "needs_revision" })

        if feedback and feedback ~= "" then
            ws:data({
                type = "feedback",
                discriminator = "review",
                parent_data_id = branch_id,
                content = feedback,
                content_type = "text/plain",
                status = "active",
                metadata = {
                    feedback_type = "review",
                    review_passed = false,
                    title = "Review Feedback"
                }
            })
        end

        local exec_result, exec_err = ws:execute()
        if exec_err then
            return nil, "Failed to write feedback: " .. exec_err
        end

        return {
            state = collector_output.state,
            result = {
                should_stop = false,
                status = "needs_revision",
                stop_reason = "review_failed",
                iterations_run = collector_output.state.iterations_run
            },
            continue = true
        }
    end
end

return { run = run }
