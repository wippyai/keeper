-- Unit tests for keeper.task:scope.for_phase
--
-- Pins the shape of the task-scope payload that every spawn site
-- (lifecycle.spawn_agent / spawn_function and develop:implement_task)
-- declares via :with_input on the dataflow root.

local test = require("test")
local sql  = require("sql")
local uuid = require("uuid")

local scope          = require("scope")
local task_writer    = require("task_writer")
local changeset_client = require("changeset_client")

local function fresh_task()
    local res = task_writer.create_task({
        title    = "scope probe",
        actor_id = "scope_test",
    }):execute()
    return res and res.task_id or nil
end

local function cleanup(task_id)
    if not task_id or task_id == "" then return end
    local db, err = sql.get("keeper.state:db")
    if err then error("db: " .. tostring(err)) end
    if not db then error("db unavailable") end
    db:execute("DELETE FROM keeper_changeset_changes WHERE changeset_id IN (SELECT changeset_id FROM keeper_changesets WHERE task_id = ?)", { task_id })
    db:execute("DELETE FROM keeper_changesets WHERE task_id = ?", { task_id })
    db:execute("DELETE FROM keeper_task_nodes WHERE task_id = ?", { task_id })
    db:execute("DELETE FROM keeper_tasks WHERE task_id = ?", { task_id })
    db:release()
end

local function define_tests()
    test.describe("keeper.task:scope.for_phase", function()

        test.it("returns task_id+phase with nil changeset/branch when no cs exists",
            function()
                local task_id = fresh_task()
                test.not_nil(task_id)

                local s = scope.for_phase(task_id, "design")
                test.eq(s.task_id, task_id)
                test.eq(s.phase, "design")
                test.is_nil(s.changeset_id)
                test.is_nil(s.overlay_branch)
                test.is_nil(s.actor_id)

                cleanup(task_id)
            end)

        test.it("resolves changeset_id and overlay_branch from active_for_task",
            function()
                local task_id = fresh_task()
                local ws, err = changeset_client.create({
                    title    = "scope probe cs",
                    kind     = "session",
                    actor_id = "scope_test",
                    task_id  = task_id,
                })
                test.is_nil(err)

                local s = scope.for_phase(task_id, "implement")
                test.eq(s.task_id, task_id)
                test.eq(s.phase, "implement")
                test.eq(s.changeset_id, ws.changeset_id)
                test.eq(s.overlay_branch, ws.state_branch)
                test.is_nil(s.actor_id)

                cleanup(task_id)
            end)

        test.it("opts.changeset_id is the fallback when no live cs exists",
            function()
                local task_id = fresh_task()
                local s = scope.for_phase(task_id, "integrate", {
                    changeset_id = "fallback-cs-xyz",
                })
                test.eq(s.changeset_id, "fallback-cs-xyz")
                test.is_nil(s.overlay_branch,
                    "no overlay_branch when active_for_task returns nothing")

                cleanup(task_id)
            end)

        test.it("opts.changeset_id is overridden by a live changeset",
            function()
                local task_id = fresh_task()
                local ws, _ = changeset_client.create({
                    title    = "scope probe cs",
                    kind     = "session",
                    actor_id = "scope_test",
                    task_id  = task_id,
                })

                local s = scope.for_phase(task_id, "review", {
                    changeset_id = "ignored-fallback",
                })
                test.eq(s.changeset_id, ws.changeset_id,
                    "live cs wins over the opts fallback")

                cleanup(task_id)
            end)

        test.it("opts.actor_id flows through onto the payload", function()
            local task_id = fresh_task()
            local s = scope.for_phase(task_id, "integrate", {
                actor_id = "user@example.com",
            })
            test.eq(s.actor_id, "user@example.com")
            cleanup(task_id)
        end)

        test.it("returns the same fields each call (shape contract)", function()
            local task_id = fresh_task()
            local s = scope.for_phase(task_id, "plan")
            -- The shape is the contract every spawn site relies on. Any
            -- field added here must be added consciously.
            local keys = {}
            for k in pairs(s) do keys[k] = true end
            test.is_true(keys.task_id and keys.phase
                and keys.changeset_id ~= nil
                and keys.overlay_branch ~= nil
                and keys.actor_id ~= nil
                or  -- nil-presence still counts: keys must exist
                (s.task_id ~= nil and s.phase ~= nil),
                "task_id and phase always present")
            cleanup(task_id)
        end)

    end)
end

return { define_tests = define_tests }
