-- Suspect / orphan heuristic. Pure Lua — no LLM.
-- A change is "suspect" if its target name matches one of the throwaway-pattern
-- regexes below. The rebuild flow pulls these out before clustering so they
-- don't pollute real topic clusters.

local M = {}

-- Patterns ordered: most specific first.
-- Separator class: keeper entry IDs use `:` between namespace and name,
-- `.` inside namespaces, `/` inside file paths. Patterns must accept all three.
M.PATTERNS = {
    { regex = "%.bak$",                          reason = "Editor backup file (.bak) — should not be checked in." },
    { regex = "%.DS_Store$",                     reason = "OS metadata file." },
    { regex = "Thumbs%.db$",                     reason = "OS metadata file." },
    { regex = "^.*[:/.]_[^/:]+$",                reason = "Underscore-prefixed entry — looks like scratch/debug-only work." },
    { regex = "[:/.]zzz_",                       reason = "zzz_ prefix — looks like a placeholder." },
    { regex = "[:/.]TODO_remove",                reason = "Even the name asks to be removed." },
    { regex = "[:/.]tmp_",                       reason = 'Named "tmp_…" — almost certainly a one-off probe.' },
    { regex = "[:/.]scratch[:/]",                reason = "In a scratch namespace nobody else uses." },
    { regex = "[:/.]experiment[:/].*half_done",  reason = 'Name says "half_done".' },
    { regex = "[:/.]foo$",                       reason = 'Named "foo" — looks unfinished.' },
    { regex = "test_seed_[0-9]+",                reason = "Old test seed." },
}

-- Returns reason string when target matches a suspect pattern, nil otherwise.
function M.match(target)
    if not target or target == "" then return nil end
    for _, p in ipairs(M.PATTERNS) do
        if target:match(p.regex) then return p.reason end
    end
    return nil
end

-- Partition a list of changes into { topic_changes, orphans } where orphans is
-- a list of { change, reason } pairs.
function M.partition(changes)
    local topic, orphans = {}, {}
    for _, ch in ipairs(changes or {}) do
        local reason = M.match(ch.target)
        if reason then
            table.insert(orphans, { change = ch, reason = reason })
        else
            table.insert(topic, ch)
        end
    end
    return topic, orphans
end

return M
