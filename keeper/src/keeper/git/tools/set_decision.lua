-- keeper.git.tools:set_decision — approve/skip/reopen a reviewed cluster.
local git_client = require("git_client")
local consts = require("git_consts")

local M = {}

function M.handler(params)
    params = params or {}
    if not consts.is_decision(params.decision) then
        return nil, "decision must be one of: pending, approved, skipped, pushed"
    end
    return git_client.set_decision(params.cluster_id, params.decision)
end

return M
