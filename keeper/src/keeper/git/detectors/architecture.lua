local consts = require("git_consts")

-- Architecture-fit detector. Pure heuristics (no LLM):
--   - touches keeper governance / changeset / state code
--   - mixes too many top-level namespaces (signals scope creep)
--   - cluster size threshold (large = suggest split)

local M = {}

local function ns_root(target)
    if not target or target == "" then return "" end
    local m = target:match("^([^.:/]+)")
    return m or ""
end

local function touches_governance(target)
    if not target then return false end
    return target:find("^keeper%.gov") ~= nil
        or target:find("^keeper%.changeset") ~= nil
        or target:find("^keeper%.state") ~= nil
        or target:find("^keeper%.git") ~= nil
end

function M.run(cluster_changes)
    local recs = {}
    local namespaces = {}
    local gov_hits = {}
    for _, ch in ipairs(cluster_changes or {}) do
        local root = ns_root(ch.target)
        if root ~= "" then namespaces[root] = (namespaces[root] or 0) + 1 end
        if touches_governance(ch.target) then table.insert(gov_hits, ch) end
    end

    local ns_count = 0
    for _ in pairs(namespaces) do ns_count = ns_count + 1 end

    if #gov_hits > 0 then
        table.insert(recs, {
            severity = consts.SEVERITY.WARN,
            text = "Cluster modifies keeper governance code.",
            fix_hint = "Verify lifecycle invariants and changeset rollback paths manually.",
            change_id = gov_hits[1].change_id,
        })
    end

    if ns_count >= 4 then
        table.insert(recs, {
            severity = consts.SEVERITY.WARN,
            text = string.format("Cluster spans %d top-level namespaces — looks like scope creep.", ns_count),
            fix_hint = "Consider splitting per-namespace.",
            change_id = nil,
        })
    end

    if #cluster_changes > 25 then
        table.insert(recs, {
            severity = consts.SEVERITY.WARN,
            text = string.format("Cluster is large (%d entries) — splitting into 2–3 PRs would be safer.", #cluster_changes),
            fix_hint = 'Use "Needs split" to break by sub-topic or namespace.',
            change_id = nil,
        })
    end

    return recs
end

M._ns_root = ns_root
M._touches_governance = touches_governance

return M
