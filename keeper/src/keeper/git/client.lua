local time = require("time")
local uuid = require("uuid")
local consts = require("git_consts")

local M = {}

local function new_id()
    local id, err = uuid.v4()
    if err then error("uuid generation failed: " .. err) end
    return id
end

local function send_and_wait(operation, args, timeout)
    timeout = timeout or "10s"

    local reply_topic = "keeper.git.response." .. new_id()
    local reply_channel = process.listen(reply_topic)

    local sent = process.send(consts.PROCESS_NAMES.SERVICE, consts.TOPICS.COMMANDS, {
        operation  = operation,
        args       = args or {},
        id         = new_id(),
        respond_to = reply_topic,
    })
    if not sent then return nil, consts.ERRORS.MAILBOX_SEND_FAILED end

    local timeout_ch = time.after(timeout)
    local result = channel.select({
        reply_channel:case_receive(),
        timeout_ch:case_receive(),
    })

    if result.channel == timeout_ch then
        return nil, consts.ERRORS.MAILBOX_TIMEOUT .. " after " .. timeout
    end

    local response = result.value
    if not response then return nil, "empty response" end
    if not response.success then return nil, response.error or "operation failed" end
    return response.result, nil
end

function M.list_clusters(timeout)
    return send_and_wait(consts.OPERATIONS.LIST_CLUSTERS, {}, timeout)
end

function M.get_cluster(cluster_id, timeout)
    return send_and_wait(consts.OPERATIONS.GET_CLUSTER, { cluster_id = cluster_id }, timeout)
end

function M.set_decision(cluster_id, decision, timeout)
    return send_and_wait(consts.OPERATIONS.SET_DECISION,
        { cluster_id = cluster_id, decision = decision }, timeout)
end

function M.update_recommendation(cluster_id, recommendation_id, state, timeout)
    return send_and_wait(consts.OPERATIONS.UPDATE_RECOMMENDATION,
        { cluster_id = cluster_id, recommendation_id = recommendation_id, state = state }, timeout)
end

-- AI flows return immediately with { started=true, request_id }. The FE
-- correlates the relay event by request_id; the Lua client doesn't await it.
function M.explain_recommendation(cluster_id, recommendation_id, opts, timeout)
    opts = opts or {}
    return send_and_wait(consts.OPERATIONS.EXPLAIN_RECOMMENDATION, {
        cluster_id = cluster_id, recommendation_id = recommendation_id,
        force = opts.force, model = opts.model, request_id = opts.request_id,
    }, timeout)
end

function M.rebuild(args, timeout)
    return send_and_wait(consts.OPERATIONS.REBUILD, args or {}, timeout)
end

function M.suggest_split(cluster_id, opts, timeout)
    opts = opts or {}
    return send_and_wait(consts.OPERATIONS.SUGGEST_SPLIT, {
        cluster_id = cluster_id,
        mode       = opts.mode or "ai",   -- "ai" | "by_prefix" | "by_kind"
        depth      = opts.depth,
        model      = opts.model,
        request_id = opts.request_id,
    }, timeout)
end

function M.split_cluster(cluster_id, groups, timeout)
    return send_and_wait(consts.OPERATIONS.SPLIT_CLUSTER,
        { cluster_id = cluster_id, groups = groups }, timeout or "30s")
end

function M.push(cluster_ids, message, timeout)
    return send_and_wait(consts.OPERATIONS.PUSH,
        { cluster_ids = cluster_ids, message = message }, timeout or "120s")
end

return M
