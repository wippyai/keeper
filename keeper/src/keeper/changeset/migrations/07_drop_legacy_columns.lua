-- Drop three columns from keeper_changesets that are no longer referenced:
--   * git_branch / git_pr_id  — git integration never shipped; reader returned
--     them, writer inserted NULLs, nothing else used them.
--   * pre_push_version        — stamp_pre_push_version went away when push.lua
--     was stripped down to a pure governance publisher. The baseline version is
--     now captured live in integrate.run.lua via governance.current_version(),
--     no persistent column required.
--
-- keeper_changeset_baselines is the source of truth for pre-change snapshots.

return require("migration").define(function()
    migration("Drop legacy git_branch, git_pr_id, pre_push_version columns from keeper_changesets", function()
        database("sqlite", function()
            up(function(db)
                local function has_col(name)
                    local rows, err = db:query(
                        "SELECT 1 FROM pragma_table_info('keeper_changesets') WHERE name = ?",
                        { name }
                    )
                    if err then error("probe " .. name .. ": " .. err) end
                    return rows and #rows > 0
                end
                local function drop(name)
                    if not has_col(name) then return end
                    local _, err = db:execute("ALTER TABLE keeper_changesets DROP COLUMN " .. name)
                    if err then error("drop " .. name .. ": " .. err) end
                end
                drop("git_branch")
                drop("git_pr_id")
                drop("pre_push_version")
                return true
            end)

            down(function(db)
                db:execute("ALTER TABLE keeper_changesets ADD COLUMN git_branch TEXT")
                db:execute("ALTER TABLE keeper_changesets ADD COLUMN git_pr_id TEXT")
                db:execute("ALTER TABLE keeper_changesets ADD COLUMN pre_push_version TEXT")
                return true
            end)
        end)
    end)
end)
