-- Project-level git scan config.
--
-- Reads `<project_root>/.keeper/git.json` (or `keeper.git.json` at root)
-- if present, otherwise derives the safe default from governance-managed
-- namespaces (GOV_MANAGED_NAMESPACES -> src/<namespace>/).
-- File shape:
--   {
--     "tracked_dirs":     ["src/", "frontend/applications/", "lua/"],
--     "exclude_patterns": ["custom/.*%.bak$"],
--     "diff_base":        "main",
--     "untracked_mode":   "all"
--   }
--
-- Per-call opts (passed by API/tool) override file values, file values
-- override consts defaults.

local json = require("json")
local logger = require("logger")
local system = require("system")
local exec = require("exec")
local consts = require("git_consts")
local gov_consts = require("gov_consts")

local log = logger:named("keeper.git.config")

local M = {}

local CANDIDATE_PATHS = {
    ".keeper/git.json",
    "keeper.git.json",
}

local function project_root()
    local root = system.process.cwd()
    if root and root ~= "" then return root end
    return "."
end

local function shell_escape(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

-- Read file via host `cat` (host_shell is exec.native, no shell builtins).
local function read_file(path)
    local shell, serr = exec.get(consts.HOST_SHELL_ID)
    if not shell then return nil end
    local proc, perr = shell:exec("cat " .. shell_escape(path))
    if not proc then
        if shell.release then shell:release() end
        return nil
    end
    local stdout = proc:stdout_stream()
    local ok = proc:start()
    if not ok then
        if stdout and stdout.close then stdout:close() end
        if shell.release then shell:release() end
        return nil
    end
    local buf = {}
    while true do
        local chunk = stdout:read()
        if chunk == nil then break end
        if chunk ~= "" then table.insert(buf, chunk) end
    end
    local code = proc:wait() or 0
    if shell.release then shell:release() end
    if code ~= 0 then return nil end
    local data = table.concat(buf)
    if data == "" then return nil end
    return data
end

local function load_file_config()
    local root = project_root()
    for _, rel in ipairs(CANDIDATE_PATHS) do
        local full = root .. "/" .. rel
        local data = read_file(full)
        if data then
            local decoded, derr = json.decode(data)
            if derr then
                log:warn("invalid project git config", { path = full, error = derr })
                return nil
            end
            log:info("loaded project git config", { path = full })
            return decoded
        end
    end
    return nil
end

local function tracked_dirs_from_managed_namespaces(namespaces)
    local out = {}
    for _, namespace in ipairs(namespaces or {}) do
        local path = tostring(namespace):gsub("%.", "/")
        if path ~= "" then
            table.insert(out, "src/" .. path .. "/")
        end
    end
    return out
end

local function normalize_namespaces(namespaces): string[]
    local out = {}
    for _, namespace in ipairs(namespaces or {}) do
        if type(namespace) == "string" and namespace ~= "" then
            table.insert(out, namespace)
        end
    end
    return out
end

-- Public: resolve(opts) -> { tracked_dirs, exclude_patterns, diff_base }
-- Layers (lowest-to-highest priority):
--   1. managed namespace defaults (GOV_MANAGED_NAMESPACES -> src/<ns>/)
--   2. project file (.keeper/git.json)
--   3. opts (API/tool args)
function M.resolve(opts)
    opts = opts or {}
    local file_cfg = load_file_config() or {}

    local managed_namespaces = normalize_namespaces(
        opts.managed_namespaces
            or file_cfg.managed_namespaces
            or gov_consts.get_managed_namespaces()
    )

    local tracked = opts.tracked_dirs
        or file_cfg.tracked_dirs
        or tracked_dirs_from_managed_namespaces(managed_namespaces)

    local exclude = opts.exclude_patterns
        or file_cfg.exclude_patterns
        or consts.EXCLUDE_PATTERNS

    local base = opts.diff_base
        or file_cfg.diff_base
        or consts.DEFAULT_DIFF_BASE

    local untracked_mode = opts.untracked_mode
        or file_cfg.untracked_mode
        or consts.DEFAULT_UNTRACKED_MODE

    return {
        tracked_dirs       = tracked,
        managed_namespaces = managed_namespaces,
        exclude_patterns   = exclude,
        diff_base          = base,
        untracked_mode     = untracked_mode,
        source             = file_cfg.tracked_dirs and "project_file" or "managed_namespaces",
    }
end

function M._tracked_dirs_from_managed_namespaces(namespaces)
    return tracked_dirs_from_managed_namespaces(namespaces)
end

return M
