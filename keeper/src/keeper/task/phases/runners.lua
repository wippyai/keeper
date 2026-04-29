-- keeper.task.phases:runners
--
-- PHASE_RUNNERS registry. Every phase has exactly one runner; a runner is
-- either an agent orchestrator (LLM arena) or a deterministic function
-- (integrate, rollback). Spawner dispatches via runner.kind so both kinds
-- emit the same phase_started / phase_exited rails without any special-
-- casing downstream.

local state_machine = require("state_machine")

local P = state_machine.PHASES

local M = {}

-- Exit schema descriptions surfaced to the agent orchestrator prompts.
local AGENT_STATUS_DESC = {
    [P.RESEARCH]  = "done=findings ready, ask_user=need clarification, abandoned=infeasible",
    [P.DESIGN]    = "approved=spec final, abandoned=infeasible, ask_user=need clarification, needs_research=spec needs more context",
    [P.PLAN]      = "planned=task list persisted, ask_user=need clarification, abandoned=infeasible, needs_research=spec is not implementable yet",
    [P.IMPLEMENT] = "staged=changes ready for review, spec_wrong=spec infeasible, stuck=retries not converging, ask_user=targeted question",
    [P.REVIEW]    = "approved=all green, bugs=implementation wrong, ask_user=clarification",
    [P.TEST]      = "approved=verified, rollback=integration broke main, bugs=implementation wrong, ask_user=clarification",
}

local AGENT_SUMMARY_DESC = {
    [P.RESEARCH]  = "Findings summary, question, or abandonment reason",
    [P.DESIGN]    = "Spec summary, question, or abandonment reason",
    [P.PLAN]      = "Plan summary (count of steps, kinds) or question",
    [P.IMPLEMENT] = "What was staged, why stuck, or the question",
    [P.REVIEW]    = "Verdict or question",
    [P.TEST]      = "Verification result, rollback reason, or question",
}

M.PHASE_RUNNERS = {
    [P.RESEARCH] = {
        kind = "agent",
        id   = "keeper.agents:research_orchestrator",
    },
    [P.DESIGN] = {
        kind = "agent",
        id   = "keeper.agents:design_orchestrator",
    },
    [P.PLAN] = {
        kind = "agent",
        id   = "keeper.agents:planner",
    },
    [P.IMPLEMENT] = {
        kind = "agent",
        id   = "keeper.agents:implement_orchestrator",
    },
    [P.REVIEW] = {
        kind = "agent",
        id   = "keeper.agents:review_orchestrator",
    },
    [P.TEST] = {
        kind = "agent",
        id   = "keeper.agents:test_orchestrator",
    },
    [P.INTEGRATE] = {
        kind = "function",
        id   = "keeper.develop.integrate:run",
    },
    [P.ROLLBACK] = {
        kind = "function",
        id   = "keeper.develop.integrate:rollback_run",
    },
}

function M.for_phase(phase)
    return M.PHASE_RUNNERS[phase]
end

function M.is_agent_phase(phase)
    local r = M.PHASE_RUNNERS[phase]
    if type(r) ~= "table" then return false end
    return r.kind == "agent"
end

function M.is_function_phase(phase)
    local r = M.PHASE_RUNNERS[phase]
    if type(r) ~= "table" then return false end
    return r.kind == "function"
end

-- Allowed exit signals for a phase — derived from the state machine so the
-- agent schema stays in sync when transitions are added.
local S = state_machine.SIGNALS
function M.exit_signals_for(phase)
    local transitions = state_machine.TRANSITIONS[phase] or {}
    local signals = { S.ASK_USER }
    for signal in pairs(transitions) do
        if signal ~= S.ASK_USER then
            table.insert(signals, signal)
        end
    end
    table.sort(signals)
    return signals
end

function M.exit_schema_for(phase)
    return {
        type = "object",
        properties = {
            status = {
                type        = "string",
                enum        = M.exit_signals_for(phase),
                description = AGENT_STATUS_DESC[phase] or "phase exit signal",
            },
            summary = {
                type        = "string",
                description = AGENT_SUMMARY_DESC[phase] or "phase exit summary",
            },
        },
        required = { "status", "summary" },
    }
end

return M
