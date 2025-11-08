-- iteration_collector.lua
local json = require("json")
local uuid = require("uuid")
local ctx = require("ctx")
local design_writer = require("design_writer")
local design_reader = require("design_reader")

local function run(inputs)
    local branch_id = inputs.branch_id
    local agent_output = inputs.agent_output or {}

    if not branch_id then
        return nil, "branch_id required"
    end

    local workspace_id = ctx.get("active_workspace_id")
    if not workspace_id then
        return nil, "active_workspace_id not set"
    end

    local reader = design_reader.for_workspace(workspace_id)

    local existing_iterations = reader
        :with_type("iteration")
        :with_parent_direct(branch_id)
        :count()

    local iteration = (existing_iterations or 0) + 1

    local reasoning = agent_output.reasoning or ""
    local operations = agent_output.operations or {}

    local branch, err = reader:with_data(branch_id):one()
    if err or not branch then
        return nil, "Failed to load branch: " .. (err or branch_id)
    end

    local ws = design_writer.existing_workspace(workspace_id)

    ws:update_data(branch_id, { status = "active" })

    ws:data({
        type = "iteration",
        parent_data_id = branch_id,
        content = reasoning,
        status = "completed",
        metadata = {
            iteration_number = iteration,
            parent_branch_id = branch_id,
            title = "Iteration " .. iteration
        }
    })

    local has_blocking_questions = false
    local marked_final = false
    local scheduled_research = 0

    for _, op in ipairs(operations) do
        local op_type = op.op_type

        if op_type == "research" then
            local title = op.title or "Research"

            ws:data({
                type = "research",
                parent_data_id = branch_id,
                discriminator = op.agent_id,
                content = op.prompt,
                status = "pending",
                metadata = {
                    agent_id = op.agent_id,
                    title = title,
                    requested_in_iteration = iteration,
                    parent_branch_id = branch_id,
                    query = op.prompt,
                    comment = op.comment
                }
            })

            scheduled_research = scheduled_research + 1

        elseif op_type == "context" then
            local key = op.key or "context"

            local existing_context = reader
                :with_type("context")
                :with_parent_direct(branch_id)
                :with_discriminator(key)
                :with_statuses("current")
                :one()

            if existing_context then
                ws:update_data(existing_context.data_id, { status = "superseded" })
            end

            ws:data({
                type = "context",
                parent_data_id = branch_id,
                discriminator = key,
                content = op.content,
                content_type = "text/plain",
                status = "current",
                metadata = {
                    title = key,
                    comment = op.comment,
                    created_in_iteration = iteration,
                    parent_branch_id = branch_id
                }
            })

        elseif op_type == "delete_context" then
            local key = op.key

            local existing = reader
                :with_type("context")
                :with_parent_direct(branch_id)
                :with_discriminator(key)
                :with_statuses("current")
                :one()

            if existing then
                ws:delete_data(existing.data_id)
            end

        elseif op_type == "question" then
            ws:data({
                type = "question",
                parent_data_id = branch_id,
                content = op.content,
                status = "open",
                metadata = {
                    title = "Question",
                    comment = op.comment,
                    blocking = op.blocking or false,
                    asked_in_iteration = iteration,
                    parent_branch_id = branch_id
                }
            })

            if op.blocking then
                has_blocking_questions = true
            end

        elseif op_type == "answer" then
            local question, _ = reader:with_data(op.question_id):one()
            if question then
                local is_child_question = question.parent_data_id ~= branch_id

                ws:update_data(op.question_id, { status = "answered" })

                ws:data({
                    type = "answer",
                    parent_data_id = branch_id,
                    content = op.content,
                    metadata = {
                        title = "Answer",
                        answered_by = branch_id,
                        answered_in_iteration = iteration,
                        forwarded = is_child_question,
                        parent_question_id = op.question_id,
                        comment = op.comment
                    }
                })

                if is_child_question then
                    local child_branch_id = question.parent_data_id
                    ws:update_data(child_branch_id, { status = "scheduled" })
                end
            end

        elseif op_type == "design_spec" then
            local existing = reader
                :with_type("design_version")
                :with_parent_direct(branch_id)
                :with_statuses("current")
                :one()

            local version = 1
            if existing then
                version = (existing.metadata.version or 0) + 1
                ws:update_data(existing.data_id, { status = "superseded" })
            end

            ws:data({
                type = "design_version",
                parent_data_id = branch_id,
                discriminator = "v" .. version,
                content = op.content,
                content_type = "text/plain",
                status = "current",
                metadata = {
                    title = "Design Spec v" .. version,
                    version = version,
                    is_final = op.is_final or false,
                    created_in_iteration = iteration,
                    parent_branch_id = branch_id,
                    comment = op.comment
                }
            })

            ws:update_data(branch_id, {
                metadata = {
                    current_version = version,
                    is_final = op.is_final or false
                }
            })

            marked_final = op.is_final or false
        end
    end

    local exec_result, exec_err = ws:execute()
    if exec_err then
        return nil, "Failed to execute writes: " .. exec_err
    end

    local should_stop = false
    local final_status = "active"
    local stop_reason = nil

    local open_questions = reader
        :with_type("question")
        :with_parent_direct(branch_id)
        :with_statuses("open")
        :order_by_position()
        :all()

    local open_questions_list = {}
    for _, q in ipairs(open_questions or {}) do
        local meta = q.metadata or {}
        table.insert(open_questions_list, {
            question_id = q.data_id,
            content = q.content,
            blocking = meta.blocking or false,
            comment = meta.comment
        })
    end

    if has_blocking_questions then
        ws = design_writer.existing_workspace(workspace_id)
        ws:update_data(branch_id, { status = "blocked" })
        ws:execute()

        should_stop = true
        final_status = "blocked"
        stop_reason = "blocking_questions"
    end

    return {
        state = {
            branch_id = branch_id,
            iterations_run = iteration
        },
        result = {
            should_stop = should_stop,
            status = final_status,
            stop_reason = stop_reason,
            iterations_run = iteration,
            operations_processed = #operations,
            open_questions = open_questions_list,
            marked_final = marked_final
        },
        continue = not should_stop
    }
end

return { run = run }