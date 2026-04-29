local lifecycle = require("lifecycle")

local function handler(args)
    args = args or {}
    local result = args.result or {
        status  = args.status,
        summary = args.summary or "nested exit probe",
    }
    return lifecycle.handle_exit(args.task_id, args.phase, result)
end

return { handler = handler }
