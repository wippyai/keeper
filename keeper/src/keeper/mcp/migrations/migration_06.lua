local function add_column(db, ddl, label)
    local _, err = db:execute(ddl)
    if err and not string.find(tostring(err), "duplicate column") then
        error(label .. ": " .. tostring(err))
    end
end

return require("migration").define(function()
    migration("MCP tokens: issuer and revocation audit fields", function()
        database("sqlite", function()
            up(function(db)
                add_column(db,
                    "ALTER TABLE keeper_mcp_tokens ADD COLUMN issued_by TEXT",
                    "add issued_by")
                add_column(db,
                    "ALTER TABLE keeper_mcp_tokens ADD COLUMN revoked_at INTEGER",
                    "add revoked_at")
                add_column(db,
                    "ALTER TABLE keeper_mcp_tokens ADD COLUMN revoked_by TEXT",
                    "add revoked_by")

                db:execute("CREATE INDEX IF NOT EXISTS idx_mcp_tokens_issued_by ON keeper_mcp_tokens(issued_by)")
                db:execute("CREATE INDEX IF NOT EXISTS idx_mcp_tokens_revoked_by ON keeper_mcp_tokens(revoked_by)")
                return true
            end)

            down(function(db)
                return true
            end)
        end)
    end)
end)
