-- Pull request workflow for Keeper Git.
--
-- This module is intentionally explicit: it can inspect repo state, build a
-- non-mutating plan, and execute that exact plan only when confirm=true. It
-- does not hide git commit/push/PR side effects behind cluster approval.

local exec = require("exec")
local system = require("system")
local consts = require("git_consts")

local M = {}

local PROTECTED_BRANCHES = {
    main = true,
    master = true,
    trunk = true,
}

local VALID_ACTIONS = {
    status = true,
    plan = true,
    create = true,
    full = true,
}

type RemoteMap = {[string]: string}

type PullRequestStatus = {
    cwd: string,
    current_branch: string,
    protected_branch: boolean,
    dirty: boolean,
    status: string,
    remotes: RemoteMap,
    gh_available: boolean,
    gh_authenticated: boolean,
    gh_status: string,
}

type PullRequestStep = {
    label: string,
    command: string,
    mutates: boolean,
}

local function shell_escape(s: unknown): string
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function trim(s: unknown): string
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function project_root()
    local root = system.process.cwd()
    if root and root ~= "" then return root end
    return "."
end

local function run(cmd)
    local shell, serr = exec.get(consts.HOST_SHELL_ID)
    if not shell then return nil, "shell unavailable: " .. tostring(serr) end

    local proc, perr = shell:exec(cmd)
    if not proc then
        if shell.release then shell:release() end
        return nil, "exec failed: " .. tostring(perr)
    end

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
        command = cmd,
    }, nil
end

local function run_git(args, cwd)
    return run("git -C " .. shell_escape(cwd or project_root()) .. " " .. args)
end

local function validate_branch(name, field)
    field = field or "branch"
    if type(name) ~= "string" or trim(name) == "" then
        return nil, field .. " is required"
    end
    name = trim(name)
    if name:find("[%z\r\n]") then return nil, field .. " must be one line" end
    if name:find("..", 1, true) then return nil, field .. " must not contain '..'" end
    if name:sub(1, 1) == "-" then return nil, field .. " must not start with '-'" end
    if name:sub(1, 1) == "/" or name:sub(-1) == "/" then
        return nil, field .. " must not start or end with '/'"
    end
    if name:find("//", 1, true) then return nil, field .. " must not contain '//'" end
    if name:find("[ %~%^:%?%*%[%]\\]") then
        return nil, field .. " contains invalid git ref characters"
    end
    return name, nil
end

local function validate_remote(name)
    name = trim(name or "origin")
    if name == "" then return nil, "remote is required" end
    if name:find("[^%w%._%-/]") or name:sub(1, 1) == "-" then
        return nil, "remote contains invalid characters"
    end
    return name, nil
end

local function normalize_path(path)
    if type(path) ~= "string" or trim(path) == "" then return nil, "path required" end
    path = path:gsub("\\", "/")
    if path:find("[%z\r\n]") then return nil, "path must be one line" end
    if path:sub(1, 1) == "/" or path:match("^%a:/") or path:sub(1, 2) == "//" then
        return nil, "path must be repo-relative"
    end
    if path:sub(1, 1) == "-" then return nil, "path must not start with '-'" end
    if path:find("//", 1, true) then return nil, "path must be normalized" end
    for segment in path:gmatch("[^/]+") do
        if segment == "." or segment == ".." then
            return nil, "path must not contain . or .. segments"
        end
    end
    return path, nil
end

