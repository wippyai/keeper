local registry = require("registry")
local time = require("time")
local channel = require("channel")
local logger = require("logger")
local consts = require("consts")
local events = require("events")
local events_consts = require("events_consts")

local log = logger:named("gov.service.central")

local PROCESS_NAME: string = tostring(consts.PROCESS_NAME)
local PROCESS_HOST: string = tostring(consts.PROCESS_HOST)
local TOPIC_RESPONSE: string = tostring(consts.TOPICS.RESPONSE)

local function response_topic(payload)
    if type(payload) == "table" and type(payload.respond_to) == "string" and payload.respond_to ~= "" then
        return payload.respond_to
    end
    return TOPIC_RESPONSE
end

local function propagate_version_change(old_version, new_version)
    events.publish(events_consts.TOPICS.VERSION, {
        old_version = old_version,
        new_version = new_version,
        timestamp = time.now():unix()
    })

    log:debug("Propagated version change", {
        old_version = old_version,
        new_version = new_version
    })
end

local function init_state()
    return {
        current_version = nil,
        last_updated = nil,
        operation_in_progress = false,
        current_operation = nil,
        operation_start_time = nil,
        registry_changes_pending = false,
        filesystem_changes_pending = false,
        pending_operations = {},
        last_operation_type = nil,
        last_download_version = nil
    }
end

local function reply_to(payload, from, body)
    process.send(from, response_topic(payload), body)
end

local function handle_get_state(state, payload, from)
    log:debug("Handling get_state request", { requester = from, request_id = payload.id })

    local current_version, err = registry.current_version()
    if err then
        log:error("Failed to get current registry version", { error = err })
        reply_to(payload, from, {
            success = false,
            message = "Failed to get current registry version",
            error = err,
            request_id = payload.id,
        })
        return
    end

    reply_to(payload, from, {
        success = true,
        state = {
            registry = {
                current_version = current_version:id(),
                timestamp = time.now():unix(),
            },
            governance = {
                status = "running",
                pid = process.pid(),
                operation_in_progress = state.operation_in_progress,
                current_operation = state.current_operation,
                last_operation_type = state.last_operation_type,
                last_updated = state.last_updated,
            },
            changes = {
                filesystem_changes_pending = state.filesystem_changes_pending,
                registry_changes_pending = state.registry_changes_pending,
            },
        },
        request_id = payload.id,
        timestamp = time.now():unix(),
    })
end

local function finalize_operation(state, worker_pid, operation, response)
    if operation.from and operation.respond_to then
        process.send(tostring(operation.from), tostring(operation.respond_to), response)
    end
    state.operation_in_progress = false
    state.current_operation = nil
    state.pending_operations[worker_pid] = nil
end

local function maybe_propagate_version(state, new_version)
    if not new_version or new_version == state.current_version then return end
    local old_version = state.current_version
    state.current_version = new_version
    propagate_version_change(old_version, new_version)
end

local function reject_if_busy(state, payload, from)
    if not state.operation_in_progress then return false end
    log:warn("Rejecting request - operation already in progress", {
        current_operation = state.current_operation,
        requested = payload.operation,
        requester = from,
    })
    reply_to(payload, from, {
        success = false,
        message = consts.ERRORS.OPERATION_IN_PROGRESS .. ": " .. state.current_operation,
        error = "Please try again later",
        request_id = payload.id,
    })
    return true
end

-- Spec describes one async governance operation. Fields:
--   operation      (consts.OPERATIONS.*)
--   worker_id      registry id of the worker process to spawn
--   worker_label   short label for log messages ("uploader", "changeset worker", ...)
--   spawn_payload  function(payload) -> table passed to process.spawn_monitored
--   extra_log      optional function(payload) -> table of extra "Starting" log fields
--   stage          optional stage tag stored on pending_operations (e.g. "upload")
local function dispatch_operation(state, payload, from, spec)
    if reject_if_busy(state, payload, from) then return end

    state.operation_in_progress  = true
    state.current_operation      = spec.operation
    state.operation_start_time   = time.now():unix()

    local start_fields = {
        requester  = from,
        request_id = payload.id,
        user_id    = payload.user_id,
    }
    if spec.extra_log then
        for k, v in pairs(spec.extra_log(payload)) do start_fields[k] = v end
    end
    log:info("Starting " .. spec.operation .. " operation", start_fields)

    local worker_pid, err = process.spawn_monitored(
        spec.worker_id,
        PROCESS_HOST,
        spec.spawn_payload(payload)
    )
    if err then
        log:error("Failed to spawn " .. spec.worker_label, { error = err, requester = from })
        state.operation_in_progress = false
        state.current_operation     = nil
        reply_to(payload, from, {
            success = false,
            message = consts.ERRORS.WORKER_SPAWN_FAILED,
            error = err,
            request_id = payload.id,
        })
        return
    end

    local pending = {
        from         = from,
        request_id   = payload.id,
        operation    = spec.operation,
        start_time   = state.operation_start_time,
        respond_to   = payload.respond_to or consts.TOPICS.RESPONSE,
        user_id      = payload.user_id,
        options      = payload.options or {},
    }
    if spec.stage then pending.stage = spec.stage end
    state.pending_operations[worker_pid] = pending

    log:debug("Started " .. spec.worker_label, {
        worker_pid = worker_pid,
        host       = consts.PROCESS_HOST,
    })
