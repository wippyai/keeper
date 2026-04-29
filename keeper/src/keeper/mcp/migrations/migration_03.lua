return require("migration").define(function()
    migration("MCP session state: overlay_branch column", function()
        database("sqlite", function()
            up(function(db)
                local _, err = db:execute(
                    "ALTER TABLE keeper_mcp_session_state ADD COLUMN overlay_branch TEXT"
                )
                if err and not string.find(tostring(err), "duplicate column") then
                    error("add overlay_branch: " .. err)
                end
                return true
            end)

            down(function(db)
                return true
            end)
        end)
    end)
end)
