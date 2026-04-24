local consts          = require("consts")
local repo            = require("repo")
local transitions_lib = require("transitions")

local STATES = consts.STATES

local function fire(changeset_id, event, reason, guard_ctx)
    return transitions_lib.run({
        changeset_id = changeset_id,
        event        = event,
        reason       = reason,
        guard_ctx    = guard_ctx,
    })
end

-- Drive a workspace from whatever live state it is in up to ACCEPTED, running
-- every intermediate transition (submit_for_review → accept, reopen if
-- REJECTED). Each step hard-fails on guard rejection. Called by push.lua right
-- after the pre-push lint so the workspace is in a canonical state before
-- publish.
--
-- Args:
--   changeset_id  (required)
--   pending_count (number, ≥1) — feeds the submit_for_review guard
--   lint_success  (bool, default true) — feeds the accept guard
--   reason        (string, optional)
local function handler(args)
    args = args or {}
    local changeset_id = args.changeset_id
    if not changeset_id or changeset_id == "" then
        return { ok = false, error = "changeset_id required" }
    end

    local ws, err = repo.get_changeset(changeset_id)
    if err then return { ok = false, error = tostring(err) } end

    local reason = args.reason or "drive-to-accepted"

    local pending_count = tonumber(args.pending_count) or 0
    if pending_count < 1 then pending_count = 1 end
    local pending_changes = {}
    for i = 1, pending_count do
        table.insert(pending_changes, { target = "pending", op = "update" })
    end
    local submit_guard = { pending_changes = pending_changes }

    local accept_guard = {
        linter_result = { success = args.lint_success ~= false },
    }

    local plan = {}
    if ws.state == STATES.OPEN then
        return { ok = false, error = "workspace has no edits (state=open)" }
    elseif ws.state == STATES.EDITING then
        plan = {
            { event = "submit_for_review", guard = submit_guard },
            { event = "accept",            guard = accept_guard },
        }
    elseif ws.state == STATES.REVIEW then
        plan = { { event = "accept", guard = accept_guard } }
    elseif ws.state == STATES.ACCEPTED then
        plan = {}
    elseif ws.state == STATES.REJECTED then
        plan = {
            { event = "reopen",            guard = {} },
            { event = "submit_for_review", guard = submit_guard },
            { event = "accept",            guard = accept_guard },
        }
    else
        return { ok = false, error = "cannot drive terminal state '" .. ws.state .. "' to accepted" }
    end

    local from_state = ws.state
    local current    = ws.state
    for _, step in ipairs(plan) do
        local result, terr = fire(changeset_id, step.event, reason, step.guard)
        if terr then
            return {
                ok         = false,
                error      = "transition " .. step.event .. " failed: " .. tostring(terr),
                from_state = from_state,
                last_state = current,
            }
        end
        current = result.to_state
    end

    return {
        ok         = true,
        from_state = from_state,
        to_state   = current,
    }
end

return { handler = handler }
