local ctx = require("ctx")
local audit = require("audit")
local nodes_writer = require("nodes_writer")
local nodes_reader = require("nodes_reader")

local M = {}

local function load_open_step(task_id, step_id)
    local rows, err = nodes_reader.by_type(task_id, "step", { discriminator = step_id })
    if err then return nil, err end
    for i = #rows, 1, -1 do
        local r = rows[i]
        if r.status == "pending" or r.status == "active" then
            return r, nil
        end
    end
    if rows and #rows > 0 then
        return nil, "step '" .. step_id .. "' is " .. (rows[#rows].status or "closed")
    end
    return nil, "step '" .. step_id .. "' not found"
end

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

    local step, err = load_open_step(task_id, step_id)
    if not step then return nil, err end

    -- Emit an ask_user node tied to the step (parent = step node).
    local ask, aerr = nodes_writer.record({
        task_id        = task_id,
        parent_node_id = step.node_id,
        type           = "ask_user",
        discriminator  = step_id,
        title          = "Blocked on " .. step_id,
        content        = question,
        content_type   = "text/markdown",
        status         = "active",
        visibility     = "user",
        agent_id       = ctx.get("agent_id"),
        metadata       = { step_id = step_id, phase = ctx.get("phase") },
    })
    if aerr then return nil, "Failed to emit ask_user: " .. aerr end

    -- Mark the step blocked and point it at the ask_user node.
    local _, uerr = nodes_writer.update(step.node_id, {
        status         = "blocked",
        result_summary = "blocked: awaiting user response",
        error_message  = question,
        agent_id       = ctx.get("agent_id"),
        metadata       = {
            blocker_node_id = ask and ask.node_id,
        },
    })
    if uerr then return nil, "Failed to update step: " .. uerr end

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
