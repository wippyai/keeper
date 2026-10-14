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
        CREATE TABLE IF NOT EXISTS keeper_overlay_entries (
            id TEXT NOT NULL,
            branch TEXT NOT NULL DEFAULT 'main',
            kind TEXT NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            PRIMARY KEY (id, branch)
        )
    ]], "Failed to create keeper_overlay_entries")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_overlay_entries_branch ON keeper_overlay_entries(branch)
    ]], "Failed to create branch index")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_overlay_entries_kind ON keeper_overlay_entries(branch, kind)
    ]], "Failed to create kind index")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_overlay_entries_deleted ON keeper_overlay_entries(branch, deleted)
    ]], "Failed to create deleted index")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE TABLE IF NOT EXISTS keeper_overlay_chunks (
            chunk_id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id TEXT NOT NULL,
            branch TEXT NOT NULL,
            chunk_type TEXT NOT NULL,
            content TEXT NOT NULL,
            content_hash TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (entry_id, branch) REFERENCES keeper_overlay_entries(id, branch) ON DELETE CASCADE
        )
    ]], "Failed to create keeper_overlay_chunks")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_overlay_chunks_entry ON keeper_overlay_chunks(entry_id, branch)
    ]], "Failed to create chunks entry index")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_overlay_chunks_type ON keeper_overlay_chunks(chunk_type)
    ]], "Failed to create chunks type index")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_overlay_chunks_hash ON keeper_overlay_chunks(content_hash)
    ]], "Failed to create chunks hash index")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE VIRTUAL TABLE IF NOT EXISTS keeper_overlay_chunks_fts USING fts5(
            entry_id UNINDEXED,
            branch UNINDEXED,
            content,
            tokenize = 'porter'
        )
    ]], "Failed to create keeper_overlay_chunks_fts")
    if err then
        ok, err = exec(db, [[
            CREATE TABLE IF NOT EXISTS keeper_overlay_chunks_fts (
                entry_id TEXT NOT NULL,
                branch TEXT NOT NULL,
                content TEXT NOT NULL
            )
        ]], "Failed to create FTS fallback table")
        if err then return nil, err end
    end

    ok, err = exec(db, [[
        CREATE TABLE IF NOT EXISTS keeper_overlay_attributes (
            entry_id TEXT NOT NULL,
            branch TEXT NOT NULL,
            attr_key TEXT NOT NULL,
            attr_value TEXT NOT NULL,
            PRIMARY KEY (entry_id, branch, attr_key),
            FOREIGN KEY (entry_id, branch) REFERENCES keeper_overlay_entries(id, branch) ON DELETE CASCADE
        )
    ]], "Failed to create keeper_overlay_attributes")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_overlay_attr_key ON keeper_overlay_attributes(attr_key)
    ]], "Failed to create attribute key index")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_overlay_attr_value ON keeper_overlay_attributes(attr_key, attr_value)
    ]], "Failed to create attribute value index")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE TABLE IF NOT EXISTS keeper_overlay_edges (
            source_id TEXT NOT NULL,
            target_id TEXT NOT NULL,
            branch TEXT NOT NULL,
            edge_type TEXT NOT NULL,
            metadata TEXT,
            created_at TEXT NOT NULL,
            PRIMARY KEY (source_id, target_id, branch, edge_type)
        )
    ]], "Failed to create keeper_overlay_edges")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_overlay_edges_source ON keeper_overlay_edges(source_id, branch, edge_type)
    ]], "Failed to create edges source index")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_overlay_edges_target ON keeper_overlay_edges(target_id, branch, edge_type)
    ]], "Failed to create edges target index")
    if err then return nil, err end

    ok, err = exec(db, [[
        CREATE INDEX IF NOT EXISTS keeper_idx_overlay_edges_type ON keeper_overlay_edges(edge_type)
    ]], "Failed to create edges type index")
    if err then return nil, err end

    ensured = true
    return true, nil
end

function M.drop(db)
    db:execute("DROP TABLE IF EXISTS keeper_overlay_edges")
    db:execute("DROP TABLE IF EXISTS keeper_overlay_attributes")
    db:execute("DROP TABLE IF EXISTS keeper_overlay_chunks_fts")
    db:execute("DROP TABLE IF EXISTS keeper_overlay_chunks")
    db:execute("DROP TABLE IF EXISTS keeper_overlay_entries")
    ensured = false
    return true
end

return M
