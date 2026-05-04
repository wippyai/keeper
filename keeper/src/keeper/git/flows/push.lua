-- Per-cluster push helper, shared between the in-process service handler and
-- the MCP-callable tool. Takes a cluster object (already loaded from the
-- snapshot), validates its push-readiness, and routes through existing
-- keeper.state.tools:push.

local funcs = require("funcs")
local logger = require("logger")
local consts = require("git_consts")
local push_policy = require("push_policy")

local log = logger:named("keeper.git.flows.push")

local M = {}

local function branch_for(changeset_id)
    return "ws/" .. changeset_id
end

local function cluster_stats(cluster)
    local stats = cluster.stats or {}
    return {
        changes    = #(cluster.changes or {}),
        files      = stats.files or #(cluster.changes or {}),
        namespaces = stats.namespaces or {},
        added      = stats.added or 0,
        removed    = stats.removed or 0,
    }
end

function M.push_blockers(cluster)
    return push_policy.blockers(cluster)
end

-- Build a non-mutating publish plan for a single cluster. This is the shape UI
-- and MCP should use for review/confirmation before calling push_cluster.
function M.plan_cluster(cluster, message)
    if not cluster then
        return {
            ok = false,
            pushable = false,
            error = "cluster missing",
            blockers = { "cluster missing" },
        }
    end

    local blockers = M.push_blockers(cluster)
    local primary = cluster.primary_changeset_id
    local approved = cluster.decision == consts.DECISIONS.APPROVED
    local decision_blockers = {}
    if not approved then
        table.insert(decision_blockers, "cluster is not approved (decision=" .. tostring(cluster.decision) .. ")")
    end
    for _, b in ipairs(blockers) do table.insert(decision_blockers, b) end

    return {
        ok                   = approved and #blockers == 0,
        cluster_id           = cluster.id,
        title                = cluster.title,
        decision             = cluster.decision,
        verdict              = cluster.verdict,
        source               = cluster.source,
        changeset_ids        = cluster.changeset_ids or {},
        primary_changeset_id = primary,
        branch               = primary and branch_for(primary) or nil,
        message              = message,
        stats                = cluster_stats(cluster),
        pushable             = #blockers == 0,
        approved             = approved,
        blockers             = decision_blockers,
    }
end

-- Push a single cluster. Returns (push_result, nil) on success or (nil, err).
function M.push_cluster(cluster, message)
    if not cluster then return nil, "cluster missing" end
    if cluster.decision ~= consts.DECISIONS.APPROVED then
        return nil, "cluster is not approved (decision=" .. tostring(cluster.decision) .. ")"
    end

    local blockers = M.push_blockers(cluster)
    if #blockers > 0 then
        return nil, table.concat(blockers, "; ")
    end

    local primary = cluster.primary_changeset_id
    local f = funcs.new()
    local result, err = f:call("keeper.state.tools:push", {
        branch  = branch_for(primary),
        message = message,
    })
    if err then return nil, err end
    if type(result) == "table" and result.success == false then
        return nil, result.error or "push failed"
    end
    return result, nil
end

-- Push a list of clusters in order. Snapshot mutator is a callback (cluster_id, decision)
-- so this library doesn't need to know about service internals.
function M.push_many(clusters_by_id, cluster_ids, message, mark_pushed_fn, opts)
    opts = opts or {}
    local results, pushed, failed = {}, 0, 0
    for _, cid in ipairs(cluster_ids or {}) do
        local cluster = clusters_by_id[cid]
        if not cluster then
            failed = failed + 1
            table.insert(results, { cluster_id = cid, ok = false, error = "unknown cluster_id" })
        else
            if opts.dry_run then
                local plan = M.plan_cluster(cluster, message)
                if not plan.ok then failed = failed + 1 end
                table.insert(results, plan)
            else
                local res, err = M.push_cluster(cluster, message)
                if err then
                    failed = failed + 1
                    table.insert(results, { cluster_id = cid, ok = false, error = err })
                    log:warn("cluster push failed", { cluster_id = cid, error = err })
                else
                    pushed = pushed + 1
                    table.insert(results, {
                        cluster_id = cid,
                        ok = true,
                        version  = res and res.version,
                        added    = res and res.added,
                        modified = res and res.modified,
                        deleted  = res and res.deleted,
                    })
                    if mark_pushed_fn then mark_pushed_fn(cid) end
                end
            end
        end
    end
    return {
        ok      = failed == 0,
        dry_run = opts.dry_run == true,
        results = results,
        pushed  = pushed,
        failed  = failed,
    }
end

return M
