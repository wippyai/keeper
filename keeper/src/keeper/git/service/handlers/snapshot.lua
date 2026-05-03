-- Read-side handlers: list_clusters / get_cluster.

local consts = require("git_consts")

local M = {}

function M.list(payload, deps)
    deps.state:recompute_stale()
    deps.reply(payload, deps.state:summary())
end

function M.get(payload, deps)
    local id = (payload.args or {}).cluster_id
    if not id or id == "" then
        return deps.reply(payload, nil, consts.ERRORS.MISSING_REQUIRED .. ": cluster_id")
    end
    local c = deps.state:get_cluster(id)
    if not c then return deps.reply(payload, nil, consts.ERRORS.UNKNOWN_CLUSTER) end
    deps.reply(payload, c)
end

return M
