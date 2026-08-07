local ctx = require("ctx")
local audit = require("audit")
local task_mutations = require("task_mutations")

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

    local result, err = task_mutations.write_plan(task_id, params)
    if err then return nil, err end
    return "Plan rev " .. result.revision .. " saved (" .. result.inserted .. " steps)"
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
