return require("migration").define(function()
    migration("Drop obsolete design_id column from keeper_changesets (post design->task rename)", function()
        database("sqlite", function()
            up(function(db)
                local rows, err = db:query([[
                    SELECT 1 FROM pragma_table_info('keeper_changesets') WHERE name = 'design_id'
                ]])
                if err then error("Failed to probe design_id: " .. err) end
                if not rows or #rows == 0 then
                    -- Fresh schema already omits the column; migration is a no-op.
                    db:execute("DROP INDEX IF EXISTS keeper_idx_ws_design")
                    return true
                end

                local count_rows = db:query("SELECT COUNT(*) AS c FROM keeper_changesets WHERE design_id IS NOT NULL")
                local has_data = count_rows and count_rows[1] and tonumber(count_rows[1].c or 0) or 0
                if has_data > 0 then
                    error("Refusing to drop design_id: " .. has_data .. " rows still reference it")
                end

                local _, drop_err = db:execute("ALTER TABLE keeper_changesets DROP COLUMN design_id")
                if drop_err then error("Failed to drop design_id column: " .. drop_err) end

                db:execute("DROP INDEX IF EXISTS keeper_idx_ws_design")
                return true
            end)

            down(function(db)
                db:execute("ALTER TABLE keeper_changesets ADD COLUMN design_id TEXT")
                db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_ws_design
                    ON keeper_changesets(design_id) WHERE design_id IS NOT NULL
                ]])
                return true
            end)
        end)
    end)
end)
