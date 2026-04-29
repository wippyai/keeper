local cs_client = require("cs_client")

-- Thin funcs-callable wrapper around cs_client.open_or_resume so callers that
-- cannot depend on the keeper.changeset:client pool can still drive an
-- open-or-resume through the central supervisor. All serialization and race
-- resolution lives in central — this function just forwards.
local function handler(args)
    args = args or {}
    local result, err = cs_client.open_or_resume({
        branch       = args.branch,
        state_branch = args.state_branch,
        title        = args.title,
        description  = args.description,
        kind         = args.kind,
        actor_id     = args.actor_id,
        session_id   = args.session_id,
        task_id      = args.task_id,
    }, args.timeout or "10s")
    if err then
        return { ok = false, error = tostring(err) }
    end
    return {
        ok           = true,
        resumed      = result.resumed and true or false,
        changeset_id = result.changeset_id,
        state_branch = result.state_branch,
        kind         = result.kind,
        title        = result.title,
        state        = result.state,
    }
end

return { handler = handler }
