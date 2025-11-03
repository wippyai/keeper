local json = require("json")
local ctx = require("ctx")
local design_reader = require("design_reader")
local design_writer = require("design_writer")

local function get_active_workspace()
    local workspace_id, err = ctx.get("active_workspace_id")
    if not err and workspace_id and workspace_id ~= "" then
        return workspace_id, nil
    end
    return nil, "No active workspace (use workspace open first)"
end

local function auto_detect_target(workspace_id, reader)
    local materialize_node_id = ctx.get("materialize_node_id")
    if materialize_node_id and materialize_node_id ~= "" then
        local node = reader:with_data(materialize_node_id):one()
        if node then
            return materialize_node_id, "materialize"
        end
    end

    local root = reader
        :with_type("design")
        :with_discriminator("root")
        :with_depth(0)
        :one()

    if root then
        return root.data_id, "design_root"
    end

    return nil, "No target found (no materialize context or root design)"
end

local function handler(args)
    local workspace_id, err = get_active_workspace()
    if err then
        return nil, err
    end

    if not args.content or args.content == "" then
        return nil, "content required"
    end

    local reader = design_reader.for_workspace(workspace_id)
    local target_data_id = args.target_data_id
    local auto_detected = false

    if not target_data_id or target_data_id == "" then
        local target_type
        target_data_id, target_type = auto_detect_target(workspace_id, reader)
        if not target_data_id then
            return nil, target_type
        end
        auto_detected = true
    end

    local target, err = reader:with_data(target_data_id):one()
    if err or not target then
        return nil, "Target node not found: " .. (err or target_data_id)
    end

    local feedback_type = args.feedback_type or "comment"
    local ws = design_writer.existing_workspace(workspace_id)

    local metadata = args.metadata or {}
    metadata.feedback_type = feedback_type
    metadata.target_node_type = target.type
    metadata.title = "Feedback"
    if auto_detected then
        metadata.auto_detected = true
    end

    if target.type == "question" and feedback_type == "answer" then
        ws:update_data(target_data_id, { status = "answered" })
        metadata.title = "Answer"

        if target.parent_data_id then
            local parent_branch = reader:with_data(target.parent_data_id):one()
            if parent_branch and parent_branch.status == "blocked" then
                local open_questions = reader
                    :with_type("question")
                    :with_parent_direct(target.parent_data_id)
                    :with_statuses("open")
                    :count()

                if open_questions == 1 then
                    ws:update_data(target.parent_data_id, { status = "scheduled" })
                end
            end
        end
    end

    ws:data({
        type = "feedback",
        discriminator = feedback_type,
        parent_data_id = target_data_id,
        content = args.content,
        content_type = "text/plain",
        status = "active",
        metadata = metadata
    })

    local result, exec_err = ws:execute()
    if exec_err then
        return nil, "Failed to add feedback: " .. exec_err
    end

    local feedback_id = result.results and result.results[#result.results] and result.results[#result.results].data_id

    return {
        feedback_id = feedback_id,
        target_data_id = target_data_id,
        feedback_type = feedback_type,
        auto_detected = auto_detected,
        message = "Feedback added"
    }
end

return { handler = handler }