return require("migration").define(function()
    migration("Add workspace FS content table", function()
        database("sqlite", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS keeper_changeset_fs_content (
                        changeset_id  TEXT NOT NULL,
                        rel_path      TEXT NOT NULL,
                        content       BLOB NOT NULL,
                        content_hash  TEXT NOT NULL,
                        updated_at    TEXT NOT NULL,
                        PRIMARY KEY (changeset_id, rel_path),
                        FOREIGN KEY (changeset_id) REFERENCES keeper_changesets(changeset_id) ON DELETE CASCADE
                    )
                ]])
                if err then error("Failed to create keeper_changeset_fs_content: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_wfc_hash ON keeper_changeset_fs_content(content_hash)
                ]])
                if err then error("Failed to create wfc hash index: " .. err) end

                return true
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS keeper_changeset_fs_content")
                return true
            end)
        end)
    end)
end)
