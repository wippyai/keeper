-- keeper.git.tools:pull_request — PR status, dry-run planning, and confirmed execution.
local git_client = require("git_client")

local M = {}

function M.handler(params)
    return git_client.pull_request(params or {})
end

return M
