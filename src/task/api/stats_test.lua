local test = require("test")
local sql  = require("sql")
local uuid = require("uuid")
local stats_mod = require("stats")
local consts = require("task_consts")
local writer = require("task_writer")

local function define_tests()
    describe("keeper.task.api:stats.compute", function()
        local created = {}
        local actor_prefix = "test.stats." .. uuid.v7()

        local function purge(db)
            db:execute("DELETE FROM keeper_task_log_fts WHERE task_id IN (SELECT task_id FROM keeper_tasks WHERE actor_id LIKE 'test.stats%')")
            db:execute("DELETE FROM keeper_task_log     WHERE task_id IN (SELECT task_id FROM keeper_tasks WHERE actor_id LIKE 'test.stats%')")
            db:execute("DELETE FROM keeper_tasks        WHERE actor_id LIKE 'test.stats%'")
        end

        before_all(function()
            local db = sql.get(consts.DATABASE.RESOURCE_ID); if db then purge(db); db:release() end
        end)
        after_all(function()
            local db = sql.get(consts.DATABASE.RESOURCE_ID); if db then purge(db); db:release() end
        end)

        local function snapshot()
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            local s = stats_mod.compute(db)
            db:release()
            return s
        end

        local function create(opts)
            opts = opts or {}
            local r, err = writer.create_task({
                title    = opts.title or "stats-test",
                actor_id = actor_prefix,
            }):execute()
            assert(not err, tostring(err))
            table.insert(created, r.task_id)
            if opts.status or opts.phase or opts.archived ~= nil then
                writer.for_task(r.task_id):update_task({
                    status   = opts.status,
                    phase    = opts.phase,
                    archived = opts.archived,
                }):execute()
            end
            return r.task_id
        end

        it("counts status + archived buckets", function()
            local before = snapshot()
            create({ status = "active" })
            create({ status = "active" })
            create({ status = "active" })
            create({ status = "completed" })
            create({ status = "abandoned" })
            create({ status = "active", archived = true })
            local after = snapshot()

            test.eq(after.total - before.total, 6)
            test.eq(after.open - before.open, 4)
            test.eq(after.completed - before.completed, 1)
            test.eq(after.cancelled - before.cancelled, 1)
            test.eq(after.archived - before.archived, 1)
        end)

        it("counts by_phase buckets for spec/design/implement/review/done", function()
            local before = snapshot()
            create({ phase = "spec" })
            create({ phase = "design" })
            create({ phase = "implement" })
            create({ phase = "review" })
            create({ phase = "done" })
            local after = snapshot()
            test.eq(after.by_phase.spec      - before.by_phase.spec,      1)
            test.eq(after.by_phase.design    - before.by_phase.design,    1)
            test.eq(after.by_phase.implement - before.by_phase.implement, 1)
            test.eq(after.by_phase.review    - before.by_phase.review,    1)
            test.eq(after.by_phase.finish    - before.by_phase.finish,    1)
        end)

        it("always returns all by_phase keys", function()
            local s = snapshot()
            test.not_nil(s.by_phase)
            for _, k in ipairs({"spec","design","implement","review","finish"}) do
                test.not_nil(s.by_phase[k])
            end
        end)
    end)
end

return { define_tests = test.run_cases(define_tests) }