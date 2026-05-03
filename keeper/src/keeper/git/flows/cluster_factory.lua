-- Assembles cluster objects from a group spec and a list of changes.
--
-- Inputs:
--   spec        : { title, plain_summary?, change_ids[] }
--   change_list : full change rows (path/op/added/removed/ns_root/namespace/category)
--   opts        : {
--     id_prefix      = "cl-" | "cl-suspect-" | "cl-split-",
--     suspect        = bool,                  -- mark cluster.is_suspect
--     verdict_text   = "...",                 -- override verdict text
--     decision       = "pending",             -- override
--     extra_recs     = { ... }[],             -- e.g. orphan reasons
--     skip_detectors = bool,                  -- pure orphan clusters skip detector run
--     changeset_ids? = explicit list (rebuild path; cluster_factory normally derives)
--   }

local uuid = require("uuid")
local consts = require("git_consts")
local coverage = require("coverage")
local security_d = require("security_d")
local architecture = require("architecture")
local verdict_d = require("verdict_d")
local push_policy = require("push_policy")

local M = {}

local function gen_id(prefix)
    return (prefix or "cl-") .. (uuid.v7() or tostring(math.random(1, 1e9)))
end

local function compact_changes(change_list)
    local out = {}
    for _, ch in ipairs(change_list) do
        table.insert(out, {
            change_id         = ch.change_id,
            changeset_id      = ch.changeset_id,
            path              = ch.target or ch.path,
            op                = ch.op,
            category          = ch.category,
            ns_root           = ch.ns_root,
            namespace         = ch.namespace,
            managed_namespace = ch.managed_namespace,
            source            = ch.source,
            added             = ch.added or 0,
            removed           = ch.removed or 0,
        })
    end
    return out
end

local function compute_stats(change_list)
    local namespaces, added, removed = {}, 0, 0
    for _, ch in ipairs(change_list) do
        local ns = ch.namespace or ch.ns_root
        if ns and ns ~= "" then namespaces[ns] = true end
        added   = added   + (ch.added   or 0)
        removed = removed + (ch.removed or 0)
    end
    local ns_list = {}
    for n, _ in pairs(namespaces) do table.insert(ns_list, n) end
    table.sort(ns_list)
    return { files = #change_list, namespaces = ns_list, added = added, removed = removed }
end

local function collect_changeset_ids(change_list)
    local set, list = {}, {}
    for _, ch in ipairs(change_list) do
        local cs = ch.changeset_id
        if cs and cs ~= "" and not set[cs] then
            set[cs] = true
            table.insert(list, cs)
        end
    end
    table.sort(list)
    return list
end

local function collect_source(change_list)
    local source = nil
    for _, ch in ipairs(change_list) do
        local s = ch.source or "unknown"
        if not source then source = s
        elseif source ~= s then return "mixed" end
    end
    return source or "unknown"
end

local function compute_push_blockers(change_list, changeset_ids, source, recs)
    return push_policy.blockers({
        changes = compact_changes(change_list),
        changeset_ids = changeset_ids,
        primary_changeset_id = #changeset_ids == 1 and changeset_ids[1] or nil,
        source = source,
        recommendations = recs or {},
    })
end

local function run_detectors(change_list, extra_recs)
    local recs = {}
    for _, r in ipairs(coverage.run(change_list))     do table.insert(recs, r) end
    for _, r in ipairs(security_d.run(change_list))   do table.insert(recs, r) end
    for _, r in ipairs(architecture.run(change_list)) do table.insert(recs, r) end
    for _, r in ipairs(extra_recs or {})              do table.insert(recs, r) end
    for i, r in ipairs(recs) do
        r.id = r.id or ("rec-" .. i)
        r.state = r.state or consts.REC_STATES.OPEN
    end
    return recs
end

-- Assemble a cluster from a group spec + the change rows it owns.
function M.build(spec, change_list, opts)
    opts = opts or {}
    if #change_list == 0 then return nil end

    local recs
    if opts.skip_detectors then
        recs = opts.extra_recs or {}
        for i, r in ipairs(recs) do
            r.id = r.id or ("rec-" .. i)
            r.state = r.state or consts.REC_STATES.OPEN
        end
    else
        recs = run_detectors(change_list, opts.extra_recs)
    end

    local v, vt, imp
    if opts.suspect then
        -- Suspect clusters bypass verdict-from-recs and use a fixed shape.
        v   = consts.VERDICTS.CLOSER_LOOK
        vt  = opts.verdict_text or "Review individually."
        imp = consts.IMPORTANCE.SUSPECT
    else
        v, vt, imp = verdict_d.from_recommendations(recs, #change_list)
        if opts.verdict_text then vt = opts.verdict_text end
    end

    local cs_ids = opts.changeset_ids or collect_changeset_ids(change_list)
    local source = collect_source(change_list)
    local cluster = {
        id                   = gen_id(opts.id_prefix),
        title                = spec.title,
        plain_summary        = spec.plain_summary or "",
        importance           = imp,
        verdict              = v,
        verdict_text         = vt,
        decision             = opts.decision or consts.DECISIONS.PENDING,
        change_ids           = spec.change_ids,
        changes              = compact_changes(change_list),
        changeset_ids        = cs_ids,
        primary_changeset_id = #cs_ids == 1 and cs_ids[1] or nil,
        source               = source,
        pushable             = false,
        push_blockers        = {},
        recommendations      = recs,
        stats                = compute_stats(change_list),
        is_suspect           = opts.suspect or nil,
    }
    push_policy.apply(cluster)
    return cluster
end

function M.refresh_metadata(cluster)
    if not cluster then return nil end
    local changes = cluster.changes or {}
    local cs_ids = collect_changeset_ids(changes)
    cluster.stats = compute_stats(changes)
    cluster.changeset_ids = cs_ids
    cluster.primary_changeset_id = #cs_ids == 1 and cs_ids[1] or nil
    cluster.source = collect_source(changes)
    push_policy.apply(cluster)
    return cluster
end

-- Exposed for tests
M._compact_changes = compact_changes
M._compute_push_blockers = compute_push_blockers
M._compute_stats = compute_stats

return M
