local ctx = require("ctx")
local audit = require("audit")
local nodes_writer = require("nodes_writer")
local nodes_reader = require("nodes_reader")
local sql = require("sql")

local M = {}

local VALID_KINDS = {
    impl            = true,
    migration       = true,
    fs_write        = true,
    test_create     = true,
    test_run        = true,
    endpoint_probe  = true,
    view_probe      = true,
    verify          = true,
    research        = true,
}

local function supersede_prior_plan(task_id)
    local db = sql.get("keeper.state:db")
    if not db then return end
    db:execute(
        "UPDATE keeper_task_nodes SET status = 'superseded' WHERE task_id = ? AND type = 'plan' AND status = 'active'",
        { task_id }
    )
    db:execute(
        "UPDATE keeper_task_nodes SET status = 'cancelled' WHERE task_id = ? AND type = 'step' AND status IN ('pending','in_progress','blocked')",
        { task_id }
    )
    db:release()
end

function M.write(task_id, params)
    if not task_id or task_id == "" then
        return nil, "No active task context"
    end

    params = params or {}
    local steps = params.steps
    if type(steps) ~= "table" or #steps == 0 then
        return nil, "steps array is required (at least one step)"
    end

    -- Validate every step structurally before writing anything.
    local ids = {}
    for i, s in ipairs(steps) do
        if type(s) ~= "table" then return nil, "step " .. i .. " must be an object" end
        if not s.id or s.id == "" then return nil, "step " .. i .. ": id is required" end
        if ids[s.id] then return nil, "step " .. i .. ": duplicate id '" .. s.id .. "'" end
        ids[s.id] = true
        if not s.kind or not VALID_KINDS[s.kind] then
            return nil, "step " .. s.id .. ": kind must be one of impl|migration|fs_write|test_create|test_run|endpoint_probe|view_probe|verify|research"
        end
        if not s.title or s.title == "" then return nil, "step " .. s.id .. ": title required" end
        if not s.task or s.task == "" then return nil, "step " .. s.id .. ": task (body) required" end
    end
    for _, s in ipairs(steps) do
        local needs = s.needs or {}
        if type(needs) ~= "table" then
            return nil, "step " .. s.id .. ": needs must be an array of step ids"
        end
        for _, nid in ipairs(needs) do
            if not ids[nid] then
                return nil, "step " .. s.id .. ": needs references unknown step id '" .. nid .. "'"
            end
        end
    end

    -- Determine revision.
    local prior, _ = nodes_reader.by_type(task_id, "plan")
    local next_rev = tostring((prior and #prior or 0) + 1)
    supersede_prior_plan(task_id)

    local total = #steps
    local plan_title = params.title or ("Implementation Plan (rev " .. next_rev .. ")")
    local plan_row, err = nodes_writer.record({
        task_id       = task_id,
        type          = "plan",
        discriminator = next_rev,
        title         = plan_title,
        content       = params.summary,
        content_type  = "text/markdown",
        status        = "active",
        visibility    = "user",
        metadata      = {
            revision    = next_rev,
            step_count  = total,
            description = params.summary,
        },
    })
    if err or not plan_row then
        return nil, "Failed to record plan node: " .. tostring(err)
    end

    local inserted = 0
    for i, s in ipairs(steps) do
        local _, serr = nodes_writer.record({
            task_id        = task_id,
            parent_node_id = plan_row.node_id,
            type           = "step",
            discriminator  = s.id,
            title          = s.title,
            content        = s.task,
            content_type   = "text/markdown",
            status         = "pending",
            visibility     = "user",
            metadata       = {
                kind             = s.kind,
                target           = s.target,
                needs            = s.needs or {},
                agent_id         = s.agent_id,
                produces_prompt  = s.produces_prompt,
                acceptance       = s.acceptance,
                verification_tool = s.verification_tool,
                position         = i,
                plan_node_id     = plan_row.node_id,
                plan_revision    = next_rev,
            },
        })
        if serr then
            return nil, "Failed to record step '" .. s.id .. "': " .. serr
        end
        inserted = inserted + 1
    end

    return "Plan rev " .. next_rev .. " saved (" .. inserted .. " steps)"
end

function M.handler(params)
    params = params or {}
    local step_count = (type(params.steps) == "table") and #params.steps or 0
    return audit.wrap({
        tool          = "write_plan",
        discriminator = "write_plan",
        target        = tostring(step_count) .. " steps",
        params        = { step_count = step_count, title = params.title },
        summarise = function(result, err)
            if err then return "write_plan failed: " .. tostring(err) end
            return "wrote plan (" .. step_count .. " steps)"
        end,
    }, function()
        return M.write(ctx.get("task_id"), params)
    end)
end

return M
