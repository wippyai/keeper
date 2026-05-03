-- keeper.git.tools:rebuild — thin wrapper that asks the service to rebuild.
local git_client = require("git_client")

local M = {}

function M.handler(params)
    params = params or {}
    return git_client.rebuild({
        mode        = params.mode or "manual",
        model       = params.model,
        max_changes = params.max_changes,
        tracked_dirs = params.tracked_dirs,
        diff_base   = params.diff_base,
    })
end

return M
