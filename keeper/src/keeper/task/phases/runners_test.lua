local runners = require("runners")
local state_machine = require("state_machine")
local test = require("test")

local function define_tests()
    describe("Phase runners registry", function()
        local P = state_machine.PHASES

        describe("for_phase", function()
            it("returns agent runner for research/design/implement/review/test", function()
                for _, phase in ipairs({ P.RESEARCH, P.DESIGN, P.IMPLEMENT, P.REVIEW, P.TEST }) do
                    local r = runners.for_phase(phase)
                    test.not_nil(r, "expected runner for " .. phase)
                    test.eq(r.kind, "agent")
                    test.not_nil(r.id)
                end
            end)

            it("returns function runner for integrate/rollback", function()
                local integ = runners.for_phase(P.INTEGRATE)
                test.not_nil(integ)
                test.eq(integ.kind, "function")
                test.eq(integ.id, "keeper.develop.integrate:run")

                local rb = runners.for_phase(P.ROLLBACK)
                test.not_nil(rb)
                test.eq(rb.kind, "function")
            end)

            it("returns nil for terminal phases", function()
                test.is_nil(runners.for_phase(P.FINISH))
                test.is_nil(runners.for_phase(P.ABANDONED))
            end)
        end)

        describe("is_agent_phase / is_function_phase", function()
            it("agent phases report kind=agent", function()
                test.is_true(runners.is_agent_phase(P.DESIGN))
                test.is_false(runners.is_function_phase(P.DESIGN))
            end)

            it("function phases report kind=function", function()
                test.is_true(runners.is_function_phase(P.INTEGRATE))
                test.is_false(runners.is_agent_phase(P.INTEGRATE))
            end)

            it("unknown phase reports neither", function()
                test.is_false(runners.is_agent_phase("bogus"))
                test.is_false(runners.is_function_phase("bogus"))
            end)
        end)

        describe("exit_signals_for / exit_schema_for", function()
            it("design signals include approved + needs_research + ask_user", function()
                local signals = runners.exit_signals_for(P.DESIGN)
                local set = {}
                for _, s in ipairs(signals) do set[s] = true end
                test.is_true(set["approved"])
                test.is_true(set["needs_research"])
                test.is_true(set["abandoned"])
                test.is_true(set["ask_user"])
            end)

            it("implement signals include staged (new) and pushed (legacy)", function()
                local signals = runners.exit_signals_for(P.IMPLEMENT)
                local set = {}
                for _, s in ipairs(signals) do set[s] = true end
                test.is_true(set["staged"])
                test.is_true(set["pushed"])
            end)

            it("test signals include approved, rollback, bugs", function()
                local signals = runners.exit_signals_for(P.TEST)
                local set = {}
                for _, s in ipairs(signals) do set[s] = true end
                test.is_true(set["approved"])
                test.is_true(set["rollback"])
                test.is_true(set["bugs"])
            end)

            it("schema shape is exit-func compatible", function()
                local schema = runners.exit_schema_for(P.REVIEW)
                test.eq(schema.type, "object")
                test.not_nil(schema.properties.status)
                test.not_nil(schema.properties.summary)
                test.eq(schema.required[1], "status")
                test.eq(schema.required[2], "summary")
            end)
        end)

        describe("registry completeness", function()
            it("every non-terminal phase has a runner", function()
                for phase in pairs(state_machine.TRANSITIONS) do
                    local r = runners.for_phase(phase)
                    test.not_nil(r, "missing runner for phase: " .. tostring(phase))
                end
            end)

            it("every function phase is marked in FUNCTION_PHASES", function()
                for phase, r in pairs(runners.PHASE_RUNNERS) do
                    if r.kind == "function" then
                        test.is_true(state_machine.FUNCTION_PHASES[phase],
                            phase .. " should be in FUNCTION_PHASES")
                    end
                end
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
