local consts = require("git_consts")

-- Security & audit detector — flags large delete batches and changes that
-- touch authentication / policy code.

local M = {}

local AUTH_PATTERNS = {
    "auth", "security", "policy", "token", "credential", "password",
    "session", "actor", "permission",
}

local function touches_auth(target)
    if not target then return false end
    local t = target:lower()
    for _, kw in ipairs(AUTH_PATTERNS) do
        if t:find(kw, 1, true) then return true end
    end
    return false
end

function M.run(cluster_changes)
    local recs = {}
    local deletes = {}
    local auth_touches = {}
    for _, ch in ipairs(cluster_changes or {}) do
        if ch.op == "delete" then table.insert(deletes, ch) end
        if touches_auth(ch.target) then table.insert(auth_touches, ch) end
    end

    if #deletes >= 8 then
        table.insert(recs, {
            severity = consts.SEVERITY.BLOCK,
            text = string.format("%d entries are being deleted in one cluster — review before pushing.", #deletes),
            fix_hint = "Consider splitting deletions into a separate PR after verifying no incoming refs.",
            change_id = nil,
        })
    elseif #deletes >= 4 then
        table.insert(recs, {
            severity = consts.SEVERITY.WARN,
            text = string.format("%d deletions in this cluster.", #deletes),
            fix_hint = "Run gov.discovery for incoming references on each one before push.",
            change_id = nil,
        })
    end

    if #auth_touches > 0 then
        table.insert(recs, {
            severity = consts.SEVERITY.BLOCK,
            text = string.format("%d changes touch authentication or policy code.", #auth_touches),
            fix_hint = "Manual security review required before pushing.",
            change_id = auth_touches[1].change_id,
        })
    end

    return recs
end

M._touches_auth = touches_auth

return M
