local sql = require("sql")
local fs = require("fs")
local time = require("time")
local hash = require("hash")
local consts = require("consts")

local M = {}

local STATE_DB  = consts.DATABASE.RESOURCE_ID
local FE_VOLUME = consts.FS.FE_VOLUME
local FE_PREFIX = "frontend/"

type FlushStep = {
    op?: string,
    inside: string,
    had_prior?: boolean,
    prior_content?: string,
    had_before?: boolean,
    before_content?: string,
}

local function now_iso()
    return time.now():format(time.RFC3339NANO)
end

local function ensure_parent_dirs(vol, rel_path)
    local parts = {}
    for part in rel_path:gmatch("[^/]+") do
        table.insert(parts, part)
    end
    if #parts <= 1 then return end
    local dir = ""
    for i = 1, #parts - 1 do
        dir = dir == "" and parts[i] or (dir .. "/" .. parts[i])
        if vol.mkdir then
            pcall(vol.mkdir, vol, dir)
        end
    end
end

local function revert_applied(vol, applied: {FlushStep})
    for i = #applied, 1, -1 do
        local step = applied[i]
        if step and step.op == "write" then
            if step.had_prior then
                pcall(vol.writefile, vol, step.inside, step.prior_content)
            else
                pcall(vol.remove, vol, step.inside)
            end
        elseif step and step.op == "delete" then
            pcall(vol.writefile, vol, step.inside, step.prior_content)
        end
    end
end

local function restore_before_state(vol, applied: {FlushStep})
    for i = #applied, 1, -1 do
        local step = applied[i]
        if step and step.had_before then
            ensure_parent_dirs(vol, step.inside)
            pcall(vol.writefile, vol, step.inside, step.before_content)
        elseif step then
            pcall(vol.remove, vol, step.inside)
        end
    end
end

