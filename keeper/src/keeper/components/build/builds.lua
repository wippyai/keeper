-- keeper.components.build:builds
--
-- Canonical storage and lifecycle for FE component builds. Every rebuild,
-- regardless of who triggered it (user / agent / session), lands in the
-- same two tables so the UI and agents see one consistent history.
--
-- Public API:
--   builds.start(component_id, opts)      -> build_id, err
--   builds.get(build_id)                   -> build
--   builds.get_with_lines(build_id)        -> build + lines
--   builds.list(component_id?, limit?)     -> builds[]
--   builds.append_line(build_id, stream, text)
--   builds.finish(build_id, status, exit_code, error?)
--   builds.cancel(build_id)

local sql = require("sql")
local uuid = require("uuid")
local process = require("process")

local consts = require("consts")
local config = require("keeper_config")
local scanner = require("scanner")
local notify = require("notify")

local M = {}

local RELAY_TOPIC = "keeper.builds"

local function publish(event, data)
    notify.publish(RELAY_TOPIC, { event = event, data = data })
end

local function get_db()
    local db, err = sql.get(consts.db_id())
    if not db then return nil, "database unavailable: " .. (err or "unknown") end
    return db
end

local function now_seconds()
    return os.time()
end

local function is_postgres(db)
    local ok, t = pcall(function() return db:type() end)
    return ok and t == sql.type.POSTGRES
end

local function resolve_component(component_id)
    local desc, err = scanner.get(component_id)
    if not desc then return nil, err or "component not found" end
    if not desc.editable then
        return nil, "component is not editable (prebuilt bundle): " .. component_id
    end
    if not desc.scripts or not desc.scripts.build then
        return nil, "component has no build script: " .. component_id
    end
    return desc
end

local function prune_old(db, component_id)
    -- Retention: keep last N per component.
    local res = sql.builder.select("build_id")
        :from("keeper_fe_builds")
        :where("component_id = ?", component_id)
        :order_by("started_at DESC")
        :run_with(db)
        :query()
    if not res then return end
    local keep = consts.BUILD_RETENTION_PER_COMPONENT
    if #res <= keep then return end
    for i = keep + 1, #res do
        sql.builder.delete("keeper_fe_builds")
            :where("build_id = ?", res[i].build_id)
            :run_with(db)
            :exec()
    end
end

-- Create a new build row and spawn the runner process. Opts:
--   trigger       = "user" | "agent" | "session"   (default "user")
--   triggered_by  = actor id string (optional)
--   session_id    = session id if build is session-scoped (optional)
function M.start(component_id, opts)
    if type(component_id) ~= "string" or component_id == "" then
        return nil, "component_id required"
    end
    opts = opts or {}

    local desc, err = resolve_component(component_id)
    if not desc then return nil, err end

    local db, derr = get_db()
    if not db then return nil, derr end

    local trigger = opts.trigger or consts.BUILD_TRIGGER.USER
    if trigger ~= consts.BUILD_TRIGGER.USER
        and trigger ~= consts.BUILD_TRIGGER.AGENT
        and trigger ~= consts.BUILD_TRIGGER.SESSION then
        return nil, "invalid trigger: " .. tostring(trigger)
    end

    -- Only one running build per component at a time.
    local existing = sql.builder.select("build_id")
        :from("keeper_fe_builds")
        :where("component_id = ?", component_id)
        :where("status IN (?, ?)", consts.BUILD_STATUS.QUEUED, consts.BUILD_STATUS.RUNNING)
        :limit(1)
        :run_with(db)
        :query()
    if existing and existing[1] then
        return nil, "a build is already in progress for " .. component_id .. ": " .. existing[1].build_id
    end

    local build_id = uuid.v7()
    local script = desc.scripts.build or "build"
    -- Rewrite default vite outDir into the descriptor's out_dir so the
    -- bundle lands where the keeper http server expects it. The build
    -- still happens inside the container; we cp dist back into out_dir
    -- via a post-step so we don't touch the package.json.
    local cmd = "npm install --no-audit --no-fund --prefer-offline && npm run " .. script
    local image = "node:20-alpine"
    local toolchain = desc.toolchain or "fe_node"
    local started = now_seconds()

    local ok, ierr = sql.builder.insert("keeper_fe_builds")
        :set_map({
            build_id = build_id,
            component_id = component_id,
            component_path = desc.path,
            session_id = opts.session_id or sql.NULL,
            trigger = trigger,
            triggered_by = opts.triggered_by or "",
            status = consts.BUILD_STATUS.QUEUED,
            command = cmd,
            image = image,
            toolchain = toolchain,
            started_at = started,
        })
        :run_with(db)
        :exec()
    if not ok then
        return nil, "failed to create build row: " .. (ierr or "unknown")
    end

    prune_old(db, component_id)

    -- Initial system line so the UI has something immediately.
    M.append_line(build_id, consts.BUILD_STREAM.SYSTEM,
        "queued (trigger=" .. trigger .. " image=" .. image .. " path=" .. desc.path .. ")")

    local pid, perr = process.spawn(consts.BUILD_RUNNER_ID, config.process_host(), {
        build_id = build_id,
        component_path = desc.path,
        out_dir = desc.out_dir,
        command = cmd,
    })
    if not pid then
        M.finish(build_id, consts.BUILD_STATUS.FAILED, nil, "failed to spawn runner: " .. (perr or "unknown"))
        return nil, perr
    end

    return build_id
