local ctx = require("ctx")
local audit = require("audit")
local nodes_writer = require("nodes_writer")

local M = {}

function M.save(task_id, params)
    if not task_id or task_id == "" then
        return nil, "No active task context"
    end

    params = params or {}
    if not params.key or params.key == "" then
        return nil, "key is required"
    end
    if not params.content or params.content == "" then
        return nil, "content is required"
    end

    local row, err = nodes_writer.record({
        task_id       = task_id,
        type          = "finding",
        discriminator = params.key,
        title         = params.key,
        content       = params.content,
        content_type  = "text/markdown",
        status        = "active",
        visibility    = "user",
        metadata      = { comment = params.comment },
    })
    if err then return nil, "Failed to save finding: " .. err end

    return "Finding saved: " .. params.key
end

function M.handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "save_context",
        discriminator = "save_context",
        target        = params.key,
        params        = { key = params.key, comment = params.comment },
        summarise = function(result, err)
            if err then return "save_context failed: " .. tostring(err) end
            return "saved finding: " .. (params.key or "?")
        end,
    }, function()
        return M.save(ctx.get("task_id"), params)
    end)
end

return M
