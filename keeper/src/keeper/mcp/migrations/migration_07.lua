return require("migration").define(function()
    migration("MCP context keyed by credential and transport session", function()
        database("sqlite", function()
            up(function(db)
                local columns, err = db:query("PRAGMA table_info(keeper_mcp_session_state)")
                if err then error("read session state schema: " .. tostring(err)) end
                for _, column in ipairs(columns) do
                    if column.name == "session_id" then return true end
                end

                -- The migration runner commits the table rebuild and ledger in one
                -- transaction. Legacy context has no known transport owner.
                local statements = {
                    [[CREATE TABLE keeper_mcp_session_state_scoped (
                        token TEXT NOT NULL,
                        session_id TEXT NOT NULL DEFAULT '',
                        active_traits TEXT NOT NULL DEFAULT '[]',
                        updated_at INTEGER NOT NULL,
                        overlay_branch TEXT,
                        changeset_id TEXT,
                        PRIMARY KEY (token, session_id)
                    )]],
                    [[INSERT INTO keeper_mcp_session_state_scoped
                        (token, session_id, active_traits, updated_at, overlay_branch, changeset_id)
                        SELECT token, '', active_traits, updated_at, overlay_branch, changeset_id
                        FROM keeper_mcp_session_state]],
                    "DROP TABLE keeper_mcp_session_state",
                    "ALTER TABLE keeper_mcp_session_state_scoped RENAME TO keeper_mcp_session_state",
                }
                for _, statement in ipairs(statements) do
                    local _, exec_err = db:execute(statement)
                    if exec_err then error("scope session state: " .. tostring(exec_err)) end
                end
                return true
            end)
            down(function() return true end)
        end)
        database("postgres", function()
            up(function(db)
                local statements = {
                    "ALTER TABLE keeper_mcp_session_state ADD COLUMN IF NOT EXISTS session_id TEXT NOT NULL DEFAULT ''",
                    "ALTER TABLE keeper_mcp_session_state DROP CONSTRAINT IF EXISTS keeper_mcp_session_state_pkey",
                    "ALTER TABLE keeper_mcp_session_state ADD PRIMARY KEY (token, session_id)",
                }
                for _, statement in ipairs(statements) do
                    local _, err = db:execute(statement)
                    if err then error("scope session state: " .. tostring(err)) end
                end
                return true
            end)
            down(function() return true end)
        end)
    end)
end)
