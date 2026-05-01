local security = require("security")
local task_writer = require("task_writer")
local lifecycle = require("lifecycle")

local M = {}

local function resolve_actor_id()
    local actor = security.actor()
    if actor and actor.id then
        local ok, id = pcall(function() return actor:id() end)
        if ok and id and id ~= "" then return id end
    end
    return "mcp.admin"
end

function M.handler(params)
    params = params or {}
    local title = params.title
    if not title or title == "" then return nil, "title is required" end

    local actor_id = resolve_actor_id()
    local result, err = task_writer.create_task({
        title       = title,
        description = params.description,
        spec        = params.spec,
        actor_id    = actor_id,
        metadata    = { source = "launch_task" },
    }):execute()
    if err or not result then return nil, err or "create_task returned no result" end

    if params.start == false then
        return { task_id = result.task_id, started = false }
    end

    local _, start_err = lifecycle.start_cycle(result.task_id, {}, actor_id)
    if start_err then
        return nil, "start_cycle failed: " .. tostring(start_err.message or start_err)
    end
    return { task_id = result.task_id, started = true }
end

return M
