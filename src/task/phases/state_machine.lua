local M = {}

M.PHASES = {
    RESEARCH  = "research",
    DESIGN    = "design",
    PLAN      = "plan",
    IMPLEMENT = "implement",
    REVIEW    = "review",
    INTEGRATE = "integrate",
    TEST      = "test",
    ROLLBACK  = "rollback",
    FINISH    = "finish",
    ABANDONED = "abandoned",
}

M.SIGNALS = {
    APPROVED        = "approved",
    ABANDONED       = "abandoned",
    PUSHED          = "pushed",
    STAGED          = "staged",
    BUGS            = "bugs",
    SPEC_WRONG      = "spec_wrong",
    STUCK           = "stuck",
    ASK_USER        = "ask_user",
    DONE            = "done",
    PLANNED         = "planned",
    NEEDS_RESEARCH  = "needs_research",
    OK              = "ok",
    FAIL            = "fail",
    ROLLBACK        = "rollback",
}

M.TERMINAL = {
    [M.PHASES.FINISH]    = true,
    [M.PHASES.ABANDONED] = true,
}

-- Runners that execute as deterministic functions (not agent orchestrators).
-- Integrate + rollback publish and roll back registry state without an LLM.
M.FUNCTION_PHASES = {
    [M.PHASES.INTEGRATE] = true,
    [M.PHASES.ROLLBACK]  = true,
}

local P = M.PHASES
local S = M.SIGNALS

M.TRANSITIONS = {
    [P.RESEARCH] = {
        [S.DONE]       = P.DESIGN,
        [S.ABANDONED]  = P.ABANDONED,
    },
    [P.DESIGN] = {
        [S.APPROVED]        = P.PLAN,
        [S.ABANDONED]       = P.ABANDONED,
        [S.NEEDS_RESEARCH]  = P.RESEARCH,
    },
    [P.PLAN] = {
        [S.PLANNED]         = P.IMPLEMENT,
        [S.ABANDONED]       = P.ABANDONED,
        [S.NEEDS_RESEARCH]  = P.DESIGN,
    },
    [P.IMPLEMENT] = {
        [S.PUSHED]     = P.REVIEW,
        [S.STAGED]     = P.REVIEW,
        [S.SPEC_WRONG] = P.DESIGN,
        -- stuck pauses for the user instead of routing; flow.advance treats
        -- it like ask_user (self-loop + log_question). Matches PLAN.md §Step 4
        -- where implement.stuck→ask_user.
        [S.STUCK]      = P.IMPLEMENT,
    },
    [P.REVIEW] = {
        [S.APPROVED]   = P.INTEGRATE,
        [S.BUGS]       = P.IMPLEMENT,
    },
    [P.INTEGRATE] = {
        [S.OK]         = P.TEST,
        [S.FAIL]       = P.IMPLEMENT,
    },
    [P.TEST] = {
        [S.APPROVED]   = P.FINISH,
        [S.ROLLBACK]   = P.ROLLBACK,
        [S.BUGS]       = P.IMPLEMENT,
    },
    [P.ROLLBACK] = {
        [S.DONE]       = P.IMPLEMENT,
    },
}

-- Bounce caps per (from_phase -> to_phase) edge. flow.lua enforces them;
-- context.lua surfaces the remaining budget to the orchestrator so it knows
-- when it is on its last chance. Trail title is always "<from> -> <to>".
M.BOUNCE_CAPS = {
    [P.REVIEW] = {
        [P.IMPLEMENT] = { cap = 1, terminal = P.FINISH,
            note = "Review returned bugs once and implement tried to fix. If the second review is still red, the task is force-finished with a bugs signal — no further retries." },
    },
    [P.IMPLEMENT] = {
        [P.DESIGN] = { cap = 3, terminal = P.ABANDONED,
            note = "Implement keeps rejecting the spec. On the next bounce the task is abandoned." },
        [P.REVIEW] = { cap = 5, terminal = P.FINISH,
            note = "Implement has pushed repeatedly without closure. On the next bounce the task is force-finished." },
    },
    [P.TEST] = {
        [P.IMPLEMENT] = { cap = 3, terminal = P.FINISH,
            note = "Test has bounced to implement repeatedly without the endpoints going green. On the next bounce the task is force-finished." },
    },
}

function M.bounce_cap(from_phase, to_phase)
    if not from_phase or not to_phase then return nil end
    local row = M.BOUNCE_CAPS[from_phase]
    return row and row[to_phase] or nil
end

-- Iterate every capped outbound edge for `from_phase`. Yields (to_phase, cap).
-- Used by context.lua to render per-phase retry budget without string-parsing keys.
function M.outbound_caps(from_phase)
    local row = M.BOUNCE_CAPS[from_phase]
    if not row then return function() return nil end end
    return pairs(row)
end

function M.is_valid_phase(phase)
    if not phase then return false end
    return M.TRANSITIONS[phase] ~= nil
end

function M.is_terminal(phase)
    return M.TERMINAL[phase] == true
end

-- Routes (current_phase, exit_signal) -> next_phase.
-- ask_user is a non-transition: caller stays in current_phase until user responds.
-- Returns next_phase, error_message.
function M.route(current_phase, signal)
    if signal == S.ASK_USER then
        return current_phase, nil
    end
    if M.is_terminal(current_phase) then
        return nil, "already terminal: " .. current_phase
    end
    local map = M.TRANSITIONS[current_phase]
    if not map then
        return nil, "unknown phase: " .. tostring(current_phase)
    end
    local next_phase = map[signal]
    if not next_phase then
        return nil, "invalid signal '" .. tostring(signal) .. "' for phase '" .. current_phase .. "'"
    end
    return next_phase, nil
end

return M
