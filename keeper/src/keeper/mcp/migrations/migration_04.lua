return require("migration").define(function()
    migration("MCP session state: changeset_id column", function()
        database("sqlite", function()
            up(function(db)
                local _, err = db:execute(
                    "ALTER TABLE keeper_mcp_session_state ADD COLUMN changeset_id TEXT"
                )
                if err and not string.find(tostring(err), "duplicate column") then
                    error("add changeset_id: " .. err)
                end
                return true
            end)

            down(function(db)
                return true
            end)
        end)

        database("postgres", function()
            up(function(db)
                local _, err = db:execute(
                    "ALTER TABLE keeper_mcp_session_state ADD COLUMN IF NOT EXISTS changeset_id TEXT"
                )
                if err then error("add changeset_id: " .. err) end
                return true
            end)

            down(function(db)
                return true
            end)
        end)
    end)
end)
