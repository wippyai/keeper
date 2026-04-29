local ctx = require("ctx")
local lifecycle = require("lifecycle")

local function handler(args)
    args = args or {}
    local result, err = lifecycle.handle_phase_failure(
        args.task_id or ctx.get("task_id"),
        args.phase or ctx.get("phase"),
        args.error or args.message or args
    )
    if err then
        return nil, err
    end
    return result
end

return { handler = handler }
