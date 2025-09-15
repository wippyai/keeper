return require("migration").define(function()
    migration("Add workspace context table for contextual data storage", function()
        database("postgres", function()
            up(function(db)
                -- Create overlay_registry_workspace_context table
                local success, err = db:execute([[
                    CREATE TABLE overlay_registry_workspace_context (
                        context_id UUID PRIMARY KEY,
                        workspace_id UUID NOT NULL,
                        label TEXT NOT NULL,
                        content TEXT,
                        content_type TEXT DEFAULT 'text/plain',
                        metadata JSONB DEFAULT '{}',
                        created_at TIMESTAMP NOT NULL DEFAULT now(),
                        updated_at TIMESTAMP NOT NULL DEFAULT now(),
                        FOREIGN KEY (workspace_id) REFERENCES overlay_registry_workspaces(workspace_id) ON DELETE CASCADE
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_context_workspace ON overlay_registry_workspace_context(workspace_id, created_at DESC)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_context_label ON overlay_registry_workspace_context(workspace_id, label)")
                if err then error(err) end
            end)

            down(function(db)
                local success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_context_label")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_context_workspace")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_workspace_context")
                if err then error(err) end
            end)
        end)

        database("sqlite", function()
            up(function(db)
                -- Create overlay_registry_workspace_context table
                local success, err = db:execute([[
                    CREATE TABLE overlay_registry_workspace_context (
                        context_id TEXT PRIMARY KEY,
                        workspace_id TEXT NOT NULL,
                        label TEXT NOT NULL,
                        content TEXT,
                        content_type TEXT DEFAULT 'text/plain',
                        metadata TEXT DEFAULT '{}',
                        created_at INTEGER NOT NULL,
                        updated_at INTEGER NOT NULL,
                        FOREIGN KEY (workspace_id) REFERENCES overlay_registry_workspaces(workspace_id) ON DELETE CASCADE
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_context_workspace ON overlay_registry_workspace_context(workspace_id, created_at DESC)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_overlay_registry_workspace_context_label ON overlay_registry_workspace_context(workspace_id, label)")
                if err then error(err) end
            end)

            down(function(db)
                local success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_context_label")
                if err then error(err) end

                success, err = db:execute("DROP INDEX IF EXISTS idx_overlay_registry_workspace_context_workspace")
                if err then error(err) end

                success, err = db:execute("DROP TABLE IF EXISTS overlay_registry_workspace_context")
                if err then error(err) end
            end)
        end)
    end)
end)