local function inside_fe_path(rel_path)
    rel_path = rel_path or ""
    if rel_path:sub(1, #FE_PREFIX) ~= FE_PREFIX then return nil end
    local inside = rel_path:sub(#FE_PREFIX + 1)
    if inside == "" then return nil end
    return inside
end

local function capture_current(vol, inside)
    local had_before = vol:exists(inside)
    local before_content = nil
    if had_before then
        local content, err = vol:readfile(inside)
        if err then return nil, nil, err end
        before_content = content
    end
    return had_before, before_content, nil
end

-- Flush staged fs content for a changeset. Captures prior bytes per path, writes
-- to fe_fs, stamps flushed_at. Everything runs inside a state_db transaction;
-- on any fs error or commit failure, fe_fs is reverted to pre-flush state.
function M.flush(changeset_id)
    local written_paths, deleted_paths = {}, {}
    if not changeset_id or changeset_id == "" then
        return 0, 0, nil, written_paths, deleted_paths
    end

    local db = sql.get(STATE_DB)
    if not db then return 0, 0, "state db unavailable", written_paths, deleted_paths end

    local content_rows, content_err = db:query(
        "SELECT rel_path, content FROM keeper_changeset_fs_content " ..
        "WHERE changeset_id = ? AND flushed_at IS NULL ORDER BY rel_path ASC",
        { changeset_id }
    )
    if content_err then
        db:release()
        return 0, 0, "content query failed: " .. tostring(content_err), written_paths, deleted_paths
    end
    content_rows = content_rows or {}

    local delete_rows, delete_err = db:query(
        "SELECT rel_path FROM keeper_changeset_fs_deletes " ..
        "WHERE changeset_id = ? AND flushed_at IS NULL ORDER BY rel_path ASC",
        { changeset_id }
    )
    if delete_err then
        db:release()
        return 0, 0, "delete query failed: " .. tostring(delete_err), written_paths, deleted_paths
    end
    delete_rows = delete_rows or {}

    if #content_rows == 0 and #delete_rows == 0 then
        db:release()
        return 0, 0, nil, written_paths, deleted_paths
    end

    local vol, verr = fs.get(FE_VOLUME)
    if verr or not vol then
        db:release()
        return 0, 0, "fe_fs unavailable: " .. tostring(verr), written_paths, deleted_paths
    end

    local tx, txerr = db:begin()
    if txerr then
        db:release()
        return 0, 0, "flush txn begin failed: " .. tostring(txerr), written_paths, deleted_paths
    end

    local applied: {FlushStep} = {}
    local written, deleted = 0, 0
    local flushed_at = now_iso()

    local function abort(err)
        tx:rollback()
        db:release()
        revert_applied(vol, applied)
        return 0, 0, err, {}, {}
    end

    for _, row in ipairs(content_rows) do
        local rel = row.rel_path or ""
        if rel:sub(1, #FE_PREFIX) == FE_PREFIX then
            local inside = rel:sub(#FE_PREFIX + 1)
            if inside ~= "" then
                local had_prior = vol:exists(inside)
                local prior_content = nil
                local prior_hash = ""
                if had_prior then
                    local pc, rerr = vol:readfile(inside)
                    if rerr then return abort("prior read failed for " .. rel .. ": " .. tostring(rerr)) end
                    prior_content = pc
                    local hh, herr = hash.sha256(pc or "")
                    if herr then return abort("prior hash failed for " .. rel .. ": " .. tostring(herr)) end
                    prior_hash = hh
                end

                ensure_parent_dirs(vol, inside)
                local _, werr = vol:writefile(inside, row.content or "")
                if werr then return abort("fs write failed for " .. rel .. ": " .. tostring(werr)) end
                table.insert(applied, {
                    op = "write", inside = inside, had_prior = had_prior, prior_content = prior_content,
                })

                local _, uerr = tx:execute(
                    "UPDATE keeper_changeset_fs_content " ..
                    "SET prior_content = ?, prior_hash = ?, flushed_at = ? " ..
                    "WHERE changeset_id = ? AND rel_path = ? AND flushed_at IS NULL",
                    { prior_content, prior_hash, flushed_at, changeset_id, rel }
                )
                if uerr then return abort("flush stamp failed for " .. rel .. ": " .. tostring(uerr)) end

                written = written + 1
                table.insert(written_paths, { path = rel, op = had_prior and "update" or "create" })
            end
        end
    end

    for _, row in ipairs(delete_rows) do
        local rel = row.rel_path or ""
        if rel:sub(1, #FE_PREFIX) == FE_PREFIX then
            local inside = rel:sub(#FE_PREFIX + 1)
            if inside ~= "" then
                local prior_content = nil
                if vol:exists(inside) then
                    local pc, rerr = vol:readfile(inside)
                    if rerr then return abort("prior read failed for " .. rel .. ": " .. tostring(rerr)) end
                    prior_content = pc

                    local _, derr = vol:remove(inside)
                    if derr then return abort("fs delete failed for " .. rel .. ": " .. tostring(derr)) end
                    table.insert(applied, {
                        op = "delete", inside = inside, prior_content = prior_content,
                    })
                    deleted = deleted + 1
                    table.insert(deleted_paths, { path = rel, op = "delete" })
                end

                local _, uerr = tx:execute(
                    "UPDATE keeper_changeset_fs_deletes " ..
                    "SET prior_content = ?, flushed_at = ? " ..
                    "WHERE changeset_id = ? AND rel_path = ? AND flushed_at IS NULL",
                    { prior_content, flushed_at, changeset_id, rel }
                )
                if uerr then return abort("delete stamp failed for " .. rel .. ": " .. tostring(uerr)) end
            end
        end
    end

    local _, commit_err = tx:commit()
    db:release()
    if commit_err then
        revert_applied(vol, applied)
        return 0, 0, "flush commit failed: " .. tostring(commit_err), {}, {}
    end

    return written, deleted, nil, written_paths, deleted_paths
end

-- Undo a prior successful flush for a changeset after integrate side effects
-- fail. Physical fe_fs is restored to the pre-flush bytes and the DB rows are
-- made staged again (flushed_at=NULL), so the reopened changeset sees the same
-- overlay and the next publish can flush it again with fresh prior snapshots.
function M.revert_flushed(changeset_id)
    if not changeset_id or changeset_id == "" then
        return { restored = 0, restaged = 0, paths = {} }, nil
    end

    local db = sql.get(STATE_DB)
    if not db then return nil, "state db unavailable" end

    local content_rows, content_err = db:query(
        "SELECT rel_path, prior_content FROM keeper_changeset_fs_content " ..
        "WHERE changeset_id = ? AND flushed_at IS NOT NULL ORDER BY rel_path ASC",
        { changeset_id }
    )
    if content_err then
        db:release()
        return nil, "content query failed: " .. tostring(content_err)
    end
    content_rows = content_rows or {}

    local delete_rows, delete_err = db:query(
        "SELECT rel_path, prior_content FROM keeper_changeset_fs_deletes " ..
        "WHERE changeset_id = ? AND flushed_at IS NOT NULL ORDER BY rel_path ASC",
        { changeset_id }
    )
    if delete_err then
        db:release()
        return nil, "delete query failed: " .. tostring(delete_err)
    end
    delete_rows = delete_rows or {}

    if #content_rows == 0 and #delete_rows == 0 then
        db:release()
        return { restored = 0, restaged = 0, paths = {} }, nil
    end

    local vol, verr = fs.get(FE_VOLUME)
    if verr or not vol then
        db:release()
        return nil, "fe_fs unavailable: " .. tostring(verr)
    end

    local tx, txerr = db:begin()
    if txerr then
        db:release()
        return nil, "revert txn begin failed: " .. tostring(txerr)
    end

    local applied = {}
    local paths = {}
    local restored, restaged = 0, 0

    local function abort(err)
        tx:rollback()
        db:release()
        restore_before_state(vol, applied)
        return nil, err
    end

    local function remember_current(inside, rel)
        local had_before, before_content, rerr = capture_current(vol, inside)
        if rerr then
            return nil, "current read failed for " .. rel .. ": " .. tostring(rerr)
        end
        table.insert(applied, {
            inside = inside, had_before = had_before, before_content = before_content,
        })
        return true, nil
    end

    -- Flush applies writes before deletes; undo deletes first so even a
    -- pathological same-path write+delete pair is restored in reverse order.
    for _, row in ipairs(delete_rows) do
        local rel = row.rel_path or ""
        local inside = inside_fe_path(rel)
        if inside then
            local _, rerr = remember_current(inside, rel)
            if rerr then return abort(rerr) end

            if row.prior_content ~= nil then
                if type(row.prior_content) ~= "string" then
                    return abort("fs restore failed for " .. rel .. ": prior content is not a string")
                end
                ensure_parent_dirs(vol, inside)
                local _, werr = vol:writefile(inside, row.prior_content)
                if werr then return abort("fs restore failed for " .. rel .. ": " .. tostring(werr)) end
                restored = restored + 1
            elseif vol:exists(inside) then
                local _, derr = vol:remove(inside)
                if derr then return abort("fs remove failed for " .. rel .. ": " .. tostring(derr)) end
                restored = restored + 1
            end

            local _, uerr = tx:execute(
                "UPDATE keeper_changeset_fs_deletes " ..
                "SET prior_content = NULL, flushed_at = NULL " ..
                "WHERE changeset_id = ? AND rel_path = ? AND flushed_at IS NOT NULL",
                { changeset_id, rel }
            )
            if uerr then return abort("delete restage failed for " .. rel .. ": " .. tostring(uerr)) end

            restaged = restaged + 1
            table.insert(paths, { path = rel, op = "delete" })
        end
    end

    for _, row in ipairs(content_rows) do
        local rel = row.rel_path or ""
        local inside = inside_fe_path(rel)
        if inside then
            local _, rerr = remember_current(inside, rel)
            if rerr then return abort(rerr) end

            if row.prior_content ~= nil then
                if type(row.prior_content) ~= "string" then
                    return abort("fs restore failed for " .. rel .. ": prior content is not a string")
                end
                ensure_parent_dirs(vol, inside)
                local _, werr = vol:writefile(inside, row.prior_content)
                if werr then return abort("fs restore failed for " .. rel .. ": " .. tostring(werr)) end
            elseif vol:exists(inside) then
                local _, derr = vol:remove(inside)
                if derr then return abort("fs remove failed for " .. rel .. ": " .. tostring(derr)) end
            end
            restored = restored + 1

            local _, uerr = tx:execute(
                "UPDATE keeper_changeset_fs_content " ..
                "SET prior_content = NULL, prior_hash = NULL, flushed_at = NULL " ..
                "WHERE changeset_id = ? AND rel_path = ? AND flushed_at IS NOT NULL",
                { changeset_id, rel }
            )
            if uerr then return abort("content restage failed for " .. rel .. ": " .. tostring(uerr)) end

            restaged = restaged + 1
            table.insert(paths, { path = rel, op = "write" })
        end
    end

    local _, commit_err = tx:commit()
    db:release()
    if commit_err then
        restore_before_state(vol, applied)
        return nil, "revert commit failed: " .. tostring(commit_err)
    end

    return {
        restored = restored,
        restaged = restaged,
        paths = paths,
    }, nil
end

return M
