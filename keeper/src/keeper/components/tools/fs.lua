local fs = require("fs")
local audit = require("audit")
local cs_consts = require("cs_consts")
local fs_view = require("fs_view")
local repo = require("cs_repo")
local branch_ctx = require("branch_ctx")
local summarize = require("summarize")
local engine = require("patch_engine")

local MAX_WRITE_BYTES = 512 * 1024
local MAX_READ_BYTES = 1024 * 1024
local MAX_SEARCH_FILES = 5000
local MAX_SEARCH_HITS = 200
local FE_PREFIX = "frontend/"
local PLUGIN_FRONTEND_PATTERN = "^plugins/[^/]+/frontend/"
local ALLOWED_PREFIXES_LABEL = "frontend/, plugins/<module>/frontend/"
local FE_SKIP_DIRS = {
    ["node_modules"] = true,
    ["dist"] = true,
    ["build"] = true,
    [".cache"] = true,
    [".vite"] = true,
    [".turbo"] = true,
    [".next"] = true,
    [".nuxt"] = true,
    [".svelte-kit"] = true,
    [".git"] = true,
}

local function path_allowed(rel_path)
    if type(rel_path) ~= "string" or rel_path == "" then return false, "path required" end
    if rel_path:find("%.%.") then return false, "path must not contain .." end
    if rel_path:sub(1, 1) == "/" then return false, "path must be relative" end
    if rel_path:sub(1, #FE_PREFIX) == FE_PREFIX then return true, nil end
    if rel_path:match(PLUGIN_FRONTEND_PATTERN) then return true, nil end
    return false, "path must start with one of: " .. ALLOWED_PREFIXES_LABEL
end

local function looks_binary(sample)
    if not sample or sample == "" then return false end
    if sample:find("\0", 1, true) then return true end
    return false
end

local function open_reader(require_cs)
    local changeset_id, cs_err = branch_ctx.resolve_changeset_id()
    if not changeset_id then
        if require_cs then
            return nil, nil, "no active changeset (" ..
                tostring(cs_err or "missing changeset_id") ..
                "). Call set_branch to open a workspace first."
        end
        local project_fs, ferr = fs.get(cs_consts.FS.PROJECT_VOLUME)
        if ferr then return nil, nil, "project_fs open failed: " .. tostring(ferr) end
        local reader = {
            read = function(_, path)
                if not project_fs:exists(path) then return nil, "not found" end
                return project_fs:readfile(path), nil
            end,
            exists = function(_, path)
                if type(path) ~= "string" then return false, "path required" end
                return project_fs:exists(path), nil
            end,
        }
        return reader, nil, nil
    end
    local view, verr = fs_view.open(changeset_id)
    if verr then return nil, nil, "fs_view open failed: " .. tostring(verr) end
    return view, changeset_id, nil
end

-- ============================================================================
-- Commands
-- ============================================================================

-- Provenance banner so agents can tell whether what they're reading is
-- already-staged-in-this-changeset (overlay scratch) or untouched-from-main
-- (project filesystem passthrough). Without this, agents misread their own staged work
-- as "already on main" after a review→implement bounce and incorrectly
-- conclude the task is done.
local function provenance_banner(view, changeset_id, rel_path)
    if not view or not changeset_id then
        return "[fs source: main (no active changeset)]"
    end
    local has_scratch = false
    if type(view.has_scratch_copy) == "function" then
        has_scratch = view:has_scratch_copy(rel_path) or false
    end
    if has_scratch then
        return "[fs source: OVERLAY (changeset " .. changeset_id ..
            " has staged edits to this file — DIFFERS from main)]"
    end
    return "[fs source: main (no edits in changeset " .. changeset_id .. ")]"
end

local function cmd_view(params)
    if type(params.path) ~= "string" then return nil, "path required" end
    local ok, err = path_allowed(params.path)
    if not ok then return nil, err end

    local view, changeset_id, open_err = open_reader(false)
    if open_err then return nil, open_err end

    local content, rerr = view:read(params.path)
    if rerr then return nil, rerr end
    if not content then return nil, "not found: " .. params.path end

    if #content > MAX_READ_BYTES then
        return nil, string.format("file too large (%d bytes > %d). Use view_range to read a slice.",
            #content, MAX_READ_BYTES)
    end

    if looks_binary(content:sub(1, 1024)) then
        return nil, "binary file; refusing to return as text"
    end

    local banner = provenance_banner(view, changeset_id, params.path)
    local raw_mode = params.raw == true

    if params.view_range and type(params.view_range) == "table" and #params.view_range == 2 then
        local start_line = tonumber(params.view_range[1])
        local end_line = tonumber(params.view_range[2])
        if start_line and end_line and start_line > 0 then
            local out = {}
            if not raw_mode then table.insert(out, banner) end
            local ln = 1
            for line in (content .. "\n"):gmatch("([^\n]*)\n") do
                if ln >= start_line and (end_line == -1 or ln <= end_line) then
                    if raw_mode then
                        table.insert(out, line)
                    else
                        table.insert(out, ln .. ": " .. line)
                    end
                end
                ln = ln + 1
                if end_line ~= -1 and ln > end_line then break end
            end
            return table.concat(out, "\n"), nil
        end
    end

    if raw_mode then return content, nil end

    local out = { banner }
    local ln = 1
    for line in (content .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(out, ln .. ": " .. line)
        ln = ln + 1
    end
    return table.concat(out, "\n"), nil
end

-- Walk project_fs starting at an agent-facing root-relative path.
local function walk_project_fs(project_fs, inside, acc, budget)
    if budget.count >= MAX_SEARCH_FILES then return end
    local list_path = (inside == "" or inside == nil) and "." or inside
    local ok, collected = pcall(function()
        local entries = {}
        for entry in project_fs:readdir(list_path) do
            entries[#entries + 1] = {
                name = entry.name,
                type = entry.type,
            }
        end
        return entries
    end)
    if not ok or not collected then return end
    for _, entry in ipairs(collected) do
        if entry.name and entry.name ~= "." and entry.name ~= ".." then
            local child = inside == "" and entry.name or (inside .. "/" .. entry.name)
            if entry.type == "directory" then
                if not FE_SKIP_DIRS[entry.name] then
                    walk_project_fs(project_fs, child, acc, budget)
                end
            elseif entry.type == "file" then
                acc[child] = true
                budget.count = budget.count + 1
                if budget.count >= MAX_SEARCH_FILES then return end
            end
        end
    end
end

local function cmd_search(params)
    if type(params.query) ~= "string" or params.query == "" then
        return nil, "query is required"
    end
    local start = type(params.path) == "string" and params.path or FE_PREFIX
    if start ~= "" then
        local ok, err = path_allowed(start)
        if not ok then return nil, err end
    end

    local view, changeset_id, open_err = open_reader(false)
    if open_err then return nil, open_err end

    local project_fs, fs_err = fs.get(cs_consts.FS.PROJECT_VOLUME)
    if fs_err then return nil, "project_fs open failed: " .. tostring(fs_err) end

    local candidates = {}
    local budget = { count = 0 }
    local walk_start = start
    if walk_start:sub(-1) == "/" then walk_start = walk_start:sub(1, -2) end
    walk_project_fs(project_fs, walk_start, candidates, budget)

    if changeset_id then
        local rows = repo.list_fs_content(changeset_id)
        for _, row in ipairs(rows or {}) do
            if row.rel_path and row.rel_path:sub(1, #start) == start then
                candidates[row.rel_path] = true
            end
        end
        local dels = repo.list_fs_deletes(changeset_id)
        for _, row in ipairs(dels or {}) do
            candidates[row.rel_path] = nil
        end
    end

    local glob = params.glob
    local function matches_glob(path)
        if not glob or glob == "" then return true end
        local pat = "^" .. glob:gsub("[%-%^%$%(%)%.%[%]%+%?]", "%%%0"):gsub("%*%*", ".*"):gsub("%*", "[^/]*") .. "$"
        return path:find(pat) ~= nil
    end

    local use_regex = params.regex == true
    local literal = not use_regex
    local query = params.query
    local case_insensitive = params.case_insensitive == true
    if case_insensitive then query = query:lower() end

    local hits = {}
    local hit_count = 0
    local files_scanned = 0
    local paths = {}
    for p in pairs(candidates) do table.insert(paths, p) end
    table.sort(paths)

    local max_hits = tonumber(params.limit) or MAX_SEARCH_HITS
    if max_hits > MAX_SEARCH_HITS then max_hits = MAX_SEARCH_HITS end

    for _, p in ipairs(paths) do
        if hit_count >= max_hits then break end
        if matches_glob(p) then
            local content, _ = view:read(p)
            if content and #content <= MAX_READ_BYTES and not looks_binary(content:sub(1, 1024)) then
                files_scanned = files_scanned + 1
                local ln = 1
                for line in (content .. "\n"):gmatch("([^\n]*)\n") do
                    local hay = case_insensitive and line:lower() or line
                    local found
                    if literal then
                        found = hay:find(query, 1, true) ~= nil
                    else
                        found = hay:find(query) ~= nil
                    end
                    if found then
                        table.insert(hits, { path = p, line = ln, text = line })
                        hit_count = hit_count + 1
                        if hit_count >= max_hits then break end
                    end
                    ln = ln + 1
                end
            end
        end
    end

    local header = string.format(
        "fs search '%s' under %s (%d hits across %d files%s%s)",
        params.query, start, #hits, files_scanned,
        budget.count >= MAX_SEARCH_FILES and ", walk truncated" or "",
        hit_count >= max_hits and ", hits truncated" or "")

    local lines = { header, "" }
    for _, h in ipairs(hits) do
        table.insert(lines, string.format("%s:%d: %s", h.path, h.line, h.text))
    end
    local rendered = table.concat(lines, "\n")

    if params.full ~= true then
        local goal = params.goal
        if not goal or goal == "" then
            goal = "Relevant occurrences of '" .. params.query .. "' in " .. start
        end
        local compressed, _sum_err, was_summarized = summarize.summarize(rendered, goal, {
            tool = "fs:search",
        })
        if was_summarized then rendered = compressed end
    end

    return rendered, nil
end

local function unwrap(result, e)
    if not result then
        if type(e) == "table" then return nil, e.message or e.code or "fs failed" end
        return nil, e
    end
    return result, nil
end

local function cmd_str_replace(params)
    return unwrap(engine.apply_one({
        target  = "fs",
        path    = params.path,
        op      = "str_replace",
        old_str = params.old_str,
        new_str = params.new_str,
    }))
end

local function cmd_create(params)
    return unwrap(engine.apply_one({
        target  = "fs",
        path    = params.path,
        op      = "create",
        content = params.content,
    }))
end

local function cmd_rewrite(params)
    return unwrap(engine.apply_one({
        target  = "fs",
        path    = params.path,
        op      = "rewrite",
        content = params.content,
    }))
end

local function cmd_delete(params)
    return unwrap(engine.apply_one({
        target = "fs",
        path   = params.path,
        op     = "delete",
    }))
end

-- ============================================================================
-- Dispatch
-- ============================================================================

local function do_handler(params)
    if type(params) ~= "table" then return nil, "params required" end
    local command = params.command
    if not command or command == "" then
        return nil, "command required (view, search, str_replace, create, rewrite, delete)"
    end

    if command == "view" then return cmd_view(params) end
    if command == "search" then return cmd_search(params) end
    if command == "str_replace" then return cmd_str_replace(params) end
    if command == "create" then return cmd_create(params) end
    if command == "rewrite" then return cmd_rewrite(params) end
    if command == "delete" then return cmd_delete(params) end

    return nil, "unknown command: " .. tostring(command) ..
        " (expected view, search, str_replace, create, rewrite, delete)"
end

local function handler(params)
    params = params or {}
    local cmd = params.command or "?"
    return audit.wrap({
        tool          = "fs",
        discriminator = "fs." .. cmd,
        target        = params.path,
        params        = { command = cmd, path = params.path,
                          bytes = params.content and #params.content or nil,
                          query = params.query },
        summarise = function(result, err)
            if err then return "fs " .. cmd .. " failed: " .. tostring(err) end
            if cmd == "view" or cmd == "search" then
                return "fs " .. cmd .. " " .. (params.path or params.query or "")
            end
            if type(result) == "table" and result.bytes then
                return cmd .. " " .. (params.path or "?") .. " (" .. result.bytes .. "b)"
            end
            return "fs " .. cmd .. " " .. (params.path or "")
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }
