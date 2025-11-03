local json = require("json")

local VALID_OP_TYPES = {
    research = true,
    child_branch = true,
    question = true,
    answer = true,
    design_spec = true,
    context = true,
    delete_context = true
}

local function handler(input)
    if not input then
        return nil, "Input required"
    end

    if not input.reasoning or input.reasoning == "" then
        return nil, "reasoning field is required and cannot be empty"
    end

    local operations = input.operations or {}

    local has_research = false
    local has_question = false

    for i, op in ipairs(operations) do
        if not op.op_type then
            return nil, string.format("Operation %d missing op_type", i)
        end

        if not VALID_OP_TYPES[op.op_type] then
            return nil, string.format("Operation %d has invalid op_type: %s", i, op.op_type)
        end

        if op.op_type == "research" then
            has_research = true
        elseif op.op_type == "question" then
            has_question = true
        end

        if op.op_type == "research" then
            if not op.agent_id or op.agent_id == "" then
                return nil, string.format("Operation %d (research) missing agent_id", i)
            end
            if not op.prompt or op.prompt == "" then
                return nil, string.format("Operation %d (research) missing prompt", i)
            end
            if not op.title or op.title == "" then
                return nil, string.format("Operation %d (research) missing title", i)
            end

        elseif op.op_type == "child_branch" then
            if not op.agent_id or op.agent_id == "" then
                return nil, string.format("Operation %d (child_branch) missing agent_id", i)
            end
            if not op.prompt or op.prompt == "" then
                return nil, string.format("Operation %d (child_branch) missing prompt", i)
            end

        elseif op.op_type == "question" then
            if not op.content or op.content == "" then
                return nil, string.format("Operation %d (question) missing content", i)
            end
            if op.blocking == nil then
                return nil, string.format("Operation %d (question) missing blocking field", i)
            end

        elseif op.op_type == "answer" then
            if not op.question_id or op.question_id == "" then
                return nil, string.format("Operation %d (answer) missing question_id", i)
            end
            if not op.content or op.content == "" then
                return nil, string.format("Operation %d (answer) missing content", i)
            end

        elseif op.op_type == "design_spec" then
            if not op.content or op.content == "" then
                return nil, string.format("Operation %d (design_spec) missing content", i)
            end

        elseif op.op_type == "context" then
            if not op.key or op.key == "" then
                return nil, string.format("Operation %d (context) missing key", i)
            end
            if not op.content or op.content == "" then
                return nil, string.format("Operation %d (context) missing content", i)
            end

        elseif op.op_type == "delete_context" then
            if not op.key or op.key == "" then
                return nil, string.format("Operation %d (delete_context) missing key", i)
            end
        end
    end

    if has_research and has_question then
        return nil, "Cannot schedule both research and question operations in same iteration. Choose one: either research to discover information, or questions to ask user. Context and design_spec operations are allowed with both."
    end

    return input
end

return { handler = handler }