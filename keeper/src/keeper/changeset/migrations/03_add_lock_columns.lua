return require("migration").define(function()
    migration("Add lock columns to keeper_changesets", function()
        database("sqlite", function()
            up(function(db)
                local success, err

                success, err = db:execute([[
                    ALTER TABLE keeper_changesets ADD COLUMN locked_by TEXT
                ]])
                if err then error("Failed to add locked_by: " .. err) end

                success, err = db:execute([[
                    ALTER TABLE keeper_changesets ADD COLUMN locked_at TEXT
                ]])
                if err then error("Failed to add locked_at: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_ws_locked ON keeper_changesets(locked_by)
                    WHERE locked_by IS NOT NULL
                ]])
                if err then error("Failed to create locked_by index: " .. err) end

                return true
            end)

            down(function(db)
                db:execute("DROP INDEX IF EXISTS keeper_idx_ws_locked")
                return true
            end)
        end)
    end)
end)
