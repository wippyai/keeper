local test = require("test")
local schema = require("schema")

local function fake_db()
    local db = { statements = {} }
    function db:execute(statement)
        table.insert(self.statements, statement)
        return true, nil
    end
    return db
end

local function define_tests()
    describe("keeper.git.persist:schema", function()
        it("ensures git run table and indexes idempotently", function()
            local db = fake_db()
            schema.drop(db)
            local ok, err = schema.ensure(db)
            test.is_nil(err)
            test.is_true(ok)

            local joined = table.concat(db.statements, "\n")
            test.is_true(joined:find("keeper_git_runs", 1, true) ~= nil)
            test.is_true(joined:find("keeper_idx_git_runs_finished", 1, true) ~= nil)
            test.is_true(joined:find("keeper_idx_git_runs_status", 1, true) ~= nil)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
