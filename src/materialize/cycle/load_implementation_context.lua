local json = require("json")
local ctx = require("ctx")
local design_reader = require("design_reader")

local type_renderers = {}

function type_renderers.materialize_reasoning(child, output)
    table.insert(output, "### Reasoning")
    table.insert(output, "")
    table.insert(output, child.content or "")
    table.insert(output, "")
end

function type_renderers.materialize_plan(child, output)
    table.insert(output, "### Implementation Plan")
    table.insert(output, "")
    if child.content and child.content_type == "application/json" then
        local plan = json.decode(child.content)
        if plan.steps then
            for i, step in ipairs(plan.steps) do
                table.insert(output, string.format("%d. **%s** (`%s`)", i, step.title or step.id, step.agent_id or "unknown"))
                if step.needs and #step.needs > 0 then
                    table.insert(output, string.format("   Depends on: %s", table.concat(step.needs, ", ")))
                end
            end
        end
    end
    table.insert(output, "")
end

function type_renderers.materialize_implementation(child, output)
    table.insert(output, "### Implementation Result")
    table.insert(output, "")
    table.insert(output, string.format("Status: %s", child.status or "unknown"))
    table.insert(output, "")

    if child.content and child.content_type == "application/json" then
        local result = json.decode(child.content)

        if result.has_failures then
            table.insert(output, string.format("**ERROR**: %s", result.error_summary or "Implementation failed"))
            table.insert(output, "")
        end

        if result.total_steps then
            table.insert(output, string.format("Summary: %d/%d steps succeeded (%.0f%%)",
                result.succeeded or 0, result.total_steps, (result.success_rate or 0) * 100))
            table.insert(output, "")
        end

        if result.successes and #result.successes > 0 then
            table.insert(output, "#### Successful Steps")
            table.insert(output, "")
            for _, s in ipairs(result.successes) do
                table.insert(output, string.format("**%s**", s.step))
                table.insert(output, "")
                if s.result and s.result.output then
                    table.insert(output, s.result.output)
                    table.insert(output, "")
                end
            end
        end

        if result.failures and #result.failures > 0 then
            table.insert(output, "#### Failed Steps")
            table.insert(output, "")
            for _, f in ipairs(result.failures) do
                table.insert(output, string.format("**%s** - FAILED", f.step))
                table.insert(output, "")

                if f.error then
                    table.insert(output, string.format("Error: %s", f.error))
                    table.insert(output, "")
                end

                if f.details then
                    if f.details.code then
                        table.insert(output, string.format("Code: %s", f.details.code))
                    end
                    if f.details.message then
                        table.insert(output, string.format("Message: %s", f.details.message))
                    end
                    table.insert(output, "")
                end

                if f.result then
                    if f.result.error then
                        table.insert(output, string.format("Result Error: %s", f.result.error))
                        table.insert(output, "")
                    end
                    if f.result.output then
                        table.insert(output, f.result.output)
                        table.insert(output, "")
                    end
                end
            end
        end
    end
end

function type_renderers.materialize_integration(child, output)
    table.insert(output, "### Integration Result")
    table.insert(output, "")
    table.insert(output, string.format("Status: %s", child.status or "unknown"))
    table.insert(output, "")

    if child.content and child.content_type == "application/json" then
        local result = json.decode(child.content)

        if result.success ~= nil then
            table.insert(output, string.format("**%s**", result.success and "SUCCESS" or "FAILED"))
            table.insert(output, "")
        end

        if result.message then
            table.insert(output, result.message)
            table.insert(output, "")
        end

        if result.pipeline and not result.pipeline.success then
            table.insert(output, "**Pipeline Error:**")
            table.insert(output, "")
            for _, exec in ipairs(result.pipeline.execution or {}) do
                if exec.error then
                    table.insert(output, string.format("Handler: `%s`", exec.handler_id))
                    table.insert(output, string.format("Error: %s", exec.error))
                    table.insert(output, "")
                end
            end
        end

        if result.rollback then
            table.insert(output, "**Rollback Applied:**")
            if result.rollback.version_restored then
                table.insert(output, string.format("- Registry version restored: %s", result.rollback.message or "yes"))
            end
            if result.rollback.pipeline_reverted then
                table.insert(output, "- Pipeline changes reverted")
            end
            table.insert(output, "")
        end

        if result.push then
            table.insert(output, "**Push Summary:**")
            table.insert(output, string.format("- Branch: `%s` → `%s`", result.push.branch or "unknown", result.push.base_branch or "unknown"))
            table.insert(output, string.format("- Changes: +%d ~%d -%d",
                result.push.added or 0, result.push.modified or 0, result.push.deleted or 0))
            if result.push.version then
                table.insert(output, string.format("- Registry version: %d", result.push.version))
            end
            table.insert(output, "")
        end

        if result.diff then
            table.insert(output, "**Changes:**")
            table.insert(output, "```")
            table.insert(output, result.diff)
            table.insert(output, "```")
            table.insert(output, "")
        end
    end
end

function type_renderers.materialize_test(child, output)
    table.insert(output, "### Test Result")
    table.insert(output, "")
    table.insert(output, string.format("Status: %s", child.status or "unknown"))
    table.insert(output, "")

    if child.content and child.content_type == "application/json" then
        local result = json.decode(child.content)

        if result.passed or result.failed or result.total then
            table.insert(output, string.format("Results: %d passed, %d failed (total: %d)",
                result.passed or 0, result.failed or 0, result.total or 0))
            table.insert(output, "")
        end

        if result.tests then
            for _, test in ipairs(result.tests) do
                local status = test.success and "PASS" or "FAIL"
                table.insert(output, string.format("**[%s] %s**", status, test.title or test.id))
                table.insert(output, "")

                if test.error then
                    table.insert(output, string.format("Error Code: %s", test.error.code or "unknown"))
                    table.insert(output, string.format("Error Message: %s", test.error.message or "unknown"))
                    table.insert(output, "")
                elseif test.result and test.result.details then
                    table.insert(output, test.result.details)
                    table.insert(output, "")
                end
            end
        elseif result.details then
            table.insert(output, result.details)
            table.insert(output, "")
        end
    end
