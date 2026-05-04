-- keeper.git.tools:push — MCP-callable bulk push wrapper.
-- Forwards to the keeper.git service which owns snapshot state and routes
-- through the shared push_flow library. Result shape:
--   { ok=bool, results=[{cluster_id, ok, version?, error?}], pushed=N, failed=N }
local git_client = require("git_client")

local M = {}

function M.handler(params)
    params = params or {}
    return git_client.push(params.cluster_ids, params.message, nil, {
        dry_run = params.dry_run == true,
    })
end

return M
