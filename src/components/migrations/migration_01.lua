return require("migration").define(function()
    migration("Create FE component build tables", function()
        database("sqlite", function()
            up(function(db)
                local _, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_fe_builds (
                        build_id TEXT PRIMARY KEY,
                        component_id TEXT NOT NULL,
                        component_path TEXT NOT NULL,
                        session_id TEXT,
                        trigger TEXT NOT NULL,              -- user | agent | session
                        triggered_by TEXT,                  -- actor id
                        status TEXT NOT NULL,               -- queued | running | success | failed | cancelled
                        command TEXT NOT NULL,
                        image TEXT NOT NULL,
                        toolchain TEXT NOT NULL,
                        exit_code INTEGER,
                        duration_ms INTEGER,
                        error TEXT,
                        started_at INTEGER NOT NULL,
                        finished_at INTEGER
                    )
                ]])
                if err then error("Failed to create keeper_fe_builds: " .. err) end

                db:execute("CREATE INDEX IF NOT EXISTS idx_fe_builds_component ON keeper_fe_builds(component_id)")
                db:execute("CREATE INDEX IF NOT EXISTS idx_fe_builds_status ON keeper_fe_builds(status)")
                db:execute("CREATE INDEX IF NOT EXISTS idx_fe_builds_session ON keeper_fe_builds(session_id) WHERE session_id IS NOT NULL")
                db:execute("CREATE INDEX IF NOT EXISTS idx_fe_builds_started ON keeper_fe_builds(started_at)")

                local _, err2 = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_fe_build_lines (
                        build_id TEXT NOT NULL,
                        seq INTEGER NOT NULL,
                        stream TEXT NOT NULL,               -- stdout | stderr | system
                        at INTEGER NOT NULL,
                        text TEXT NOT NULL,
                        PRIMARY KEY (build_id, seq),
                        FOREIGN KEY (build_id) REFERENCES keeper_fe_builds(build_id) ON DELETE CASCADE
                    )
                ]])
                if err2 then error("Failed to create keeper_fe_build_lines: " .. err2) end

                db:execute("CREATE INDEX IF NOT EXISTS idx_fe_build_lines_build ON keeper_fe_build_lines(build_id)")

                return true
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS keeper_fe_build_lines")
                db:execute("DROP TABLE IF EXISTS keeper_fe_builds")
                return true
            end)
        end)
    end)
end)
