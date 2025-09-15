local registry = require("registry")
local json = require("json")
local time = require("time")
local uuid = require("uuid")
local actor = require("actor")
local logger = require("logger")
local consts = require("consts")

local log = logger:named("gov.service.central")

local function propagate_version_change(old_version, new_version)
    process.send(consts.TOPICS.RELAY, consts.TOPICS.VERSION, {
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

local function handle_get_state(state, payload, from)
    log:debug("Handling get_state request", {
        requester = from,
        request_id = payload.id
    })

    local current_version, err = registry.current_version()
    if err then
        log:error("Failed to get current registry version", {
            error = err
        })

        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
            success = false,
            message = "Failed to get current registry version",
            error = err,
            request_id = payload.id
        })
        return
    end

    local system_state = {
        registry = {
            current_version = current_version:id(),
            timestamp = time.now():unix()
        },
        governance = {
            status = "running",
            pid = process.pid(),
            operation_in_progress = state.operation_in_progress,
            current_operation = state.current_operation,
            last_operation_type = state.last_operation_type,
            last_updated = state.last_updated
        },
        changes = {
            filesystem_changes_pending = state.filesystem_changes_pending,
            registry_changes_pending = state.registry_changes_pending
        }
    }

    process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
        success = true,
        state = system_state,
        request_id = payload.id,
        timestamp = time.now():unix()
    })

    log:debug("Sent state response", {
        requester = from,
        request_id = payload.id
    })
end

local function handle_upload(state, payload, from)
    if state.operation_in_progress then
        log:warn("Rejecting upload request - operation already in progress", {
            current_operation = state.current_operation,
            requester = from
        })

        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
            success = false,
            message = consts.ERRORS.OPERATION_IN_PROGRESS .. ": " .. state.current_operation,
            error = "Please try again later",
            request_id = payload.id
        })
        return
    end

    state.operation_in_progress = true
    state.current_operation = consts.OPERATIONS.UPLOAD
    state.operation_start_time = time.now():unix()

    log:info("Starting upload operation", {
        requester = from,
        request_id = payload.id,
        user_id = payload.user_id
    })

    local uploader_pid, err = process.spawn_monitored(
        "keeper.gov.service:upload",
        consts.PROCESS_HOST,
        {
            options = payload.options or {},
            user_id = payload.user_id,
            request_id = payload.id
        }
    )

    if err then
        log:error("Failed to spawn uploader process", {
            error = err,
            requester = from
        })

        state.operation_in_progress = false
        state.current_operation = nil

        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
            success = false,
            message = consts.ERRORS.WORKER_SPAWN_FAILED,
            error = err,
            request_id = payload.id
        })
        return
    end

    state.pending_operations[uploader_pid] = {
        from = from,
        request_id = payload.id,
        operation = consts.OPERATIONS.UPLOAD,
        start_time = state.operation_start_time,
        respond_to = payload.respond_to or consts.TOPICS.RESPONSE,
        stage = "upload",
        user_id = payload.user_id,
        options = payload.options or {}
    }

    log:debug("Started uploader process", {
        worker_pid = uploader_pid,
        host = consts.PROCESS_HOST
    })
end

local function handle_download(state, payload, from)
    if state.operation_in_progress then
        log:warn("Rejecting download request - operation already in progress", {
            current_operation = state.current_operation,
            requester = from
        })

        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
            success = false,
            message = consts.ERRORS.OPERATION_IN_PROGRESS .. ": " .. state.current_operation,
            error = "Please try again later",
            request_id = payload.id
        })
        return
    end

    state.operation_in_progress = true
    state.current_operation = consts.OPERATIONS.DOWNLOAD
    state.operation_start_time = time.now():unix()

    log:info("Starting download operation", {
        requester = from,
        request_id = payload.id,
        user_id = payload.user_id
    })

    local downloader_pid, err = process.spawn_monitored(
        "keeper.gov.service:download",
        consts.PROCESS_HOST,
        {
            options = payload.options or {},
            user_id = payload.user_id,
            request_id = payload.id
        }
    )

    if err then
        log:error("Failed to spawn downloader process", {
            error = err,
            requester = from
        })

        state.operation_in_progress = false
        state.current_operation = nil

        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
            success = false,
            message = consts.ERRORS.WORKER_SPAWN_FAILED,
            error = err,
            request_id = payload.id
        })
        return
    end

    state.pending_operations[downloader_pid] = {
        from = from,
        request_id = payload.id,
        operation = consts.OPERATIONS.DOWNLOAD,
        start_time = state.operation_start_time,
        respond_to = payload.respond_to or consts.TOPICS.RESPONSE,
        user_id = payload.user_id,
        options = payload.options or {}
    }

    log:debug("Started downloader process", {
        worker_pid = downloader_pid,
        host = consts.PROCESS_HOST
    })
