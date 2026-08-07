local ctx = require("ctx")
local audit = require("audit")
local task_mutations = require("task_mutations")

local M = {}

function M.write(task_id, params)
    if not task_id or task_id == "" then
        return nil, "No active task context"
    end

    params = params or {}
    if not params.content or params.content == "" then
        return nil, "spec content is required"
    end

    local result, err = task_mutations.write_spec(task_id, params)
    if err then return nil, err end
    return "Specification saved (rev " .. result.revision .. "). Proceed to implementation."
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
