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
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