end

function M.get(build_id)
    if not build_id then return nil, "build_id required" end
    local db, err = get_db()
    if not db then return nil, err end
    local rows = sql.builder.select("*")
        :from("keeper_fe_builds")
        :where("build_id = ?", build_id)
        :run_with(db)
        :query()
    if not rows or not rows[1] then return nil, "not found" end
    return rows[1]
end

function M.get_with_lines(build_id, since_seq)
    local build, err = M.get(build_id)
    if not build then return nil, err end
    local db, derr = get_db()
    if not db then return nil, derr or "db unavailable" end
    local rows
    if since_seq and since_seq > 0 then
        rows = sql.builder.select("seq", "stream", "at", "text")
            :from("keeper_fe_build_lines")
            :where("build_id = ?", build_id)
            :where("seq > ?", since_seq)
            :order_by("seq")
            :run_with(db)
            :query()
    else
        rows = sql.builder.select("seq", "stream", "at", "text")
            :from("keeper_fe_build_lines")
            :where("build_id = ?", build_id)
            :order_by("seq")
            :run_with(db)
            :query()
    end
    build.lines = rows or {}
    return build
end

function M.list(component_id, limit)
    local db, err = get_db()
    if not db then return nil, err end
    limit = limit or 50
    local rows
    if component_id and component_id ~= "" then
        rows = sql.builder.select("*")
            :from("keeper_fe_builds")
            :where("component_id = ?", component_id)
            :order_by("started_at DESC")
            :limit(limit)
            :run_with(db)
            :query()
    else
        rows = sql.builder.select("*")
            :from("keeper_fe_builds")
            :order_by("started_at DESC")
            :limit(limit)
            :run_with(db)
            :query()
    end
    return rows or {}
end

function M.append_line(build_id, stream, text)
    if not build_id or not text then return nil, "missing args" end
    stream = stream or consts.BUILD_STREAM.STDOUT
    local db, err = get_db()
    if not db then return nil, err end

    -- Keep the sequence assignment inside the database statement. Builder
    -- values cannot embed SQL expressions yet, so this is the one intentional
    -- dialect branch in the build log repository.
    local stmt = [[
        INSERT INTO keeper_fe_build_lines (build_id, seq, stream, at, text)
        VALUES (
            ?,
            COALESCE((SELECT MAX(seq) + 1 FROM keeper_fe_build_lines WHERE build_id = ?), 1),
            ?, ?, ?
        )
    ]]
    local args = { build_id, build_id, stream, now_seconds(), tostring(text) }
    if is_postgres(db) then
        stmt = [[
            INSERT INTO keeper_fe_build_lines (build_id, seq, stream, at, text)
            VALUES (
                $1,
                COALESCE((SELECT MAX(seq) + 1 FROM keeper_fe_build_lines WHERE build_id = $2), 1),
                $3, $4, $5
            )
        ]]
    end
    local ok, e = db:execute(stmt, args)
    if not ok then return nil, e end
    publish("build.line", { build_id = build_id, stream = stream, text = tostring(text) })
    return true
