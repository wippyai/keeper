local json = require("json")

local function handler(input)
    if not input then
        return nil, "Input required"
    end

    if not input.operation then
        return nil, "operation field is required"
    end

    local op = input.operation
    if op ~= "implement" and op ~= "integrate" and op ~= "test" and op ~= "debug" and op ~= "finish" then
        return nil, "operation must be: implement, integrate, test, debug, or finish"
    end

    if not input.reasoning or input.reasoning == "" then
        return nil, "reasoning field is required"
    end

    if op == "implement" then
        if not input.implementation_plan then
            return nil, "implementation_plan required for implement operation"
        end

        local plan = input.implementation_plan
        local steps = plan.steps or {}

        if #steps == 0 then
            return nil, "implementation_plan.steps must have at least one step"
        end

        local step_ids = {}
        for i, step in ipairs(steps) do
            if not step.id or step.id == "" then
                return nil, string.format("Step %d missing id", i)
            end

            if step_ids[step.id] then
                return nil, string.format("Duplicate step id: %s", step.id)
            end
            step_ids[step.id] = true

            if not step.agent_id or step.agent_id == "" then
                return nil, string.format("Step %s missing agent_id", step.id)
            end

            if not step.title or step.title == "" then
                return nil, string.format("Step %s missing title", step.id)
            end

            if not step.task or step.task == "" then
                return nil, string.format("Step %s missing task", step.id)
            end

            if not step.produces_prompt or step.produces_prompt == "" then
                return nil, string.format("Step %s missing produces_prompt", step.id)
            end
        end

        for i, step in ipairs(steps) do
            local needs = step.needs or {}
            for _, dep_id in ipairs(needs) do
                if not step_ids[dep_id] then
                    return nil, string.format("Step %s depends on non-existent step: %s", step.id, dep_id)
                end
            end
        end
    end

    if op == "test" then
        if not input.test_plan then
            return nil, "test_plan required for test operation"
        end

        local plan = input.test_plan
        local steps = plan.steps or {}

        if #steps == 0 then
            return nil, "test_plan.steps must have at least one step"
        end

        local step_ids = {}
        for i, step in ipairs(steps) do
            if not step.id or step.id == "" then
                return nil, string.format("Test step %d missing id", i)
            end

            if step_ids[step.id] then
                return nil, string.format("Duplicate test step id: %s", step.id)
            end
            step_ids[step.id] = true

            if not step.agent_id or step.agent_id == "" then
                return nil, string.format("Test step %s missing agent_id", step.id)
            end

            if not step.title or step.title == "" then
                return nil, string.format("Test step %s missing title", step.id)
            end

            if not step.task or step.task == "" then
                return nil, string.format("Test step %s missing task", step.id)
            end
        end
    end

    if op == "debug" then
        if not input.debug_prompt then
            return nil, "debug_prompt required for debug operation"
        end
    end

    return input
end

return { handler = handler }