end

local function worker_payload(payload, extra)
    local out = {
        options    = payload.options or {},
        user_id    = payload.user_id,
        request_id = payload.id,
    }
    if extra then
        for k, v in pairs(extra) do out[k] = v end
    end
    return out
end

local function handle_upload(state, payload, from)
    dispatch_operation(state, payload, from, {
        operation     = consts.OPERATIONS.UPLOAD,
        worker_id     = "keeper.gov.service:upload",
        worker_label  = "uploader process",
        stage         = "upload",
        spawn_payload = function(p) return worker_payload(p) end,
    })
end

local function handle_download(state, payload, from)
    dispatch_operation(state, payload, from, {
        operation     = consts.OPERATIONS.DOWNLOAD,
        worker_id     = "keeper.gov.service:download",
        worker_label  = "downloader process",
        spawn_payload = function(p) return worker_payload(p) end,
    })
end

local function handle_apply_changes(state, payload, from)
    dispatch_operation(state, payload, from, {
        operation     = consts.OPERATIONS.APPLY_CHANGES,
        worker_id     = "keeper.gov.service:changeset",
        worker_label  = "changeset worker",
        spawn_payload = function(p) return worker_payload(p, { changeset = p.changeset }) end,
        extra_log     = function(p) return { changeset_count = #(p.changeset or {}) } end,
    })
end

local function handle_apply_version(state, payload, from)
    dispatch_operation(state, payload, from, {
        operation     = consts.OPERATIONS.APPLY_VERSION,
        worker_id     = "keeper.gov.service:changeset",
        worker_label  = "changeset worker",
        spawn_payload = function(p) return worker_payload(p, { version_id = p.version_id }) end,
        extra_log     = function(p) return { version_id = p.version_id } end,
    })
end

local handlers = {
    __init = function(state)
        log:info("Initializing Registry Governance Service")

        local current_version, err = registry.current_version()
        if err then
            log:error("Failed to get current registry version", {
                error = err
            })
            return
        end

        state.current_version = current_version:id()
        state.last_updated = time.now():unix()
        state.last_download_version = current_version:id()

        log:info("Initial registry version", {
            version = state.current_version,
            timestamp = state.last_updated,
            process_host = consts.PROCESS_HOST
        })
    end,

    [consts.TOPICS.COMMANDS] = function(state, payload, topic, from)
        local req_log = log:with({
            operation = payload.operation,
            request_id = payload.id,
            user_id = payload.user_id,
            from = from
        })

        req_log:debug("Received command")

        if payload.operation == consts.OPERATIONS.APPLY_CHANGES then
            handle_apply_changes(state, payload, from)
        elseif payload.operation == consts.OPERATIONS.APPLY_VERSION then
            handle_apply_version(state, payload, from)
        elseif payload.operation == consts.OPERATIONS.DOWNLOAD then
            handle_download(state, payload, from)
        elseif payload.operation == consts.OPERATIONS.UPLOAD then
            handle_upload(state, payload, from)
        elseif payload.operation == consts.OPERATIONS.GET_STATE then
            handle_get_state(state, payload, from)
        else
            req_log:warn("Unknown command operation")
            process.send(from, response_topic(payload), {
                success = false,
                error = consts.ERRORS.UNKNOWN_OPERATION .. ": " .. tostring(payload.operation),
                request_id = payload.id
            })
        end
    end,

    __on_event = function(state, event)
        if event.kind == process.event.EXIT then
            local worker_pid = event.from
            local operation = state.pending_operations[worker_pid]

            if not operation then
                return
            end

            local now = time.now()
            local op_log = log:with({
                worker_pid = worker_pid,
                operation = operation.operation,
                request_id = operation.request_id,
                user_id = operation.user_id,
                duration_ms = now and (now:unix() - (tonumber(operation.start_time) or 0)) * 1000 or 0
            })

            op_log:info("Worker completed")

            local result = nil
            local error_message = nil

            if event.result and event.result.value then
                result = event.result.value
            elseif event.result and event.result.error then
                error_message = event.result.error
                op_log:error("Worker failed", {
                    error = tostring(error_message)
                })
            end

            if result and result.error then
                result.message = result.error
            end

            -- Handle upload + changeset workflow
            if operation.stage == "upload" and result and result.success then
                -- Check if there are any changes to apply
                if result.changeset and #result.changeset > 0 then
                    op_log:info("Uploader process completed successfully, spawning changeset worker")

                    local changeset_worker_pid, err = process.spawn_monitored(
                        "keeper.gov.service:changeset",
                        PROCESS_HOST,
                        {
                            changeset = result.changeset,
                            options = operation.options or {},
                            user_id = operation.user_id,
                            request_id = operation.request_id
                        }
                    )

                    if err then
                        op_log:error("Failed to spawn changeset worker", { error = err })
                        finalize_operation(state, worker_pid, operation, {
                            success = false,
                            message = "Failed to apply changes: " .. err,
                            error = err,
                            request_id = operation.request_id,
                        })
                        return
                    end

                    state.pending_operations[changeset_worker_pid] = {
                        from = operation.from,
                        request_id = operation.request_id,
                        operation = operation.operation,
                        start_time = operation.start_time,
                        respond_to = operation.respond_to,
                        stage = "changeset",
                        upload_result = result,
                        user_id = operation.user_id,
                        options = operation.options
                    }

                    state.pending_operations[worker_pid] = nil
                    return
                else
                    -- No changes to apply, respond directly
                    op_log:info("Upload completed with no changes, responding directly")
                    finalize_operation(state, worker_pid, operation, {
                        success = true,
                        message = result.message or "No changes needed, filesystem and registry are in sync",
                        request_id = operation.request_id,
                        timestamp = now and now:unix() or 0,
                        stats = result.stats,
                        changeset = result.changeset or {},
                        details = result.details or {},
                    })
                    return
                end
            end

            -- Handle changeset completion (direct or from upload)
            if operation.stage == "changeset" then
                op_log:info("Changeset worker completed")

                local upload_result = operation.upload_result or {}
                local response = {
                    success = result and result.success or false,
                    message = result and result.message or "Operation failed",
                    error = result and result.error or error_message or "Unknown error",
                    request_id = operation.request_id,
                    timestamp = now and now:unix() or 0,
                    changeset = result and result.changeset,
                    details = result and result.details,
                }

                if result and result.success then
                    response.version = result.version
                    if upload_result.stats then response.stats = upload_result.stats end
                    if not response.details and upload_result.details then
                        response.details = upload_result.details
                    end

                    state.filesystem_changes_pending = false
                    state.registry_changes_pending   = true
                    state.last_operation_type        = "upload"

                    maybe_propagate_version(state, result.version)
                end

                finalize_operation(state, worker_pid, operation, response)
                return
            end

            -- Handle direct operations (changeset, download)
            local response = {
                success = result and result.success or false,
                message = result and result.message or "Operation failed",
                request_id = operation.request_id,
                timestamp = now and now:unix() or 0,
                changeset = result and result.changeset,
                details = result and result.details,
            }

            if result and result.success then
                if operation.operation == consts.OPERATIONS.APPLY_CHANGES then
                    response.version = result.version
                    state.registry_changes_pending = true
                    maybe_propagate_version(state, result.version)
                elseif operation.operation == consts.OPERATIONS.APPLY_VERSION then
                    response.version = result.version
                    maybe_propagate_version(state, result.version)
                elseif operation.operation == consts.OPERATIONS.DOWNLOAD then
                    response.stats    = result.stats
                    response.version  = result.version
                    response.file_ops = result.file_ops
                    state.registry_changes_pending = false
                    state.last_download_version    = state.current_version
                    state.last_operation_type      = "download"
                end
            end

            op_log:debug("Sending response", {
                success    = response.success,
                respond_to = operation.respond_to,
            })
            finalize_operation(state, worker_pid, operation, response)
        end
    end,

}

local function run()
    log:info("Starting Registry Governance Service")
    process.registry.register(PROCESS_NAME)

    local state = init_state()

    -- Initialize
    handlers.__init(state)

    local inbox = process.inbox()
    local events = process.events()

    while true do
        local result = channel.select({
            inbox:case_receive(),
            events:case_receive()
        })

        if not result.ok then
            break
        end

        if result.channel == inbox then
            local msg = result.value
            local topic = msg:topic()
            local payload = msg:payload():data()
            local from = msg:from()

            local handler = handlers[topic]
            if handler then
                handler(state, payload, topic, from)
            else
                log:warn("Unhandled topic", { topic = topic })
            end

        elseif result.channel == events then
            local event = result.value
            if event.kind == process.event.CANCEL then
                log:info("Received cancellation request, shutting down...")
                log:info("Registry governance shutting down", {
                    last_version = state.current_version
                })
                break
            end
            handlers.__on_event(state, event)
        end
    end

    return {
        status = "completed",
        last_version = state.current_version
    }
end

return { run = run }
