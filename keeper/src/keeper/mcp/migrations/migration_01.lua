return require("migration").define(function()
    migration("Create MCP token management table", function()
        database("sqlite", function()
            up(function(db)
                local _, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_mcp_tokens (
                        token TEXT PRIMARY KEY,
                        label TEXT NOT NULL,
                        identity TEXT NOT NULL,
                        scopes TEXT NOT NULL DEFAULT '[]',
                        created_at INTEGER NOT NULL,
                        expires_at INTEGER,
                        revoked INTEGER NOT NULL DEFAULT 0
                    )
                ]])
                if err then error("Failed to create keeper_mcp_tokens: " .. err) end

                db:execute("CREATE INDEX IF NOT EXISTS idx_mcp_tokens_identity ON keeper_mcp_tokens(identity)")
                db:execute("CREATE INDEX IF NOT EXISTS idx_mcp_tokens_revoked ON keeper_mcp_tokens(revoked)")

                return true
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS keeper_mcp_tokens")
                return true
            end)
        end)

        database("postgres", function()
            up(function(db)
                local _, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_mcp_tokens (
                        token TEXT PRIMARY KEY,
                        label TEXT NOT NULL,
                        identity TEXT NOT NULL,
                        scopes TEXT NOT NULL DEFAULT '[]',
                        created_at INTEGER NOT NULL,
                        expires_at INTEGER,
                        revoked INTEGER NOT NULL DEFAULT 0
                    )
                ]])
                if err then error("Failed to create keeper_mcp_tokens: " .. err) end

                db:execute("CREATE INDEX IF NOT EXISTS idx_mcp_tokens_identity ON keeper_mcp_tokens(identity)")
                db:execute("CREATE INDEX IF NOT EXISTS idx_mcp_tokens_revoked ON keeper_mcp_tokens(revoked)")

                return true
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS keeper_mcp_tokens")
                return true
            end)
        end)
    end)
end)