end

local function handle_apply_changes(state, payload, from)
    if state.operation_in_progress then
        log:warn("Rejecting apply_changes request - operation already in progress", {
            current_operation = state.current_operation,
            requester = from
        })

        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
            success = false,
            message = consts.ERRORS.OPERATION_IN_PROGRESS .. ": " .. state.current_operation,
            error = "Please try again later",
            request_id = payload.id
        })
        return
    end

    state.operation_in_progress = true
    state.current_operation = consts.OPERATIONS.APPLY_CHANGES
    state.operation_start_time = time.now():unix()

    log:info("Starting apply_changes operation", {
        requester = from,
        request_id = payload.id,
        user_id = payload.user_id,
        changeset_count = #(payload.changeset or {})
    })

    local worker_pid, err = process.spawn_monitored(
        "keeper.gov.service:changeset",
        consts.PROCESS_HOST,
        {
            changeset = payload.changeset,
            options = payload.options or {},
            user_id = payload.user_id,
            request_id = payload.id
        }
    )

    if err then
        log:error("Failed to spawn changeset worker", {
            error = err,
            requester = from
        })

        state.operation_in_progress = false
        state.current_operation = nil

        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
            success = false,
            message = consts.ERRORS.WORKER_SPAWN_FAILED,
            error = err,
            request_id = payload.id
        })
        return
    end

    state.pending_operations[worker_pid] = {
        from = from,
        request_id = payload.id,
        operation = consts.OPERATIONS.APPLY_CHANGES,
        start_time = state.operation_start_time,
        respond_to = payload.respond_to or consts.TOPICS.RESPONSE,
        user_id = payload.user_id,
        options = payload.options or {}
    }

    log:debug("Started changeset worker", {
        worker_pid = worker_pid,
        host = consts.PROCESS_HOST
    })
end

