local fs = require("fs")
local text = require("text")
local audit = require("audit")
local cs_client = require("cs_client")
local cs_consts = require("cs_consts")
local fs_view = require("fs_view")
local repo = require("cs_repo")
local branch_ctx = require("branch_ctx")
local summarize = require("summarize")

local MAX_WRITE_BYTES = 512 * 1024
local MAX_READ_BYTES = 1024 * 1024
local MAX_SEARCH_FILES = 5000
local MAX_SEARCH_HITS = 200
local FE_PREFIX = "frontend/"
local ALLOWED_PREFIXES = { FE_PREFIX }

local function fe_fs_path(rel_path)
    if rel_path:sub(1, #FE_PREFIX) == FE_PREFIX then
        return rel_path:sub(#FE_PREFIX + 1)
    end
    return rel_path
end
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
    for _, prefix in ipairs(ALLOWED_PREFIXES) do
        if rel_path:sub(1, #prefix) == prefix then return true, nil end
    end
    return false, "path must start with one of: " .. table.concat(ALLOWED_PREFIXES, ", ")
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
        local fe_fs, ferr = fs.get(cs_consts.FS.FE_VOLUME)
        if ferr then return nil, nil, "fe_fs open failed: " .. tostring(ferr) end
        local reader = {
            read = function(_, path)
                local inside = fe_fs_path(path)
                if not fe_fs:exists(inside) then return nil, "not found" end
                return fe_fs:readfile(inside), nil
            end,
            exists = function(_, path) return fe_fs:exists(fe_fs_path(path)), nil end,
        }
        return reader, nil, nil
    end
    local view, verr = fs_view.open(changeset_id)
    if verr then return nil, nil, "fs_view open failed: " .. tostring(verr) end
    return view, changeset_id, nil
end

local function perform_text_replacement(content, old_str, new_str)
    local differ, err = text.diff.new({
        diff_timeout = 5.0,
        match_threshold = 0.3,
        match_distance = 1000,
        patch_margin = 4
    })
    if err then return nil, "diff init failed: " .. err end

    local exact_start, exact_end = content:find(old_str, 1, true)
    if exact_start then
        local second = content:find(old_str, (exact_end or 0) + 1, true)
        if second then
            return nil, "Error: old_str matches more than once. Add surrounding context to make it unique."
        end
        return content:sub(1, (exact_start or 0) - 1) .. new_str .. content:sub((exact_end or 0) + 1), nil
    end

    local patches, perr = differ:patch_make(tostring(content), tostring(content:gsub(old_str:gsub(
        "[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1"), new_str, 1)))
    if perr or not patches or #patches == 0 then
        local preview = old_str:sub(1, 200)
        return nil, "Error: No match found for old_str.\n\nSearched for:\n" .. preview ..
            (#old_str > 200 and "..." or "") ..
            "\n\nUse command=view to see the current file before retrying."
    end

    local result, ok = differ:patch_apply(patches, tostring(content))
    if not ok then return nil, "Fuzzy patch application failed" end
    if result == content then return nil, "No actual changes made" end
    return result, nil
end

-- ============================================================================
-- Commands
-- ============================================================================

local function cmd_view(params)
    local ok, err = path_allowed(params.path)
    if not ok then return nil, err end

    local view, _, open_err = open_reader(false)
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

    local raw_mode = params.raw == true

    if params.view_range and type(params.view_range) == "table" and #params.view_range == 2 then
        local start_line = tonumber(params.view_range[1])
        local end_line = tonumber(params.view_range[2])
        if start_line and end_line and start_line > 0 then
            local out = {}
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

    local out = {}
    local ln = 1
    for line in (content .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(out, ln .. ": " .. line)
        ln = ln + 1
    end
    return table.concat(out, "\n"), nil
end

-- Walk fe_fs starting at `inside` (fe_fs-native, no frontend/ prefix).
-- Collected paths are stored WITH the frontend/ prefix so they match the
-- agent-facing convention used everywhere else in this tool.
local function walk_fe_fs(fe_fs, inside, acc, budget)
    if budget.count >= MAX_SEARCH_FILES then return end
    local list_path = (inside == "" or inside == nil) and "." or inside
    local ok, collected = pcall(function()
        local entries = {}
        for entry in fe_fs:readdir(list_path) do
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
                    walk_fe_fs(fe_fs, child, acc, budget)
                end
            elseif entry.type == "file" then
                acc[FE_PREFIX .. child] = true
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
    local start = params.path or FE_PREFIX
    if start ~= "" then
        local ok, err = path_allowed(start)
        if not ok then return nil, err end
    end

    local view, changeset_id, open_err = open_reader(false)
    if open_err then return nil, open_err end

    local fe_fs, fe_err = fs.get(cs_consts.FS.FE_VOLUME)
    if fe_err then return nil, "fe_fs open failed: " .. tostring(fe_err) end

    local candidates = {}
    local budget = { count = 0 }
    walk_fe_fs(fe_fs, fe_fs_path(start), candidates, budget)

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

local function write_through_changeset(path, content, changeset_id)
    local result, edit_err = cs_client.edit({
        changeset_id = changeset_id,
        kind         = cs_consts.EDIT_KINDS.FS_WRITE,
        rel_path     = path,
        content      = content,
    })
    if edit_err then return nil, "write failed: " .. tostring(edit_err) end
    return (result and result.current_hash) or "", nil
end

local function cmd_str_replace(params)
    if type(params.old_str) ~= "string" then return nil, "old_str required" end
    if type(params.new_str) ~= "string" then return nil, "new_str required" end

    local ok, perr = path_allowed(params.path)
    if not ok then return nil, perr end

    local view, changeset_id, open_err = open_reader(true)
    if open_err then return nil, open_err end

    local current, rerr = view:read(params.path)
    if rerr then return nil, rerr end
    if not current then return nil, "not found: " .. params.path end

    local updated, replace_err = perform_text_replacement(current, params.old_str, params.new_str)
    if replace_err then return nil, replace_err end

    if #updated > MAX_WRITE_BYTES then
        return nil, string.format("result exceeds %d bytes after replacement", MAX_WRITE_BYTES)
    end

    local h, werr = write_through_changeset(params.path, updated, changeset_id)
    if werr then return nil, werr end

    return {
        path = params.path, bytes = #updated, content_hash = h, changeset_id = changeset_id,
    }, nil
end

local function cmd_create(params)
    if type(params.content) ~= "string" then return nil, "content required" end
    if #params.content > MAX_WRITE_BYTES then
        return nil, "content exceeds " .. MAX_WRITE_BYTES .. " bytes"
    end

    local ok, perr = path_allowed(params.path)
    if not ok then return nil, perr end

    local view, changeset_id, open_err = open_reader(true)
    if open_err then return nil, open_err end

    local exists, _ = view:exists(params.path)
    if exists then
        return nil, "already exists: " .. params.path .. " — use str_replace or rewrite"
    end

    local h, werr = write_through_changeset(params.path, params.content, changeset_id)
    if werr then return nil, werr end

    return {
        path = params.path, bytes = #params.content, content_hash = h, changeset_id = changeset_id,
    }, nil
end

local function cmd_rewrite(params)
    if type(params.content) ~= "string" then return nil, "content required" end
    if #params.content > MAX_WRITE_BYTES then
        return nil, "content exceeds " .. MAX_WRITE_BYTES .. " bytes"
    end

    local ok, perr = path_allowed(params.path)
    if not ok then return nil, perr end

    local _, changeset_id, open_err = open_reader(true)
    if open_err then return nil, open_err end

    local h, werr = write_through_changeset(params.path, params.content, changeset_id)
    if werr then return nil, werr end

    return {
        path = params.path, bytes = #params.content, content_hash = h, changeset_id = changeset_id,
    }, nil
end

local function cmd_delete(params)
    local ok, perr = path_allowed(params.path)
    if not ok then return nil, perr end

    local view, changeset_id, open_err = open_reader(true)
    if open_err then return nil, open_err end

    local exists, _ = view:exists(params.path)
    if not exists then
        return nil, "not found: " .. params.path
    end

    local result, edit_err = cs_client.edit({
        changeset_id = changeset_id,
        kind         = cs_consts.EDIT_KINDS.FS_DELETE,
        rel_path     = params.path,
    })
    if edit_err then return nil, "delete failed: " .. tostring(edit_err) end

    return { path = params.path, changeset_id = changeset_id, result = result }, nil
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
