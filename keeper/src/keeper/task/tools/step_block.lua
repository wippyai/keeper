local ctx = require("ctx")
local audit = require("audit")
local task_mutations = require("task_mutations")

local M = {}

function M.block(task_id, params)
    if not task_id or task_id == "" then
        return nil, "No active task context"
    end
    params = params or {}
    local step_id = params.step_id
    if not step_id or step_id == "" then
        return nil, "step_id is required"
    end
    local question = params.question
    if not question or question == "" then
        return nil, "question is required"
    end

    local _, err = task_mutations.block_step(task_id, {
        step_id = step_id,
        question = question,
        agent_id = ctx.get("agent_id"),
        phase = ctx.get("phase"),
    })
    if err then return nil, err end

    return "step '" .. step_id .. "' blocked; exit with status='ask_user' and include the question in summary"
end

function M.handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "step_block",
        discriminator = "step_block",
        target        = params.step_id,
        params        = { step_id = params.step_id, question_chars = params.question and #params.question or 0 },
        summarise = function(result, err)
            if err then return "step_block failed: " .. tostring(err) end
            return "blocked step: " .. (params.step_id or "?")
        end,
    }, function()
        return M.block(ctx.get("task_id"), params)
    end)
end

return M
