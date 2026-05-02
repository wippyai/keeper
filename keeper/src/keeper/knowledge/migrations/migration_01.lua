return require("migration").define(function()
    migration("Create knowledge base tables", function()
        database("sqlite", function()
            up(function(db)
                local success, err

                -- Knowledge bases registry
                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_kbs (
                        id TEXT PRIMARY KEY,
                        name TEXT NOT NULL UNIQUE,
                        description TEXT DEFAULT '',
                        created_at TEXT NOT NULL,
                        updated_at TEXT NOT NULL
                    )
                ]])
                if err then error("Failed to create keeper_kbs: " .. err) end

                -- Default KB
                db:execute([[
                    INSERT OR IGNORE INTO keeper_kbs (id, name, description, created_at, updated_at)
                    VALUES (?, 'General', 'Default knowledge base', datetime('now'), datetime('now'))
                ]], { "00000000-0000-0000-0000-000000000001" })

                -- Knowledge nodes
                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_kb_nodes (
                        id TEXT PRIMARY KEY,
                        kb_id TEXT NOT NULL REFERENCES keeper_kbs(id) ON DELETE CASCADE,
                        parent_id TEXT REFERENCES keeper_kb_nodes(id) ON DELETE SET NULL,
                        workspace_id TEXT,
                        node_type TEXT NOT NULL,
                        title TEXT NOT NULL,
                        content TEXT NOT NULL,
                        source TEXT NOT NULL DEFAULT 'human',
                        summary TEXT DEFAULT '',
                        confidence REAL NOT NULL DEFAULT 1.0,
                        embedded INTEGER NOT NULL DEFAULT 0,
                        scope_namespace TEXT,
                        scope_kind TEXT,
                        scope_meta_type TEXT,
                        refs TEXT DEFAULT '[]',
                        metadata TEXT DEFAULT '{}',
                        created_at TEXT NOT NULL,
                        updated_at TEXT NOT NULL
                    )
                ]])
                if err then error("Failed to create keeper_kb_nodes: " .. err) end

                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_kb ON keeper_kb_nodes(kb_id)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_type ON keeper_kb_nodes(node_type)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_parent ON keeper_kb_nodes(parent_id)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_source ON keeper_kb_nodes(source)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_workspace ON keeper_kb_nodes(workspace_id)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_embedded ON keeper_kb_nodes(embedded)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_scope_ns ON keeper_kb_nodes(scope_namespace)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_scope_kind ON keeper_kb_nodes(scope_kind)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_scope_mt ON keeper_kb_nodes(scope_meta_type)")

                -- FTS for keyword search
                success, err = db:execute([[
                    CREATE VIRTUAL TABLE IF NOT EXISTS keeper_kb_nodes_fts USING fts5(
                        id UNINDEXED,
                        title,
                        content,
                        node_type UNINDEXED,
                        tokenize = 'porter'
                    )
                ]])
                if err then
                    db:execute([[
                        CREATE TABLE IF NOT EXISTS keeper_kb_nodes_fts (
                            id TEXT NOT NULL,
                            title TEXT NOT NULL,
                            content TEXT NOT NULL,
                            node_type TEXT NOT NULL
                        )
                    ]])
                end

                -- Vector embeddings for semantic search
                success, err = db:execute([[
                    CREATE VIRTUAL TABLE IF NOT EXISTS keeper_kb_embeddings USING vec0(
                        node_id TEXT PRIMARY KEY,
                        embedding float[512],
                        +title TEXT,
                        +content_preview TEXT
                    )
                ]])
                if err then
                    db:execute([[
                        CREATE TABLE IF NOT EXISTS keeper_kb_embeddings (
                            node_id TEXT PRIMARY KEY,
                            embedding TEXT,
                            title TEXT,
                            content_preview TEXT
                        )
                    ]])
                end

                -- Changelog (registry change history, not KB-related)
                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_changelog (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        version INTEGER,
                        timestamp TEXT NOT NULL,
                        user_id TEXT,
                        request_id TEXT,
                        op_type TEXT NOT NULL,
                        entry_id TEXT,
                        entry_kind TEXT,
                        entry_meta_type TEXT,
                        namespace TEXT,
                        summary TEXT DEFAULT '{}',
                        created_at TEXT NOT NULL
                    )
                ]])
                if err then error("Failed to create keeper_changelog: " .. err) end

                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_changelog_version ON keeper_changelog(version)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_changelog_timestamp ON keeper_changelog(timestamp)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_changelog_namespace ON keeper_changelog(namespace)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_changelog_entry ON keeper_changelog(entry_id)")

                return true
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS keeper_changelog")
                db:execute("DROP TABLE IF EXISTS keeper_kb_embeddings")
                db:execute("DROP TABLE IF EXISTS keeper_kb_nodes_fts")
                db:execute("DROP TABLE IF EXISTS keeper_kb_nodes")
                db:execute("DROP TABLE IF EXISTS keeper_kbs")
                return true
            end)
        end)

        database("postgres", function()
            up(function(db)
                local success, err

                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_kbs (
                        id TEXT PRIMARY KEY,
                        name TEXT NOT NULL UNIQUE,
                        description TEXT DEFAULT '',
                        created_at TEXT NOT NULL,
                        updated_at TEXT NOT NULL
                    )
                ]])
                if err then error("Failed to create keeper_kbs: " .. err) end

                db:execute([[
                    INSERT INTO keeper_kbs (id, name, description, created_at, updated_at)
                    VALUES ('00000000-0000-0000-0000-000000000001', 'General', 'Default knowledge base', CURRENT_TIMESTAMP::TEXT, CURRENT_TIMESTAMP::TEXT)
                    ON CONFLICT (id) DO NOTHING
                ]])

                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_kb_nodes (
                        id TEXT PRIMARY KEY,
                        kb_id TEXT NOT NULL REFERENCES keeper_kbs(id) ON DELETE CASCADE,
                        parent_id TEXT REFERENCES keeper_kb_nodes(id) ON DELETE SET NULL,
                        workspace_id TEXT,
                        node_type TEXT NOT NULL,
                        title TEXT NOT NULL,
                        content TEXT NOT NULL,
                        source TEXT NOT NULL DEFAULT 'human',
                        summary TEXT DEFAULT '',
                        confidence DOUBLE PRECISION NOT NULL DEFAULT 1.0,
                        embedded INTEGER NOT NULL DEFAULT 0,
                        scope_namespace TEXT,
                        scope_kind TEXT,
                        scope_meta_type TEXT,
                        refs TEXT DEFAULT '[]',
                        metadata TEXT DEFAULT '{}',
                        created_at TEXT NOT NULL,
                        updated_at TEXT NOT NULL
                    )
                ]])
                if err then error("Failed to create keeper_kb_nodes: " .. err) end

                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_kb ON keeper_kb_nodes(kb_id)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_type ON keeper_kb_nodes(node_type)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_parent ON keeper_kb_nodes(parent_id)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_source ON keeper_kb_nodes(source)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_workspace ON keeper_kb_nodes(workspace_id)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_embedded ON keeper_kb_nodes(embedded)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_scope_ns ON keeper_kb_nodes(scope_namespace)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_scope_kind ON keeper_kb_nodes(scope_kind)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_kb_nodes_scope_mt ON keeper_kb_nodes(scope_meta_type)")

                -- PostgreSQL uses direct ILIKE search in repo.lua today. Keep
                -- this compatibility table so node writes stay uniform across
                -- dialects and future FTS backends can be plugged in without a
                -- repository contract change.
                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_kb_nodes_fts (
                        id TEXT NOT NULL,
                        title TEXT NOT NULL,
                        content TEXT NOT NULL,
                        node_type TEXT NOT NULL
                    )
                ]])
                if err then error("Failed to create keeper_kb_nodes_fts: " .. err) end

                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_kb_embeddings (
                        node_id TEXT PRIMARY KEY REFERENCES keeper_kb_nodes(id) ON DELETE CASCADE,
                        embedding TEXT,
                        title TEXT,
                        content_preview TEXT
                    )
                ]])
                if err then error("Failed to create keeper_kb_embeddings: " .. err) end

                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_changelog (
                        id BIGSERIAL PRIMARY KEY,
                        version INTEGER,
                        timestamp TEXT NOT NULL,
                        user_id TEXT,
                        request_id TEXT,
                        op_type TEXT NOT NULL,
                        entry_id TEXT,
                        entry_kind TEXT,
                        entry_meta_type TEXT,
                        namespace TEXT,
                        summary TEXT DEFAULT '{}',
                        created_at TEXT NOT NULL
                    )
                ]])
                if err then error("Failed to create keeper_changelog: " .. err) end

                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_changelog_version ON keeper_changelog(version)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_changelog_timestamp ON keeper_changelog(timestamp)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_changelog_namespace ON keeper_changelog(namespace)")
                db:execute("CREATE INDEX IF NOT EXISTS keeper_idx_changelog_entry ON keeper_changelog(entry_id)")

                return true
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS keeper_changelog")
                db:execute("DROP TABLE IF EXISTS keeper_kb_embeddings")
                db:execute("DROP TABLE IF EXISTS keeper_kb_nodes_fts")
                db:execute("DROP TABLE IF EXISTS keeper_kb_nodes")
                db:execute("DROP TABLE IF EXISTS keeper_kbs")
                return true
            end)
        end)
    end)
end)
