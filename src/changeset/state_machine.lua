local consts = require("consts")

local M = {}

local STATES = consts.STATES

-- Events that can drive transitions. State transitions are pure — guards are
-- decided by the caller (service/state.lua) based on workspace + change data.
M.EVENTS = {
    FIRST_EDIT        = "first_edit",       -- open -> editing on first change
    SUBMIT_FOR_REVIEW = "submit_for_review",
    ACCEPT            = "accept",
    REJECT            = "reject",
    REOPEN            = "reopen",
    PUSH_START        = "push_start",
    PUSH_SUCCESS      = "push_success",
    PUSH_FAILURE      = "push_failure",
    DROP              = "drop",
}

-- Transition table: [from_state][event] = to_state
-- nil in cells means the transition is invalid.
local TRANSITIONS = {
    [STATES.OPEN] = {
        [M.EVENTS.FIRST_EDIT] = STATES.EDITING,
        [M.EVENTS.DROP]       = STATES.DROPPED,
    },
    [STATES.EDITING] = {
        [M.EVENTS.SUBMIT_FOR_REVIEW] = STATES.REVIEW,
        [M.EVENTS.DROP]              = STATES.DROPPED,
    },
    [STATES.REVIEW] = {
        [M.EVENTS.ACCEPT] = STATES.ACCEPTED,
        [M.EVENTS.REJECT] = STATES.REJECTED,
        [M.EVENTS.DROP]   = STATES.DROPPED,
    },
    [STATES.ACCEPTED] = {
        [M.EVENTS.PUSH_START]   = STATES.ACCEPTED, -- stays accepted, lock held by caller
        [M.EVENTS.PUSH_SUCCESS] = STATES.MERGED,
        [M.EVENTS.PUSH_FAILURE] = STATES.REJECTED,
        [M.EVENTS.DROP]         = STATES.DROPPED,
    },
    [STATES.REJECTED] = {
        [M.EVENTS.REOPEN] = STATES.EDITING,
        [M.EVENTS.DROP]   = STATES.DROPPED,
    },
    -- terminal states: no outgoing transitions
    [STATES.MERGED]  = {},
    [STATES.DROPPED] = {},
}

-- Pure state transition. Returns (new_state, nil) on success, (nil, error) otherwise.
function M.next_state(current_state, event)
    if not current_state then
        return nil, "missing current_state"
    end
    if not event then
        return nil, "missing event"
    end

    local row = TRANSITIONS[current_state]
    if not row then
        return nil, consts.ERRORS.INVALID_STATE .. ": " .. tostring(current_state)
    end

    local next_state = row[event]
    if not next_state then
        return nil, consts.ERRORS.INVALID_TRANSITION ..
            ": " .. tostring(current_state) .. " -> " .. tostring(event)
    end

    return next_state, nil
end

-- Is this state terminal (no further transitions possible)?
function M.is_terminal(state)
    return state == STATES.MERGED or state == STATES.DROPPED
end

-- Is this state a live, editable workspace (agents may write into it)?
function M.is_live(state)
    return state == STATES.OPEN
        or state == STATES.EDITING
        or state == STATES.REVIEW
        or state == STATES.ACCEPTED
        or state == STATES.REJECTED
end

-- Guards used by service/transitions.lua when evaluating an event. Each guard
-- takes a single ctx table carrying everything it needs, so callers don't have
-- to marshal positional args per-event:
--
--   ctx.workspace       — the workspace row injected by transitions.run (always present)
--   ctx.pending_changes — computed list from diff.compute (submit_for_review)
--   ctx.conflicts       — filtered list of pending changes with conflict_with (submit_for_review)
--   ctx.linter_result   — { success: bool, issues: [] } (accept)
M.guards = {
    submit_for_review = function(ctx)
        if not ctx.pending_changes or #ctx.pending_changes == 0 then
            return false, "no pending changes to submit"
        end
        if ctx.conflicts and #ctx.conflicts > 0 then
            return false, "unresolved conflicts: " .. #ctx.conflicts
        end
        return true
    end,

    accept = function(ctx)
        if not ctx.linter_result or not ctx.linter_result.success then
            return false, "review linter not clean"
        end
        return true
    end,

    push_start = function(ctx)
        if not ctx.workspace or ctx.workspace.state ~= STATES.ACCEPTED then
            return false, "changeset must be accepted before push"
        end
        return true
    end,
}

-- Export constants for callers
M.STATES = STATES

return M
