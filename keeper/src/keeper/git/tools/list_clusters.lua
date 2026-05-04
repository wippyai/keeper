-- keeper.git.tools:list_clusters — MCP-callable review surface.
local git_client = require("git_client")

local M = {}

function M.handler()
    return git_client.list_clusters()
end

return M
