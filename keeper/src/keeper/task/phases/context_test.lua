local test = require("test")
local context = require("context")
local state_machine = require("state_machine")
local task_writer = require("task_writer")
local nodes_writer = require("nodes_writer")
local sql = require("sql")
local task_consts = require("task_consts")

local function define_tests()
    describe("Phase context prompt builder", function()
        local P = state_machine.PHASES
        local created_ids = {}

        local function track(task_id)
            table.insert(created_ids, task_id)
        end

        local function cleanup()
            local db = sql.get(task_consts.DATABASE.RESOURCE_ID)
            if not db then return end
            for _, id in ipairs(created_ids) do
                db:execute("DELETE FROM keeper_task_nodes WHERE task_id = ?", { id })
                db:execute("DELETE FROM keeper_tasks WHERE task_id = ?", { id })
            end
            db:release()
        end

        after_all(cleanup)

        local function make_task(title)
            local res, err = task_writer.create_task({
                title    = title or "Budget Test",
                actor_id = "test.context",
                spec     = "Example spec body",
            }):execute()
            if err then error(err) end
            track(res.task_id)
            return res.task_id
        end

        local function record_bounce(task_id, from_phase, to_phase)
            nodes_writer.record({
                task_id       = task_id,
                type          = "phase_transition",
                discriminator = from_phase .. "->" .. to_phase,
                title         = from_phase .. " → " .. to_phase,
                content       = "bounce",
                status        = "active",
                visibility    = "user",
                metadata      = { from_phase = from_phase, to_phase = to_phase },
            })
        end

        local function record_finding(task_id, key, body)
            nodes_writer.record({
                task_id       = task_id,
                type          = "finding",
                discriminator = key,
                title         = key,
                content       = body,
                status        = "active",
                visibility    = "user",
            })
        end

        describe("retry budget rendering", function()
            it("renders zero-used budget on fresh task", function()
                local task_id = make_task("Fresh budget")
                local prompt, _, _, _, err = context.build(task_id, P.REVIEW, {})
                test.is_nil(err)
                test.is_true(prompt:find("## Retry Budget") ~= nil, "budget header missing")
                test.is_true(prompt:find("review %-> implement: 0/1 used %(1 left%)") ~= nil,
                    "expected 0/1 used on fresh review (cap=1 regression)")
            end)

            it("counts bounces from phase_transition nodes", function()
                local task_id = make_task("Counted bounces")
                record_bounce(task_id, "review", "implement")
                local prompt, _, _, _, err = context.build(task_id, P.REVIEW, {})
                test.is_nil(err)
                test.is_true(prompt:find("review %-> implement: 1/1 used %(0 left%)") ~= nil,
                    "expected 1/1 used after one review bounce (cap=1 means no room left)")
            end)

            it("resets retry budget after successful integrate->test", function()
                local task_id = make_task("Post-integrate budget")
                for _ = 1, 5 do
                    record_bounce(task_id, "implement", "review")
                end
                record_bounce(task_id, "integrate", "test")

                local prompt, _, _, _, err = context.build(task_id, P.IMPLEMENT, {})
                test.is_nil(err)
                test.is_true(prompt:find("implement %-> review: 0/5 used %(5 left%)") ~= nil,
                    "post-publish test recovery must not inherit pre-integrate implement->review budget")
            end)

            it("implement phase surfaces implement->design and implement->review caps", function()
                local task_id = make_task("Implement budget")
                record_bounce(task_id, "implement", "design")
                local prompt = context.build(task_id, P.IMPLEMENT, {})
                test.is_true(prompt:find("implement %-> design: 1/3 used") ~= nil,
                    "implement->design count missing")
                test.is_true(prompt:find("implement %-> review: 0/5 used") ~= nil,
                    "implement->review cap missing")
            end)

            it("design phase has no capped edges so no budget section", function()
                local task_id = make_task("Design budget")
                local prompt = context.build(task_id, P.DESIGN, {})
                test.is_true(prompt:find("## Retry Budget") == nil,
                    "design phase should not render budget — no capped outbound edges")
            end)
        end)

        describe("prior research injection", function()
            it("surfaces finding nodes into design prompt", function()
                local task_id = make_task("Prior research in design")
                record_finding(task_id, "api_pattern", "Auth uses app:api router")
                local prompt = context.build(task_id, P.DESIGN, {})
                test.is_true(prompt:find("## Prior Research Discoveries") ~= nil,
                    "design prompt missing prior research section")
                test.is_true(prompt:find("Auth uses app:api router") ~= nil,
                    "design prompt missing finding content")
            end)

            it("surfaces finding nodes into test prompt", function()
                local task_id = make_task("Prior research in test")
                record_finding(task_id, "endpoint_shape", "Returns {ok: true, who: string}")
                local prompt = context.build(task_id, P.TEST, {})
                test.is_true(prompt:find("## Prior Research Discoveries") ~= nil,
                    "test prompt missing prior research section")
                test.is_true(prompt:find("endpoint_shape") ~= nil,
                    "test prompt missing finding key")
            end)
        end)

        describe("lookup tool boundaries", function()
            it("design delegates KB and docs lookup instead of advertising direct tools", function()
                local task_id = make_task("Design lookup boundaries")
                local prompt = context.build(task_id, P.DESIGN, {})

                test.is_true(prompt:find("Delegate lookup gaps to research", 1, true) ~= nil,
                    "design prompt must send lookup gaps through the research delegate")
                test.is_true(prompt:find("direct registry / KB / docs lookup tools", 1, true) ~= nil,
                    "design prompt must explain that direct lookup tools are not available")
                test.is_true(prompt:find("explore / kb_read / fetch_docs to fill gaps", 1, true) == nil,
                    "design prompt must not advertise direct KB/docs tools")
            end)

            it("research phase remains the explicit read-capable context capture phase", function()
                local task_id = make_task("Research lookup boundaries")
                local prompt = context.build(task_id, P.RESEARCH, {})

                test.is_true(prompt:find("search_knowledge for existing findings", 1, true) ~= nil,
                    "research phase should read existing KB findings")
                test.is_true(prompt:find("fetch_docs for platform APIs", 1, true) ~= nil,
                    "research phase should be able to fetch docs")
                test.is_true(prompt:find("save_context one row per concrete finding", 1, true) ~= nil,
                    "research phase should persist task-context findings")
                test.is_true(prompt:find("write_knowledge", 1, true) == nil,
                    "task research must not write durable KB nodes")
            end)
        end)

        -- ============================================================
        -- Prior Phase Result + Summary plumbing.
        -- v22/v24 bounce loops happened because the next orchestrator
        -- spawn saw only the one-line phase_exited.content and missed
        -- the phase_summary_<phase> finding (which carries file paths,
        -- line numbers, decisions, runtime tracebacks). These cases pin
        -- the contract that phase_summary is forwarded on EVERY
        -- transition — success and failure — so every fresh orchestrator
        -- starts with the predecessor's narrative in hand.
        -- ============================================================

        local function record_phase_exit(task_id, from_phase, to_phase, signal, summary)
            nodes_writer.record({
                task_id       = task_id,
                type          = "phase_exited",
                discriminator = from_phase,
                title         = from_phase .. " exited: " .. signal,
                content       = summary,
                status        = "passed",
                visibility    = "user",
                metadata      = { signal = signal, to_phase = to_phase, from_phase = from_phase },
            })
            nodes_writer.record({
                task_id       = task_id,
                type          = "phase_transition",
                discriminator = from_phase .. "->" .. to_phase,
                title         = from_phase .. " -> " .. to_phase,
                content       = "transition",
                status        = "active",
                visibility    = "user",
                metadata      = { from_phase = from_phase, to_phase = to_phase, signal = signal },
            })
        end

        local function record_phase_summary(task_id, phase, body)
            nodes_writer.record({
                task_id       = task_id,
                type          = "finding",
                discriminator = "phase_summary_" .. phase,
                title         = phase .. " summary",
                content       = body,
                status        = "active",
                visibility    = "user",
                metadata      = { phase = phase, kind = "phase_summary" },
            })
        end

        describe("prior phase summary handoff", function()
            it("design->plan: plan prompt carries the design summary verbatim", function()
                local task_id = make_task("Design->Plan handoff")
                record_phase_exit(task_id, "design", "plan", "approved", "design exited approved")
                record_phase_summary(task_id,
                    "design",
                    "Spec lists app.x:foo + app.x:foo_test on app:api. Auth: token. Acceptance: GET /foo 200.")
                local prompt = context.build(task_id, P.PLAN, {})
                test.is_true(prompt:find("## Prior Phase Result") ~= nil,
                    "plan prompt missing prior phase result block")
                test.is_true(prompt:find("Phase: design") ~= nil,
                    "plan prompt missing prior phase name")
                test.is_true(prompt:find("Signal: approved") ~= nil,
                    "plan prompt missing prior signal")
                test.is_true(prompt:find("## Prior Phase Summary %(design%)") ~= nil,
                    "plan prompt missing the summary section even on the success handoff")
                test.is_true(prompt:find("app%.x:foo_test on app:api") ~= nil,
                    "plan prompt missing the actual summary content")
            end)

            it("integrate-fail->implement: orchestrator sees the failure tracebacks", function()
                local task_id = make_task("Integrate fail handoff")
                record_phase_exit(task_id, "integrate", "implement", "fail",
                    "integrate: handlers failed; rolled back")
                record_phase_summary(task_id, "integrate",
                    "Phase: integrate — signal=fail\nStage handlers failed: " ..
                    "test_handler: app.x:foo_test:12: attempt to call a non-function object")
                local prompt = context.build(task_id, P.IMPLEMENT, {})
                test.is_true(prompt:find("Signal: fail") ~= nil,
                    "implement prompt missing fail signal")
                test.is_true(prompt:find("Outcome: FAILED") ~= nil,
                    "fail handoff missing the explicit outcome marker that tells the orch to forward the error")
                test.is_true(prompt:find("## Prior Phase Summary %(integrate%)") ~= nil,
                    "implement prompt missing summary section on integrate-fail")
                test.is_true(prompt:find("attempt to call a non%-function object") ~= nil,
                    "the actionable tracebak is missing — this is the v22/v24 hole")
                test.is_true(prompt:find("app%.x:foo_test:12") ~= nil,
                    "the file:line is missing — agents need this to self%-correct")
            end)

            it("review-bugs->implement: bugs detail forwarded to next implement", function()
                local task_id = make_task("Review bugs handoff")
                record_phase_exit(task_id, "review", "implement", "bugs",
                    "review: spec mismatch on app.x:foo_test")
                record_phase_summary(task_id, "review",
                    "Spec says app.x:foo (kind=function.lua) but branch has app.x:foo (kind=library.lua). Fix kind.")
                local prompt = context.build(task_id, P.IMPLEMENT, {})
                test.is_true(prompt:find("Signal: bugs") ~= nil)
                test.is_true(prompt:find("Outcome: FAILED") ~= nil,
                    "bugs is a fail signal and must be flagged for the implement orch")
                test.is_true(prompt:find("kind=function%.lua") ~= nil,
                    "review's specific mismatch must reach the next implement")
            end)

            it("test-bugs->implement: post-merge runtime failure forwarded", function()
                local task_id = make_task("Test bugs handoff")
                record_phase_exit(task_id, "test", "implement", "bugs",
                    "test: GET /foo returned 500")
                record_phase_summary(task_id, "test",
                    "Endpoint /foo crashed on call: nil index 'rows'. Fix repo.list_recent.")
                local prompt = context.build(task_id, P.IMPLEMENT, {})
                test.is_true(prompt:find("Outcome: FAILED") ~= nil)
                test.is_true(prompt:find("nil index 'rows'") ~= nil,
                    "test phase's runtime trace must reach implement")
                test.is_true(prompt:find("repo%.list_recent") ~= nil,
                    "the specific function-to-fix hint must reach implement")
            end)

            it("repeat bounces surface a Bounce History block", function()
                local task_id = make_task("Repeat bounces")
                -- record_phase_exit writes BOTH phase_exited + phase_transition,
                -- so 3 calls = 3 transitions on the integrate->implement edge.
                record_phase_exit(task_id, "integrate", "implement", "fail", "integrate fail #1")
                record_phase_exit(task_id, "integrate", "implement", "fail", "integrate fail #2")
                record_phase_exit(task_id, "integrate", "implement", "fail", "integrate fail #3")
                local prompt = context.build(task_id, P.IMPLEMENT, {})
                test.is_true(prompt:find("## Bounce History") ~= nil,
                    "repeat bounces should produce a Bounce History block")
                test.is_true(prompt:find("integrate %-> implement: 3 times") ~= nil,
                    "bounce history must report the count")
            end)

            it("first-time transition does NOT render Bounce History (avoids noise)", function()
                local task_id = make_task("First transition")
                -- exactly ONE phase_transition on the design->plan edge
                record_phase_exit(task_id, "design", "plan", "approved", "design ok")
                local prompt = context.build(task_id, P.PLAN, {})
                test.is_true(prompt:find("## Bounce History") == nil,
                    "single forward transition is not a bounce — no history block")
            end)

            it("self-resume on stuck does NOT render prior-phase block (would self-mirror)", function()
                local task_id = make_task("Stuck self-resume")
                record_phase_exit(task_id, "implement", "implement", "stuck", "stuck on step")
                record_phase_summary(task_id, "implement", "stuck details")
                local prompt = context.build(task_id, P.IMPLEMENT, {})
                test.is_true(prompt:find("## Prior Phase Result") == nil,
                    "self-loop must not render Prior Phase Result against itself")
                test.is_true(prompt:find("## Prior Phase Summary") == nil,
                    "self-loop must not render Prior Phase Summary against itself")
            end)

            it("missing phase_summary still renders prior phase result (best effort)", function()
                local task_id = make_task("No summary recorded")
                record_phase_exit(task_id, "design", "plan", "approved", "design ok")
                -- intentionally NO record_phase_summary call
                local prompt = context.build(task_id, P.PLAN, {})
                test.is_true(prompt:find("## Prior Phase Result") ~= nil,
                    "prior result still rendered when summary missing")
                test.is_true(prompt:find("## Prior Phase Summary") == nil,
                    "summary section omitted when there is no finding to render")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
