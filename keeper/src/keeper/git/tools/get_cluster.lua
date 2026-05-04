-- keeper.git.tools:get_cluster — full cluster detail for review.
local git_client = require("git_client")

local M = {}

function M.handler(params)
    params = params or {}
    return git_client.get_cluster(params.cluster_id)
end

return M
