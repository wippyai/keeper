return require("migration").define(function()
    migration("Create git index runs table", function()
        database("sqlite", function()
            up(function(db)
                local success, err

                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_git_runs (
                        run_id        TEXT PRIMARY KEY,
                        started_at    TEXT NOT NULL,
                        finished_at   TEXT,
                        status        TEXT NOT NULL,
                        journal_size  INTEGER NOT NULL DEFAULT 0,
                        cluster_count INTEGER NOT NULL DEFAULT 0,
                        ai_model      TEXT,
                        error         TEXT,
                        payload_json  TEXT NOT NULL
                    )
                ]])
                if err then error("Failed to create keeper_git_runs: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_git_runs_finished
                    ON keeper_git_runs(finished_at DESC)
                    WHERE finished_at IS NOT NULL
                ]])
                if err then error("Failed to create git runs finished index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_git_runs_status
                    ON keeper_git_runs(status)
                ]])
                if err then error("Failed to create git runs status index: " .. err) end
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS keeper_git_runs")
            end)
        end)
    end)
end)
