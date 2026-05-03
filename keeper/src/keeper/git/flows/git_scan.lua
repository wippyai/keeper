-- Reads the actual git working tree via `git status --porcelain` +
-- `git diff --numstat`. Filters by tracked dirs / exclude patterns.
-- Returns change rows in the same shape rebuild.lua + clusterer.lua expect.

local exec = require("exec")
local logger = require("logger")
local system = require("system")
local funcs = require("funcs")
local consts = require("git_consts")
local git_config = require("git_config")
local gov_consts = require("gov_consts")

local log = logger:named("keeper.git.scan")

local M = {}

local function shell_escape(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

-- Fire-and-collect: run command via host shell, return (stdout, stderr, exit)
local function run(cmd, opts)
    opts = opts or {}
    local shell, serr = exec.get(consts.HOST_SHELL_ID)
    if not shell then return nil, "shell unavailable: " .. tostring(serr) end

    local proc, perr = shell:exec(cmd)
    if not proc then return nil, "exec failed: " .. tostring(perr) end

    local stdout_stream = proc:stdout_stream()
    local stderr_stream = proc:stderr_stream()

    local ok, err = proc:start()
    if not ok then
        if stdout_stream and stdout_stream.close then stdout_stream:close() end
        if stderr_stream and stderr_stream.close then stderr_stream:close() end
        if shell.release then shell:release() end
        return nil, "start failed: " .. tostring(err)
    end

    local stdout_buf, stderr_buf = {}, {}
    while true do
        local chunk = stdout_stream:read()
        if chunk == nil then break end
        if chunk ~= "" then table.insert(stdout_buf, chunk) end
    end
    while true do
        local chunk = stderr_stream:read()
        if chunk == nil then break end
        if chunk ~= "" then table.insert(stderr_buf, chunk) end
    end

    local code = proc:wait() or 0
    if shell.release then shell:release() end
    return {
        stdout = table.concat(stdout_buf),
        stderr = table.concat(stderr_buf),
        code = code,
    }, nil
end

local function project_root()
    local root = system.process.cwd()
    if root and root ~= "" then return root end
    return "."
end

local function is_excluded(path: string, patterns: string[]?)
    patterns = patterns or consts.EXCLUDE_PATTERNS
    for _, pat in ipairs(patterns) do
        if path:find(pat) then return true end
    end
    return false
end

local function in_tracked(path: string, tracked_dirs: string[]?)
    if not tracked_dirs or #tracked_dirs == 0 then return true end
    for _, d in ipairs(tracked_dirs) do
        if path:sub(1, #d) == d then return true end
    end
    return false
end

local function normalize_repo_path(path: unknown): (string?, string?)
    if type(path) ~= "string" or path == "" then return nil, "path required" end
    if path:find("\0", 1, true) then return nil, "path must not contain NUL" end

    path = path:gsub("\\", "/")
    if path:sub(1, 1) == "/" or path:match("^%a:/") or path:sub(1, 2) == "//" then
        return nil, "path must be repo-relative"
    end
    if path:sub(-1) == "/" then return nil, "path must name a file" end

    local saw_segment = false
    for segment in path:gmatch("[^/]+") do
        saw_segment = true
        if segment == "." or segment == ".." then
            return nil, "path must not contain . or .. segments"
        end
    end
    if not saw_segment or path:find("//", 1, true) then
        return nil, "path must be normalized"
    end
    return path, nil
end

local function registry_tail_for_path(path)
    if path:match("^src/.*/_index%.yaml$") or path:match("^src/.*%.lua$") then
        return path:match("^src/(.+)/[^/]+$")
    end
    if path:match("^plugins/[^/]+/src/.*/_index%.yaml$") or path:match("^plugins/[^/]+/src/.*%.lua$") then
        return path:match("^plugins/[^/]+/src/(.+)/[^/]+$")
    end
    return nil
end

local function registry_namespace_for_path(path)
    local tail = registry_tail_for_path(path)
    if not tail then return nil end
    return tail:gsub("/", ".")
end

local function is_managed_namespace(namespace, cfg)
    if type(cfg) == "table" and type(cfg.managed_namespaces) == "table" then
        return gov_consts.is_namespace_in(namespace, cfg.managed_namespaces)
    end
    return gov_consts.is_namespace_managed(namespace)
end

local function validate_scan_path(
    path: unknown,
    cfg: { tracked_dirs: string[]?, exclude_patterns: string[]?, diff_base: string?, source: string?, managed_namespaces: string[]? }?
): (string?, string?)
    local normalized, err = normalize_repo_path(path)
    if err then return nil, err end

    cfg = cfg or git_config.resolve({})
    if is_excluded(normalized, cfg.exclude_patterns) then
        return nil, "path is excluded from git review"
    end
    if not in_tracked(normalized, cfg.tracked_dirs) then
        return nil, "path is outside configured tracked dirs"
    end
    local registry_ns = registry_namespace_for_path(normalized)
    if registry_ns and not is_managed_namespace(registry_ns, cfg) then
        return nil, "path is outside managed registry namespaces"
    end
    return normalized, nil
end

local function porcelain_op(xy)
    -- Two-char status code from `git status --porcelain`.
    -- Index char (X) + worktree char (Y). We collapse to a single op label.
    local x = xy:sub(1, 1)
    local y = xy:sub(2, 2)
    if y == "?" or x == "?" then return "create" end
    if y == "D" or x == "D" then return "delete" end
    if y == "A" or x == "A" then return "create" end
    if y == "M" or x == "M" then return "update" end
    if y == "R" or x == "R" then return "update" end
    if y == "C" or x == "C" then return "create" end
    return "update"
end

local function namespace_from_src_path(path)
    return registry_namespace_for_path(path)
end

local function ns_root_from(path)
    -- `src/keeper/git/flows/rebuild.lua` -> "keeper"
    -- `src/app/notes_v158/handler.lua` -> "app"
    -- `plugins/git/src/keeper/git/flows/rebuild.lua` -> "keeper"
    local tail = registry_tail_for_path(path)
    local m = tail and tail:match("^([^/]+)")
    if m then return m end
    -- `frontend/applications/keeper/src/pages/git.vue` -> "frontend"
    -- `plugins/git/frontend/applications/git/src/pages/git.vue` -> "frontend"
    if path:find("^frontend/") or path:find("^plugins/[^/]+/frontend/") then return "frontend" end
    return path:match("^([^/]+)/") or "root"
end

local function category(path)
    -- registry-relevant: anything inside src/<ns>/ that's _index.yaml or .lua
    if registry_tail_for_path(path) then
        return "registry"
    end
    return "filesystem"
end

local function classify_path(path, cfg)
    local cat = category(path)
    local namespace = nil
    local managed = nil

    if cat == "registry" then
        namespace = namespace_from_src_path(path)
        managed = namespace ~= nil and is_managed_namespace(namespace, cfg) or false
    end

    return {
        category = cat,
        namespace = namespace,
        ns_root = ns_root_from(path),
        managed_namespace = managed,
    }
end

local function should_include_change(path, cfg)
    if is_excluded(path, cfg.exclude_patterns) or not in_tracked(path, cfg.tracked_dirs) then
        return false, "excluded"
    end

    local info = classify_path(path, cfg)
    if info.category == "registry" and not info.managed_namespace then
        return false, "unmanaged_namespace"
    end
    return true, info
end

local function path_to_change_id(path)
    -- Stable per-path id within a snapshot (no length restriction)
    return "g-" .. path:gsub("[^%w]", "_")
end

-- Parse `git status --porcelain` output. Lines look like:
--   "XY <path>" with exact 2-char status, single space, then path.
--   Renames: "R  <old> -> <new>" (with -z this would be NUL-separated).
local function parse_status(stdout)
    local rows = {}
    for line in stdout:gmatch("[^\n]+") do
        if #line >= 4 then
            local xy = line:sub(1, 2)
            local rest = line:sub(4)
            -- Handle rename arrow if present
            local arrow = rest:find(" %-> ")
            local path = arrow and rest:sub(arrow + 4) or rest
            -- strip surrounding quotes if git emitted them
            if path:sub(1, 1) == '"' and path:sub(-1) == '"' then
                path = path:sub(2, -2)
            end
            table.insert(rows, { xy = xy, path = path })
        end
    end
    return rows
end

-- Parse `git diff --numstat HEAD` output. Lines: "<added>\t<removed>\t<path>"
-- Binary files have "-\t-\t<path>" (we record as 0/0).
local function parse_numstat(stdout)
    local map = {}
    for line in stdout:gmatch("[^\n]+") do
        local added, removed, path = line:match("^([%d-]+)\t([%d-]+)\t(.+)$")
        if path then
            local renamed = path:match(" => (.+)}")
            if renamed then path = path:gsub("{[^}]*}", "") end
            map[path] = {
                added = tonumber(added) or 0,
                removed = tonumber(removed) or 0,
            }
        end
    end
    return map
end

local function is_untracked_path(cwd, path)
    local cmd = "git -C " .. shell_escape(cwd) ..
        " ls-files --others --exclude-standard -- " .. shell_escape(path)
    local res, err = run(cmd)
    if err or not res or res.code ~= 0 then return false end
    for line in (res.stdout or ""):gmatch("[^\n]+") do
        if line == path then return true end
    end
    return false
end

-- Public: list_changes(opts)
--   opts.tracked_dirs (table[string])  -- override default; nil/empty => all
--   opts.diff_base    (string)         -- "HEAD" / "main" / etc.
-- Returns ({ change }[], nil) or (nil, err)
function M.list_changes(opts)
    opts = opts or {}
    local cfg = git_config.resolve(opts)
    local tracked = cfg.tracked_dirs
    local exclude = cfg.exclude_patterns
    local base = cfg.diff_base
    local cwd = project_root()

    -- 1. status (gives untracked + staged + worktree). Use `git -C <root>`
    -- so we don't need a shell to chdir.
    local status_cmd = "git -C " .. shell_escape(cwd) ..
        " status --porcelain --untracked-files=all"
    local s_res, s_err = run(status_cmd)
    if s_err then return nil, "git status: " .. s_err end
    if s_res.code ~= 0 then
        return nil, "git status exit " .. s_res.code .. ": " .. (s_res.stderr or "")
    end

    -- 2. numstat against base (gives line counts; tracked-only)
    local diff_cmd = "git -C " .. shell_escape(cwd) ..
        " diff --numstat " .. shell_escape(base)
    local d_res, d_err = run(diff_cmd)
    if d_err then return nil, "git diff: " .. d_err end
    local numstat = (d_res and d_res.code == 0) and parse_numstat(d_res.stdout) or {}

    -- 3. compose
    local status_rows = parse_status(s_res.stdout)
    local out = {}
    local skipped_unmanaged = 0
    for _, row in ipairs(status_rows) do
        local path = row.path
        local include, info = should_include_change(path, cfg)
        if include then
            local stats = numstat[path] or { added = 0, removed = 0 }
            local op = porcelain_op(row.xy)
            -- Untracked files have no diff in numstat — count their byte size
            -- as a rough "added" so detectors see them as creates.
            if stats.added == 0 and stats.removed == 0 and op == "create" then
                stats.added = 1
            end
            table.insert(out, {
                change_id = path_to_change_id(path),
                category  = info.category,
                op        = op,
                target    = path,
                ns_root   = info.ns_root,
                namespace = info.namespace,
                managed_namespace = info.managed_namespace,
                source    = "git_scan",
                status    = "pending",
                added     = stats.added,
                removed   = stats.removed,
            })
        elseif info == "unmanaged_namespace" then
            skipped_unmanaged = skipped_unmanaged + 1
        end
    end
    log:info("git scan", {
        cwd = cwd, tracked_dirs = tracked, base = base,
        config_source = cfg.source,
        total = #out, status_lines = #status_rows,
        skipped_unmanaged = skipped_unmanaged,
    })
    return out, cfg
end

function M.sync_preflight(changes)
    local blockers = {}
    for _, ch in ipairs(changes or {}) do
        if ch.category == "registry" and ch.managed_namespace ~= false then
            table.insert(blockers, {
                path = ch.target or ch.path,
                namespace = ch.namespace,
                reason = "managed registry file is already dirty",
            })
        end
    end
    if #blockers > 0 then
        return nil, blockers
    end
    return true, nil
end

-- Diff for a single file (used by the cluster detail pane).
function M.file_diff(path, opts)
    opts = opts or {}
    local cfg = git_config.resolve({
        tracked_dirs = opts.tracked_dirs,
        diff_base = opts.diff_base,
    })
    local safe_path, path_err = validate_scan_path(path, cfg)
    if path_err then return nil, path_err end

    local base = cfg.diff_base
    local cwd = project_root()

    -- Tracked-file diff first.
    local tracked_cmd = "git -C " .. shell_escape(cwd) ..
        " diff " .. shell_escape(base) .. " -- " .. shell_escape(safe_path)
    local res, err = run(tracked_cmd)
    if err then return nil, err end

    -- Only use no-index for confirmed untracked repo-relative paths. Without
    -- this guard, a caller could ask the diff endpoint to read arbitrary host
    -- files by passing an absolute path.
    if (res.stdout or "") == "" and res.code == 0 and is_untracked_path(cwd, safe_path) then
        local untracked_cmd = "git -C " .. shell_escape(cwd) ..
            " diff --no-index --no-color -- /dev/null " .. shell_escape(safe_path)
        local r2, e2 = run(untracked_cmd)
        if not e2 and r2 and r2.stdout and r2.stdout ~= "" then
            return { path = safe_path, diff = r2.stdout, exit_code = r2.code }, nil
        end
    end

    return {
        path = safe_path,
        diff = res.stdout or "",
        exit_code = res.code,
    }, nil
end

-- Sync registry overlay -> filesystem. Wraps keeper.gov.tools:sync_to_fs.
-- Returns (result, err). Best-effort: any error is surfaced but doesn't abort
-- caller flow; caller decides whether to continue.
function M.sync_registry_to_fs()
    local f = funcs.new()
    local result, err = f:call("keeper.gov.tools:sync_to_fs", {})
    if err then return nil, err end
    return result, nil
end

M._validate_scan_path = validate_scan_path
M._classify_path = classify_path
M._should_include_change = should_include_change

return M
