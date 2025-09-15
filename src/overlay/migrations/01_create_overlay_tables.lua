return require("migration").define(function()
    migration("Create registry overlay system tables", function()
        database("postgres", function()
            up(function(db)
                -- Create overlay_registry_workspaces table
                local success, err = db:execute([[
                    CREATE TABLE overlay_registry_workspaces (
                        workspace_id UUID PRIMARY KEY,
                        user_id TEXT NOT NULL,
                        status TEXT NOT NULL DEFAULT 'draft',
                        title TEXT,
                        description TEXT,
                        metadata JSONB DEFAULT '{}',
                        created_at TIMESTAMP NOT NULL DEFAULT now(),
                        updated_at TIMESTAMP NOT NULL DEFAULT now()
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspaces_user ON overlay_registry_workspaces(user_id, status)")
                if err then error(err) end

                -- Create overlay_registry_workspace_permissions table
                success, err = db:execute([[
                    CREATE TABLE overlay_registry_workspace_permissions (
                        permission_id UUID PRIMARY KEY,
                        workspace_id UUID NOT NULL,
                        namespace_pattern TEXT NOT NULL,
                        permission_type TEXT NOT NULL,
                        created_at TIMESTAMP NOT NULL DEFAULT now(),
                        FOREIGN KEY (workspace_id) REFERENCES overlay_registry_workspaces(workspace_id) ON DELETE CASCADE
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_permissions_workspace ON overlay_registry_workspace_permissions(workspace_id)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_permissions_namespace ON overlay_registry_workspace_permissions(namespace_pattern)")
                if err then error(err) end

                -- Create overlay_registry_workspace_entries table (WITH ENTRY_KIND FIELD)
                success, err = db:execute([[
                    CREATE TABLE overlay_registry_workspace_entries (
                        workspace_entry_id UUID PRIMARY KEY,
                        workspace_id UUID NOT NULL,
                        operation_type TEXT NOT NULL,
                        entry_id TEXT NOT NULL,
                        entry_kind TEXT NOT NULL,
                        entry_data JSONB,
                        entry_meta JSONB DEFAULT '{}',
                        created_at TIMESTAMP NOT NULL DEFAULT now(),
                        updated_at TIMESTAMP NOT NULL DEFAULT now(),
                        FOREIGN KEY (workspace_id) REFERENCES overlay_registry_workspaces(workspace_id) ON DELETE CASCADE,
                        UNIQUE(workspace_id, entry_id)
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_entries_workspace ON overlay_registry_workspace_entries(workspace_id, created_at DESC)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_entries_entry ON overlay_registry_workspace_entries(entry_id)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_entries_kind ON overlay_registry_workspace_entries(entry_kind)")
                if err then error(err) end

                -- Create overlay_registry_ops table
                success, err = db:execute([[
                    CREATE TABLE overlay_registry_ops (
                        op_id UUID PRIMARY KEY,
                        workspace_id UUID NOT NULL,
                        operation_type TEXT NOT NULL,
                        operation_data JSONB,
                        user_id TEXT NOT NULL,
                        created_at TIMESTAMP NOT NULL DEFAULT now(),
                        FOREIGN KEY (workspace_id) REFERENCES overlay_registry_workspaces(workspace_id) ON DELETE CASCADE
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_ops_workspace ON overlay_registry_ops(workspace_id, created_at DESC)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_ops_user ON overlay_registry_ops(user_id, created_at DESC)")
                if err then error(err) end

                -- Create overlay_registry_workspace_reviews table
                success, err = db:execute([[
                    CREATE TABLE overlay_registry_workspace_reviews (
                        review_id UUID PRIMARY KEY,
                        workspace_id UUID NOT NULL,
                        name TEXT NOT NULL,
                        content TEXT,
                        content_type TEXT DEFAULT 'text/plain',
                        meta JSONB DEFAULT '{}',
                        status TEXT DEFAULT 'draft',
                        created_at TIMESTAMP NOT NULL DEFAULT now(),
                        updated_at TIMESTAMP NOT NULL DEFAULT now(),
                        FOREIGN KEY (workspace_id) REFERENCES overlay_registry_workspaces(workspace_id) ON DELETE CASCADE,
                        UNIQUE(workspace_id, name)
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_reviews_workspace ON overlay_registry_workspace_reviews(workspace_id, created_at DESC)")
                if err then error(err) end
            end)

            down(function(db)
                local success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_reviews_workspace")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_workspace_reviews")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_ops_user")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_ops_workspace")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_ops")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_entries_kind")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_entries_entry")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_entries_workspace")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_workspace_entries")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_permissions_namespace")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_permissions_workspace")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_workspace_permissions")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspaces_user")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_workspaces")
                if err then error(err) end
            end)
        end)

        database("sqlite", function()
            up(function(db)
                -- Create overlay_registry_workspaces table
                local success, err = db:execute([[
                    CREATE TABLE overlay_registry_workspaces (
                        workspace_id TEXT PRIMARY KEY,
                        user_id TEXT NOT NULL,
                        status TEXT NOT NULL DEFAULT 'draft',
                        title TEXT,
                        description TEXT,
                        metadata TEXT DEFAULT '{}',
                        created_at INTEGER NOT NULL,
                        updated_at INTEGER NOT NULL
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspaces_user ON overlay_registry_workspaces(user_id, status)")
                if err then error(err) end

                -- Create overlay_registry_workspace_permissions table
                success, err = db:execute([[
                    CREATE TABLE overlay_registry_workspace_permissions (
                        permission_id TEXT PRIMARY KEY,
                        workspace_id TEXT NOT NULL,
                        namespace_pattern TEXT NOT NULL,
                        permission_type TEXT NOT NULL,
                        created_at INTEGER NOT NULL,
                        FOREIGN KEY (workspace_id) REFERENCES overlay_registry_workspaces(workspace_id) ON DELETE CASCADE
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_permissions_workspace ON overlay_registry_workspace_permissions(workspace_id)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_permissions_namespace ON overlay_registry_workspace_permissions(namespace_pattern)")
                if err then error(err) end

                -- Create overlay_registry_workspace_entries table (WITH ENTRY_KIND FIELD)
                success, err = db:execute([[
                    CREATE TABLE overlay_registry_workspace_entries (
                        workspace_entry_id TEXT PRIMARY KEY,
                        workspace_id TEXT NOT NULL,
                        operation_type TEXT NOT NULL,
                        entry_id TEXT NOT NULL,
                        entry_kind TEXT NOT NULL,
                        entry_data TEXT,
                        entry_meta TEXT DEFAULT '{}',
                        created_at INTEGER NOT NULL,
                        updated_at INTEGER NOT NULL,
                        FOREIGN KEY (workspace_id) REFERENCES overlay_registry_workspaces(workspace_id) ON DELETE CASCADE,
                        UNIQUE(workspace_id, entry_id)
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_entries_workspace ON overlay_registry_workspace_entries(workspace_id, created_at DESC)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_entries_entry ON overlay_registry_workspace_entries(entry_id)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_entries_kind ON overlay_registry_workspace_entries(entry_kind)")
                if err then error(err) end

                -- Create overlay_registry_ops table
                success, err = db:execute([[
                    CREATE TABLE overlay_registry_ops (
                        op_id TEXT PRIMARY KEY,
                        workspace_id TEXT NOT NULL,
                        operation_type TEXT NOT NULL,
                        operation_data TEXT,
                        user_id TEXT NOT NULL,
                        created_at INTEGER NOT NULL,
                        FOREIGN KEY (workspace_id) REFERENCES overlay_registry_workspaces(workspace_id) ON DELETE CASCADE
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_ops_workspace ON overlay_registry_ops(workspace_id, created_at DESC)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_ops_user ON overlay_registry_ops(user_id, created_at DESC)")
                if err then error(err) end

                -- Create overlay_registry_workspace_reviews table
                success, err = db:execute([[
                    CREATE TABLE overlay_registry_workspace_reviews (
                        review_id TEXT PRIMARY KEY,
                        workspace_id TEXT NOT NULL,
                        name TEXT NOT NULL,
                        content TEXT,
                        content_type TEXT DEFAULT 'text/plain',
                        meta TEXT DEFAULT '{}',
                        status TEXT DEFAULT 'draft',
                        created_at INTEGER NOT NULL,
                        updated_at INTEGER NOT NULL,
                        FOREIGN KEY (workspace_id) REFERENCES overlay_registry_workspaces(workspace_id) ON DELETE CASCADE,
                        UNIQUE(workspace_id, name)
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_reviews_workspace ON overlay_registry_workspace_reviews(workspace_id, created_at DESC)")
                if err then error(err) end
            end)

            down(function(db)
                local success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_reviews_workspace")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_workspace_reviews")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_ops_user")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_ops_workspace")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_ops")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_entries_kind")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_entries_entry")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_entries_workspace")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_workspace_entries")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_permissions_namespace")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_permissions_workspace")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_workspace_permissions")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspaces_user")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_workspaces")
                if err then error(err) end
            end)
        end)
    end)
end)