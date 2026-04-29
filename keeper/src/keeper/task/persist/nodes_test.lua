local test = require("test")
local uuid = require("uuid")
local sql = require("sql")

local nodes_writer = require("nodes_writer")
local nodes_reader = require("nodes_reader")

local function fresh_task_id()
    local id, _ = uuid.v7()
    return "test-task-" .. id
end

-- Clean up rows for a given task_id so a re-run is independent.
local function wipe(task_id)
    local db, err = sql.get("keeper.state:db")
    if err then return end
    db:execute("DELETE FROM keeper_task_nodes WHERE task_id = ?", { task_id })
    db:release()
end

local function must_workspace(task_id)
    local ws, err = nodes_writer.for_task(task_id)
    test.is_nil(err)
    if not ws then error("nodes writer workspace unavailable") end
    return ws
end

local function define_tests()
    test.describe("keeper.task.persist:nodes_writer + nodes_reader", function()

        test.it("inserts a root node and returns row metadata", function()
            local task_id = fresh_task_id()
            local ws = must_workspace(task_id)

            local row, werr = ws:record({
                type = "phase_started",
                discriminator = "design",
                title = "Started design phase",
                visibility = "user",
            })
            test.is_nil(werr); test.not_nil(row)
            test.not_nil(row.node_id)
            test.eq(row.task_id, task_id)
            test.eq(row.path, "/")
            test.eq(row.depth, 0)
            test.eq(row.position, 0)
            test.eq(row.seq, 1)

            wipe(task_id)
        end)

        test.it("rejects missing task_id and missing type", function()
            local _, err1 = nodes_writer.record({ type = "x" })
            test.not_nil(err1)
            test.is_true(err1:find("task_id required") ~= nil)

            local _, err2 = nodes_writer.record({ task_id = "t" })
            test.not_nil(err2)
            test.is_true(err2:find("type required") ~= nil)
        end)

        test.it("builds a two-level hierarchy with correct path/depth/position", function()
            local task_id = fresh_task_id()
            local ws = must_workspace(task_id)

            local parent, _ = ws:record({ type = "integrate_stage", discriminator = "run" })
            test.not_nil(parent)

            local child1, _ = ws:node(parent.node_id):add({
                type = "integrate_stage", discriminator = "lint",
            })
            local child2, _ = ws:node(parent.node_id):add({
                type = "integrate_stage", discriminator = "publish",
            })
            test.eq(child1.depth, 1)
            test.eq(child2.depth, 1)
            test.eq(child1.position, 0)
            test.eq(child2.position, 1)
            test.is_true(child1.path:find(parent.node_id, 1, true) ~= nil)

            local grand, _ = ws:node(child1.node_id):add({
                type = "integrate_handler", discriminator = "migration_handler",
            })
            test.eq(grand.depth, 2)

            -- children() returns siblings in position order
            local kids, cerr = nodes_reader.children(parent.node_id)
            test.is_nil(cerr)
            test.eq(#kids, 2)
            test.eq(kids[1].node_id, child1.node_id)
            test.eq(kids[2].node_id, child2.node_id)

            wipe(task_id)
        end)

        test.it("list() returns rows in seq order and supports visibility filter", function()
            local task_id = fresh_task_id()
            local ws = must_workspace(task_id)

            ws:record({ type = "phase_started", discriminator = "design", visibility = "user" })
            ws:record({ type = "baseline", discriminator = "design", visibility = "debug" })
            ws:record({ type = "tool_call", discriminator = "explore", visibility = "user" })

            local all, _ = nodes_reader.list(task_id, { visibility = "all" })
            if not all then error("expected node rows") end
            test.eq(#all, 3)
            local first = all[1]
            local third = all[3]
            if not first or not third then error("expected three node rows") end
            test.eq(first.seq, 1)
            test.eq(third.seq, 3)

            local user_only, _ = nodes_reader.list(task_id, { visibility = "user" })
            test.eq(#user_only, 2)
            for _, r in ipairs(user_only) do test.eq(r.visibility, "user") end

            local both, _ = nodes_reader.list(task_id, { visibility = "user,debug" })
            test.eq(#both, 3)

            wipe(task_id)
        end)

        test.it("latest_of_type returns the newest spec, by_type returns all revisions", function()
            local task_id = fresh_task_id()
            local ws = must_workspace(task_id)

            ws:record({ type = "spec", discriminator = "1", status = "superseded", title = "v1" })
            ws:record({ type = "spec", discriminator = "2", status = "superseded", title = "v2" })
            ws:record({ type = "spec", discriminator = "3", status = "active",     title = "v3" })

            local current, _ = nodes_reader.latest_of_type(task_id, "spec", { status = "active" })
            test.not_nil(current)
            test.eq(current.discriminator, "3")
            test.eq(current.status, "active")

            local all, _ = nodes_reader.by_type(task_id, "spec")
            if not all then error("expected spec rows") end
            test.eq(#all, 3)
            local first_spec = all[1]
            local third_spec = all[3]
            if not first_spec or not third_spec then error("expected three spec rows") end
            test.eq(first_spec.discriminator, "1")
            test.eq(third_spec.discriminator, "3")

            wipe(task_id)
        end)

        test.it("findings() dedupes by discriminator (key) to newest row", function()
            local task_id = fresh_task_id()
            local ws = must_workspace(task_id)

            ws:record({ type = "finding", discriminator = "pattern_x", status = "superseded", content = "v1" })
            ws:record({ type = "finding", discriminator = "pattern_x", status = "active",     content = "v2" })
            ws:record({ type = "finding", discriminator = "pattern_y", status = "active",     content = "other" })

            local f, _ = nodes_reader.findings(task_id)
            test.eq(#f, 2)
            -- pattern_x should be the v2 row
            local x
            for _, r in ipairs(f) do if r.discriminator == "pattern_x" then x = r end end
            test.not_nil(x)
            test.eq(x.content, "v2")

            wipe(task_id)
        end)

        test.it("transition_count reads phase_transition rows by discriminator", function()
            local task_id = fresh_task_id()
            local ws = must_workspace(task_id)

            ws:record({ type = "phase_transition", discriminator = "implement->design", title = "t1" })
            ws:record({ type = "phase_transition", discriminator = "implement->design", title = "t2" })
            ws:record({ type = "phase_transition", discriminator = "review->implement", title = "t3" })

            local n1, e1 = nodes_reader.transition_count(task_id, "implement", "design")
            test.is_nil(e1)
            test.eq(n1, 2)

            local n2 = nodes_reader.transition_count(task_id, "review", "implement")
            test.eq(n2, 1)

            local n3 = nodes_reader.transition_count(task_id, "design", "implement")
            test.eq(n3, 0)

            wipe(task_id)
        end)

        test.it("transition_count can count after a progress boundary", function()
            local task_id = fresh_task_id()
            local ws = must_workspace(task_id)

            ws:record({ type = "phase_transition", discriminator = "implement->review", title = "old push" })
            ws:record({ type = "phase_transition", discriminator = "integrate->test", title = "published" })
            ws:record({ type = "phase_transition", discriminator = "implement->review", title = "post-test fix" })

            local reset_seq, seq_err = nodes_reader.latest_transition_seq(task_id, "integrate", "test")
            test.is_nil(seq_err)
            test.not_nil(reset_seq)

            local total = nodes_reader.transition_count(task_id, "implement", "review")
            test.eq(total, 2)

            local after_reset = nodes_reader.transition_count(task_id, "implement", "review",
                { after_seq = reset_seq })
            test.eq(after_reset, 1)

            wipe(task_id)
        end)

        test.it("update() can transition a tool_call from running to passed with timing", function()
            local task_id = fresh_task_id()
            local ws = must_workspace(task_id)

            local row, _ = ws:record({
                type = "tool_call", discriminator = "explore",
                status = "running", title = "explore_state",
            })
            test.eq(row.seq, 1)

            local _, uerr = nodes_writer.update(row.node_id, {
                status = "passed",
                execution_ms = 42,
                result_summary = "12 entries returned",
            })
            test.is_nil(uerr)

            local reread, _ = nodes_reader.get(row.node_id)
            test.not_nil(reread)
            test.eq(reread.status, "passed")
            test.eq(tonumber(reread.execution_ms), 42)
            test.eq(reread.result_summary, "12 entries returned")

            wipe(task_id)
        end)

    end)
end

return { define_tests = define_tests }
