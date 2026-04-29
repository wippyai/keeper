local fs = require("fs")
local hash = require("hash")
local sql = require("sql")
local consts = require("consts")
local repo = require("repo")

local M = {}
type FileVolume = {
    exists: (FileVolume, string) -> boolean,
    readfile: (FileVolume, string) -> string,
    isdir: (FileVolume, string) -> boolean,
    readdir: (FileVolume, string) -> any,
}

type ChangesetFsView = {
    changeset_id: string,
    baseline_fs: FileVolume,
    has_scratch_copy: (ChangesetFsView, string) -> (boolean, string?),
    is_deleted: (ChangesetFsView, string) -> (boolean, string?),
    read: (ChangesetFsView, string) -> (string?, string?),
    exists: (ChangesetFsView, string) -> (boolean, string?),
    write: (ChangesetFsView, string, string) -> (string?, string?),
    delete: (ChangesetFsView, string) -> (boolean?, string?),
    destroy_scratch: (ChangesetFsView) -> (boolean?, string?),
}

local View = {}
View.__index = View

-- ============================================================================
-- Path validation
-- ============================================================================

local function validate_rel_path(rel_path: unknown): (string?, string?)
    if type(rel_path) ~= "string" or rel_path == "" then
        return nil, consts.ERRORS.INVALID_PATH .. ": empty"
    end
    if rel_path:find("\0", 1, true) then
        return nil, consts.ERRORS.INVALID_PATH .. ": null byte"
    end
    if rel_path:sub(1, 1) == "/" then
        return nil, consts.ERRORS.INVALID_PATH .. ": absolute"
    end

    rel_path = rel_path:gsub("\\", "/")

    local segments = {}
    for segment in rel_path:gmatch("[^/]+") do
        if segment == "" or segment == "." then
            return nil, consts.ERRORS.INVALID_PATH .. ": empty segment"
        end
        if segment == ".." then
            return nil, consts.ERRORS.INVALID_PATH .. ": '..' segment"
        end
        table.insert(segments, segment)
    end

    if #segments == 0 then
        return nil, consts.ERRORS.INVALID_PATH .. ": empty after normalize"
    end

    return table.concat(segments, "/"), nil
end

M.validate_rel_path = validate_rel_path

-- ============================================================================
-- Constructor
-- ============================================================================

function M.open(changeset_id: string): (ChangesetFsView?, string?)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local baseline_fs, fs_err = fs.get(consts.FS.PROJECT_VOLUME)
    if fs_err then
        return nil, consts.ERRORS.FS_ERROR .. ": project_fs: " .. tostring(fs_err)
    end

    local view = setmetatable({
        changeset_id = changeset_id,
        baseline_fs  = baseline_fs,
    }, View) :: ChangesetFsView
    return view, nil
end

-- ============================================================================
-- Read operations
-- ============================================================================

function View:has_scratch_copy(rel_path: string): (boolean, string?)
    local safe, perr = validate_rel_path(rel_path)
    if perr then return false, perr end

    local row, _ = repo.get_fs_content(self.changeset_id, safe)
    return row ~= nil, nil
end

function View:is_deleted(rel_path: string): (boolean, string?)
    local safe, perr = validate_rel_path(rel_path)
    if perr then return false, perr end

    local rows, err = repo.list_fs_deletes(self.changeset_id)
    if err then return false, err end
    for _, row in ipairs(rows or {}) do
        if row.rel_path == safe then return true, nil end
    end
    return false, nil
end

-- Read a file as seen from inside the workspace:
--   1. if marked deleted -> nil, "deleted"
--   2. if stored in DB (workspace content) -> return it
--   3. else fall through to the project filesystem baseline
function View:read(rel_path: string): (string?, string?)
    local safe, perr = validate_rel_path(rel_path)
    if perr then return nil, perr end

    local deleted, derr = self:is_deleted(safe)
    if derr then return nil, derr end
    if deleted then return nil, "deleted" end

    local row, _ = repo.get_fs_content(self.changeset_id, safe)
    if row then return row.content, nil end

    if self.baseline_fs:exists(safe) then
        local content = self.baseline_fs:readfile(safe)
        if type(content) ~= "string" then
            return nil, "file content is not a string"
        end
        return content, nil
    end

    return nil, "not found"
end

function View:exists(rel_path: string): (boolean, string?)
    local safe, perr = validate_rel_path(rel_path)
    if perr then return false, perr end

    local deleted, derr = self:is_deleted(safe)
    if derr then return false, derr end
    if deleted then return false, nil end

    local row, _ = repo.get_fs_content(self.changeset_id, safe)
    if row then return true, nil end

    if self.baseline_fs:exists(safe) then return true, nil end
    return false, nil
end

-- ============================================================================
-- Write operations
-- ============================================================================

-- Write a file into the workspace (stored in keeper_changeset_fs_content table).
-- Returns (content_hash, nil) on success.
function View:write(rel_path: string, content: string): (string?, string?)
    local safe, perr = validate_rel_path(rel_path)
    if perr then return nil, perr end
    if type(content) ~= "string" then
        return nil, consts.ERRORS.INVALID_PATH .. ": content must be a string"
    end

    local deleted, derr = self:is_deleted(safe)
    if derr then return nil, derr end
    if deleted then
        local _, undel_err = repo.unrecord_fs_delete(self.changeset_id, safe)
        if undel_err then return nil, undel_err end
    end

    local h, herr = hash.sha256(content)
    if herr then return nil, consts.ERRORS.HASH_ERROR .. ": " .. tostring(herr) end

    local _, store_err = repo.store_fs_content(self.changeset_id, safe, content, h)
    if store_err then return nil, store_err end

    return h, nil
end

-- Mark a path as deleted. Removes DB content row (if any) and records delete marker.
function View:delete(rel_path: string): (boolean?, string?)
    local safe, perr = validate_rel_path(rel_path)
    if perr then return nil, perr end

    local baseline_hash = ""
    if self.baseline_fs:exists(safe) then
        local base_content = self.baseline_fs:readfile(safe)
        if type(base_content) ~= "string" then return nil, "file content is not a string" end
        local h, _ = hash.sha256(base_content)
        if h then baseline_hash = h end
    end

    repo.delete_fs_content(self.changeset_id, safe)

    local _, dberr = repo.record_fs_delete(self.changeset_id, safe, baseline_hash)
    if dberr then return nil, dberr end
    return true, nil
end

-- Drop staged FS content (pre-flush only). History rows with flushed_at stay
-- so revert remains possible. Cascade-delete on the changeset row still removes
-- everything if the changeset itself is deleted.
function View:destroy_scratch(): (boolean?, string?)
    local db, err = sql.get(consts.DATABASE.RESOURCE_ID)
    if err then return nil, tostring(err) end

    db:execute(
        "DELETE FROM keeper_changeset_fs_content WHERE changeset_id = ? AND flushed_at IS NULL",
        { self.changeset_id }
    )
    db:execute(
        "DELETE FROM keeper_changeset_fs_deletes WHERE changeset_id = ? AND flushed_at IS NULL",
        { self.changeset_id }
    )
    db:release()

    return true, nil
end

return M
