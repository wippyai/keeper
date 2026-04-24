local sql = require("sql")
local consts = require("consts")
local fs_hash = require("fs_hash")
local fs_view = require("fs_view")
local repo = require("repo")

local M = {}

-- ============================================================================
-- Registry side: overlay_entries diff between workspace branch and main
--
-- A registry entry is stored as two overlay chunks — "definition" (the YAML
-- metadata) and "content" (the source body, optional). Edits to one part
-- should surface distinctly from edits to the other, mirroring the registry
-- view's meta/data tabs. Rules:
--
--   CREATE / UPDATE → one row per part that changed (definition, content, or
--                     both). Per-part rows carry `part` = "definition" |
--                     "content" so the UI can render and diff them separately.
--   DELETE          → a single row with `part = nil`, since removing the
--                     whole entry is one conceptual action.
-- ============================================================================

M.PARTS = { consts.CHUNKS.DEFINITION, consts.CHUNKS.CONTENT }

local function chunk_hashes(tx, entry_id, branch)
    local rows, err = tx:query([[
        SELECT chunk_type, content_hash
        FROM keeper_overlay_chunks
        WHERE entry_id = ? AND branch = ?
    ]], { entry_id, branch })
    if err then return nil, err end

    local out = {}
    for _, row in ipairs(rows or {}) do
        out[row.chunk_type] = row.content_hash
    end
    return out, nil
end

function M.has_any_chunk(hashes)
    if type(hashes) ~= "table" then return false end
    return hashes[consts.CHUNKS.DEFINITION] ~= nil
        or hashes[consts.CHUNKS.CONTENT] ~= nil
end

function M.classify_part_change(branch_hash, main_hash)
    if branch_hash and not main_hash then return consts.OPS.CREATE end
    if not branch_hash and main_hash then return consts.OPS.DELETE end
    if branch_hash and main_hash and branch_hash ~= main_hash then return consts.OPS.UPDATE end
    return nil
end

function M.fs_sort_order(a, b)
    if a.op ~= b.op then return a.op < b.op end
    return a.target < b.target
end

function M.registry_diff(changeset_id)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local branch = consts.branch_for(changeset_id)

    local db, err = sql.get(consts.DATABASE.RESOURCE_ID)
    if err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(err) end

    local tx, tx_err = db:begin()
    if tx_err then
        db:release()
        return nil, consts.ERRORS.DB_ERROR .. ": begin: " .. tostring(tx_err)
    end

    local rows, qerr = tx:query([[
        SELECT id, deleted
        FROM keeper_overlay_entries
        WHERE branch = ?
        ORDER BY id ASC
    ]], { branch })
    if qerr then
        tx:rollback(); db:release()
        return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr)
    end

    local result = {}
    for _, row in ipairs(rows or {}) do
        local entry_id = row.id
        local is_deleted_in_branch = tonumber(row.deleted) == 1

        local branch_hashes, bch_err = chunk_hashes(tx, entry_id, branch)
        if bch_err then tx:rollback(); db:release(); return nil, bch_err end

        local main_hashes, mch_err = chunk_hashes(tx, entry_id, consts.MAIN_BRANCH)
        if mch_err then tx:rollback(); db:release(); return nil, mch_err end

        if is_deleted_in_branch then
            -- Full-entry delete collapses to a single row — the entry is gone.
            if M.has_any_chunk(main_hashes) then
                table.insert(result, {
                    category      = consts.CATEGORIES.REGISTRY,
                    op            = consts.OPS.DELETE,
                    target        = entry_id,
                    part          = nil,
                    baseline_hash = nil,
                    current_hash  = nil,
                })
            end
        else
            for _, part in ipairs(M.PARTS) do
                local bh = branch_hashes[part]
                local mh = main_hashes[part]
                local op = M.classify_part_change(bh, mh)
                if op then
                    table.insert(result, {
                        category      = consts.CATEGORIES.REGISTRY,
                        op            = op,
                        target        = entry_id,
                        part          = part,
                        baseline_hash = mh,
                        current_hash  = bh,
                    })
                end
            end
        end
    end

    tx:commit()
    db:release()
    return result, nil
end

-- ============================================================================
-- Filesystem side: DB content vs fe_fs
-- ============================================================================

function M.filesystem_diff(changeset_id, view)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not view then
        local v, err = fs_view.open(changeset_id)
        if err then return nil, err end
        view = v
    end

    -- Changeset FS content from DB
    local ws_files, ws_err = repo.list_fs_content(changeset_id)
    if ws_err then return nil, ws_err end

    local ws_by_path = {}
    for _, row in ipairs(ws_files) do
        ws_by_path[row.rel_path] = row
    end

    -- Walk fe_fs for baseline (skip build output)
    local fe_snap, fe_err = fs_hash.snapshot(view.fe_fs, "", {
        skip_dirs = consts.FE_SKIP_DIRS,
    })
    if fe_err then return nil, fe_err end

    local fe_by_path = {}
    for _, item in ipairs(fe_snap.manifest) do
        fe_by_path[item.path] = item
    end

    local result = {}

    -- Creates + updates from workspace DB content
    for path, ws_row in pairs(ws_by_path) do
        local fe_item = fe_by_path[path]
        if not fe_item then
            table.insert(result, {
                category      = consts.CATEGORIES.FILESYSTEM,
                op            = consts.OPS.CREATE,
                target        = path,
                baseline_hash = nil,
                current_hash  = ws_row.content_hash,
            })
        elseif fe_item.sha256 ~= ws_row.content_hash then
            table.insert(result, {
                category      = consts.CATEGORIES.FILESYSTEM,
                op            = consts.OPS.UPDATE,
                target        = path,
                baseline_hash = fe_item.sha256,
                current_hash  = ws_row.content_hash,
            })
        end
    end

    -- Explicit deletes
    local deletes, del_err = repo.list_fs_deletes(changeset_id)
    if del_err then return nil, del_err end
    for _, del in ipairs(deletes or {}) do
        local fe_item = fe_by_path[del.rel_path]
        if fe_item then
            table.insert(result, {
                category      = consts.CATEGORIES.FILESYSTEM,
                op            = consts.OPS.DELETE,
                target        = del.rel_path,
                baseline_hash = fe_item.sha256,
                current_hash  = nil,
            })
        end
    end

    table.sort(result, M.fs_sort_order)

    return result, nil
end

-- ============================================================================
-- Combined
-- ============================================================================

function M.compute(changeset_id)
    local registry_changes, reg_err = M.registry_diff(changeset_id)
    if reg_err then return nil, "registry diff: " .. reg_err end

    local fs_changes, fs_err = M.filesystem_diff(changeset_id)
    if fs_err then return nil, "fs diff: " .. fs_err end

    return {
        registry   = registry_changes,
        filesystem = fs_changes,
    }, nil
end

return M
