local sm = require("state_machine")
local test = require("test")

local function define_tests()
    describe("Phase state machine", function()
        local P = sm.PHASES
        local S = sm.SIGNALS

        describe("route", function()
            it("routes design->plan on approved", function()
                local next_phase, err = sm.route(P.DESIGN, S.APPROVED)
                test.eq(next_phase, P.PLAN)
                test.is_nil(err)
            end)

            it("routes plan->implement on planned", function()
                local next_phase, err = sm.route(P.PLAN, S.PLANNED)
                test.eq(next_phase, P.IMPLEMENT)
                test.is_nil(err)
            end)

            it("routes plan->design on needs_research", function()
                local next_phase = sm.route(P.PLAN, S.NEEDS_RESEARCH)
                test.eq(next_phase, P.DESIGN)
            end)

            it("routes design->abandoned on abandoned", function()
                local next_phase = sm.route(P.DESIGN, S.ABANDONED)
                test.eq(next_phase, P.ABANDONED)
            end)

            it("routes design->finish on already_done (post-merge re-spawn that finds spec already met)", function()
                local next_phase, err = sm.route(P.DESIGN, S.ALREADY_DONE)
                test.eq(next_phase, P.FINISH,
                    "already_done lands in FINISH (status=completed), not abandoned — prevents post-merge cascades from being mislabelled")
                test.is_nil(err)
            end)

            it("routes plan->finish on already_done", function()
                local next_phase, err = sm.route(P.PLAN, S.ALREADY_DONE)
                test.eq(next_phase, P.FINISH)
                test.is_nil(err)
            end)

            it("routes implement->finish on already_done after verified post-merge recovery", function()
                local next_phase, err = sm.route(P.IMPLEMENT, S.ALREADY_DONE)
                test.eq(next_phase, P.FINISH,
                    "finish.verify only permits this when no active edits exist and the task already merged once")
                test.is_nil(err)
            end)

            it("already_done is rejected from phases that do not own it", function()
                local _, err2 = sm.route(P.REVIEW, S.ALREADY_DONE)
                test.not_nil(err2, "review cannot exit already_done")
                local _, err3 = sm.route(P.INTEGRATE, S.ALREADY_DONE)
                test.not_nil(err3, "integrate cannot exit already_done")
                local _, err4 = sm.route(P.TEST, S.ALREADY_DONE)
                test.not_nil(err4, "test cannot exit already_done")
            end)

            it("routes implement->review on pushed", function()
                local next_phase = sm.route(P.IMPLEMENT, S.PUSHED)
                test.eq(next_phase, P.REVIEW)
            end)

            it("routes implement->design on spec_wrong", function()
                local next_phase = sm.route(P.IMPLEMENT, S.SPEC_WRONG)
                test.eq(next_phase, P.DESIGN)
            end)

            it("routes implement->implement on stuck (self-loop — pauses for user per plan)", function()
                local next_phase = sm.route(P.IMPLEMENT, S.STUCK)
                test.eq(next_phase, P.IMPLEMENT,
                    "stuck is a pause, not a transition; flow.advance treats it like ask_user (PLAN.md §Step 4: implement.stuck→ask_user)")
            end)

            it("routes review->integrate on approved (deterministic publish path)", function()
                local next_phase = sm.route(P.REVIEW, S.APPROVED)
                test.eq(next_phase, P.INTEGRATE,
                    "review.approved must route to integrate function runner, not finish — publish happens inside integrate, not in review")
            end)

            it("routes review->implement on bugs", function()
                local next_phase = sm.route(P.REVIEW, S.BUGS)
                test.eq(next_phase, P.IMPLEMENT)
            end)

            it("review->design is BLOCKED (regression: review never bounces to design)", function()
                local next_phase, err = sm.route(P.REVIEW, S.SPEC_WRONG)
                test.is_nil(next_phase)
                test.not_nil(err)
                test.is_true(err:find("invalid signal") ~= nil,
                    "review must not accept spec_wrong signal; reviewer emits bugs or approved only")
            end)

            it("ask_user stays in current phase", function()
                test.eq(sm.route(P.DESIGN, S.ASK_USER), P.DESIGN)
                test.eq(sm.route(P.IMPLEMENT, S.ASK_USER), P.IMPLEMENT)
                test.eq(sm.route(P.REVIEW, S.ASK_USER), P.REVIEW)
            end)

            it("rejects invalid signal for phase", function()
                local next_phase, err = sm.route(P.DESIGN, S.PUSHED)
                test.is_nil(next_phase)
                test.not_nil(err)
                test.is_true(err:find("invalid signal") ~= nil)
            end)

            it("rejects routing from terminal phase", function()
                local next_phase, err = sm.route(P.FINISH, S.APPROVED)
                test.is_nil(next_phase)
                test.not_nil(err)
                test.is_true(err:find("terminal") ~= nil)
            end)

            it("rejects unknown phase", function()
                local next_phase, err = sm.route("unknown_phase", S.APPROVED)
                test.is_nil(next_phase)
                test.not_nil(err)
            end)

            it("routes research->design on done", function()
                test.eq(sm.route(P.RESEARCH, S.DONE), P.DESIGN)
            end)

            it("routes research->abandoned on abandoned", function()
                test.eq(sm.route(P.RESEARCH, S.ABANDONED), P.ABANDONED)
            end)

            it("routes design->research on needs_research", function()
                test.eq(sm.route(P.DESIGN, S.NEEDS_RESEARCH), P.RESEARCH)
            end)

            it("routes implement->review on staged (alias of pushed)", function()
                test.eq(sm.route(P.IMPLEMENT, S.STAGED), P.REVIEW)
            end)

            it("routes integrate->test on ok", function()
                test.eq(sm.route(P.INTEGRATE, S.OK), P.TEST)
            end)

            it("routes integrate->implement on fail", function()
                test.eq(sm.route(P.INTEGRATE, S.FAIL), P.IMPLEMENT)
            end)

            it("routes test->finish on approved", function()
                test.eq(sm.route(P.TEST, S.APPROVED), P.FINISH)
            end)

            it("routes test->rollback on rollback", function()
                test.eq(sm.route(P.TEST, S.ROLLBACK), P.ROLLBACK)
            end)

            it("routes test->implement on bugs", function()
                test.eq(sm.route(P.TEST, S.BUGS), P.IMPLEMENT)
            end)

            it("routes rollback->implement on done", function()
                test.eq(sm.route(P.ROLLBACK, S.DONE), P.IMPLEMENT)
            end)
        end)

        describe("FUNCTION_PHASES", function()
            it("integrate and rollback are function runners", function()
                test.is_true(sm.FUNCTION_PHASES[P.INTEGRATE])
                test.is_true(sm.FUNCTION_PHASES[P.ROLLBACK])
            end)

            it("agent phases are not function runners", function()
                test.is_nil(sm.FUNCTION_PHASES[P.RESEARCH])
                test.is_nil(sm.FUNCTION_PHASES[P.DESIGN])
                test.is_nil(sm.FUNCTION_PHASES[P.IMPLEMENT])
                test.is_nil(sm.FUNCTION_PHASES[P.REVIEW])
                test.is_nil(sm.FUNCTION_PHASES[P.TEST])
            end)
        end)

        describe("is_terminal", function()
            it("true for finish and abandoned", function()
                test.is_true(sm.is_terminal(P.FINISH))
                test.is_true(sm.is_terminal(P.ABANDONED))
            end)

            it("false for active phases", function()
                test.is_false(sm.is_terminal(P.DESIGN))
                test.is_false(sm.is_terminal(P.IMPLEMENT))
                test.is_false(sm.is_terminal(P.REVIEW))
            end)
        end)

        describe("is_valid_phase", function()
            it("true for every non-terminal phase", function()
                test.is_true(sm.is_valid_phase(P.RESEARCH))
                test.is_true(sm.is_valid_phase(P.DESIGN))
                test.is_true(sm.is_valid_phase(P.IMPLEMENT))
                test.is_true(sm.is_valid_phase(P.REVIEW))
                test.is_true(sm.is_valid_phase(P.INTEGRATE))
                test.is_true(sm.is_valid_phase(P.TEST))
                test.is_true(sm.is_valid_phase(P.ROLLBACK))
            end)

            it("false for terminal and unknown", function()
                test.is_false(sm.is_valid_phase(P.FINISH))
                test.is_false(sm.is_valid_phase(P.ABANDONED))
                test.is_false(sm.is_valid_phase(nil))
                test.is_false(sm.is_valid_phase("bogus"))
            end)
        end)

        describe("bounce_cap", function()
            it("returns review->implement cap=1 toward ask_user (convergence ping-pong needs human, not finish-lie)", function()
                local cap = sm.bounce_cap(P.REVIEW, P.IMPLEMENT)
                test.not_nil(cap)
                test.eq(cap.cap, 1,
                    "review->implement cap must be 1; increasing lets buggy work loop indefinitely")
                test.eq(cap.terminal, "ask_user",
                    "cap-exhaustion on review-bugs routes to ask_user — the human can adjudicate, the partial work isn't thrown away")
            end)

            it("review->design bounce edge is REMOVED (regression: no design bounce from review)", function()
                local cap = sm.bounce_cap(P.REVIEW, P.DESIGN)
                test.is_nil(cap,
                    "review must have no design-bound cap because the state machine no longer allows that transition")
            end)

            it("returns implement->design cap toward abandoned", function()
                local cap = sm.bounce_cap(P.IMPLEMENT, P.DESIGN)
                test.not_nil(cap)
                test.eq(cap.cap, 3)
                test.eq(cap.terminal, P.ABANDONED)
            end)

            it("returns implement->review cap toward ask_user (push-loop without convergence pauses for user, not silent fail)", function()
                local cap = sm.bounce_cap(P.IMPLEMENT, P.REVIEW)
                test.not_nil(cap)
                test.eq(cap.cap, 5)
                test.eq(cap.terminal, "ask_user")
            end)

            it("ZERO bounce-cap terminals route to FINISH (regression: cap exhaustion is never a successful ship)", function()
                local edges = {
                    { from = P.REVIEW,    to = P.IMPLEMENT },
                    { from = P.IMPLEMENT, to = P.DESIGN },
                    { from = P.IMPLEMENT, to = P.REVIEW },
                    { from = P.TEST,      to = P.IMPLEMENT },
                    { from = P.INTEGRATE, to = P.IMPLEMENT },
                }
                for _, e in ipairs(edges) do
                    local cap = sm.bounce_cap(e.from, e.to)
                    if cap then
                        test.is_true(cap.terminal ~= P.FINISH,
                            string.format(
                                "%s->%s cap-exhaustion MUST NOT terminal=FINISH; that mislabels non-shipping outcome as completed (v25 regression)",
                                e.from, e.to))
                        test.is_true(cap.terminal == "ask_user" or cap.terminal == P.ABANDONED,
                            string.format(
                                "%s->%s cap terminal must be ask_user or abandoned, got %s",
                                e.from, e.to, tostring(cap.terminal)))
                    end
                end
            end)

            it("convergence-failure caps prefer ask_user (work isn't thrown away)", function()
                -- review-bugs ping-pong, push-without-converge, runtime-test fail,
                -- integrate-fail loop — all are "agent stuck, human can break it"
                for _, e in ipairs({
                    { P.REVIEW,    P.IMPLEMENT },
                    { P.IMPLEMENT, P.REVIEW },
                    { P.TEST,      P.IMPLEMENT },
                    { P.INTEGRATE, P.IMPLEMENT },
                }) do
                    local cap = sm.bounce_cap(e[1], e[2])
                    test.eq(cap and cap.terminal, "ask_user",
                        string.format("%s->%s should ask_user (convergence ping-pong)", e[1], e[2]))
                end
            end)

            it("infeasibility cap prefers abandoned (agents say spec is wrong)", function()
                -- implement->design with spec_wrong is the agents reporting that
                -- the design itself is broken. Asking the user to override that
                -- makes them re-author the spec from scratch — abandon is right.
                local cap = sm.bounce_cap(P.IMPLEMENT, P.DESIGN)
                test.eq(cap and cap.terminal, P.ABANDONED,
                    "implement->design cap-exhaustion is real infeasibility, not ping-pong; abandoned is correct")
            end)

            it("returns nil for uncapped edges", function()
                test.is_nil(sm.bounce_cap(P.DESIGN, P.IMPLEMENT))
                test.is_nil(sm.bounce_cap(P.DESIGN, P.ABANDONED))
            end)

            it("returns nil for missing args", function()
                test.is_nil(sm.bounce_cap(nil, P.IMPLEMENT))
                test.is_nil(sm.bounce_cap(P.REVIEW, nil))
            end)

            it("every capped edge carries a non-empty note", function()
                for _, row in pairs(sm.BOUNCE_CAPS) do
                    for _, cap in pairs(row) do
                        test.not_nil(cap.note)
                        test.is_true(cap.note ~= "")
                    end
                end
            end)
        end)

        describe("outbound_caps", function()
            it("review yields only implement outbound cap (regression: no design edge)", function()
                local seen: {[string]: boolean} = {}
                for to_phase, cap in sm.outbound_caps(P.REVIEW) do
                    seen[to_phase] = cap ~= nil
                end
                test.not_nil(seen[P.IMPLEMENT], "review should have implement outbound cap")
                test.is_nil(seen[P.DESIGN],
                    "review must NOT have a design outbound cap; reviewer can only route to implement or finish")
            end)

            it("yields nothing for design (no capped outbound edges)", function()
                local count = 0
                for _ in sm.outbound_caps(P.DESIGN) do count = count + 1 end
                test.eq(count, 0, "design has no capped outbound edges")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
