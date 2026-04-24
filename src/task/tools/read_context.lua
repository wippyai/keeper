local ctx = require("ctx")
local audit = require("audit")
local nodes_reader = require("nodes_reader")
local summarize = require("summarize")

local M = {}

function M.read(task_id)
    if not task_id or task_id == "" then
        return nil, "No active task context"
    end

    local rows, err = nodes_reader.findings(task_id)
    if err then return nil, "Failed to read findings: " .. err end

    if not rows or #rows == 0 then
        return "No prior findings saved for this task."
    end

    local parts = { "# Saved Findings (" .. #rows .. ")" }
    for _, r in ipairs(rows) do
        local title = r.title or r.discriminator or "(untitled)"
        local content = r.content or ""
        table.insert(parts, "")
        table.insert(parts, "## " .. title)
        if content ~= "" then table.insert(parts, content) end
    end
    return table.concat(parts, "\n")
end

function M.handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "read_context",
        discriminator = "read_context",
        params        = { goal = params.goal, full = params.full },
        summarise = function(result, err)
            if err then return "read_context failed: " .. tostring(err) end
            if type(result) == "string" then
                local n = result:match("# Saved Findings %((%d+)%)")
                if n then return n .. " findings loaded" end
            end
            return "read_context done"
        end,
    }, function()
        local rendered, err = M.read(ctx.get("task_id"))
        if err then return nil, err end
        if not rendered or params.full == true then return rendered end
        local goal = params.goal
        if not goal or goal == "" then
            goal = "Prior research, decisions, and handoffs for this task"
        end
        local compressed, _sum_err, was_summarized = summarize.summarize(rendered, goal, {
            tool = "read_context",
        })
        if was_summarized then return compressed end
        return rendered
    end)
end

return M
