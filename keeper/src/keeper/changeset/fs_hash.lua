local fs = require("fs")
local hash = require("hash")
local json = require("json")

local M = {}

-- Join two path segments with a single forward slash.
local function join(a, b)
    if not a or a == "" then return b end
    if not b or b == "" then return a end
    if a:sub(-1) == "/" then a = a:sub(1, -2) end
    if b:sub(1, 1) == "/" then b = b:sub(2) end
    return a .. "/" .. b
end

-- Is this directory entry one we should skip (hidden / build output / etc.)?
local function is_skipped(name, skip_set)
    if not name or name == "" then return true end
    if name:sub(1, 1) == "." then return true end  -- hidden files & dirs
    if skip_set and skip_set[name] then return true end
    return false
end

-- Build a lookup set from an optional array of dir names to skip.
local function build_skip_set(skip_dirs)
    if not skip_dirs then return nil end
    local set = {}
    for _, name in ipairs(skip_dirs) do set[name] = true end
    return set
end

-- Default max file size for hashing. 16 MB is enough for source files,
-- images, and small binaries; anything larger indicates a build artifact
-- that shouldn't be in a workspace scratch anyway.
local DEFAULT_MAX_FILE_BYTES = 16 * 1024 * 1024
M.DEFAULT_MAX_FILE_BYTES = DEFAULT_MAX_FILE_BYTES

-- Recursive walk starting at rel_root inside vol.
-- Returns a flat list of {path, sha256, size, mode} sorted by path.
-- rel_root "" means the volume's root. Missing/empty directories yield {}.
function M.walk(vol, rel_root, opts)
    if not vol then return nil, "missing volume" end
    opts = opts or {}
    local skip_set = build_skip_set(opts.skip_dirs)
    local max_file_bytes = opts.max_file_bytes or DEFAULT_MAX_FILE_BYTES

    rel_root = rel_root or ""
    -- Normalize trailing slash off the root so join() works cleanly.
    if rel_root:sub(-1) == "/" then rel_root = rel_root:sub(1, -2) end

    local manifest = {}

    -- If the root doesn't exist, return empty manifest (fresh workspace scratch).
    if rel_root ~= "" and not vol:exists(rel_root) then
        return manifest, nil
    end

    local function walk_dir(current)
        local list_path = current == "" and "." or current
        local ok, iter_err = pcall(function()
            for entry in vol:readdir(list_path) do
                if not is_skipped(entry.name, skip_set) then
                    local child = join(current, entry.name)
                    if entry.type == "directory" then
                        walk_dir(child)
                    else
                        local content, read_err = vol:readfile(child)
                        if read_err then
                            error("readfile failed for " .. child .. ": " .. tostring(read_err))
                        end
                        if max_file_bytes and #content > max_file_bytes then
                            error("file exceeds max_file_bytes: " .. child)
                        end
                        local h, hash_err = hash.sha256(content)
                        if hash_err then
                            error("hash failed for " .. child .. ": " .. tostring(hash_err))
                        end
                        local info = vol:stat(child) or {}
                        table.insert(manifest, {
                            path   = child,
                            sha256 = h,
                            size   = info.size or #content,
                            mode   = info.mode,
                        })
                    end
                end
            end
        end)
        if not ok then error(iter_err) end
    end

    local walk_ok, walk_err = pcall(walk_dir, rel_root)
    if not walk_ok then return nil, tostring(walk_err) end

    -- Sort by path for deterministic tree hashing.
    table.sort(manifest, function(a, b) return a.path < b.path end)
    return manifest, nil
end

-- Compute a tree hash over a manifest. Format: sorted `path\0sha256\0mode\n` lines.
-- Deterministic given the same manifest content. Empty manifest -> sha256 of "".
function M.tree_hash(manifest)
    if not manifest then return nil, "missing manifest" end

    -- Expect manifest already sorted (M.walk returns sorted), but be safe.
    local lines = {}
    for _, item in ipairs(manifest) do
        table.insert(lines, string.format(
            "%s\0%s\0%s\n",
            item.path or "",
            item.sha256 or "",
            item.mode and tostring(item.mode) or ""
        ))
    end

    local joined = table.concat(lines)
    local h, err = hash.sha256(joined)
    if err then return nil, "tree_hash failed: " .. tostring(err) end
    return h, nil
end

-- Convenience: walk + tree_hash in one call. Returns {tree_hash, manifest}.
function M.snapshot(vol, rel_root, opts)
    local manifest, err = M.walk(vol, rel_root, opts)
    if err then return nil, err end
    local th, th_err = M.tree_hash(manifest)
    if th_err then return nil, th_err end
    return { tree_hash = th, manifest = manifest }, nil
end

-- Snapshot a volume by entry id (convenience wrapper for fs.get + snapshot).
function M.snapshot_volume(vol_entry_id, rel_root, opts)
    local vol, err = fs.get(vol_entry_id)
    if err then return nil, "fs.get failed for " .. tostring(vol_entry_id) .. ": " .. tostring(err) end
    return M.snapshot(vol, rel_root, opts)
end

-- Diff two manifests. Returns list of {path, op, old_hash, new_hash} where op in
-- {"create", "update", "delete"}.
function M.diff_manifests(baseline_manifest, current_manifest)
    baseline_manifest = baseline_manifest or {}
    current_manifest = current_manifest or {}

    local baseline_by_path = {}
    for _, item in ipairs(baseline_manifest) do
        baseline_by_path[item.path] = item
    end
    local current_by_path = {}
    for _, item in ipairs(current_manifest) do
        current_by_path[item.path] = item
    end

    local diffs = {}
    for path, cur in pairs(current_by_path) do
        local base = baseline_by_path[path]
        if not base then
            table.insert(diffs, { path = path, op = "create", new_hash = cur.sha256 })
        elseif base.sha256 ~= cur.sha256 then
            table.insert(diffs, {
                path     = path,
                op       = "update",
                old_hash = base.sha256,
                new_hash = cur.sha256,
            })
        end
    end
    for path, base in pairs(baseline_by_path) do
        if not current_by_path[path] then
            table.insert(diffs, { path = path, op = "delete", old_hash = base.sha256 })
        end
    end

    table.sort(diffs, function(a, b) return a.path < b.path end)
    return diffs
end

return M
