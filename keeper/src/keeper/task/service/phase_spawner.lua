local channel = require("channel")
local logger = require("logger")
local process = require("process")

local lifecycle = require("lifecycle")
local nodes_reader = require("nodes_reader")
local task_consts = require("task_consts")
local task_reader = require("task_reader")

local log = logger:named("keeper.task.phase_spawner")

local M = {}

function M._is_missing_task_error(err)
    if not err then return false end
    return err == task_consts.ERRORS.NOT_FOUND
        or tostring(err):find("task not found", 1, true) ~= nil
end

local function latest_transition_to(task_id, phase)
    local rows, err = nodes_reader.by_type(task_id, "phase_transition", {
        order = "desc",
        limit = 50,
    })
    if err then return nil, err end

    local suffix = "->" .. tostring(phase)
    for _, row in ipairs(rows or {}) do
        local meta = row.metadata or {}
        local discriminator = row.discriminator or ""
        if meta.to_phase == phase or discriminator:sub(-#suffix) == suffix then
            return tonumber(row.seq) or 0, nil
        end
    end
    return 0, nil
end

local function already_spawned(task_id, phase)
    local transition_seq, terr = latest_transition_to(task_id, phase)
    if terr then return false, terr end

    local started, serr = nodes_reader.latest_of_type(task_id, "phase_started", {
        discriminator = phase,
    })
    if serr then return false, serr end
    if not started or not started.seq then return false, nil end

    return tonumber(started.seq) > (transition_seq or 0), nil
end

local function handle_spawn_phase(payload)
    local task_id = payload.task_id
    local phase = payload.phase
    if not task_id or task_id == "" or not phase or phase == "" then
        return nil, "spawn_phase requires task_id and phase"
    end

    local task, terr = task_reader.get_task(task_id)
    if terr then
        if M._is_missing_task_error(terr) then
            return { skipped = true, reason = "missing_task" }, nil
        end
        return nil, terr
    end
    if not task then
        return { skipped = true, reason = "missing_task" }, nil
    end

    if task.phase ~= phase then
        log:debug("skipping stale phase spawn", {
            task_id = task_id,
            requested_phase = phase,
            current_phase = task.phase,
        })
        return { skipped = true, reason = "stale_phase" }, nil
    end
    if task.status ~= "active" then
        log:debug("skipping inactive phase spawn", {
            task_id = task_id,
            phase = phase,
            status = task.status,
        })
        return { skipped = true, reason = "inactive_task" }, nil
    end

    local spawned, serr = already_spawned(task_id, phase)
    if serr then return nil, serr end
    if spawned then
        log:debug("skipping duplicate phase spawn", { task_id = task_id, phase = phase })
        return { skipped = true, reason = "already_spawned" }, nil
    end

    local dataflow_id, spawn_err = lifecycle.spawn_phase(task_id, phase, payload.opts or {})
    if spawn_err then return nil, spawn_err end
    return { dataflow_id = dataflow_id, task_id = task_id, phase = phase }, nil
end

local function handle_pump_queue(payload)
    local started_task_id, err = lifecycle._pump_queue(payload.actor_id)
    if err then return nil, err end
    if not started_task_id then
        return { skipped = true, reason = "empty_queue" }, nil
    end
    return { task_id = started_task_id }, nil
end

local HANDLERS = {
    spawn_phase = handle_spawn_phase,
    pump_queue = handle_pump_queue,
}

local function handle_message(msg)
    local payload = msg:payload():data()
    if not payload or not payload.operation then
        log:warn("received message without operation")
        return
    end

    local handler = HANDLERS[payload.operation]
    if not handler then
        log:warn("unknown operation", { operation = tostring(payload.operation) })
        return
    end

    local ok, result, err = pcall(handler, payload)
    if not ok then
        log:error("operation panicked", { operation = payload.operation, error = tostring(result) })
        return
    end
    if err then
        log:error("operation failed", { operation = payload.operation, error = tostring(err) })
        return
    end
    if result and result.skipped then
        log:debug("operation skipped", {
            operation = payload.operation,
            reason = result.reason,
        })
    end
end

function M.run()
    log:info("Starting task phase spawner")
    process.registry.register(task_consts.PROCESS_NAMES.SERVICE)

    local inbox = process.inbox()
    local proc_events = process.events()

    while true do
        local result = channel.select({
            inbox:case_receive(),
            proc_events:case_receive(),
        })

        if not result.ok then
            break
        end

        if result.channel == inbox then
            handle_message(result.value)
        elseif result.channel == proc_events then
            local event = result.value
            if event.kind == process.event.CANCEL then
                break
            end
        end
    end

    log:info("Task phase spawner stopped")
    return { status = "completed" }
end

return M
