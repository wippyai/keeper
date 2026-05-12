return require("migration").define(function()
    migration("Create probe_verify table", function()
        database("sqlite", function()
            up(function(db)
                local _, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS probe_verify (
                        id TEXT PRIMARY KEY,
                        created_at TEXT
                    )
                ]])
                if err then error("Failed to create probe_verify: " .. tostring(err)) end
                return true
            end)

            down(function(db)
                local _, err = db:execute("DROP TABLE IF EXISTS probe_verify")
                if err then error("Failed to drop probe_verify: " .. tostring(err)) end
                return true
            end)
        end)
    end)
end)
