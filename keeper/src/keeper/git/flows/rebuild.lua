-- Git rebuild workflow.
--
-- Scans the working tree, peels suspects via the heuristic detector, asks
-- the AI clusterer (parallel by path-prefix bucket) to topical-group the
-- rest, then assembles cluster objects via cluster_factory and persists.
--
-- Returns (snapshot, run_row, nil) on success, (nil, nil, err) on failure.

local time = require("time")
local uuid = require("uuid")
local logger = require("logger")
local consts = require("git_consts")
local run_repo = require("run_repo")
local git_scan = require("git_scan")
local suspect = require("suspect")
local clusterer_parallel = require("clusterer_parallel")
local cluster_factory = require("cluster_factory")
local snapshot_lib = require("snapshot")

local log = logger:named("keeper.git.rebuild")

local M = {}

local function enforce_max_changes(changes: unknown[]?, max_changes: unknown)
    local max = tonumber(max_changes or consts.DEFAULT_MAX_CHANGES)
    if not max or max <= 0 then return true, nil end
    local count = #(changes or {})
    if count > max then
        return false, string.format(
            "too many git changes (%d > %d); narrow tracked_dirs or raise max_changes",
            count, max)
    end
    return true, nil
end

local function now_iso()
    return time.now():format("2006-01-02T15:04:05Z")
end

local function gen_id(prefix)
    local id, err = uuid.v7()
    if err then error("uuid generation failed: " .. err) end
    return (prefix or "") .. id
end

function M._enforce_max_changes(changes: unknown[]?, max_changes: unknown)
    return enforce_max_changes(changes, max_changes)
end

