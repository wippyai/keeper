return require("migration").define(function()
    migration("Create keeper task schema — tasks + typed nodes", function()
        database("sqlite", function()
            up(function(db)
                local ok, err

                -- keeper_tasks: lifecycle only. Every event/payload lives in
                -- keeper_task_nodes.
                ok, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_tasks (
                        task_id      TEXT PRIMARY KEY,
                        title        TEXT NOT NULL,
                        description  TEXT,
                        spec         TEXT,
                        acceptance   TEXT,
                        status       TEXT NOT NULL DEFAULT 'active',
                        phase        TEXT NOT NULL DEFAULT 'spec',
                        iteration    INTEGER NOT NULL DEFAULT 0,
                        blocked_from TEXT,
                        actor_id     TEXT,
                        session_id   TEXT,
                        archived     INTEGER NOT NULL DEFAULT 0,
                        metadata     TEXT,
                        created_at   TEXT NOT NULL,
                        updated_at   TEXT NOT NULL,
                        completed_at TEXT
                    )
                ]])
                if err then error("create keeper_tasks: " .. err) end

                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_tasks_status ON keeper_tasks(status, archived)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_tasks_phase ON keeper_tasks(phase)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_tasks_actor ON keeper_tasks(actor_id, created_at)")

                -- keeper_task_nodes: one hierarchical typed table. Every
                -- phase_started / phase_exited / phase_transition /
                -- ask_user / user_response / tool_call / spec / finding /
                -- research_task / cycle_start / integrate_stage / override
                -- row lives here.
                ok, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_task_nodes (
                        node_id         TEXT PRIMARY KEY,
                        task_id         TEXT NOT NULL,
                        parent_node_id  TEXT,
                        path            TEXT NOT NULL DEFAULT '/',
                        depth           INTEGER NOT NULL DEFAULT 0,
                        position        INTEGER NOT NULL DEFAULT 0,

                        type            TEXT NOT NULL,
                        discriminator   TEXT,

                        title           TEXT NOT NULL DEFAULT '',
                        content         TEXT,
                        content_type    TEXT NOT NULL DEFAULT 'text/plain',
                        status          TEXT,
                        visibility      TEXT NOT NULL DEFAULT 'user',

                        agent_id        TEXT,
                        dataflow_id     TEXT,
                        changeset_id    TEXT,
                        execution_ms    INTEGER,
                        error_message   TEXT,
                        result_summary  TEXT,
                        metadata        TEXT NOT NULL DEFAULT '{}',

                        seq             INTEGER NOT NULL,
                        created_at      INTEGER NOT NULL,
                        updated_at      INTEGER NOT NULL
                    )
                ]])
                if err then error("create keeper_task_nodes: " .. err) end

                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_task_nodes_task_seq ON keeper_task_nodes(task_id, seq)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_task_nodes_type ON keeper_task_nodes(task_id, type, seq)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_task_nodes_type_disc ON keeper_task_nodes(task_id, type, discriminator)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_task_nodes_parent ON keeper_task_nodes(parent_node_id, position)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_task_nodes_visibility ON keeper_task_nodes(task_id, visibility, seq)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_task_nodes_status ON keeper_task_nodes(task_id, type, status)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_task_nodes_dataflow ON keeper_task_nodes(dataflow_id)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_task_nodes_changeset ON keeper_task_nodes(changeset_id)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_task_nodes_agent ON keeper_task_nodes(task_id, agent_id, seq)")

                ok, err = db:execute([[
                    CREATE VIRTUAL TABLE IF NOT EXISTS keeper_task_nodes_fts
                    USING fts5(
                        title, content,
                        content='keeper_task_nodes',
                        content_rowid='rowid'
                    )
                ]])
                if err then error("create keeper_task_nodes_fts: " .. err) end

                db:execute([[
                    CREATE TRIGGER IF NOT EXISTS keeper_task_nodes_ai
                    AFTER INSERT ON keeper_task_nodes BEGIN
                        INSERT INTO keeper_task_nodes_fts(rowid, title, content)
                        VALUES (new.rowid, new.title, COALESCE(new.content, ''));
                    END;
                ]])
                db:execute([[
                    CREATE TRIGGER IF NOT EXISTS keeper_task_nodes_ad
                    AFTER DELETE ON keeper_task_nodes BEGIN
                        INSERT INTO keeper_task_nodes_fts(keeper_task_nodes_fts, rowid, title, content)
                        VALUES ('delete', old.rowid, old.title, COALESCE(old.content, ''));
                    END;
                ]])
                db:execute([[
                    CREATE TRIGGER IF NOT EXISTS keeper_task_nodes_au
                    AFTER UPDATE ON keeper_task_nodes BEGIN
                        INSERT INTO keeper_task_nodes_fts(keeper_task_nodes_fts, rowid, title, content)
                        VALUES ('delete', old.rowid, old.title, COALESCE(old.content, ''));
                        INSERT INTO keeper_task_nodes_fts(rowid, title, content)
                        VALUES (new.rowid, new.title, COALESCE(new.content, ''));
                    END;
                ]])

                return true
            end)

            down(function(db)
                db:execute("DROP TRIGGER IF EXISTS keeper_task_nodes_au")
                db:execute("DROP TRIGGER IF EXISTS keeper_task_nodes_ad")
                db:execute("DROP TRIGGER IF EXISTS keeper_task_nodes_ai")
                db:execute("DROP TABLE IF EXISTS keeper_task_nodes_fts")
                db:execute("DROP TABLE IF EXISTS keeper_task_nodes")
                db:execute("DROP TABLE IF EXISTS keeper_tasks")
                return true
            end)
        end)
    end)
end)
