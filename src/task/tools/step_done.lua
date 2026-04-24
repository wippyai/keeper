local ctx = require("ctx")
local audit = require("audit")
local nodes_writer = require("nodes_writer")
local nodes_reader = require("nodes_reader")
local sql = require("sql")

local M = {}

local function load_active_step(task_id, step_id)
    local rows, err = nodes_reader.by_type(task_id, "step", { discriminator = step_id })
    if err then return nil, err end
    -- Prefer the latest row (last pushed revision).
    for i = #rows, 1, -1 do
        local r = rows[i]
        if r.status == "pending" or r.status == "active" or r.status == "blocked" then
            return r, nil
        end
    end
    if rows and #rows > 0 then
        return nil, "step '" .. step_id .. "' is " .. (rows[#rows].status or "closed")
    end
    return nil, "step '" .. step_id .. "' not found"
end

function M.mark(task_id, params)
    if not task_id or task_id == "" then
        return nil, "No active task context"
    end
    params = params or {}
    local step_id = params.step_id
    if not step_id or step_id == "" then
        return nil, "step_id is required"
    end

    local step, err = load_active_step(task_id, step_id)
    if not step then return nil, err end

    local summary = params.result_summary or params.summary
    local fields = {
        status         = "completed",
        result_summary = summary,
        agent_id       = ctx.get("agent_id"),
    }
    local _, uerr = nodes_writer.update(step.node_id, fields)
    if uerr then return nil, "Failed to update step: " .. uerr end

    return "step '" .. step_id .. "' marked completed" ..
        (summary and (": " .. summary) or "")
end

function M.handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "step_done",
        discriminator = "step_done",
        target        = params.step_id,
        params        = { step_id = params.step_id, chars = params.result_summary and #params.result_summary or 0 },
        summarise = function(result, err)
            if err then return "step_done failed: " .. tostring(err) end
            return "closed step: " .. (params.step_id or "?")
        end,
    }, function()
        return M.mark(ctx.get("task_id"), params)
    end)
end

return M
