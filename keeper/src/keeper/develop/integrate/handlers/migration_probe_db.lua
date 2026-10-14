-- Test support for the live probe migrations: ledger and table state on app:db,
-- portable across SQLite and Postgres.

local sql = require("sql")
local sql_dialect = require("sql_dialect")

local M = {}

local function must_db()
    local db, err = sql.get("app:db")
    if err then error("app:db unavailable: " .. tostring(err)) end
    if not db then error("app:db unavailable") end
    return db
end

local function must_rows(db, statement, params)
    local rows, err = sql_dialect.query(db, statement, params)
    if err then
        db:release()
        error(err)
    end
    return rows or {}
end

local function must_execute(db, statement, params)
    local _, err = sql_dialect.execute(db, statement, params)
    if err then
        db:release()
        error(err)
    end
end

-- Drops the probe table and forgets the migration in the ledger.
function M.reset(table_name: string, migration_id: string)
    local db = must_db()
    must_execute(db, "DROP TABLE IF EXISTS " .. table_name)
    must_execute(db, "DELETE FROM _migrations WHERE id = ?", { migration_id })
    db:release()
end

function M.table_exists(table_name: string): boolean
    local db = must_db()
    local statement = "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?"
    if sql_dialect.is_postgres(db) then
        statement = "SELECT table_name AS name FROM information_schema.tables " ..
            "WHERE table_schema = current_schema() AND table_name = ?"
    end
    local rows = must_rows(db, statement, { table_name })
    db:release()
    return #rows == 1
end

function M.migration_applied(migration_id: string): boolean
    local db = must_db()
    local rows = must_rows(db, "SELECT 1 FROM _migrations WHERE id = ?", { migration_id })
    db:release()
    return #rows == 1
end

-- Records a ledger row as a competing runner would.
function M.record_applied(migration_id: string, description: string): string?
    local db = must_db()
    local _, err = sql_dialect.execute(db, "INSERT INTO _migrations (id, description) VALUES (?, ?)",
        { migration_id, description })
    db:release()
    return err
end

return M
