local sql = require("sql")
local fs = require("fs")
local time = require("time")
local hash = require("hash")
local consts = require("consts")

local M = {}

local STATE_DB  = consts.DATABASE.RESOURCE_ID
local FE_VOLUME = consts.FS.FE_VOLUME
local FE_PREFIX = "frontend/"

local function now_iso()
    local ok, now = pcall(time.now)
    if not ok or not now then return os.date("!%Y-%m-%dT%H:%M:%SZ") end
    if type(now) == "table" and now.format then
        local fok, s = pcall(now.format, now, "rfc3339")
        if fok and s and s ~= "" then return s end
    end
    return tostring(now)
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

local function revert_applied(vol, applied)
    for i = #applied, 1, -1 do
        local step = applied[i]
        if step.op == "write" then
            if step.had_prior then
                pcall(vol.writefile, vol, step.inside, step.prior_content)
            else
                pcall(vol.remove, vol, step.inside)
            end
        elseif step.op == "delete" then
            pcall(vol.writefile, vol, step.inside, step.prior_content)
        end
    end
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

    local content_rows = db:query(
        "SELECT rel_path, content FROM keeper_changeset_fs_content " ..
        "WHERE changeset_id = ? AND flushed_at IS NULL ORDER BY rel_path ASC",
        { changeset_id }
    ) or {}
    local delete_rows = db:query(
        "SELECT rel_path FROM keeper_changeset_fs_deletes " ..
        "WHERE changeset_id = ? AND flushed_at IS NULL ORDER BY rel_path ASC",
        { changeset_id }
    ) or {}

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

    local applied = {}
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

return M
