-- keeper.components.build:build_runner
--
-- Dormant-until-spawned process that executes a single FE component build.
-- Resolves the project root from env at runtime so nothing is hardcoded,
-- then shells out to `docker run node:20-alpine` with the component's
-- directory as the working directory. Stdout/stderr are drained on
-- concurrent coroutines into keeper_fe_build_lines.

local exec = require("exec")
local env = require("env")
local logger = require("logger"):named("keeper.components.build_runner")

local builds = require("builds")
local consts = require("consts")

-- POSIX shell single-quote escape: wrap in '...' and replace any ' with '\''
local function shell_escape(s)
    if s == nil then return "''" end
    return "'" .. tostring(s):gsub("'", [['\'']]) .. "'"
end

local function drain_stream(stream, stream_name, build_id)
    local scanner = stream:scanner("lines")
    while scanner:scan() do
        local line = scanner:text()
        if line and line ~= "" then
            builds.append_line(build_id, stream_name, line)
        end
    end
end

local function resolve_project_root()
    local root = env.get(consts.PROJECT_ROOT_ENV)
    return root or ""
end

-- Compute host workspace + container work_dir for a component path. If the
-- path is prefixed with ../ (linked bundle), we mount the project PARENT as
-- the workspace so docker can reach sibling repos. Otherwise mount the
-- project root itself.
local function resolve_mount(project_root, component_path)
    -- Normalise: turn ../foo/bar into foo/bar relative to the parent dir.
    local rel = component_path or ""
    local mount_host = project_root
    if rel:sub(1, 3) == "../" then
        rel = rel:sub(4)
        -- Strip trailing slash from project root if any, then drop last segment.
        local parent = project_root:gsub("/+$", ""):gsub("/[^/]+$", "")
        if parent == "" then parent = "/" end
        mount_host = parent
    end
    local container_workdir = consts.CONTAINER_WORKSPACE .. "/" .. rel
    return mount_host, container_workdir
end

local function resolve_host_uid_gid()
    local uid = env.get("HOST_UID")
    if not uid or uid == "" then uid = "1000" end
    local gid = env.get("HOST_GID")
    if not gid or gid == "" then gid = "1000" end
    return uid, gid
end

local function build_docker_command(project_root, component_path, inner_cmd)
    local host_workspace, container_workdir = resolve_mount(project_root, component_path)
    local uid, gid = resolve_host_uid_gid()

    local parts = {
        "docker", "run", "--rm",
        "--network", "bridge",
        "--memory", consts.CONTAINER_MEMORY,
        "--user", uid .. ":" .. gid,
        "-e", "NODE_OPTIONS=" .. shell_escape(consts.NODE_OPTIONS),
        "-e", "HOME=/tmp",
        "-e", "npm_config_cache=" .. consts.CONTAINER_WORKSPACE .. "/.wippy/fe-npm-cache",
        "-v", shell_escape(host_workspace) .. ":" .. consts.CONTAINER_WORKSPACE .. ":rw",
        "-w", shell_escape(container_workdir),
        consts.BUILD_IMAGE,
        "sh", "-c", shell_escape(inner_cmd),
    }
    return table.concat(parts, " ")
end

