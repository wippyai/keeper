local test = require("test")
local sql = require("sql")
local write_plan = require("write_plan")
local step_done = require("step_done")
local step_block = require("step_block")
local task_writer = require("task_writer")
local nodes_reader = require("nodes_reader")
local task_consts = require("task_consts")

local function define_tests()
    describe("Plan tools", function()
        local created_ids = {}

        after_all(function()
            local db = sql.get(task_consts.DATABASE.RESOURCE_ID)
            if not db then return end
            for _, id in ipairs(created_ids) do
                db:execute("DELETE FROM keeper_task_nodes WHERE task_id = ?", { id })
                db:execute("DELETE FROM keeper_tasks WHERE task_id = ?", { id })
            end
            db:release()
        end)

        local function make_task(title)
            local res, err = task_writer.create_task({
                title    = title or "plan test",
                actor_id = "test.plan",
                spec     = "x",
            }):execute()
            if err then error(err) end
            table.insert(created_ids, res.task_id)
            return res.task_id
        end

        describe("write_plan", function()
            it("rejects when task_id missing", function()
                local out, err = write_plan.write(nil, { steps = { { id = "a", kind = "impl", title = "x", task = "y" } } })
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("No active task context") ~= nil)
            end)

            it("rejects empty steps", function()
                local id = make_task("empty steps")
                local _, err = write_plan.write(id, { steps = {} })
                test.not_nil(err)
                test.is_true(err:find("steps array is required") ~= nil)
            end)

            it("rejects missing id", function()
                local id = make_task("missing id")
                local _, err = write_plan.write(id, { steps = { { kind = "impl", title = "t", task = "b" } } })
                test.not_nil(err)
                test.is_true(err:find("id is required") ~= nil)
            end)

            it("rejects unknown kind", function()
                local id = make_task("bad kind")
                local _, err = write_plan.write(id, { steps = { { id = "a", kind = "bogus", title = "t", task = "b" } } })
                test.not_nil(err)
                test.is_true(err:find("kind must be one of") ~= nil)
            end)

            it("rejects needs referencing unknown id", function()
                local id = make_task("bad needs")
                local _, err = write_plan.write(id, { steps = {
                    { id = "a", kind = "impl", title = "t", task = "b", needs = { "zzz" } }
                } })
                test.not_nil(err)
                test.is_true(err:find("unknown step id") ~= nil)
            end)

            it("persists plan + step nodes with metadata", function()
                local id = make_task("persists plan")
                local out, err = write_plan.write(id, {
                    title   = "Demo Plan",
                    summary = "one endpoint + verify",
                    steps = {
                        { id = "mk_fn", kind = "impl", target = "app.api:ping", title = "create handler",
                          task = "create function.lua app.api:ping" },
                        { id = "mk_ep", kind = "impl", target = "app.api:ping.endpoint", title = "create endpoint",
                          task = "create http.endpoint app.api:ping.endpoint", needs = { "mk_fn" } },
                        { id = "probe", kind = "endpoint_probe", target = "GET /api/v1/ping", title = "probe",
                          task = "test_endpoint GET /api/v1/ping returns 200",
                          verification_tool = "test_endpoint", needs = { "mk_ep" } },
                    },
                })
                test.is_nil(err)
                test.not_nil(out)

                local plans = nodes_reader.by_type(id, "plan")
                test.eq(#plans, 1, "one plan row persisted")
                test.eq(plans[1].title, "Demo Plan")
                test.eq(plans[1].discriminator, "1")
                test.eq(plans[1].status, "active")

                local steps = nodes_reader.children(plans[1].node_id)
                test.eq(#steps, 3, "three step rows persisted as children")
                local by_id = {}
                for _, s in ipairs(steps) do by_id[s.discriminator] = s end
                test.eq(by_id.mk_fn.status, "pending")
                test.eq(by_id.mk_fn.metadata.kind, "impl")
                test.eq(by_id.mk_ep.metadata.needs[1], "mk_fn")
                test.eq(by_id.probe.metadata.verification_tool, "test_endpoint")
                test.eq(by_id.probe.metadata.kind, "endpoint_probe")
            end)

            it("supersedes prior plan on re-plan", function()
                local id = make_task("re-plan")
                write_plan.write(id, { steps = { { id = "a", kind = "impl", title = "t", task = "b" } } })
                write_plan.write(id, { steps = {
                    { id = "b", kind = "impl", title = "t2", task = "b2" },
                    { id = "c", kind = "verify", title = "v", task = "v", needs = { "b" } },
                } })

                local plans = nodes_reader.by_type(id, "plan")
                test.eq(#plans, 2, "two plan revisions persisted")
                test.eq(plans[1].status, "superseded", "prior plan marked superseded")
                test.eq(plans[2].status, "active")
                test.eq(plans[2].discriminator, "2")

                local old_steps = nodes_reader.children(plans[1].node_id)
                test.eq(#old_steps, 1)
                test.eq(old_steps[1].status, "cancelled",
                    "prior open steps cancelled when plan is superseded")
            end)
        end)

        describe("step_done", function()
            it("marks a pending step completed", function()
                local id = make_task("step_done happy")
                write_plan.write(id, { steps = { { id = "a", kind = "impl", title = "t", task = "b" } } })

                local out, err = step_done.mark(id, { step_id = "a", result_summary = "created entry" })
                test.is_nil(err)
                test.is_true(out:find("marked completed") ~= nil)

                local rows = nodes_reader.by_type(id, "step", { discriminator = "a" })
                test.eq(rows[#rows].status, "completed")
                test.eq(rows[#rows].result_summary, "created entry")
            end)

            it("rejects unknown step_id", function()
                local id = make_task("step_done unknown")
                write_plan.write(id, { steps = { { id = "a", kind = "impl", title = "t", task = "b" } } })
                local _, err = step_done.mark(id, { step_id = "zzz" })
                test.not_nil(err)
                test.is_true(err:find("not found") ~= nil)
            end)

            it("rejects closing an already-completed step", function()
                local id = make_task("step_done twice")
                write_plan.write(id, { steps = { { id = "a", kind = "impl", title = "t", task = "b" } } })
                step_done.mark(id, { step_id = "a", result_summary = "first" })
                local _, err = step_done.mark(id, { step_id = "a", result_summary = "second" })
                test.not_nil(err)
                test.is_true(err:find("is completed") ~= nil)
            end)
        end)

        describe("step_block", function()
            it("marks step blocked and emits ask_user node", function()
                local id = make_task("step_block happy")
                write_plan.write(id, { steps = { { id = "a", kind = "impl", title = "t", task = "b" } } })

                local out, err = step_block.block(id, { step_id = "a", question = "which port?" })
                test.is_nil(err)
                test.is_true(out:find("blocked") ~= nil)

                local steps = nodes_reader.by_type(id, "step", { discriminator = "a" })
                test.eq(steps[#steps].status, "blocked")
                test.eq(steps[#steps].error_message, "which port?")
                test.not_nil(steps[#steps].metadata.blocker_node_id)

                local asks = nodes_reader.by_type(id, "ask_user")
                test.eq(#asks, 1)
                test.eq(asks[1].discriminator, "a")
                test.eq(asks[1].content, "which port?")
            end)

            it("rejects blocking a completed step", function()
                local id = make_task("step_block on done")
                write_plan.write(id, { steps = { { id = "a", kind = "impl", title = "t", task = "b" } } })
                step_done.mark(id, { step_id = "a" })

                local _, err = step_block.block(id, { step_id = "a", question = "?" })
                test.not_nil(err)
                test.is_true(err:find("is completed") ~= nil)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
