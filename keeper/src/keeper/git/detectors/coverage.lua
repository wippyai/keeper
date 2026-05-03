local consts = require("git_consts")

-- Test coverage detector — given a cluster's changes, flag new entries that
-- have no associated test entry in the same cluster.

local M = {}

local function is_test(target)
    if not target or target == "" then return false end
    if target:find(":test") or target:find(":.*_test") then return true end
    if target:find("_test%.lua$") or target:find("_test$") then return true end
    return false
end

local function is_new_registry(ch)
    return ch.category == "registry" and ch.op == "create"
end

function M.run(cluster_changes)
    local new_entries = {}
    local has_any_test = false
    for _, ch in ipairs(cluster_changes or {}) do
        if is_new_registry(ch) and not is_test(ch.target) then
            table.insert(new_entries, ch)
        end
        if is_test(ch.target) then has_any_test = true end
    end
    if #new_entries == 0 then return {} end
    if has_any_test then return {} end

    local recs = {}
    table.insert(recs, {
        severity = consts.SEVERITY.WARN,
        text = string.format("%d new entries have no associated test in this cluster.", #new_entries),
        fix_hint = "Add a `*_test.lua` for at least the public entry points before pushing.",
        change_id = nil,
    })
    -- Per-entry hints (cap at 3 to keep the recommendation list tidy).
    for i = 1, math.min(#new_entries, 3) do
        local ch = new_entries[i]
        table.insert(recs, {
            severity = consts.SEVERITY.INFO,
            text = "No test paired with " .. ch.target,
            fix_hint = nil,
            change_id = ch.change_id,
        })
    end
    return recs
end

return M
