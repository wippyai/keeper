-- Split handlers: suggest_split (deterministic + AI) and split_cluster (apply).

local consts = require("git_consts")
local split_lib = require("split_lib")
local suggest_split_flow = require("suggest_split_flow")
local cluster_factory = require("cluster_factory")
local async_task = require("async_task")

local M = {}

function M.suggest(payload, deps)
    local args = payload.args or {}
    local cid = args.cluster_id
    if not cid then
        return deps.reply(payload, nil, consts.ERRORS.MISSING_REQUIRED .. ": cluster_id")
    end
    local cluster = deps.state:get_cluster(cid)
    if not cluster then return deps.reply(payload, nil, consts.ERRORS.UNKNOWN_CLUSTER) end

    local mode = args.mode or "ai"
    if mode == "by_prefix" then
        return deps.reply(payload, {
            mode = "by_prefix",
            groups = split_lib.propose_by_prefix(cluster, args.depth or 2),
        })
    end
    if mode == "by_kind" then
        return deps.reply(payload, {
            mode = "by_kind",
            groups = split_lib.propose_by_kind(cluster),
        })
    end
    if mode ~= "ai" then
        return deps.reply(payload, nil, "unknown split mode: " .. tostring(mode))
    end

    local request_id = async_task.run({
        request_id     = args.request_id,
        started_event  = consts.EVENTS.SUGGEST_SPLIT_STARTED,
        finished_event = consts.EVENTS.SUGGEST_SPLIT_FINISHED,
        failed_event   = consts.EVENTS.SUGGEST_SPLIT_FAILED,
        started_data   = { cluster_id = cid },
        relay          = deps.relay,
        log            = deps.log,
        work = function()
            local result = suggest_split_flow.run(cluster, { model = args.model })
            if not result.ok then
                return false, { cluster_id = cid, error = result.error }
            end
            return true, {
                cluster_id = cid, mode = "ai",
                groups = result.groups, model = result.model,
                duration_ms = result.duration_ms,
            }
        end,
    })

    deps.reply(payload, { mode = "ai", started = true, request_id = request_id })
end

function M.apply(payload, deps)
    local args = payload.args or {}
    local cid, groups = args.cluster_id, args.groups
    if not cid or type(groups) ~= "table" then
        return deps.reply(payload, nil, consts.ERRORS.MISSING_REQUIRED .. ": cluster_id, groups[]")
    end
    local source = deps.state:get_cluster(cid)
    if not source then return deps.reply(payload, nil, consts.ERRORS.UNKNOWN_CLUSTER) end

    local ok, verr = split_lib.validate_groups(source, groups)
    if not ok then return deps.reply(payload, nil, "invalid groups: " .. verr) end

    local result, err = split_lib.apply_split(deps.state.snapshot, cid, groups,
        function(g, change_list)
            return cluster_factory.build(g, change_list, {
                id_prefix = "cl-",
                suspect   = source.is_suspect,
            })
        end)
    if err then return deps.reply(payload, nil, err) end

    if not result.removed_source then
        cluster_factory.refresh_metadata(deps.state.snapshot.clusters[cid])
    end
    deps.state:reorder()
    deps.state:persist(deps.log)

    local summary = deps.state:summary()
    summary.split_result = {
        new_cluster_ids = result.new_cluster_ids,
        removed_source  = result.removed_source,
    }
    deps.reply(payload, summary)
end

return M
