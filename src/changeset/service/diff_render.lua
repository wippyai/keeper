-- keeper.changeset.service:diff_render
--
-- Renders baseline vs current content for a changeset target so the diff
-- view can show both sides. Owns the overlay-chunk reads for registry
-- targets and the filesystem reads for fs targets, keeping the API
-- handler a thin adapter.

local sql = require("sql")
local fs = require("fs")

local consts = require("consts")
local repo = require("repo")
local fs_view = require("fs_view")

local M = {}

local VALID_PARTS = {
    [consts.CHUNKS.DEFINITION] = true,
    [consts.CHUNKS.CONTENT] = true,
}

M.ERR = {
    BAD_REQUEST  = "bad_request",
    NOT_FOUND    = "not_found",
    FORBIDDEN    = "forbidden",
    UNAUTHORIZED = "unauthorized",
    CONFLICT     = "conflict",
    INTERNAL     = "internal",
}

local function fail(code, message, extra)
    local err = { code = code, message = message }
    if extra then
        for k, v in pairs(extra) do err[k] = v end
    end
    return nil, err
end

function M.language_from_kind(kind)
    if not kind or kind == "" then return "plaintext" end
    if kind:match("%.lua$") then return "lua" end
    if kind == "migration" then return "lua" end
    if kind == "template.jet" then return "html" end
    if kind:match("template") then return "html" end
    return "plaintext"
end
local language_from_kind = M.language_from_kind

function M.detect_fs_language(target)
    if type(target) ~= "string" then return "plaintext" end
    if target:match("%.lua$") then return "lua" end
    if target:match("%.vue$") then return "html" end
    if target:match("%.ts$") then return "typescript" end
    if target:match("%.js$") then return "javascript" end
    if target:match("%.json$") then return "json" end
    if target:match("%.yaml$") or target:match("%.yml$") then return "yaml" end
    if target:match("%.css$") then return "css" end
    if target:match("%.md$") then return "markdown" end
    return "plaintext"
end
local detect_fs_language = M.detect_fs_language

function M.validate_params(params)
    if type(params) ~= "table" then
        return { code = M.ERR.BAD_REQUEST, message = "params required" }
    end
    if not params.changeset_id or params.changeset_id == "" then
        return { code = M.ERR.BAD_REQUEST, message = "workspace id required" }
    end
    if not params.target or params.target == "" then
        return { code = M.ERR.BAD_REQUEST, message = "target query param required" }
    end
    local part = params.part
    if part == "" then part = nil end
    if part and not VALID_PARTS[part] then
        return { code = M.ERR.BAD_REQUEST, message = "invalid part: " .. tostring(part) }
    end
    return nil
end

local function read_chunk(db, entry_id, branch, chunk_type)
    local rows, err = db:query([[
        SELECT content FROM keeper_overlay_chunks
        WHERE entry_id = ? AND branch = ? AND chunk_type = ?
    ]], { entry_id, branch, chunk_type })
    if err then return "", err end
    if not rows or #rows == 0 then return "", nil end
    return rows[1].content or "", nil
end

local function read_entry_combined(db, entry_id, branch)
    local rows, err = db:query([[
        SELECT chunk_type, content FROM keeper_overlay_chunks
        WHERE entry_id = ? AND branch = ?
        ORDER BY chunk_type ASC
    ]], { entry_id, branch })
    if err then return "", err end
    if not rows or #rows == 0 then return "", nil end

    local parts = {}
    for _, row in ipairs(rows) do
        if row.chunk_type == consts.CHUNKS.DEFINITION then
            table.insert(parts, 1, row.content)
        elseif row.chunk_type == consts.CHUNKS.CONTENT then
            table.insert(parts, row.content)
        end
    end
    return table.concat(parts, "\n\n"), nil
end

local function read_entry_kind(db, entry_id, branch)
    local rows, err = db:query([[
        SELECT kind FROM keeper_overlay_entries
        WHERE id = ? AND branch = ?
    ]], { entry_id, branch })
    if err or not rows or #rows == 0 then return "", nil end
    return rows[1].kind or "", nil
end

local function render_registry(changeset, target, part)
    local db, db_err = sql.get(consts.DATABASE.RESOURCE_ID)
    if db_err then return fail(M.ERR.INTERNAL, "Failed to load diff content") end

    local baseline, current, language
    if part == consts.CHUNKS.DEFINITION then
        language = "yaml"
        baseline = read_chunk(db, target, consts.MAIN_BRANCH, part)
        current = read_chunk(db, target, changeset.state_branch, part)
    elseif part == consts.CHUNKS.CONTENT then
        local kind = read_entry_kind(db, target, changeset.state_branch)
        if kind == "" then kind = read_entry_kind(db, target, consts.MAIN_BRANCH) end
        language = language_from_kind(kind)
        baseline = read_chunk(db, target, consts.MAIN_BRANCH, part)
        current = read_chunk(db, target, changeset.state_branch, part)
    else
        language = "yaml"
        baseline = read_entry_combined(db, target, consts.MAIN_BRANCH)
        current = read_entry_combined(db, target, changeset.state_branch)
    end

    db:release()
    return { baseline = baseline or "", current = current or "", language = language }
end

local function render_filesystem(changeset, target)
    local baseline, current = "", ""
    local language = detect_fs_language(target)

    local fe_vol, fe_err = fs.get(consts.FS.FE_VOLUME)
    if not fe_err and fe_vol then
        local ok, content = pcall(function() return fe_vol:readfile(target) end)
        if ok and content then baseline = content end
    end

    local view, view_err = fs_view.open(changeset.changeset_id)
    if not view_err and view then
        local content, read_err = view:read(target)
        if not read_err and content then current = content end
    end

    return { baseline = baseline, current = current, language = language }
end

function M.render(params)
    local verr = M.validate_params(params)
    if verr then return nil, verr end

    local part = params.part
    if part == "" then part = nil end
    local category = params.category or consts.CATEGORIES.REGISTRY

    local changeset, ws_err = repo.get_changeset(params.changeset_id)
    if ws_err or not changeset then return fail(M.ERR.NOT_FOUND, "Changeset not found") end

    local content
    if category == consts.CATEGORIES.REGISTRY then
        local rendered, render_err = render_registry(changeset, params.target, part)
        if render_err then return nil, render_err end
        content = rendered
    elseif category == consts.CATEGORIES.FILESYSTEM then
        content = render_filesystem(changeset, params.target)
    else
        content = { baseline = "", current = "", language = "plaintext" }
    end

    return {
        target = params.target,
        category = category,
        part = part,
        language = content.language,
        baseline = content.baseline,
        current = content.current,
    }
end

return M