end

function M.mark_running(build_id)
    local db = get_db()
    if not db then return end
    sql.builder.update("keeper_fe_builds")
        :set("status", consts.BUILD_STATUS.RUNNING)
        :where("build_id = ?", build_id)
        :where("status = ?", consts.BUILD_STATUS.QUEUED)
        :run_with(db)
        :exec()
    publish("build.started", { build_id = build_id })
end

function M.tail_stderr(build_id, limit)
    local db = get_db()
    if not db then return nil end
    limit = tonumber(limit) or 5
    local rows = sql.builder.select("text")
        :from("keeper_fe_build_lines")
        :where("build_id = ?", build_id)
        :where("stream = ?", consts.BUILD_STREAM.STDERR)
        :order_by("seq DESC")
        :limit(limit)
        :run_with(db)
        :query()
    if not rows or #rows == 0 then return nil end
    local lines = {}
    for i = #rows, 1, -1 do
        table.insert(lines, rows[i].text)
    end
    return table.concat(lines, "\n")
end

-- npm/vite emit errors on stdout; only fall back here when stderr is empty so
-- the column still shows the last useful diagnostic lines the agent can act on.
function M.tail_output(build_id, limit)
    local db = get_db()
    if not db then return nil end
    limit = tonumber(limit) or 5
    local rows = sql.builder.select("text")
        :from("keeper_fe_build_lines")
        :where("build_id = ?", build_id)
        :where("stream IN (?, ?)", consts.BUILD_STREAM.STDERR, consts.BUILD_STREAM.STDOUT)
        :order_by("seq DESC")
        :limit(limit)
        :run_with(db)
        :query()
    if not rows or #rows == 0 then return nil end
    local lines = {}
    for i = #rows, 1, -1 do
        table.insert(lines, rows[i].text)
    end
    return table.concat(lines, "\n")
end

function M.finish(build_id, status, exit_code, err_text)
    local db = get_db()
    if not db then return end
    local build, _ = M.get(build_id)
    if not build then return end
    if status == consts.BUILD_STATUS.FAILED and (not err_text or err_text == "non-zero exit") then
        local tail = M.tail_stderr(build_id, 5)
        if not tail or tail == "" then
            tail = M.tail_output(build_id, 10)
        end
        if tail and tail ~= "" then
            local prefix = exit_code and ("exit " .. tostring(exit_code) .. ": ") or ""
            err_text = prefix .. tail
        end
    end
    local finished = now_seconds()
    local started_at = tonumber(build.started_at) or finished
    local duration_ms = (finished - started_at) * 1000
    sql.builder.update("keeper_fe_builds")
        :set_map({
            status = status,
            exit_code = exit_code or sql.NULL,
            error = err_text or sql.NULL,
            duration_ms = duration_ms,
            finished_at = finished,
        })
        :where("build_id = ?", build_id)
        :run_with(db)
        :exec()
    publish("build.finished", { build_id = build_id, status = status, component_id = build.component_id })
end

function M.cancel(build_id)
    local db = get_db()
    if not db then return end
    local build, _ = M.get(build_id)
    if not build then return end
    if build.status ~= consts.BUILD_STATUS.RUNNING
        and build.status ~= consts.BUILD_STATUS.QUEUED then
        return nil, "build not cancellable: " .. build.status
    end
    M.append_line(build_id, consts.BUILD_STREAM.SYSTEM, "cancellation requested")
    M.finish(build_id, consts.BUILD_STATUS.CANCELLED, nil, "cancelled by user")
    return true
end

return M