local function normalize_paths(paths)
    if paths == nil then return {}, nil end
    if type(paths) ~= "table" then return nil, "paths must be an array" end
    local out = {}
    for _, path in ipairs(paths) do
        local p, err = normalize_path(path)
        if err then return nil, err end
        out[#out + 1] = p
    end
    return out, nil
end

local function command(label: string, cmd: string, mutates: boolean?): PullRequestStep
    return { label = label, command = cmd, mutates = mutates == true }
end

local function parse_remotes(out): RemoteMap
    local remotes: RemoteMap = {}
    for line in tostring(out or ""):gmatch("[^\n]+") do
        local name, url, kind = line:match("^(%S+)%s+(%S+)%s+%((%w+)%)$")
        if name and kind == "push" then
            remotes[name] = url
        end
    end
    return remotes
end

local function current_branch(cwd)
    local res, err = run_git("branch --show-current", cwd)
    if err or not res or res.code ~= 0 then return nil, err or (res and res.stderr) or "git branch failed" end
    return trim(res.stdout), nil
end

function M.status(): (PullRequestStatus?, string?)
    local cwd = project_root()
    local inside, inside_err = run_git("rev-parse --is-inside-work-tree", cwd)
    if inside_err then return nil, inside_err end
    if not inside or inside.code ~= 0 or trim(inside.stdout) ~= "true" then
        return nil, "project root is not a git working tree"
    end

    local branch, branch_err = current_branch(cwd)
    if branch_err then return nil, branch_err end
    local status_res = run_git("status --porcelain=v1", cwd)
    local remotes_res = run_git("remote -v", cwd)
    local gh_res = run("gh auth status")

    return {
        cwd = cwd,
        current_branch = branch,
        protected_branch = PROTECTED_BRANCHES[branch] == true,
        dirty = status_res and trim(status_res.stdout) ~= "" or false,
        status = status_res and status_res.stdout or "",
        remotes = parse_remotes(remotes_res and remotes_res.stdout or ""),
        gh_available = gh_res ~= nil,
        gh_authenticated = gh_res and gh_res.code == 0 or false,
        gh_status = gh_res and ((gh_res.stdout or "") .. (gh_res.stderr or "")) or "",
    }, nil
end

local function build_plan(args: table?, status: PullRequestStatus?)
    args = args or {}
    status = status or {}

    local action = args.action or "plan"
    if not VALID_ACTIONS[action] then
        return nil, "action must be one of: status, plan, create, full"
    end

    local remote, remote_err = validate_remote(args.remote or "origin")
    if remote_err then return nil, remote_err end
    local base, base_err = validate_branch(args.base_branch or args.base or "main", "base_branch")
    if base_err then return nil, base_err end
    local head, head_err = validate_branch(args.head_branch or args.head or status.current_branch, "head_branch")
    if head_err then return nil, head_err end
    if PROTECTED_BRANCHES[head] then
        return nil, "head_branch must not be a protected branch"
    end

    local title = trim(args.title)
    if title == "" then return nil, "title is required" end
    local body = trim(args.body or "")
    local draft = args.draft == true
    local commit_message = trim(args.commit_message or "")
    local paths, paths_err = normalize_paths(args.paths)
    if paths_err then return nil, paths_err end

    local cwd = status.cwd or project_root()
    local commands = {}
    if commit_message ~= "" then
        if #paths == 0 then return nil, "paths[] required when commit_message is set" end
        local add_parts = {}
        for _, p in ipairs(paths) do add_parts[#add_parts + 1] = shell_escape(p) end
        commands[#commands + 1] = command("stage files",
            "git -C " .. shell_escape(cwd) .. " add -- " .. table.concat(add_parts, " "), true)
        commands[#commands + 1] = command("commit",
            "git -C " .. shell_escape(cwd) .. " commit -m " .. shell_escape(commit_message), true)
    end

    commands[#commands + 1] = command("push branch",
        "git -C " .. shell_escape(cwd) .. " push -u " .. shell_escape(remote) .. " " .. shell_escape(head), true)

    local pr_cmd = {
        "gh pr create",
        "--base " .. shell_escape(base),
        "--head " .. shell_escape(head),
        "--title " .. shell_escape(title),
        "--body " .. shell_escape(body),
    }
    if draft then pr_cmd[#pr_cmd + 1] = "--draft" end
    commands[#commands + 1] = command("create pull request", table.concat(pr_cmd, " "), true)

    return {
        action = action,
        cwd = cwd,
        remote = remote,
        base_branch = base,
        head_branch = head,
        title = title,
        body = body,
        draft = draft,
        commit_message = commit_message ~= "" and commit_message or nil,
        paths = paths,
        commands = commands,
        blockers = {},
    }, nil
end

function M.plan(args, status)
    local effective_status = status
    if not effective_status then
        local current_status, status_err = M.status()
        if status_err then return nil, status_err end
        effective_status = current_status
    end

    local plan, err = build_plan(args or {}, effective_status)
    if err then return nil, err end
    return plan, nil
end

local function execute_plan(plan)
    local results = {}
    for _, step in ipairs(plan.commands or {}) do
        local cmd = tostring(step.command or "")
        local res, err = run(cmd)
        results[#results + 1] = {
            label = step.label,
            command = cmd,
            exit_code = res and res.code or nil,
            stdout = res and res.stdout or "",
            stderr = res and res.stderr or tostring(err or ""),
        }
        if err or not res or res.code ~= 0 then
            return nil, {
                ok = false,
                failed_step = step.label,
                results = results,
                error = err or (res and res.stderr) or "command failed",
            }
        end
    end
    local last = results[#results]
    return {
        ok = true,
        results = results,
        pr_url = last and trim((last.stdout or "") .. "\n" .. (last.stderr or "")):match("https://%S+") or nil,
    }, nil
end

function M.handle(args)
    args = args or {}
    local action = args.action or "plan"
    if action == "status" then
        return M.status()
    end

    local status, status_err = M.status()
    if status_err then return nil, status_err end
    local plan, plan_err = M.plan(args, status)
    if plan_err then return nil, plan_err end
    plan.status = status

    if args.dry_run ~= false or action == "plan" then
        plan.dry_run = true
        return plan, nil
    end
    if args.confirm ~= true then
        return nil, "confirm=true required to execute pull request commands"
    end
    if status.protected_branch then
        return nil, "refusing to execute PR flow from protected branch " .. tostring(status.current_branch)
    end

    local result, exec_err = execute_plan(plan)
    if exec_err then return exec_err, exec_err.error end
    result.dry_run = false
    result.base_branch = plan.base_branch
    result.head_branch = plan.head_branch
    result.title = plan.title
    return result, nil
end

M._validate_branch = validate_branch
M._normalize_path = normalize_path
M._build_plan = build_plan
M._parse_remotes = parse_remotes

return M