end

function type_renderers.materialize_test_plan(child, output)
    table.insert(output, "### Test Plan")
    table.insert(output, "")
    if child.content and child.content_type == "application/json" then
        local plan = json.decode(child.content)
        if plan.steps then
            for i, step in ipairs(plan.steps) do
                table.insert(output, string.format("%d. %s", i, step.title or step.id))
            end
        end
    end
    table.insert(output, "")
end

function type_renderers.materialize_integration_request(child, output)
    table.insert(output, "### Integration Request")
    table.insert(output, "")
end

function type_renderers.materialize_debug(child, output)
    table.insert(output, "### Debug Result")
    table.insert(output, "")
    table.insert(output, string.format("Status: %s", child.status or "unknown"))
    table.insert(output, "")

    if child.content then
        table.insert(output, child.content)
        table.insert(output, "")
    end
end

function type_renderers.feedback(child, output)
    local child_meta = child.metadata or {}
    local fb_type = child_meta.feedback_type or child.discriminator or "feedback"
    local fb_title = child_meta.title or fb_type

    table.insert(output, string.format("### [%s] %s", string.upper(fb_type), fb_title))
    table.insert(output, "")
    table.insert(output, child.content or "")
    table.insert(output, "")
end

function type_renderers.default(child, output)
    table.insert(output, string.format("### %s", child.type or "unknown"))
    table.insert(output, "")
    table.insert(output, string.format("Status: %s | Position: %s", child.status or "unknown", tostring(child.position)))
    table.insert(output, "")
    if child.content then
        table.insert(output, child.content)
        table.insert(output, "")
    end
end

local function run(args)
    local branch_id = args.branch_id
    local materialize_node_id = args.materialize_node_id

    if not branch_id or branch_id == "" then
        return nil, "branch_id required"
    end

    if not materialize_node_id or materialize_node_id == "" then
        return nil, "materialize_node_id required"
    end

    local workspace_id = ctx.get("active_workspace_id")
    if not workspace_id then
        return nil, "active_workspace_id not set"
    end

    local reader = design_reader.for_workspace(workspace_id)

    local branch = reader:with_data(branch_id):one()
    if not branch then
        return nil, "Design target not found: " .. branch_id
    end

    local materialize_node = reader:with_data(materialize_node_id):one()
    if not materialize_node then
        return nil, "Materialize node not found: " .. materialize_node_id
    end

    local mat_meta = materialize_node.metadata or {}
    local overlay_branch = mat_meta.overlay_branch or "unknown"

    local output = {}

    table.insert(output, "# IMPLEMENTATION CONTEXT")
    table.insert(output, "")
    table.insert(output, "## Design Target")
    table.insert(output, "")
    table.insert(output, "**Target**: " .. (branch.metadata.title or branch_id))
    table.insert(output, "")
    table.insert(output, "## State Overlay Branch")
    table.insert(output, "")
    table.insert(output, "**Branch**: `" .. overlay_branch .. "`")
    table.insert(output, "")
    table.insert(output, "---")
    table.insert(output, "")

    table.insert(output, "# Design Specification")
    table.insert(output, "")

    if branch.content then
        table.insert(output, "## Original Prompt")
        table.insert(output, "")
        table.insert(output, branch.content)
        table.insert(output, "")
    end

    local context_docs = reader
        :with_type("context")
        :with_parent_direct(branch_id)
        :with_statuses("current")
        :order_by_created("asc")
        :all()

    if #(context_docs or {}) > 0 then
        table.insert(output, "## Design Context")
        table.insert(output, "")
        for _, doc in ipairs(context_docs) do
            local key = doc.discriminator or "context"
            local comment = (doc.metadata or {}).comment or ""
            table.insert(output, "### " .. key)
            if comment and comment ~= "" then
                table.insert(output, "*" .. comment .. "*")
                table.insert(output, "")
            end
            table.insert(output, doc.content or "")
            table.insert(output, "")
        end
    end

    local current_design = reader
        :with_type("design_version")
        :with_parent_direct(branch_id)
        :with_statuses("current")
        :one()

    if current_design then
        table.insert(output, "## Current Design Specification")
        table.insert(output, "")
        table.insert(output, current_design.content or "")
        table.insert(output, "")
    else
        return nil, "No current design version found"
    end

    table.insert(output, "---")
    table.insert(output, "")
    table.insert(output, "# Implementation History")
    table.insert(output, "")

    local all_children = reader
        :with_parent_direct(materialize_node_id)
        :order_by_created("asc")
        :all()

    if #(all_children or {}) == 0 then
        table.insert(output, "*No implementation history*")
        table.insert(output, "")
    else
        local current_iteration = nil

        for _, child in ipairs(all_children) do
            local child_meta = child.metadata or {}
            local iter = child_meta.iteration_number

            if iter and iter ~= current_iteration then
                if current_iteration then
                    table.insert(output, "")
                    table.insert(output, "---")
                end
                current_iteration = iter
                table.insert(output, "")
                table.insert(output, string.format("# ITERATION %d", iter))
                table.insert(output, "")
            end

            local renderer = type_renderers[child.type] or type_renderers.default
            renderer(child, output)
            table.insert(output, "")
        end
    end

    return table.concat(output, "\n")
end

return { run = run }