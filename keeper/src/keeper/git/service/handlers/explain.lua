-- Per-recommendation AI deep-dive. Cached results return inline; otherwise
-- the LLM call goes async via async_task and the FE awaits the relay event.

local consts = require("git_consts")
local explain_flow = require("explain_flow")
local async_task = require("async_task")

local M = {}

local function find_rec(cluster, rid)
    for _, r in ipairs(cluster.recommendations or {}) do
        if r.id == rid then return r end
    end
end

function M.handle(payload, deps)
    local args = payload.args or {}
    local cid, rid = args.cluster_id, args.recommendation_id
    if not cid or not rid then
        return deps.reply(payload, nil,
            consts.ERRORS.MISSING_REQUIRED .. ": cluster_id, recommendation_id")
    end

    local cluster = deps.state:get_cluster(cid)
    if not cluster then return deps.reply(payload, nil, consts.ERRORS.UNKNOWN_CLUSTER) end

    local rec = find_rec(cluster, rid)
    if not rec then return deps.reply(payload, nil, "unknown recommendation_id") end

    if rec.detail and not args.force then
        return deps.reply(payload, {
            cluster_id = cid, recommendation_id = rid,
            text = rec.detail, model = rec.detail_model, cached = true,
        })
    end

    local change_list = cluster.changes or {}
    local request_id = async_task.run({
        request_id     = args.request_id,
        started_event  = consts.EVENTS.EXPLAIN_STARTED,
        finished_event = consts.EVENTS.EXPLAIN_FINISHED,
        failed_event   = consts.EVENTS.EXPLAIN_FAILED,
        started_data   = { cluster_id = cid, recommendation_id = rid },
        relay          = deps.relay,
        log            = deps.log,
        work = function()
            local result = explain_flow.run(cluster, rec, change_list, { model = args.model })
            if not result.ok then
                return false, { cluster_id = cid, recommendation_id = rid, error = result.error }
            end
            rec.detail = result.text
            rec.detail_model = result.model
            deps.state:persist(deps.log)
            return true, {
                cluster_id = cid, recommendation_id = rid,
                text = result.text, model = result.model, duration_ms = result.duration_ms,
            }
        end,
    })

    deps.reply(payload, {
        cluster_id = cid, recommendation_id = rid, started = true, request_id = request_id,
    })
end

return M
