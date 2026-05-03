-- Cluster split helpers.
--
-- propose_by_prefix(cluster, depth)
--   Pure: groups changes by the first `depth` segments of their path.
--   Returns { {title, plain_summary, change_ids} }
--
-- propose_by_kind(cluster)
--   Pure: groups by file kind (.lua / .vue / .yaml / migration / test / fs / etc).
--
-- apply_split(snap, source_cluster_id, groups, build_cluster_fn)
--   Drops change_ids in `groups` from the source cluster, creates one new
--   cluster per group via the caller-supplied build_cluster_fn, inserts them
--   into the snapshot, and removes the source cluster if it ends up empty.

local M = {}

local function path_segments(path, depth)
    local parts = {}
    for seg in path:gmatch("[^/]+") do table.insert(parts, seg) end
    if depth and #parts > depth then
        local prefix = {}
        for i = 1, depth do table.insert(prefix, parts[i]) end
        return table.concat(prefix, "/") .. "/"
    end
    return path
end

-- Group by the first `depth` path segments. depth=2 → "src/keeper/" etc.
function M.propose_by_prefix(cluster, depth)
    depth = depth or 2
    local groups = {}
    for _, ch in ipairs(cluster.changes or {}) do
        local key = path_segments(ch.path or "", depth)
        groups[key] = groups[key] or { title = key, change_ids = {} }
        table.insert(groups[key].change_ids, ch.change_id)
    end
    local out = {}
    for _, g in pairs(groups) do
        table.insert(out, {
            title         = g.title,
            plain_summary = string.format("%d files under %s", #g.change_ids, g.title),
            change_ids    = g.change_ids,
        })
    end
    table.sort(out, function(a, b) return #a.change_ids > #b.change_ids end)
    return out
end

-- Group by file kind. Buckets:
--   migrations: paths matching /migrations/ or /_migrations/
--   tests     : *_test.lua / :test ids
--   schemas   : _index.yaml entries
--   frontend  : *.vue, *.ts, *.js
--   lua_src   : *.lua (not test)
--   other     : everything else
function M.propose_by_kind(cluster)
    local buckets = {}
    local function bucket(name, label, ch)
        buckets[name] = buckets[name] or { title = label, change_ids = {} }
        table.insert(buckets[name].change_ids, ch.change_id)
    end
    for _, ch in ipairs(cluster.changes or {}) do
        local p = ch.path or ""
        if p:find("/migrations/") or p:find("_migrations/") then
            bucket("migrations", "Migrations", ch)
        elseif p:find("_test%.lua$") or p:find(":test") then
            bucket("tests", "Tests", ch)
        elseif p:find("_index%.yaml$") then
            bucket("schemas", "Registry _index.yaml", ch)
        elseif p:find("%.vue$") or p:find("%.ts$") or p:find("%.js$") then
            bucket("frontend", "Frontend", ch)
        elseif p:find("%.lua$") then
            bucket("lua_src", "Lua source", ch)
        else
            bucket("other", "Other", ch)
        end
    end
    local out = {}
    for _, b in pairs(buckets) do
        table.insert(out, {
            title         = b.title,
            plain_summary = string.format("%d files in %s", #b.change_ids, b.title),
            change_ids    = b.change_ids,
        })
    end
    table.sort(out, function(a, b) return #a.change_ids > #b.change_ids end)
    return out
end

-- Validate group spec: every change_id must belong to the source cluster, no
-- duplicates across groups, no empty groups, no missing titles.
function M.validate_groups(source_cluster, groups)
    if not groups or #groups == 0 then return false, "no groups" end
    if #groups > 20 then return false, "too many groups (max 20)" end

    local valid = {}
    for _, ch in ipairs(source_cluster.changes or {}) do
        valid[ch.change_id] = true
    end
    -- fall back to change_ids when changes[] not populated
    if next(valid) == nil then
        for _, cid in ipairs(source_cluster.change_ids or {}) do valid[cid] = true end
    end

    local seen = {}
    for i, g in ipairs(groups) do
        if not g.title or g.title == "" then return false, "group " .. i .. " missing title" end
        if not g.change_ids or #g.change_ids == 0 then return false, "group " .. i .. " has no change_ids" end
        for _, cid in ipairs(g.change_ids) do
            if not valid[cid] then return false, "change_id " .. cid .. " not in source cluster" end
            if seen[cid] then return false, "change_id " .. cid .. " is in multiple groups" end
            seen[cid] = true
        end
    end
    return true, nil
end

-- Apply a split. Returns { new_cluster_ids = [...], removed_source = bool }
-- build_cluster_fn signature: function(group_spec, change_list) -> cluster
function M.apply_split(snap, source_cluster_id, groups, build_cluster_fn, changes_lookup)
    local source = snap.clusters[source_cluster_id]
    if not source then return nil, "unknown source cluster" end

    -- Build per-change lookup from source's compact `changes` (if present)
    local change_index = {}
    for _, ch in ipairs(source.changes or {}) do
        change_index[ch.change_id] = ch
    end
    -- Augment from caller-supplied lookup (path/op/added/removed-rich rows)
    if changes_lookup then
        for cid, full in pairs(changes_lookup) do
            change_index[cid] = full
        end
    end

    local consumed = {}
    local new_ids = {}
    for _, g in ipairs(groups) do
        local change_list = {}
        for _, cid in ipairs(g.change_ids) do
            consumed[cid] = true
            local ch = change_index[cid]
            if ch then table.insert(change_list, ch) end
        end
        local cluster = build_cluster_fn(g, change_list)
        if cluster then
            cluster.split_from = source_cluster_id
            snap.clusters[cluster.id] = cluster
            table.insert(snap.cluster_order, cluster.id)
            table.insert(new_ids, cluster.id)
        end
    end

    -- Remove consumed change_ids from source. If empty, drop source.
    local remaining_ids, remaining_changes = {}, {}
    for _, cid in ipairs(source.change_ids or {}) do
        if not consumed[cid] then table.insert(remaining_ids, cid) end
    end
    for _, ch in ipairs(source.changes or {}) do
        if not consumed[ch.change_id] then table.insert(remaining_changes, ch) end
    end
    local removed_source = false
    if #remaining_ids == 0 then
        snap.clusters[source_cluster_id] = nil
        local kept = {}
        for _, id in ipairs(snap.cluster_order or {}) do
            if id ~= source_cluster_id then table.insert(kept, id) end
        end
        snap.cluster_order = kept
        removed_source = true
    else
        source.change_ids = remaining_ids
        source.changes = remaining_changes
        source.stats = source.stats or {}
        source.stats.files = #remaining_changes
    end

    return { new_cluster_ids = new_ids, removed_source = removed_source }, nil
end

return M
