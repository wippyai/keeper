-- Inverse of pipeline:execute. Delegates to step_runner.reverse, which walks the
-- original execute ledger in reverse and, per row, replays the recorded inverse
-- (when present) or the original handler with operation=down. Stays synchronous
-- for the same reason as execute.lua — the flow builder yields when called from
-- inside a dataflow and silently skips work.

local funcs       = require("funcs")
local step_runner = require("step_runner")

local function handler(params)
    params = params or {}
    return step_runner.reverse(params.execution, { funcs = funcs })
end

return { handler = handler }
