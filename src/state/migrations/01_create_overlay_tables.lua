return require("migration").define(function()
    migration("Create overlay tables", function()
        database("sqlite", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE overlay_entries (
                        id TEXT NOT NULL,
                        branch TEXT NOT NULL DEFAULT 'main',
                        kind TEXT NOT NULL,
                        deleted INTEGER NOT NULL DEFAULT 0,
                        created_at TEXT NOT NULL,
                        updated_at TEXT NOT NULL,
                        PRIMARY KEY (id, branch)
                    )
                ]])
                if err then error("Failed to create overlay_entries: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX idx_overlay_entries_branch ON overlay_entries(branch)
                ]])
                if err then error("Failed to create branch index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX idx_overlay_entries_kind ON overlay_entries(branch, kind)
                ]])
                if err then error("Failed to create kind index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX idx_overlay_entries_deleted ON overlay_entries(branch, deleted)
                ]])
                if err then error("Failed to create deleted index: " .. err) end

                success, err = db:execute([[
                    CREATE TABLE overlay_chunks (
                        chunk_id INTEGER PRIMARY KEY AUTOINCREMENT,
                        entry_id TEXT NOT NULL,
                        branch TEXT NOT NULL,
                        chunk_type TEXT NOT NULL,
                        content TEXT NOT NULL,
                        content_hash TEXT NOT NULL,
                        created_at TEXT NOT NULL,
                        FOREIGN KEY (entry_id, branch) REFERENCES overlay_entries(id, branch) ON DELETE CASCADE
                    )
                ]])
                if err then error("Failed to create overlay_chunks: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX idx_chunks_entry ON overlay_chunks(entry_id, branch)
                ]])
                if err then error("Failed to create chunks entry index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX idx_chunks_type ON overlay_chunks(chunk_type)
                ]])
                if err then error("Failed to create chunks type index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX idx_chunks_hash ON overlay_chunks(content_hash)
                ]])
                if err then error("Failed to create chunks hash index: " .. err) end

                success, err = db:execute([[
                    CREATE VIRTUAL TABLE overlay_chunks_fts USING fts5(
                        entry_id UNINDEXED,
                        branch UNINDEXED,
                        content,
                        tokenize = 'porter'
                    )
                ]])
                if err then error("Failed to create FTS table: " .. err) end

                success, err = db:execute([[
                    CREATE TABLE overlay_attributes (
                        entry_id TEXT NOT NULL,
                        branch TEXT NOT NULL,
                        attr_key TEXT NOT NULL,
                        attr_value TEXT NOT NULL,
                        PRIMARY KEY (entry_id, branch, attr_key),
                        FOREIGN KEY (entry_id, branch) REFERENCES overlay_entries(id, branch) ON DELETE CASCADE
                    )
                ]])
                if err then error("Failed to create overlay_attributes: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX idx_overlay_attr_key ON overlay_attributes(attr_key)
                ]])
                if err then error("Failed to create attribute key index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX idx_overlay_attr_value ON overlay_attributes(attr_key, attr_value)
                ]])
                if err then error("Failed to create attribute value index: " .. err) end

                success, err = db:execute([[
                    CREATE TABLE overlay_edges (
                        source_id TEXT NOT NULL,
                        target_id TEXT NOT NULL,
                        branch TEXT NOT NULL,
                        edge_type TEXT NOT NULL,
                        metadata TEXT,
                        created_at TEXT NOT NULL,
                        PRIMARY KEY (source_id, target_id, branch, edge_type)
                    )
                ]])
                if err then error("Failed to create overlay_edges: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX idx_overlay_edges_source ON overlay_edges(source_id, branch, edge_type)
                ]])
                if err then error("Failed to create edges source index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX idx_overlay_edges_target ON overlay_edges(target_id, branch, edge_type)
                ]])
                if err then error("Failed to create edges target index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX idx_overlay_edges_type ON overlay_edges(edge_type)
                ]])
                if err then error("Failed to create edges type index: " .. err) end

                return true
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS overlay_edges")
                db:execute("DROP TABLE IF EXISTS overlay_attributes")
                db:execute("DROP TABLE IF EXISTS overlay_chunks_fts")
                db:execute("DROP TABLE IF EXISTS overlay_chunks")
                db:execute("DROP TABLE IF EXISTS overlay_entries")
                return true
            end)
        end)
    end)
end)