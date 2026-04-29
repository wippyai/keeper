local ctx = require("ctx")
local audit = require("audit")
local nodes_reader = require("nodes_reader")
local summarize = require("summarize")
local changeset_repo = require("changeset_repo")
local format_context = require("format_context")

local M = {}

-- Build the "Live State" preamble that prepends every read_context result.
-- Agents tend to quote branch names from stale findings as if they were
-- still current; this preamble gives them a single unambiguous ground-truth
-- view of the active workspace every time they refresh their memory.
-- Kept small so it doesn't blow the summariser when full=false.
local function live_state_block(task_id)
    if not task_id or task_id == "" then return nil end
    local cs = changeset_repo.active_for_task(task_id)
    local lines = { "## Live State" }
    table.insert(lines, "- task_id: " .. task_id)
    if cs and cs.changeset_id then
        table.insert(lines, "- active_changeset_id: " .. cs.changeset_id)
        table.insert(lines, "- overlay_branch: " .. tostring(cs.state_branch or "(none)"))
        table.insert(lines, "- changeset_state: " .. tostring(cs.state or "(unknown)"))
    else
        table.insert(lines, "- active_changeset_id: (none — next phase will auto-fork)")
    end
    table.insert(lines, "")
    table.insert(lines,
        "**Branch/changeset values above are the SOURCE OF TRUTH.**")
    table.insert(lines,
        "Do not quote branch names from findings below if they disagree with this block.")
    return table.concat(lines, "\n")
end

function M.read(task_id)
    if not task_id or task_id == "" then
        return nil, "No active task context"
    end

    local preamble = live_state_block(task_id)

    local rows, err = nodes_reader.findings(task_id)
    if err then return nil, "Failed to read findings: " .. err end

    if not rows or #rows == 0 then
        local empty = "No prior findings saved for this task."
        if preamble then return preamble .. "\n\n" .. empty end
        return empty
    end

    local parts = {}
    if preamble then
        table.insert(parts, preamble)
        table.insert(parts, "")
    end
    table.insert(parts, "# Saved Findings (" .. #rows .. ")")
    for _, r in ipairs(rows) do
        local title = r.title or r.discriminator or "(untitled)"
        local content = r.content or ""
        table.insert(parts, "")
        table.insert(parts, "## " .. title)
        if content ~= "" then table.insert(parts, content) end
    end
    -- Resolve <embed id="ns:name" mode="..."/> placeholders against the live
    -- state reader so agents reading findings get the inlined source rather
    -- than literal embed tags. Researchers commonly stamp findings with
    -- embed refs ("here's the v26 source: <embed id='app.probe_v26:repo'/>")
    -- expecting them to expand on consumption. The dataflow path through
    -- prepare_context resolved them for orchestrator prompts but read_context
    -- did not — leaving subagents staring at unresolved tags.
    local rendered = table.concat(parts, "\n")
    return format_context.resolve(rendered)
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
