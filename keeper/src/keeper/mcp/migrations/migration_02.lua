return require("migration").define(function()
    migration("MCP trait-based access control and session state", function()
        database("sqlite", function()
            up(function(db)
                local _, err

                _, err = db:execute("ALTER TABLE keeper_mcp_tokens ADD COLUMN access_mode TEXT NOT NULL DEFAULT 'tools_only'")
                if err and not string.find(tostring(err), "duplicate column") then
                    error("add access_mode: " .. err)
                end

                _, err = db:execute("ALTER TABLE keeper_mcp_tokens ADD COLUMN available_traits TEXT")
                if err and not string.find(tostring(err), "duplicate column") then
                    error("add available_traits: " .. err)
                end

                _, err = db:execute("ALTER TABLE keeper_mcp_tokens ADD COLUMN available_tools TEXT")
                if err and not string.find(tostring(err), "duplicate column") then
                    error("add available_tools: " .. err)
                end

                _, err = db:execute("ALTER TABLE keeper_mcp_tokens ADD COLUMN default_active TEXT NOT NULL DEFAULT '[]'")
                if err and not string.find(tostring(err), "duplicate column") then
                    error("add default_active: " .. err)
                end

                _, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_mcp_session_state (
                        token TEXT PRIMARY KEY,
                        active_traits TEXT NOT NULL DEFAULT '[]',
                        updated_at INTEGER NOT NULL
                    )
                ]])
                if err then error("create keeper_mcp_session_state: " .. err) end

                return true
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS keeper_mcp_session_state")
                return true
            end)
        end)
    end)
end)
