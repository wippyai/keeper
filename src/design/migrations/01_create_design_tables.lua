return require("migration").define(function()
    migration("Create design workspace tables", function()
        database("postgres", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE design_workspaces (
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

                success, err = db:execute("CREATE INDEX idx_design_workspaces_user ON design_workspaces(user_id, status)")
                if err then error(err) end

                success, err = db:execute([[
                    CREATE TABLE design_workspace_ops (
                        op_id UUID PRIMARY KEY,
                        workspace_id UUID NOT NULL,
                        user_id TEXT NOT NULL,
                        operation_type TEXT NOT NULL,
                        operation_data JSONB,
                        created_at TIMESTAMP NOT NULL DEFAULT now(),
                        FOREIGN KEY (workspace_id) REFERENCES design_workspaces(workspace_id) ON DELETE CASCADE
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_design_workspace_ops_workspace ON design_workspace_ops(workspace_id, created_at DESC)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_design_workspace_ops_user ON design_workspace_ops(user_id, created_at DESC)")
                if err then error(err) end
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS design_workspace_ops")
                db:execute("DROP TABLE IF EXISTS design_workspaces")
            end)
        end)

        database("sqlite", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE design_workspaces (
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

                success, err = db:execute("CREATE INDEX idx_design_workspaces_user ON design_workspaces(user_id, status)")
                if err then error(err) end

                success, err = db:execute([[
                    CREATE TABLE design_workspace_ops (
                        op_id TEXT PRIMARY KEY,
                        workspace_id TEXT NOT NULL,
                        user_id TEXT NOT NULL,
                        operation_type TEXT NOT NULL,
                        operation_data TEXT,
                        created_at INTEGER NOT NULL,
                        FOREIGN KEY (workspace_id) REFERENCES design_workspaces(workspace_id) ON DELETE CASCADE
                    )
                ]])
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_design_workspace_ops_workspace ON design_workspace_ops(workspace_id, created_at DESC)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_design_workspace_ops_user ON design_workspace_ops(user_id, created_at DESC)")
                if err then error(err) end
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS design_workspace_ops")
                db:execute("DROP TABLE IF EXISTS design_workspaces")
            end)
        end)
    end)
end)