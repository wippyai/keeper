local consts = require("git_consts")

local M = {}

local function collect_source(cluster)
    if cluster.source and cluster.source ~= "" then return cluster.source end
    local source = nil
    for _, ch in ipairs(cluster.changes or {}) do
        local s = ch.source or "unknown"
        if not source then source = s
        elseif source ~= s then return "mixed" end
    end
    return source or "unknown"
end

local function collect_changeset_ids(cluster)
    local set, out = {}, {}
    for _, cs in ipairs(cluster.changeset_ids or {}) do
        if cs and cs ~= "" and not set[cs] then
            set[cs] = true
            table.insert(out, cs)
        end
    end
    for _, ch in ipairs(cluster.changes or {}) do
        local cs = ch.changeset_id
        if cs and cs ~= "" and not set[cs] then
            set[cs] = true
            table.insert(out, cs)
        end
    end
    table.sort(out)
    return out
end

local function primary_changeset(cluster, cs_ids)
    if cluster.primary_changeset_id and cluster.primary_changeset_id ~= "" then
        return cluster.primary_changeset_id
    end
    if #cs_ids == 1 then return cs_ids[1] end
    return nil
end

local function open_blocking_count(cluster)
    local n = 0
    for _, rec in ipairs(cluster.recommendations or {}) do
        if rec.severity == consts.SEVERITY.BLOCK
            and (rec.state or consts.REC_STATES.OPEN) == consts.REC_STATES.OPEN then
            n = n + 1
        end
    end
    return n
end

function M.blockers(cluster)
    if not cluster then return { "cluster missing" } end

    local blockers = {}
    local source = collect_source(cluster)
    local cs_ids = collect_changeset_ids(cluster)
    local primary = primary_changeset(cluster, cs_ids)

    if source == "git_scan" then
        table.insert(blockers,
            "working tree scan clusters are review-only; create or use a Keeper changeset before pushing")
    elseif #cs_ids > 1 then
        table.insert(blockers, "cluster spans " .. #cs_ids .. " changesets; split first")
    elseif not primary or primary == "" then
        table.insert(blockers, "cluster has no resolvable changeset_id")
    end

    for _, ch in ipairs(cluster.changes or {}) do
        if ch.category == "registry" and ch.managed_namespace == false then
            table.insert(blockers, "cluster contains unmanaged registry namespace")
            break
        end
    end

    local blocking = open_blocking_count(cluster)
    if blocking > 0 then
        table.insert(blockers, "cluster has " .. blocking .. " open blocking recommendation(s)")
    end

    return blockers
end

function M.apply(cluster)
    local blockers = M.blockers(cluster)
    cluster.push_blockers = blockers
    cluster.pushable = #blockers == 0
    return cluster
end

M._collect_source = collect_source
M._collect_changeset_ids = collect_changeset_ids

return M
