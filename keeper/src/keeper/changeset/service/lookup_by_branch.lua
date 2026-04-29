local repo = require("repo")
local consts = require("consts")

local function handler(args)
    args = args or {}
    local branch = args.branch or args.state_branch
    if not branch or branch == "" then
        return { ok = false, error = "branch required" }
    end
    if branch == consts.MAIN_BRANCH then
        return { ok = false, error = "main is not a workspace branch" }
    end

    local existing = repo.find_live_by_branch(branch)
    if not existing then
        return { ok = true, found = false }
    end
    return {
        ok = true,
        found = true,
        changeset_id = existing.changeset_id,
        state_branch = existing.state_branch,
        state = existing.state,
        title = existing.title,
        kind = existing.kind,
    }
end

return { handler = handler }