local function handle_apply_version(state, payload, from)
    if state.operation_in_progress then
        log:warn("Rejecting apply_version request - operation already in progress", {
            current_operation = state.current_operation,
            requester = from
        })

        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
            success = false,
            message = consts.ERRORS.OPERATION_IN_PROGRESS .. ": " .. state.current_operation,
            error = "Please try again later",
            request_id = payload.id
        })
        return
    end

    state.operation_in_progress = true
    state.current_operation = consts.OPERATIONS.APPLY_VERSION
    state.operation_start_time = time.now():unix()

    log:info("Starting apply_version operation", {
        requester = from,
        request_id = payload.id,
        user_id = payload.user_id,
        version_id = payload.version_id
    })

    local worker_pid, err = process.spawn_monitored(
        "keeper.gov.service:changeset",
        consts.PROCESS_HOST,
        {
            version_id = payload.version_id,
            options = payload.options or {},
            user_id = payload.user_id,
            request_id = payload.id
        }
    )

    if err then
        log:error("Failed to spawn changeset worker", {
            error = err,
            requester = from
        })

        state.operation_in_progress = false
        state.current_operation = nil

        process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
            success = false,
            message = consts.ERRORS.WORKER_SPAWN_FAILED,
            error = err,
            request_id = payload.id
        })
        return
    end

    state.pending_operations[worker_pid] = {
        from = from,
        request_id = payload.id,
        operation = consts.OPERATIONS.APPLY_VERSION,
        start_time = state.operation_start_time,
        respond_to = payload.respond_to or consts.TOPICS.RESPONSE,
        user_id = payload.user_id,
        options = payload.options or {}
    }

    log:debug("Started changeset worker", {
        worker_pid = worker_pid,
        host = consts.PROCESS_HOST
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
            process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
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

            local op_log = log:with({
                worker_pid = worker_pid,
                operation = operation.operation,
                request_id = operation.request_id,
                user_id = operation.user_id,
                duration_ms = (time.now():unix() - operation.start_time) * 1000
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
                        consts.PROCESS_HOST,
                        {
                            changeset = result.changeset,
                            options = operation.options or {},
                            user_id = operation.user_id,
                            request_id = operation.request_id
                        }
                    )

                    if err then
                        op_log:error("Failed to spawn changeset worker", {
                            error = err
                        })

                        process.send(operation.from, operation.respond_to, {
                            success = false,
                            message = "Failed to apply changes: " .. err,
                            error = err,
                            request_id = operation.request_id
                        })

                        state.operation_in_progress = false
                        state.current_operation = nil
                        state.pending_operations[worker_pid] = nil
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

                    local response = {
                        success = true,
                        message = result.message or "No changes needed, filesystem and registry are in sync",
                        request_id = operation.request_id,
                        timestamp = time.now():unix(),
                        stats = result.stats,
                        changeset = result.changeset or {},
                        details = result.details or {}
                    }

                    process.send(operation.from, operation.respond_to, response)
                    state.operation_in_progress = false
                    state.current_operation = nil
                    state.pending_operations[worker_pid] = nil
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
                    timestamp = time.now():unix(),
                    changeset = result and result.changeset,
                    details = result and result.details
                }

                if result and result.success then
                    response.version = result.version

                    if upload_result.stats then
                        response.stats = upload_result.stats
                    end

                    state.filesystem_changes_pending = false
                    state.registry_changes_pending = true
                    state.last_operation_type = "upload"

                    if result.version and result.version ~= state.current_version then
                        local old_version = state.current_version
                        state.current_version = result.version
                        propagate_version_change(old_version, result.version)
                    end
                end

                process.send(operation.from, operation.respond_to, response)
                state.operation_in_progress = false
                state.current_operation = nil
                state.pending_operations[worker_pid] = nil
                return
            end

            -- Handle direct operations (changeset, download)
            local response = {
                success = result and result.success or false,
                message = result and result.message or "Operation failed",
                request_id = operation.request_id,
                timestamp = time.now():unix(),
                changeset = result and result.changeset,
                details = result and result.details
            }

            if operation.operation == consts.OPERATIONS.APPLY_CHANGES and result and result.success then
                response.version = result.version
                state.registry_changes_pending = true

                if result.version and result.version ~= state.current_version then
                    local old_version = state.current_version
                    state.current_version = result.version
                    propagate_version_change(old_version, result.version)
                end
            elseif operation.operation == consts.OPERATIONS.APPLY_VERSION and result and result.success then
                response.version = result.version

                if result.version and result.version ~= state.current_version then
                    local old_version = state.current_version
                    state.current_version = result.version
                    propagate_version_change(old_version, result.version)
                end
            elseif operation.operation == consts.OPERATIONS.DOWNLOAD and result and result.success then
                response.stats = result.stats
                response.version = result.version
                state.registry_changes_pending = false
                state.last_download_version = state.current_version
                state.last_operation_type = "download"
            end

            op_log:debug("Sending response", {
                success = response.success,
                respond_to = operation.respond_to
            })

            process.send(operation.from, operation.respond_to, response)
            state.operation_in_progress = false
            state.current_operation = nil
            state.pending_operations[worker_pid] = nil
        end
    end,

    __on_cancel = function(state, event)
        log:info("Received cancellation request, shutting down...")

        log:info("Registry governance shutting down", {
            last_version = state.current_version
        })

        return actor.exit({
            status = "completed",
            last_version = state.current_version
        })
    end
}

local function run()
    log:info("Starting Registry Governance Service")
    process.registry.register(consts.PROCESS_NAME, process.pid())
    return actor.new(init_state(), handlers).run()
end

return { run = run }