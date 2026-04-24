local test = require("test")
local sql  = require("sql")
local status_mod = require("status")
local consts = require("task_consts")

local function define_tests()
    describe("keeper.task.api:status.compute", function()
        it("returns table with version, uptime_seconds, task_count as numbers", function()
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            test.not_nil(db)
            local s, err = status_mod.compute(db)
            db:release()
            test.is_nil(err)
            test.not_nil(s)
            test.eq(type(s), "table")
            test.eq(type(s.version), "number")
            test.eq(type(s.uptime_seconds), "number")
            test.eq(type(s.task_count), "number")
        end)
    end)
end

return { define_tests = test.run_cases(define_tests) }