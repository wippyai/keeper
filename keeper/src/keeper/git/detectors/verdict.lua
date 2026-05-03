local consts = require("git_consts")

-- Compose final verdict + importance from detector recommendations.

local M = {}

function M.from_recommendations(recs, change_count)
    local has_block, has_warn = false, false
    for _, r in ipairs(recs or {}) do
        if r.severity == consts.SEVERITY.BLOCK then has_block = true
        elseif r.severity == consts.SEVERITY.WARN then has_warn = true end
    end

    local verdict, text
    if has_block then
        verdict = consts.VERDICTS.DO_NOT_PUSH
        text = "Blocking issue detected — resolve before pushing."
    elseif has_warn then
        verdict = consts.VERDICTS.CLOSER_LOOK
        text = "Worth a closer look."
    else
        verdict = consts.VERDICTS.READY
        text = "Looks ready to push."
    end

    local importance
    if has_block then importance = consts.IMPORTANCE.CRITICAL
    elseif has_warn then importance = consts.IMPORTANCE.HIGH
    elseif (change_count or 0) <= 3 then importance = consts.IMPORTANCE.CLEANUP
    else importance = consts.IMPORTANCE.NORMAL end

    return verdict, text, importance
end

return M
