local consts = require("consts")
local repo = require("repo")
local state_machine = require("state_machine")

local M = {}

-- Apply a state machine event to a workspace. This is the SOLE path for mutating
-- keeper_changesets.state — no other library writes it directly. Callers hand in
-- the event and any guard-relevant context.
--
-- Args:
--   changeset_id (required)
--   event        (required — see state_machine.EVENTS)
--   reason       (optional — free text stored in state_reason)
--   guard_ctx    (optional table — extra context for guards, e.g. linter result)
function M.run(args)
    if not args or not args.changeset_id then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id"
    end
    if not args.event then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": event"
    end

    local workspace, err = repo.get_changeset(args.changeset_id)
    if err then return nil, err end

    -- Guard: workspace must not be terminal (merged/dropped) unless the event is
    -- one that targets a terminal state (push_success, drop).
    if state_machine.is_terminal(workspace.state) then
        return nil, consts.ERRORS.INVALID_STATE .. ": " .. workspace.state
    end

    -- Evaluate state-machine-level guards
    local guard = state_machine.guards[args.event]
    if guard then
        local ctx = args.guard_ctx or {}
        ctx.workspace = workspace
        local ok, guard_err = guard(ctx)
        if not ok then return nil, guard_err end
    end

    -- Compute next state from the transition table
    local next_state, trans_err = state_machine.next_state(workspace.state, args.event)
    if trans_err then return nil, trans_err end

    -- Apply
    local _, upd_err = repo.update_state(args.changeset_id, next_state, args.reason)
    if upd_err then return nil, upd_err end

    return {
        ok         = true,
        from_state = workspace.state,
        to_state   = next_state,
        reason     = args.reason,
    }, nil
end

return M
