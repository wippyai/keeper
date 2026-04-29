return require("migration").define(function()
    migration("Create workspace tables", function()
        database("sqlite", function()
            up(function(db)
                local success, err

                -- 1. keeper_changesets: one row per unit of intent
                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_changesets (
                        changeset_id      TEXT PRIMARY KEY,
                        kind              TEXT NOT NULL,
                        title             TEXT NOT NULL,
                        description       TEXT,
                        actor_id          TEXT,
                        session_id        TEXT,
                        parent_workspace  TEXT,
                        state             TEXT NOT NULL,
                        state_reason      TEXT,
                        state_branch      TEXT NOT NULL,
                        scratch_fs_path   TEXT NOT NULL,
                        baseline_version  TEXT NOT NULL,
                        baseline_fs_hash  TEXT NOT NULL,
                        head_version      TEXT,
                        head_fs_hash      TEXT,
                        git_branch        TEXT,
                        git_pr_id         TEXT,
                        created_at        TEXT NOT NULL,
                        updated_at        TEXT NOT NULL,
                        closed_at         TEXT
                    )
                ]])
                if err then error("Failed to create keeper_changesets: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_ws_state ON keeper_changesets(state)
                ]])
                if err then error("Failed to create ws state index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_ws_actor ON keeper_changesets(actor_id)
                    WHERE actor_id IS NOT NULL
                ]])
                if err then error("Failed to create ws actor index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_ws_session ON keeper_changesets(session_id)
                    WHERE session_id IS NOT NULL
                ]])
                if err then error("Failed to create ws session index: " .. err) end

                -- Singleton wild workspace: at most one live wild at a time
                success, err = db:execute([[
                    CREATE UNIQUE INDEX IF NOT EXISTS keeper_idx_ws_wild_singleton ON keeper_changesets(kind)
                    WHERE kind = 'wild' AND state IN ('open', 'editing', 'review')
                ]])
                if err then error("Failed to create ws wild singleton index: " .. err) end

                -- 2. keeper_changeset_changes: hybrid journal (drift, conflicts, merges, applied, rejected)
                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_changeset_changes (
                        change_id      TEXT PRIMARY KEY,
                        changeset_id   TEXT,
                        sequence       INTEGER NOT NULL,
                        category       TEXT NOT NULL,
                        op             TEXT NOT NULL,
                        target         TEXT NOT NULL,
                        baseline_hash  TEXT,
                        current_hash   TEXT,
                        source         TEXT NOT NULL,
                        status         TEXT NOT NULL,
                        conflict_with  TEXT,
                        detected_at    TEXT,
                        created_at     TEXT NOT NULL,
                        updated_at     TEXT NOT NULL,
                        FOREIGN KEY (changeset_id) REFERENCES keeper_changesets(changeset_id) ON DELETE CASCADE,
                        FOREIGN KEY (conflict_with) REFERENCES keeper_changeset_changes(change_id) ON DELETE SET NULL
                    )
                ]])
                if err then error("Failed to create keeper_changeset_changes: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_ch_ws ON keeper_changeset_changes(changeset_id, sequence)
                ]])
                if err then error("Failed to create changes ws index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_ch_target ON keeper_changeset_changes(category, target, status)
                ]])
                if err then error("Failed to create changes target index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_ch_status ON keeper_changeset_changes(status)
                ]])
                if err then error("Failed to create changes status index: " .. err) end

                -- at most one live pending change per target per workspace
                success, err = db:execute([[
                    CREATE UNIQUE INDEX IF NOT EXISTS keeper_idx_ch_ws_target_live
                    ON keeper_changeset_changes(changeset_id, category, target)
                    WHERE status = 'pending'
                ]])
                if err then error("Failed to create changes unique live index: " .. err) end

                -- 3. keeper_changeset_baselines: append-only snapshot log
                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_changeset_baselines (
                        baseline_id      TEXT PRIMARY KEY,
                        changeset_id     TEXT NOT NULL,
                        registry_version TEXT NOT NULL,
                        fs_tree_hash     TEXT NOT NULL,
                        captured_at      TEXT NOT NULL,
                        reason           TEXT NOT NULL,
                        FOREIGN KEY (changeset_id) REFERENCES keeper_changesets(changeset_id) ON DELETE CASCADE
                    )
                ]])
                if err then error("Failed to create keeper_changeset_baselines: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_bl_ws ON keeper_changeset_baselines(changeset_id, captured_at)
                ]])
                if err then error("Failed to create baselines ws index: " .. err) end

                -- 4. keeper_changeset_merges: reconciliation audit log
                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_changeset_merges (
                        merge_id         TEXT PRIMARY KEY,
                        from_workspace   TEXT,
                        into_workspace   TEXT NOT NULL,
                        change_ids       TEXT NOT NULL,
                        conflict_count   INTEGER NOT NULL DEFAULT 0,
                        resolution       TEXT NOT NULL,
                        actor_id         TEXT,
                        at               TEXT NOT NULL,
                        FOREIGN KEY (into_workspace) REFERENCES keeper_changesets(changeset_id) ON DELETE CASCADE
                    )
                ]])
                if err then error("Failed to create keeper_changeset_merges: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_mg_into ON keeper_changeset_merges(into_workspace, at)
                ]])
                if err then error("Failed to create merges into index: " .. err) end

                -- 5. keeper_fs_manifests: content-addressed per-path hash cache
                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_fs_manifests (
                        tree_hash    TEXT PRIMARY KEY,
                        root         TEXT NOT NULL,
                        entry_count  INTEGER NOT NULL,
                        captured_at  TEXT NOT NULL,
                        manifest     TEXT NOT NULL
                    )
                ]])
                if err then error("Failed to create keeper_fs_manifests: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_mf_root ON keeper_fs_manifests(root, captured_at)
                ]])
                if err then error("Failed to create fs manifests root index: " .. err) end

                -- 6. keeper_changeset_fs_deletes: per-workspace filesystem delete markers
                -- (deletes are not staged as tombstone files to keep scratch listings clean)
                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_changeset_fs_deletes (
                        changeset_id   TEXT NOT NULL,
                        rel_path       TEXT NOT NULL,
                        baseline_hash  TEXT NOT NULL,
                        deleted_at     TEXT NOT NULL,
                        PRIMARY KEY (changeset_id, rel_path),
                        FOREIGN KEY (changeset_id) REFERENCES keeper_changesets(changeset_id) ON DELETE CASCADE
                    )
                ]])
                if err then error("Failed to create keeper_changeset_fs_deletes: " .. err) end

                return true
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS keeper_changeset_fs_deletes")
                db:execute("DROP TABLE IF EXISTS keeper_fs_manifests")
                db:execute("DROP TABLE IF EXISTS keeper_changeset_merges")
                db:execute("DROP TABLE IF EXISTS keeper_changeset_baselines")
                db:execute("DROP TABLE IF EXISTS keeper_changeset_changes")
                db:execute("DROP TABLE IF EXISTS keeper_changesets")
                return true
            end)
        end)
    end)
end)
