local sql_dialect = require("sql_dialect")
local test = require("test")

local function define_tests()
    test.describe("keeper.internal sql dialect helpers", function()
        test.it("binds positional parameters for postgres", function()
            local sql, err = sql_dialect.bind_postgres_placeholders(
                "SELECT * FROM t WHERE a = ? AND b IN (?, ?)",
                { "a", "b", "c" })
            test.is_nil(err)
            test.eq(sql, "SELECT * FROM t WHERE a = $1 AND b IN ($2, $3)")
        end)

        test.it("does not rewrite question marks inside SQL literals or comments", function()
            local sql, err = sql_dialect.bind_postgres_placeholders(
                "SELECT '?' AS q, \"?\" AS ident -- ? comment\n" ..
                "FROM t /* ? block */ WHERE body = 'it''s ?' AND id = ?",
                { "id-1" })
            test.is_nil(err)
            test.eq(sql,
                "SELECT '?' AS q, \"?\" AS ident -- ? comment\n" ..
                "FROM t /* ? block */ WHERE body = 'it''s ?' AND id = $1")
        end)

        test.it("fails closed when placeholders and parameters do not match", function()
            local sql, err = sql_dialect.bind_postgres_placeholders(
                "SELECT * FROM t WHERE a = ? AND b = ?", { "a" })
            test.is_nil(sql)
            test.not_nil(err)
            test.is_true(err:find("placeholder count mismatch", 1, true) ~= nil)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
