local consts = require("consts")
local repo = require("repo")

local M = {}

-- Drop a workspace's overlay + FS content. Journal, baselines, merges, and
-- the workspace row itself are retained. Caller (central supervisor) owns
-- the state-machine DROP transition.
function M.run(args)
    if not args or not args.changeset_id then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id"
    end

    local workspace, err = repo.get_changeset(args.changeset_id)
    if err then return nil, err end

    local _, drop_err = repo.drop_changeset(args.changeset_id, workspace.state_branch)
    if drop_err then return nil, drop_err end

    return { ok = true }, nil
end

return M
