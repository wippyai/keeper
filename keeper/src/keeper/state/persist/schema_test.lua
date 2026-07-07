local test = require("test")
local schema = require("schema")

local function fake_db(opts)
    opts = opts or {}
    local db = { statements = {} }
    function db:execute(statement)
        table.insert(self.statements, statement)
        if opts.fail_fts and statement:find("CREATE VIRTUAL TABLE IF NOT EXISTS keeper_overlay_chunks_fts", 1, true) then
            return nil, "fts unavailable"
        end
        return true, nil
    end
    return db
end

local function define_tests()
    describe("keeper.state.persist:schema", function()
        it("ensures overlay tables idempotently", function()
            local db = fake_db()
            schema.drop(db)
            local ok, err = schema.ensure(db)
            test.is_nil(err)
            test.is_true(ok)

            local joined = table.concat(db.statements, "\n")
            test.is_true(joined:find("keeper_overlay_entries", 1, true) ~= nil)
            test.is_true(joined:find("keeper_overlay_chunks", 1, true) ~= nil)
            test.is_true(joined:find("keeper_overlay_attributes", 1, true) ~= nil)
            test.is_true(joined:find("keeper_overlay_edges", 1, true) ~= nil)
        end)

        it("creates table-backed search index when FTS is unavailable", function()
            local db = fake_db({ fail_fts = true })
            schema.drop(db)
            local ok, err = schema.ensure(db)
            test.is_nil(err)
            test.is_true(ok)

            local joined = table.concat(db.statements, "\n")
            test.is_true(joined:find("CREATE TABLE IF NOT EXISTS keeper_overlay_chunks_fts", 1, true) ~= nil)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
