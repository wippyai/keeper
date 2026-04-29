local test = require("test")
local task_debug = require("task_debug")

local function define_tests()
    describe("task debug helpers", function()
        it("parses comma-separated type filters", function()
            local out = task_debug.parse_types_csv("plan, integrate_stage ,finding")
            test.eq(#out, 3)
            test.eq(out[1], "plan")
            test.eq(out[2], "integrate_stage")
            test.eq(out[3], "finding")
        end)

        it("returns nil for empty type filters", function()
            test.is_nil(task_debug.parse_types_csv(nil))
            test.is_nil(task_debug.parse_types_csv(""))
            test.is_nil(task_debug.parse_types_csv(" , , "))
        end)

        it("deduplicates dataflow ids in first-seen order", function()
            local ids = task_debug.unique_dataflow_ids({
                { dataflow_id = "a" },
                { dataflow_id = "" },
                { dataflow_id = "b" },
                { dataflow_id = "a" },
                {},
            })
            test.eq(#ids, 2)
            test.eq(ids[1], "a")
            test.eq(ids[2], "b")
        end)

        it("returns the latest dataflow id by task-node order", function()
            local id = task_debug.latest_dataflow_id({
                { dataflow_id = "first" },
                {},
                { dataflow_id = "" },
                { dataflow_id = "last" },
            })
            test.eq(id, "last")
        end)

        it("counts statuses", function()
            local counts = task_debug.status_counts({
                { status = "completed" },
                { status = "failed" },
                { status = "completed" },
                {},
            })
            test.eq(counts.completed, 2)
            test.eq(counts.failed, 1)
            test.eq(counts["?"], 1)
        end)

        it("selects the latest failed node by task-node order", function()
            local node = task_debug.latest_failed_node({
                { seq = 1, status = "failed", error_message = "old" },
                { seq = 2, status = "completed" },
                { seq = 3, status = "failed", error_message = "new" },
            })
            test.eq(node.seq, 3)
            test.eq(node.error_message, "new")
        end)

        it("marks a failure historical once later phase progress exists", function()
            local current = task_debug.failure_is_current(
                { status = "active", phase = "test" },
                {
                    { seq = 10, type = "tool_call", status = "failed", error_message = "old probe" },
                    { seq = 11, type = "phase_transition", discriminator = "test->implement", status = "active" },
                },
                { seq = 10, type = "tool_call", status = "failed", error_message = "old probe" }
            )
            test.is_false(current)
        end)

        it("does not report stale failures as current blockers on completed tasks", function()
            local blocker, reason = task_debug.current_blocker(
                { status = "completed", phase = "finish" },
                {
                    { seq = 10, type = "tool_call", status = "failed", error_message = "old" },
                    { seq = 20, type = "phase_transition", discriminator = "test->finish", status = "active" },
                }
            )
            test.is_nil(blocker)
            test.eq(reason, "task completed")
        end)

        it("prefers an active ask_user row as the current blocker", function()
            local blocker, reason = task_debug.current_blocker(
                { status = "waiting_for_user", phase = "implement" },
                {
                    { seq = 10, type = "tool_call", status = "failed", error_message = "old" },
                    { seq = 11, type = "ask_user", status = "active", content = "choose" },
                }
            )
            test.eq(blocker.seq, 11)
            test.eq(reason, "waiting for user response")
        end)

        it("recommends no action for completed tasks", function()
            test.eq(task_debug.next_action({ status = "completed", phase = "finish" }), "none — task completed")
        end)

        it("recommends polling while the latest flow is running", function()
            local action = task_debug.next_action(
                { status = "active", phase = "test" },
                nil,
                { status = "running", running = 1 }
            )
            test.eq(action, "wait or poll again; latest phase dataflow is still running")
        end)

        it("recommends responding to active ask_user blockers", function()
            local action = task_debug.next_action(
                { status = "waiting_for_user", phase = "implement" },
                { type = "ask_user" },
                nil
            )
            test.eq(action, "respond to the active ask_user node")
        end)

        it("extracts phase names from flow titles", function()
            test.eq(task_debug.phase_from_flow_title("plan: build feature"), "plan")
            test.eq(task_debug.phase_from_flow_title("integrate: task abc"), "integrate")
            test.is_nil(task_debug.phase_from_flow_title("no phase here"))
        end)

        it("classifies phase attempt state from accepted exits and flow status", function()
            test.eq(task_debug.phase_attempt_state({ running = 1 }), "running")
            test.eq(task_debug.phase_attempt_state({ failed = 1, accepted_exits = 1 }), "recovered")
            test.eq(task_debug.phase_attempt_state({ completed = 1, accepted_exits = 1 }), "ok")
            test.eq(task_debug.phase_attempt_state({ failed = 1 }), "failed")
            test.eq(task_debug.phase_attempt_state({ completed = 1 }), "no_exit")
            test.eq(task_debug.phase_attempt_state({ flows = 1 }), "started")
        end)

        it("summarises phase attempts separately from accepted exits", function()
            local rollups = {
                f1 = { title = "plan: task", status = "failed" },
                f2 = { title = "plan: task", status = "completed" },
                f3 = { title = "implement: task", status = "running" },
            }
            local rows = task_debug.phase_attempt_rows({
                { dataflow_id = "f1" },
                { dataflow_id = "f2" },
                { dataflow_id = "f3" },
                { type = "phase_transition", discriminator = "plan->implement" },
                { type = "phase_transition", discriminator = "implement->review" },
            }, function(id) return rollups[id] end)

            test.eq(#rows, 2)
            test.eq(rows[1].phase, "plan")
            test.eq(rows[1].flows, 2)
            test.eq(rows[1].failed, 1)
            test.eq(rows[1].completed, 1)
            test.eq(rows[1].accepted_exits, 1)
            test.eq(rows[1].state, "recovered")
            test.eq(rows[2].phase, "implement")
            test.eq(rows[2].running, 1)
            test.eq(rows[2].accepted_exits, 1)
            test.eq(rows[2].state, "running")
        end)

        it("groups integrate stages under their run root", function()
            local runs = task_debug.integrate_runs({
                { node_id = "r1", type = "integrate_stage", discriminator = "run", status = "failed" },
                { node_id = "s1", parent_node_id = "r1", type = "integrate_stage", discriminator = "snapshot", status = "passed" },
                { node_id = "s2", parent_node_id = "r1", type = "integrate_stage", discriminator = "handlers", status = "failed" },
                { node_id = "orphan", parent_node_id = "missing", type = "integrate_stage", discriminator = "restore", status = "passed" },
            })
            test.eq(#runs, 1)
            local run = runs[1]
            if not run then error("run missing") end
            local second_stage = run.stages[2]
            if not second_stage then error("second stage missing") end
            test.eq(run.root.node_id, "r1")
            test.eq(#run.stages, 2)
            test.eq(second_stage.discriminator, "handlers")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
