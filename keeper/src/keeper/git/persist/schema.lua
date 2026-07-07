local M = {}
local ensured = false

local function exec(db, statement, message)
    local _, err = db:execute(statement)
    if err then return nil, message .. ": " .. err end
    return true, nil
end

function M.ensure(db)
    if ensured then return true, nil end

    local ok, err = exec(db, [[
        CREATE TABLE IF NOT EXISTS keeper_git_runs (
            run_id        TEXT PRIMARY KEY,
            started_at    TEXT NOT NULL,
            finished_at   TEXT,
            status        TEXT NOT NULL,
            journal_size  INTEGER NOT NULL DEFAULT 0,
            cluster_count INTEGER NOT NULL DEFAULT 0,
            ai_model      TEXT,
            error         TEXT,
            payload_json  TEXT NOT NULL
        )
    ]], "Failed to create keeper_git_runs")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_git_runs_finished
        ON keeper_git_runs(finished_at DESC)
        WHERE finished_at IS NOT NULL
    ]], "Failed to create git runs finished index")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_git_runs_status
        ON keeper_git_runs(status)
    ]], "Failed to create git runs status index")
    if err then return nil, err end

    ensured = true
    return true, nil
end

function M.drop(db)
    db:execute("DROP TABLE IF EXISTS keeper_git_runs")
    ensured = false
    return true
end

return M
