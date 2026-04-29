return require("migration").define(function()
    migration("Add fs history columns for prior-content capture + revert anchor", function()
        database("sqlite", function()
            up(function(db)
                local success, err

                success, err = db:execute([[
                    ALTER TABLE keeper_changeset_fs_content ADD COLUMN prior_content BLOB
                ]])
                if err then error("Failed to add prior_content: " .. err) end

                success, err = db:execute([[
                    ALTER TABLE keeper_changeset_fs_content ADD COLUMN prior_hash TEXT
                ]])
                if err then error("Failed to add prior_hash: " .. err) end

                success, err = db:execute([[
                    ALTER TABLE keeper_changeset_fs_content ADD COLUMN flushed_at TEXT
                ]])
                if err then error("Failed to add fs_content.flushed_at: " .. err) end

                success, err = db:execute([[
                    ALTER TABLE keeper_changeset_fs_deletes ADD COLUMN prior_content BLOB
                ]])
                if err then error("Failed to add fs_deletes.prior_content: " .. err) end

                success, err = db:execute([[
                    ALTER TABLE keeper_changeset_fs_deletes ADD COLUMN flushed_at TEXT
                ]])
                if err then error("Failed to add fs_deletes.flushed_at: " .. err) end

                success, err = db:execute([[
                    ALTER TABLE keeper_changesets ADD COLUMN pre_push_version TEXT
                ]])
                if err then error("Failed to add pre_push_version: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_wfc_flushed
                    ON keeper_changeset_fs_content(changeset_id, flushed_at)
                ]])
                if err then error("Failed to create fs_content.flushed_at index: " .. err) end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS keeper_idx_wfd_flushed
                    ON keeper_changeset_fs_deletes(changeset_id, flushed_at)
                ]])
                if err then error("Failed to create fs_deletes.flushed_at index: " .. err) end

                return true
            end)

            down(function(db)
                db:execute("DROP INDEX IF EXISTS keeper_idx_wfd_flushed")
                db:execute("DROP INDEX IF EXISTS keeper_idx_wfc_flushed")
                return true
            end)
        end)
    end)
end)
