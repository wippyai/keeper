-- Mutation handlers for cluster.decision and recommendation.state.

local consts = require("git_consts")

local M = {}

function M.set_decision(payload, deps)
    local args = payload.args or {}
    local id, decision = args.cluster_id, args.decision
    if not id or id == "" then
        return deps.reply(payload, nil, consts.ERRORS.MISSING_REQUIRED .. ": cluster_id")
    end
    if not decision or decision == "" then
        return deps.reply(payload, nil, consts.ERRORS.MISSING_REQUIRED .. ": decision")
    end
    local ok, err = deps.state:set_decision(id, decision)
    if not ok then return deps.reply(payload, nil, err) end
    deps.state:persist(deps.log)
    deps.relay(consts.EVENTS.DECISION_CHANGED, { cluster_id = id, decision = decision })
    deps.reply(payload, { cluster_id = id, decision = decision })
end

function M.update_recommendation(payload, deps)
    local args = payload.args or {}
    local cid, rid, state = args.cluster_id, args.recommendation_id, args.state
    if not cid or not rid or not state then
        return deps.reply(payload, nil,
            consts.ERRORS.MISSING_REQUIRED .. ": cluster_id, recommendation_id, state")
    end
    local ok, err = deps.state:update_recommendation(cid, rid, state)
    if not ok then return deps.reply(payload, nil, err) end
    deps.state:persist(deps.log)
    deps.reply(payload, { cluster_id = cid, recommendation_id = rid, state = state })
end

return M
