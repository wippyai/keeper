local json = require("json")
local ctx = require("ctx")
local design_reader = require("design_reader")

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

    local all_iterations = reader
        :with_type("materialize_iteration")
        :with_parent_direct(materialize_node_id)
        :order_by_position()
        :all()

    local current_iteration = 0
    local total_implementations = 0
    local successful_implementations = 0
    local failed_implementations = 0
    local has_integrated = false
    local integration_success = nil

    for _, iter in ipairs(all_iterations or {}) do
        local meta = iter.metadata or {}
        local iter_num = meta.iteration_number or 0
        if iter_num > current_iteration then
            current_iteration = iter_num
        end

        if meta.operation == "implement_graph" and meta.entry_type == "execution_result" then
            total_implementations = total_implementations + 1
            if iter.status == "completed" then
                successful_implementations = successful_implementations + 1
            else
                failed_implementations = failed_implementations + 1
            end
        elseif meta.operation == "integrate" and meta.entry_type == "integration_result" then
            has_integrated = true
            integration_success = (iter.status == "completed")
        end
    end

    current_iteration = current_iteration + 1

    local output = {}

    table.insert(output, "# IMPLEMENTATION CONTEXT")
    table.insert(output, "")
    table.insert(output, "## Design Target")
    table.insert(output, "")
    table.insert(output, "**Target**: " .. (branch.metadata.title or branch_id))
    table.insert(output, "**Target ID**: `" .. branch_id .. "`")
    table.insert(output, "")
    table.insert(output, "## State Overlay Branch")
    table.insert(output, "")
    table.insert(output, "**Branch**: `" .. overlay_branch .. "`")
    table.insert(output, "")
    table.insert(output, "*Use this branch when verifying implemented state or resetting implementation.*")
    table.insert(output, "")
    table.insert(output, "---")
    table.insert(output, "")
    table.insert(output, "# IMPLEMENTATION ITERATION: " .. current_iteration)
    table.insert(output, "")
    table.insert(output, "## Current Status")
    table.insert(output, "")
    table.insert(output, "- **Total Iterations Completed**: " .. #(all_iterations or {}))
    table.insert(output, "- **Implementation Attempts**: " .. total_implementations)
    table.insert(output, "  - Successful: " .. successful_implementations)
    table.insert(output, "  - Failed: " .. failed_implementations)
    table.insert(output, "- **Integration Run**: " .. (has_integrated and "Yes" or "No"))
    if has_integrated then
        table.insert(output, "  - Integration Status: " .. (integration_success and "Success" or "Failed"))
    end
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
        :order_by_position()
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

    local materialize_feedback = reader
        :with_type("feedback")
        :with_parent_direct(materialize_node_id)
        :order_by_position()
        :all()

    if #(materialize_feedback or {}) > 0 then
        table.insert(output, "## Implementation Feedback")
        table.insert(output, "")
        for _, fb in ipairs(materialize_feedback) do
            local fb_meta = fb.metadata or {}
            local fb_type = fb_meta.feedback_type or fb.discriminator or "feedback"
            table.insert(output, "**" .. fb_type:gsub("^%l", string.upper) .. "**: " .. (fb.content or ""))
            table.insert(output, "")
        end
    end

    if #(all_iterations or {}) > 0 then
        table.insert(output, "## Previous Implementation Iterations")
        table.insert(output, "")

        local grouped = {}
        for _, iter in ipairs(all_iterations) do
            local meta = iter.metadata or {}
            local iter_num = meta.iteration_number or 0
            if not grouped[iter_num] then
                grouped[iter_num] = {}
            end
            table.insert(grouped[iter_num], iter)
        end

        local sorted_keys = {}
        for k in pairs(grouped) do
            table.insert(sorted_keys, k)
        end
        table.sort(sorted_keys)

        for _, iter_num in ipairs(sorted_keys) do
            local entries = grouped[iter_num]
            table.insert(output, "### Iteration " .. iter_num)
            table.insert(output, "")

            local execution_result = nil
            local integration_result = nil
            local operation = "unknown"

            for _, entry in ipairs(entries) do
                local meta = entry.metadata or {}
                local entry_type = meta.entry_type
                operation = meta.operation or operation

                if entry_type == "execution_result" then
                    execution_result = entry
                elseif entry_type == "integration_result" then
                    integration_result = entry
                end
            end

            table.insert(output, "**Operation**: " .. operation)
            table.insert(output, "")

            if execution_result then
                table.insert(output, "#### Implementation Result")
                table.insert(output, "")
                table.insert(output, "**Status**: " .. (execution_result.status or "unknown"))
                table.insert(output, "")

                if execution_result.content and execution_result.content_type == "application/json" then
                    local result_data = json.decode(execution_result.content)

                    if result_data.total_steps then
                        table.insert(output, string.format("**Total Steps**: %d", result_data.total_steps))
                        table.insert(output, string.format("**Succeeded**: %d", result_data.succeeded or 0))
                        table.insert(output, string.format("**Failed**: %d", result_data.failed or 0))
                        table.insert(output, string.format("**Success Rate**: %.1f%%", (result_data.success_rate or 0) * 100))
                        table.insert(output, "")
                    end

                    if result_data.successes and #result_data.successes > 0 then
                        table.insert(output, "##### Successful Steps")
                        table.insert(output, "")
                        for _, success in ipairs(result_data.successes) do
                            table.insert(output, string.format("###### %s", success.step))
                            table.insert(output, "")
                            if success.result then
                                for key, value in pairs(success.result) do
                                    table.insert(output, string.format("**%s**:", key))
                                    table.insert(output, "```")
                                    table.insert(output, tostring(value))
                                    table.insert(output, "```")
                                    table.insert(output, "")
                                end
                            end
                        end
                    end

                    if result_data.failures and #result_data.failures > 0 then
                        table.insert(output, "##### Failed Steps")
                        table.insert(output, "")
                        for _, failure in ipairs(result_data.failures) do
                            table.insert(output, string.format("###### %s", failure.step))
                            table.insert(output, "")
                            if failure.result then
                                for key, value in pairs(failure.result) do
                                    table.insert(output, string.format("**%s**:", key))
                                    table.insert(output, "```")
                                    table.insert(output, tostring(value))
                                    table.insert(output, "```")
                                    table.insert(output, "")
                                end
                            end
                        end
                    end
                end
            end

            if integration_result then
                table.insert(output, "#### Integration Result")
                table.insert(output, "")
                table.insert(output, "**Status**: " .. (integration_result.status or "unknown"))
                table.insert(output, "")

                if integration_result.content and integration_result.content_type == "application/json" then
                    local result_data = json.decode(integration_result.content)

                    if result_data.code == "CHILD_WORKFLOW_FAILED" and type(result_data.message) == "string" then
                        local ok, parsed_message = pcall(json.decode, result_data.message)
                        if ok and type(parsed_message) == "table" then
                            table.insert(output, "**Error Code**: CHILD_WORKFLOW_FAILED")
                            table.insert(output, "")

                            if parsed_message.success ~= nil then
                                table.insert(output, "**Success**: " .. tostring(parsed_message.success))
                                table.insert(output, "")
                            end

                            if parsed_message.message then
                                table.insert(output, "**Message**: " .. parsed_message.message)
                                table.insert(output, "")
                            end

                            if parsed_message.push then
                                table.insert(output, "**Push Error**:")
                                table.insert(output, "```")
                                if type(parsed_message.push) == "table" then
                                    if parsed_message.push.code then
                                        table.insert(output, "Code: " .. parsed_message.push.code)
                                    end
                                    if parsed_message.push.message then
                                        table.insert(output, parsed_message.push.message)
                                    end
                                else
                                    table.insert(output, tostring(parsed_message.push))
                                end
                                table.insert(output, "```")
                                table.insert(output, "")
                            end

                            if parsed_message.pipeline then
                                table.insert(output, "**Pipeline**:")
                                table.insert(output, "```json")
                                table.insert(output, json.encode(parsed_message.pipeline))
                                table.insert(output, "```")
                                table.insert(output, "")
                            end

                            if parsed_message.rollback then
                                table.insert(output, "**Rollback**:")
                                table.insert(output, "```json")
                                table.insert(output, json.encode(parsed_message.rollback))
                                table.insert(output, "```")
                                table.insert(output, "")
                            end
                        else
                            table.insert(output, "**Error Code**: " .. result_data.code)
                            table.insert(output, "")
                            table.insert(output, "**Message**:")
                            table.insert(output, "```")
                            table.insert(output, result_data.message)
                            table.insert(output, "```")
                            table.insert(output, "")
                        end
                    else
                        for key, value in pairs(result_data) do
                            if type(value) == "table" then
                                table.insert(output, string.format("**%s**:", key))
                                table.insert(output, "```json")
                                table.insert(output, json.encode(value))
                                table.insert(output, "```")
                                table.insert(output, "")
                            else
                                table.insert(output, string.format("**%s**: %s", key, tostring(value)))
                                table.insert(output, "")
                            end
                        end
                    end
                end
            end
        end
    end

    print(table.concat(output, "\n"))
    return table.concat(output, "\n")
end

return { run = run }