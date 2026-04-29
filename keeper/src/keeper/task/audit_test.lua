local test  = require("test")
local uuid  = require("uuid")
local sql   = require("sql")

local audit  = require("audit")
local reader = require("nodes_reader")

local function fresh_task_id()
    local id, _ = uuid.v7()
    return "audit-test-" .. id
end

local function wipe(task_id)
    local db, err = sql.get("keeper.state:db")
    if err then return end
    db:execute("DELETE FROM keeper_task_nodes WHERE task_id = ?", { task_id })
    db:release()
end

local function ctx_for(task_id, extra)
    local c = {
        task_id        = task_id,
        parent_node_id = nil,
        agent_id       = "test-agent",
        dataflow_id    = "df-123",
        changeset_id   = "cs-abc",
        phase          = "design",
    }
    if extra then
        for k, v in pairs(extra) do c[k] = v end
    end
    return c
end

local function define_tests()
    test.describe("keeper.task:audit.wrap", function()

        test.it("no-ops when task_id is absent in ctx", function()
            local called = false
            local r, err = audit._wrap_with_ctx({ tool = "demo" }, function()
                called = true
                return "ok", nil
            end, { task_id = nil })
            test.is_true(called)
            test.eq(r, "ok")
            test.is_nil(err)
        end)

        test.it("writes a tool_call row with status=passed on success", function()
            local tid = fresh_task_id()
            local called = false
            local r, err = audit._wrap_with_ctx(
                { tool = "explore_state", discriminator = "tree", target = "app" },
                function()
                    called = true
                    return { rows = 3 }, nil
                end,
                ctx_for(tid)
            )
            test.is_true(called)
            test.not_nil(r)
            test.is_nil(err)

            local rows, rerr = reader.by_type(tid, "tool_call")
            test.is_nil(rerr)
            test.eq(#rows, 1)
            local row = rows[1]
            test.eq(row.type, "tool_call")
            test.eq(row.discriminator, "tree")
            test.eq(row.status, "passed")
            test.eq(row.title, "explore_state: app")
            test.eq(row.agent_id, "test-agent")
            test.eq(row.dataflow_id, "df-123")
            test.not_nil(row.result_summary)
            test.is_true(tonumber(row.execution_ms) >= 0)

            wipe(tid)
        end)

        test.it("captures (nil, err) return as status=failed", function()
            local tid = fresh_task_id()
            local r, err = audit._wrap_with_ctx(
                { tool = "edit", discriminator = "create", target = "ns:foo" },
                function() return nil, "schema error: missing method" end,
                ctx_for(tid)
            )
            test.is_nil(r)
            test.eq(err, "schema error: missing method")

            local row = reader.latest_of_type(tid, "tool_call")
            test.not_nil(row)
            test.eq(row.status, "failed")
            test.eq(row.error_message, "schema error: missing method")

            wipe(tid)
        end)

        test.it("propagates raised error (no pcall wrapping)", function()
            local tid = fresh_task_id()
            local raised_ok, raised_msg = pcall(function()
                audit._wrap_with_ctx(
                    { tool = "lint" },
                    function() error("boom") end,
                    ctx_for(tid)
                )
            end)
            test.is_false(raised_ok)
            test.is_true(string.find(raised_msg, "boom", 1, true) ~= nil)
            -- Row stays at status=running because the update after body never executed.
            local row = reader.latest_of_type(tid, "tool_call")
            test.not_nil(row)
            test.eq(row.status, "running")

            wipe(tid)
        end)

        test.it("uses custom summarise() when provided", function()
            local tid = fresh_task_id()
            audit._wrap_with_ctx(
                {
                    tool = "get_entries",
                    summarise = function(result, _err)
                        return "loaded " .. (result and result.count or 0) .. " entries"
                    end,
                },
                function() return { count = 12 }, nil end,
                ctx_for(tid)
            )

            local row = reader.latest_of_type(tid, "tool_call")
            test.not_nil(row)
            test.eq(row.result_summary, "loaded 12 entries")

            wipe(tid)
        end)

        test.it("honours parent_node_id so child calls nest under a parent", function()
            local tid = fresh_task_id()
            local writer = require("nodes_writer")
            local parent, _ = writer.record({
                task_id       = tid,
                type          = "phase_started",
                discriminator = "design",
                title         = "Started design phase",
            })
            test.not_nil(parent)

            audit._wrap_with_ctx(
                { tool = "explore" },
                function() return {}, nil end,
                ctx_for(tid, { parent_node_id = parent.node_id })
            )

            local row = reader.latest_of_type(tid, "tool_call")
            test.not_nil(row)
            test.eq(row.parent_node_id, parent.node_id)
            test.eq(tonumber(row.depth), 1)

            wipe(tid)
        end)

        test.it("falls back to root insert when parent_node_id is stale (foreign id)", function()
            local tid = fresh_task_id()
            audit._wrap_with_ctx(
                { tool = "explore" },
                function() return {}, nil end,
                ctx_for(tid, { parent_node_id = "stale-foreign-dataflow-node-id" })
            )

            local row = reader.latest_of_type(tid, "tool_call")
            test.not_nil(row)
            test.is_nil(row.parent_node_id)
            test.eq(tonumber(row.depth), 0)

            wipe(tid)
        end)

        test.it("writes visibility=debug when cfg.visibility says so", function()
            local tid = fresh_task_id()
            audit._wrap_with_ctx(
                { tool = "session_info", visibility = "debug" },
                function() return {}, nil end,
                ctx_for(tid)
            )

            local row = reader.latest_of_type(tid, "tool_call")
            test.not_nil(row)
            test.eq(row.visibility, "debug")

            wipe(tid)
        end)

        test.it("rejects calls without cfg.tool", function()
            local ok, err_msg = pcall(function()
                audit._wrap_with_ctx({}, function() end, ctx_for("t"))
            end)
            test.is_false(ok)
            test.is_true(string.find(err_msg, "cfg.tool required", 1, true) ~= nil)
        end)

    end)
end

return { define_tests = define_tests }
