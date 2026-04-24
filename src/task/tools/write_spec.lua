local ctx = require("ctx")
local audit = require("audit")
local nodes_writer = require("nodes_writer")
local nodes_reader = require("nodes_reader")
local task_writer = require("task_writer")

local M = {}

function M.write(task_id, params)
    if not task_id or task_id == "" then
        return nil, "No active task context"
    end

    params = params or {}
    if not params.content or params.content == "" then
        return nil, "spec content is required"
    end

    -- Determine next revision number by counting prior spec rows.
    local prior, _ = nodes_reader.by_type(task_id, "spec")
    local next_rev = tostring((prior and #prior or 0) + 1)
    local title = params.title or ("Implementation Specification (rev " .. next_rev .. ")")

    -- Supersede any prior active spec
    do
        local sql = require("sql")
        local db = sql.get("keeper.state:db")
        if db then
            db:execute(
                "UPDATE keeper_task_nodes SET status = 'superseded' WHERE task_id = ? AND type = 'spec' AND status = 'active'",
                { task_id }
            )
            db:release()
        end
    end

    local row, err = nodes_writer.record({
        task_id       = task_id,
        type          = "spec",
        discriminator = next_rev,
        title         = title,
        content       = params.content,
        content_type  = "text/markdown",
        status        = "active",
        visibility    = "user",
        metadata      = { is_final = params.is_final ~= false, revision = next_rev },
    })
    if err then return nil, "Failed to record spec node: " .. err end

    -- Also keep legacy keeper_tasks.spec in sync for code paths that still read it.
    local _, werr = task_writer.for_task(task_id)
        :update_task({ phase = "design", spec = params.content })
        :execute()
    if werr then return nil, "Failed to update task: " .. werr end

    return "Specification saved (rev " .. next_rev .. "). Proceed to implementation."
end

function M.handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "write_spec",
        discriminator = "write_spec",
        target        = params.title,
        content       = params.content,
        content_type  = "text/markdown",
        params        = { title = params.title, chars = params.content and #params.content or 0 },
        summarise = function(result, err)
            if err then return "write_spec failed: " .. tostring(err) end
            return "wrote spec (" .. (params.content and #params.content or 0) .. " chars)"
        end,
    }, function()
        return M.write(ctx.get("task_id"), params)
    end)
end

return M
