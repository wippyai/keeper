return require("migration").define(function()
    migration("Add task_id column to keeper_changesets (one changeset per task)", function()
        database("sqlite", function()
            up(function(db)
                local rows, err = db:query([[
                    SELECT 1 FROM pragma_table_info('keeper_changesets') WHERE name = 'task_id'
                ]])
                if err then error("probe task_id: " .. err) end
                if not rows or #rows == 0 then
                    local _, add_err = db:execute("ALTER TABLE keeper_changesets ADD COLUMN task_id TEXT")
                    if add_err then error("add task_id: " .. add_err) end
                end
                db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_ws_task
                    ON keeper_changesets(task_id) WHERE task_id IS NOT NULL
                ]])
                return true
            end)

            down(function(db)
                db:execute("DROP INDEX IF EXISTS keeper_idx_ws_task")
                db:execute("ALTER TABLE keeper_changesets DROP COLUMN task_id")
                return true
            end)
        end)
    end)
end)
