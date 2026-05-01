local test = require("test")
local sql = require("sql")
local launch = require("launch")
local read_context = require("read_context")
local save_context = require("save_context")
local state_machine = require("state_machine")
local write_spec = require("write_spec")
local task_writer = require("task_writer")
local task_reader = require("task_reader")
local nodes_reader = require("nodes_reader")
local task_consts = require("task_consts")

local function define_tests()
    describe("Task tools", function()
        local created_ids = {}

        local function must_row(rows, index, label)
            local row = rows[index]
            if not row then error((label or "row") .. " missing at index " .. tostring(index)) end
            return row
        end

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
                title    = title or "tools test",
                actor_id = "test.tools",
                spec     = "x",
            }):execute()
            if err then error(err) end
            table.insert(created_ids, res.task_id)
            return res.task_id
        end

        describe("launch", function()
            it("rejects missing title", function()
                local out, err = launch.handler({ start = false })
                test.is_nil(out)
                test.eq(err, "title is required")
            end)

            it("creates a task without starting when requested", function()
                local out, err = launch.handler({
                    title       = "launch tool smoke",
                    description = "created by task tool test",
                    spec        = "do the thing",
                    start       = false,
                })
                test.is_nil(err)
                test.not_nil(out)
                test.not_nil(out.task_id)
                test.eq(out.started, false)
                table.insert(created_ids, out.task_id)

                local row = task_reader.get_task(out.task_id)
                test.not_nil(row)
                test.eq(row.title, "launch tool smoke")
                test.eq(row.description, "created by task tool test")
                test.eq(row.spec, "do the thing")
                test.eq(row.metadata.source, "launch_task")
            end)
        end)

        describe("save_context", function()
            it("rejects when task_id is missing", function()
                local out, err = save_context.save(nil, { key = "k", content = "c" })
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("No active task context") ~= nil)
            end)

            it("rejects when task_id is empty", function()
                local out, err = save_context.save("", { key = "k", content = "c" })
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("No active task context") ~= nil)
            end)

            it("rejects missing key", function()
                local task_id = make_task("save_context missing key")
                local out, err = save_context.save(task_id, { content = "c" })
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("key is required") ~= nil)
            end)

            it("rejects missing content", function()
                local task_id = make_task("save_context missing content")
                local out, err = save_context.save(task_id, { key = "k" })
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("content is required") ~= nil)
            end)

            it("persists a finding node with metadata", function()
                local task_id = make_task("save_context persists")
                local out, err = save_context.save(task_id, {
                    key     = "api_pattern",
                    content = "Auth via app:api router",
                    comment = "for later",
                })
                test.is_nil(err)
                test.not_nil(out)
                test.is_true(out:find("api_pattern") ~= nil, "output should mention key")

                local rows = nodes_reader.by_type(task_id, "finding")
                test.eq(#rows, 1, "one finding node should be persisted")
                local row = must_row(rows, 1, "finding")
                test.eq(row.title, "api_pattern")
                test.eq(row.content, "Auth via app:api router")
                test.eq(row.type, "finding")
                test.eq(row.discriminator, "api_pattern")
                test.eq(row.status, "active")
                test.eq(row.metadata.comment, "for later")
            end)
        end)

        describe("read_context", function()
            it("rejects when task_id is missing", function()
                local out, err = read_context.read(nil)
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("No active task context") ~= nil)
            end)

            it("rejects when task_id is empty", function()
                local out, err = read_context.read("")
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("No active task context") ~= nil)
            end)

            it("returns a friendly message when no findings are saved", function()
                local task_id = make_task("read_context empty")
                local out, err = read_context.read(task_id)
                test.is_nil(err)
                test.is_true(out:find("No prior findings") ~= nil)
            end)

            it("returns saved findings deduped by key", function()
                local task_id = make_task("read_context ordered")
                save_context.save(task_id, { key = "first",  content = "one" })
                save_context.save(task_id, { key = "second", content = "two" })

                local out = read_context.read(task_id)
                test.not_nil(out)
                test.is_true(out:find("Saved Findings %(2%)") ~= nil,
                    "header should carry the finding count")
                test.is_true(out:find("## first") ~= nil)
                test.is_true(out:find("## second") ~= nil)
                test.is_true(out:find("one") ~= nil)
                test.is_true(out:find("two") ~= nil)
            end)
        end)

        describe("write_spec", function()
            it("rejects when task_id is missing", function()
                local out, err = write_spec.write(nil, { content = "body" })
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("No active task context") ~= nil)
            end)

            it("rejects when task_id is empty", function()
                local out, err = write_spec.write("", { content = "body" })
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("No active task context") ~= nil)
            end)

            it("rejects missing content", function()
                local task_id = make_task("write_spec missing content")
                local out, err = write_spec.write(task_id, { title = "t" })
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("spec content is required") ~= nil)
            end)

            it("creates a spec node and updates the task spec+phase", function()
                local task_id = make_task("write_spec persists")

                local out, err = write_spec.write(task_id, {
                    title   = "Impl Spec",
                    content = "Create keeper.foo:bar as function.lua",
                })
                test.is_nil(err)
                test.not_nil(out)

                local rows = nodes_reader.by_type(task_id, "spec")
                test.eq(#rows, 1)
                local spec = must_row(rows, 1, "spec")
                test.eq(spec.title, "Impl Spec")
                test.eq(spec.content, "Create keeper.foo:bar as function.lua")
                test.eq(spec.discriminator, "1")
                test.eq(spec.status, "active")

                local row = task_reader.get_task(task_id)
                test.not_nil(row)
                test.eq(row.spec, "Create keeper.foo:bar as function.lua")
                test.eq(row.phase, "design")
            end)

            it("defaults the node title to include revision number", function()
                local task_id = make_task("write_spec default title")
                write_spec.write(task_id, { content = "body" })

                local rows = nodes_reader.by_type(task_id, "spec")
                test.eq(#rows, 1)
                local spec = must_row(rows, 1, "spec")
                test.is_true(spec.title:find("Implementation Specification") ~= nil,
                    "default title should contain Implementation Specification")
                test.eq(spec.discriminator, "1")
            end)

            it("increments revision on subsequent writes and supersedes prior", function()
                local task_id = make_task("write_spec non-final")
                write_spec.write(task_id, { content = "draft", is_final = false })
                write_spec.write(task_id, { content = "final" })

                local rows = nodes_reader.by_type(task_id, "spec")
                test.eq(#rows, 2, "two revisions should be on record")
                local first = must_row(rows, 1, "first spec")
                local second = must_row(rows, 2, "second spec")
                test.eq(first.discriminator, "1")
                test.eq(first.status, "superseded")
                test.eq(second.discriminator, "2")
                test.eq(second.status, "active")
                test.eq(first.metadata.is_final, false)
            end)
        end)

    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
