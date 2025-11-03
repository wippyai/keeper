return require("migration").define(function()
    migration("Create workspace data table", function()
        database("postgres", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE design_workspace_data (
                        data_id UUID PRIMARY KEY,
                        workspace_id UUID NOT NULL,
                        user_id TEXT NOT NULL,
                        parent_data_id UUID,
                        path TEXT NOT NULL,
                        depth INTEGER NOT NULL DEFAULT 0,
                        position INTEGER DEFAULT 0,
                        type TEXT NOT NULL,
                        discriminator TEXT,
                        content TEXT,
                        content_type TEXT DEFAULT 'text/plain',
                        status TEXT,
                        metadata JSONB DEFAULT '{}',
                        created_at TIMESTAMP NOT NULL DEFAULT now(),
                        updated_at TIMESTAMP NOT NULL DEFAULT now(),
                        FOREIGN KEY (workspace_id) REFERENCES design_workspaces(workspace_id) ON DELETE CASCADE,
                        FOREIGN KEY (parent_data_id) REFERENCES design_workspace_data(data_id) ON DELETE CASCADE
                    )
                ]])
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_workspace ON design_workspace_data(workspace_id, created_at DESC)")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_user ON design_workspace_data(user_id)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_design_workspace_data_path ON design_workspace_data(path)")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_type ON design_workspace_data(workspace_id, type)")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_discriminator ON design_workspace_data(workspace_id, type, discriminator)")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_parent ON design_workspace_data(parent_data_id) WHERE parent_data_id IS NOT NULL")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_parent_position ON design_workspace_data(parent_data_id, position) WHERE parent_data_id IS NOT NULL")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_depth ON design_workspace_data(workspace_id, depth)")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_status ON design_workspace_data(workspace_id, status)")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_metadata ON design_workspace_data USING GIN (metadata)")
                if err then error(err) end
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS design_workspace_data")
            end)
        end)

        database("sqlite", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE design_workspace_data (
                        data_id TEXT PRIMARY KEY,
                        workspace_id TEXT NOT NULL,
                        user_id TEXT NOT NULL,
                        parent_data_id TEXT,
                        path TEXT NOT NULL,
                        depth INTEGER NOT NULL DEFAULT 0,
                        position INTEGER DEFAULT 0,
                        type TEXT NOT NULL,
                        discriminator TEXT,
                        content TEXT,
                        content_type TEXT DEFAULT 'text/plain',
                        status TEXT,
                        metadata TEXT DEFAULT '{}',
                        created_at INTEGER NOT NULL,
                        updated_at INTEGER NOT NULL,
                        FOREIGN KEY (workspace_id) REFERENCES design_workspaces(workspace_id) ON DELETE CASCADE,
                        FOREIGN KEY (parent_data_id) REFERENCES design_workspace_data(data_id) ON DELETE CASCADE
                    )
                ]])
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_workspace ON design_workspace_data(workspace_id, created_at DESC)")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_user ON design_workspace_data(user_id)")
                if err then error(err) end

                success, err = db:execute("CREATE INDEX idx_design_workspace_data_path ON design_workspace_data(path)")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_type ON design_workspace_data(workspace_id, type)")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_discriminator ON design_workspace_data(workspace_id, type, discriminator)")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_parent ON design_workspace_data(parent_data_id) WHERE parent_data_id IS NOT NULL")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_parent_position ON design_workspace_data(parent_data_id, position) WHERE parent_data_id IS NOT NULL")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_depth ON design_workspace_data(workspace_id, depth)")
                if err then error(err) end

                success, err = db:execute(
                "CREATE INDEX idx_design_workspace_data_status ON design_workspace_data(workspace_id, status)")
                if err then error(err) end
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS design_workspace_data")
            end)
        end)
    end)
end)