-- Compute container path of the desired output dir given the host workspace
-- mount. The out_dir is project-root-relative (e.g. static/keeper) — we
-- resolve it to /workspace/<rel-from-mount>/.
local function container_out_dir(project_root, host_workspace, out_dir)
    if not out_dir or out_dir == "" then return nil end
    -- Strip the workspace prefix from the project_root if they differ
    -- (linked builds use parent as host_workspace).
    if host_workspace == project_root then
        return consts.CONTAINER_WORKSPACE .. "/" .. out_dir
    end
    -- Linked build: project_root is a subdir of host_workspace.
    -- Compose: <container_workspace>/<project_dir_basename>/<out_dir>
    local proj = project_root:gsub("/+$", "")
    local mount = host_workspace:gsub("/+$", "")
    if proj:sub(1, #mount) == mount then
        local rel = proj:sub(#mount + 2)  -- skip leading /
        return consts.CONTAINER_WORKSPACE .. "/" .. rel .. "/" .. out_dir
    end
    return consts.CONTAINER_WORKSPACE .. "/" .. out_dir
end

local function run(args)
    if type(args) ~= "table" or not args.build_id then
        return nil, "build_runner requires build_id"
    end
    local build_id = args.build_id
    local component_path = args.component_path or ""
    local inner_cmd = args.command or "npm run build"
    local out_dir = args.out_dir

    builds.mark_running(build_id)

    local project_root = resolve_project_root()
    if project_root == "" then
        local msg = "unable to resolve project root from env " .. consts.PROJECT_ROOT_ENV
        builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, msg)
        builds.finish(build_id, consts.BUILD_STATUS.FAILED, nil, msg)
        logger:error(msg, { build_id = build_id })
        return nil, msg
    end

    local _host, _workdir = resolve_mount(project_root, component_path)
    builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, "project_root=" .. project_root)
    builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, "host_workspace=" .. _host)
    builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, "container_workdir=" .. _workdir)

    -- Ship vite's dist/ to the host out_dir. Container runs as the host
    -- user (via --user) so all writes land owned correctly — no chown hack.
    local cdest = container_out_dir(project_root, _host, out_dir)
    if cdest then
        builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, "ship_dest=" .. cdest)
        inner_cmd = inner_cmd ..
            " && rm -rf " .. shell_escape(cdest) ..
            " && mkdir -p " .. shell_escape(cdest) ..
            " && cp -a dist/. " .. shell_escape(cdest) .. "/"
    end

    local shell, serr = exec.get(consts.HOST_SHELL_ID)
    if not shell then
        local msg = "failed to acquire host shell: " .. (serr or "unknown")
        builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, msg)
        builds.finish(build_id, consts.BUILD_STATUS.FAILED, nil, msg)
        return nil, msg
    end

    local docker_cmd = build_docker_command(project_root, component_path, inner_cmd)
    builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, "$ " .. docker_cmd)

    local proc, perr = shell:exec(docker_cmd)
    if not proc then
        local msg = "failed to create process: " .. (perr or "unknown")
        builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, msg)
        builds.finish(build_id, consts.BUILD_STATUS.FAILED, nil, msg)
        if shell.release then shell:release() end
        return nil, msg
    end

    local stdout = proc:stdout_stream()
    local stderr = proc:stderr_stream()

    local ok, sserr = proc:start()
    if not ok then
        local msg = "failed to start process: " .. (sserr or "unknown")
        builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, msg)
        builds.finish(build_id, consts.BUILD_STATUS.FAILED, nil, msg)
        if stdout and stdout.close then stdout:close() end
        if stderr and stderr.close then stderr:close() end
        if shell.release then shell:release() end
        return nil, msg
    end

    coroutine.spawn(function()
        drain_stream(stdout, consts.BUILD_STREAM.STDOUT, build_id)
    end)
    coroutine.spawn(function()
        drain_stream(stderr, consts.BUILD_STREAM.STDERR, build_id)
    end)

    local exit_code, werr = proc:wait()
    if stdout and stdout.close then stdout:close() end
    if stderr and stderr.close then stderr:close() end

    if werr then
        builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, "wait failed: " .. werr)
        builds.finish(build_id, consts.BUILD_STATUS.FAILED, exit_code, werr)
    elseif exit_code and exit_code ~= 0 then
        builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, "process exited with code " .. tostring(exit_code))
        builds.finish(build_id, consts.BUILD_STATUS.FAILED, exit_code, "non-zero exit")
    else
        builds.append_line(build_id, consts.BUILD_STREAM.SYSTEM, "build completed")
        builds.finish(build_id, consts.BUILD_STATUS.SUCCESS, exit_code or 0, nil)
    end

    if shell.release then shell:release() end

    logger:info("build finished", { build_id = build_id, exit = exit_code })
    return true
end

return { run = run }
