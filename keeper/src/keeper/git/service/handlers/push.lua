-- Bulk push handler: routes each approved cluster's primary changeset
-- through keeper.state.tools:push, marks each pushed cluster in the snapshot.

local consts = require("git_consts")
local push_flow = require("push_flow")

local M = {}

function M.handle(payload, deps)
    local args = payload.args or {}
    local cluster_ids = args.cluster_ids
    if type(cluster_ids) ~= "table" or #cluster_ids == 0 then
        return deps.reply(payload, nil, consts.ERRORS.MISSING_REQUIRED .. ": cluster_ids")
    end

    local result = push_flow.push_many(
        deps.state.snapshot.clusters or {},
        cluster_ids,
        args.message,
        function(cid)
            deps.state:mark_pushed(cid)
            deps.relay(consts.EVENTS.PUSHED, { cluster_id = cid })
        end,
        { dry_run = args.dry_run == true }
    )

    if args.dry_run ~= true then
        deps.state:persist(deps.log)
    end
    deps.reply(payload, result)
end

return M