-- Manual mode: deterministic grouping by 2nd-level path prefix, no LLM.
local function manual_cluster(topic_changes)
    local groups = {}
    for _, ch in ipairs(topic_changes) do
        local key = (ch.target:match("^([^/]+/[^/]+)") or "root") .. "/"
        groups[key] = groups[key] or { title = key, change_ids = {} }
        table.insert(groups[key].change_ids, ch.change_id)
    end
    local list = {}
    for _, g in pairs(groups) do
        table.insert(list, {
            title         = g.title,
            plain_summary = string.format("%d files under %s (manual grouping)", #g.change_ids, g.title),
            change_ids    = g.change_ids,
        })
    end
    return { ok = true, clusters = list, model = "manual", duration_ms = 0 }
end

local function ai_cluster(topic_changes, opts)
    local cluster_input = {}
    for _, ch in ipairs(topic_changes) do
        table.insert(cluster_input, {
            change_id = ch.change_id, op = ch.op,
            category = ch.category, target = ch.target,
        })
    end
    return clusterer_parallel.run(cluster_input, { model = opts.model })
end

local function build_topic_clusters(specs, changes_by_id)
    local clusters = {}
    for _, spec in ipairs(specs) do
        local change_list = {}
        for _, cid in ipairs(spec.change_ids) do
            local ch = changes_by_id[cid]
            if ch then table.insert(change_list, ch) end
        end
        local c = cluster_factory.build(spec, change_list, { id_prefix = "cl-" })
        if c then table.insert(clusters, c) end
    end
    return clusters
end

local function build_orphan_cluster(orphan_pairs, changes_by_id)
    if #orphan_pairs == 0 then return nil end
    local change_ids, recs, change_list = {}, {}, {}
    for i, op in ipairs(orphan_pairs) do
        table.insert(change_ids, op.change.change_id)
        table.insert(recs, {
            id        = "rec-orphan-" .. i,
            severity  = consts.SEVERITY.WARN,
            text      = op.change.target .. " — " .. op.reason,
            fix_hint  = "Discard, or assign to a topic cluster.",
            change_id = op.change.change_id,
        })
        local ch = changes_by_id[op.change.change_id]
        if ch then table.insert(change_list, ch) end
    end
    return cluster_factory.build(
        {
            title         = "Suspect changes",
            plain_summary = "Entries that look out of place — scratch namespaces, debug dumps, .bak files, OS metadata.",
            change_ids    = change_ids,
        },
        change_list,
        {
            id_prefix      = "cl-suspect-",
            suspect        = true,
            verdict_text   = "Review individually; suspects can still be marked ready and pushed if intentional.",
            extra_recs     = recs,
            skip_detectors = true,
        }
    )
end

-- opts: { mode = "manual" | "ai" (default ai), model?, sync_first?, tracked_dirs?, diff_base? }
function M.run(opts)
    opts = opts or {}
    local started_at = now_iso()
    local run_id = gen_id("run-")

    local _, ierr = run_repo.insert({
        run_id = run_id, started_at = started_at,
        status = consts.RUN_STATUS.RUNNING,
        journal_size = 0, cluster_count = 0, payload = {},
    })
    if ierr then
        log:warn("rebuild: failed to insert run row (continuing)", { error = ierr })
    end

    if opts.sync_first then
        local before_sync, before_cfg = git_scan.list_changes({
            tracked_dirs = opts.tracked_dirs,
            diff_base    = opts.diff_base,
        })
        if not before_sync then
            local serr = "git_scan pre-sync: " .. tostring(before_cfg or "returned nil")
            run_repo.update(run_id, {
                finished_at = now_iso(), status = consts.RUN_STATUS.FAILED, error = serr,
            })
            return nil, nil, serr
        end

        local ok, blockers = git_scan.sync_preflight(before_sync)
        if not ok then
            local paths = {}
            for _, b in ipairs(blockers or {}) do
                table.insert(paths, tostring(b.path or "?"))
            end
            local berr = "refusing sync_first: managed registry files are dirty (" ..
                table.concat(paths, ", ") .. ")"
            run_repo.update(run_id, {
                finished_at = now_iso(), status = consts.RUN_STATUS.FAILED, error = berr,
            })
            return nil, nil, berr
        end

        local _, sync_err = git_scan.sync_registry_to_fs()
        if sync_err then
            local sync_msg = "sync_to_fs failed: " .. tostring(sync_err)
            run_repo.update(run_id, {
                finished_at = now_iso(), status = consts.RUN_STATUS.FAILED, error = sync_msg,
            })
            return nil, nil, sync_msg
        end
    end

    local pending, cfg = git_scan.list_changes({
        tracked_dirs = opts.tracked_dirs,
        diff_base    = opts.diff_base,
    })
    if not pending then
        local perr = "git_scan: " .. tostring(cfg or "returned nil")
        run_repo.update(run_id, {
            finished_at = now_iso(), status = consts.RUN_STATUS.FAILED, error = perr,
        })
        return nil, nil, perr
    end

    local max_ok, max_err = enforce_max_changes(pending, opts.max_changes)
    if not max_ok then
        run_repo.update(run_id, {
            finished_at = now_iso(), status = consts.RUN_STATUS.FAILED, error = max_err,
        })
        return nil, nil, max_err
    end

    local changes_by_id = {}
    for _, ch in ipairs(pending) do changes_by_id[ch.change_id] = ch end

    local topic_changes, orphan_pairs = suspect.partition(pending)

    local result = (opts.mode == "manual")
        and manual_cluster(topic_changes)
        or  ai_cluster(topic_changes, opts)

    if not result.ok then
        run_repo.update(run_id, {
            finished_at = now_iso(), status = consts.RUN_STATUS.FAILED, error = result.error,
        })
        return nil, nil, "clusterer: " .. result.error
    end

    local snap = snapshot_lib.empty()
    snap.run_id = run_id
    snap.built_at = now_iso()
    snap.journal_size_at_build = #pending
    snap.ai_model = result.model
    snap.git_config = cfg or nil

    for _, c in ipairs(build_topic_clusters(result.clusters, changes_by_id)) do
        snap.clusters[c.id] = c
        table.insert(snap.cluster_order, c.id)
    end

    local orphan = build_orphan_cluster(orphan_pairs, changes_by_id)
    if orphan then
        snap.clusters[orphan.id] = orphan
        table.insert(snap.cluster_order, orphan.id)
        for _, op in ipairs(orphan_pairs) do
            table.insert(snap.orphans, op.change.change_id)
        end
    end

    snapshot_lib.reorder(snap)

    local row = {
        run_id        = run_id,
        started_at    = started_at,
        finished_at   = now_iso(),
        status        = consts.RUN_STATUS.FINISHED,
        journal_size  = #pending,
        cluster_count = #snap.cluster_order,
        ai_model      = result.model,
        payload       = snap,
    }
    local _, uerr = run_repo.update(run_id, {
        finished_at   = row.finished_at,
        status        = row.status,
        journal_size  = row.journal_size,
        cluster_count = row.cluster_count,
        ai_model      = row.ai_model,
        payload       = snap,
    })
    if uerr then
        log:warn("run_repo.update failed (snapshot still in memory)", { error = uerr })
    end
    local cerr = run_repo.cleanup_old(consts.RUN_HISTORY_KEEP)
    if cerr then log:debug("run_repo.cleanup_old failed", { error = cerr }) end

    log:info("rebuild ok", {
        run_id = run_id, clusters = #snap.cluster_order,
        topic_changes = #topic_changes, orphans = #orphan_pairs,
        duration_ms = result.duration_ms,
    })

    return snap, row, nil
end

return M
