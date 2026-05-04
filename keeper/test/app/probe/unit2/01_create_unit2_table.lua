return require("migration").define(function()
    migration("Create unit2_probe table", function()
        database("sqlite", function()
            up(function(db)
                local _, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS unit2_probe (
                        id TEXT PRIMARY KEY,
                        created_at TEXT
                    )
                ]])
                if err then error("Failed to create unit2_probe: " .. tostring(err)) end
                return true
            end)

            down(function(db)
                local _, err = db:execute("DROP TABLE IF EXISTS unit2_probe")
                if err then error("Failed to drop unit2_probe: " .. tostring(err)) end
                return true
            end)
        end)
    end)
end)
