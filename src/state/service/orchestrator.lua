local registry = require("registry")
local json = require("json")
local time = require("time")
local logger = require("logger")
local sql = require("sql")
local consts = require("consts")

local log = logger:named("state.service.orchestrator")

local function check_database_empty(db)
    local check_query = "SELECT COUNT(*) as count FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    local result, err = db:query(check_query)
    if err then
        return nil, err
    end
    return (result[1] and result[1].count or 0) == 0
end

local function spawn_reconciliation(state)
    if state.reconcile_worker_pid then
        log:warn("Reconciliation already in progress", { pid = state.reconcile_worker_pid })
        return
    end

    log:info("Spawning reconciliation worker")
    local pid, err = process.spawn_monitored("keeper.state.service:reconcile", consts.PROCESS_HOST)
    if not pid then
        log:error("Failed to spawn reconciliation worker", { error = err })
        return
    end

    state.reconcile_worker_pid = pid
    log:info("Reconciliation worker spawned", { pid = pid })
end

local function spawn_sync_worker(state, changeset, version, is_version_operation)
    if state.sync_worker_pid then
        log:warn("Sync worker already in progress", { pid = state.sync_worker_pid })
        return false
    end

    log:info("Spawning sync worker", {
        changeset_count = #changeset,
        version = version,
        is_version_operation = is_version_operation
    })

    local pid, err = process.spawn_monitored(
        "keeper.state.service:sync",
        consts.PROCESS_HOST,
        { changeset = changeset, version = version, is_version_operation = is_version_operation }
    )

    if not pid then
        log:error("Failed to spawn sync worker", { error = err })
        return false
    end

    state.sync_worker_pid = pid
    log:info("Sync worker spawned", { pid = pid })
    return true
end

local function handle_worker_exit(state, event)
    local from_pid = event.from
    local result = event.result and event.result.value or nil

    if from_pid == state.reconcile_worker_pid then
        log:info("Reconciliation worker completed", {
            pid = from_pid,
            success = result and result.success or false
        })

        state.reconcile_worker_pid = nil

        if result and result.success then
            state.database_ready = true
            if result.changes_made then
                log:info("State reconciliation successful", {
                    stats = result.stats,
                    commands_sent = result.commands_sent
                })
            else
                log:info("State already synchronized", { stats = result.stats })
            end
        else
            local error_msg = result and result.error or "Unknown error"
            log:error("State reconciliation failed", { error = error_msg })

            if error_msg and error_msg:find("no such table") then
                log:error("Tables not materialized, exiting for restart")
                error("Tables not ready: " .. error_msg)
            end

            state.database_ready = false
        end
    elseif from_pid == state.sync_worker_pid then
        log:info("Sync worker completed", {
            pid = from_pid,
            success = result and result.success or false
        })

        state.sync_worker_pid = nil

        if result and result.success then
            log:info("Registry changes synced", {
                changes_made = result.changes_made,
                command_count = result.command_count,
                version = result.version
            })
        else
            log:error("Sync worker failed", {
                error = result and result.error or "Unknown error"
            })
            log:info("Sync failure - triggering reconciliation")
            spawn_reconciliation(state)
        end
    end
end

local function handle_get_state(state, from, request_id, respond_to)
    local current_version, err = registry.current_version()
    if err then
        log:error("Failed to get current registry version", { error = err })
        process.send(from, respond_to or consts.TOPICS.RESPONSE, {
            success = false,
            error = err,
            request_id = request_id
        })
        return
    end

    process.send(from, respond_to or consts.TOPICS.RESPONSE, {
        success = true,
        state = {
            registry = {
                current_version = current_version:id(),
                timestamp = time.now():format("RFC3339Nano")
            },
            state_system = {
                status = "running",
                pid = process.pid(),
                operation_in_progress = state.reconcile_worker_pid ~= nil or state.sync_worker_pid ~= nil,
                current_operation = state.reconcile_worker_pid and "reconciliation" or state.sync_worker_pid and "sync" or
                    nil,
                last_sync_version = state.last_sync_version,
                last_sync_time = state.last_sync_time,
                database_ready = state.database_ready,
                reconcile_worker_pid = state.reconcile_worker_pid,
                sync_worker_pid = state.sync_worker_pid,
                executor_pid = state.executor_pid
            }
        },
        request_id = request_id,
        timestamp = time.now():format("RFC3339Nano")
    })
end

local function handle_execute_commands(state, from, payload)
    log:debug("Delegating execute_commands to executor", {
        requester = from,
        request_id = payload.id,
        command_count = payload.commands and #payload.commands or 0
    })

    process.send(state.executor_pid, consts.TOPICS.COMMANDS, payload)
end

local function handle_sync_branch(state, from, payload)
    if not payload.branch or payload.branch == "" then
        local respond_to = payload.respond_to or consts.TOPICS.RESPONSE
        process.send(from, respond_to, {
            success = false,
            error = "Branch parameter required"
        })
        return
    end

    if not payload.entry_ids or type(payload.entry_ids) ~= "table" or #payload.entry_ids == 0 then
        local respond_to = payload.respond_to or consts.TOPICS.RESPONSE
        process.send(from, respond_to, {
            success = false,
            error = "entry_ids parameter required (non-empty array)"
        })
        return
    end

    log:info("Spawning sync_branch worker", {
        branch = payload.branch,
        entry_count = #payload.entry_ids
    })

    local worker_pid, err = process.spawn(
        "keeper.state.service:sync_branch",
        consts.PROCESS_HOST,
        { branch = payload.branch, entry_ids = payload.entry_ids }
    )

    if not worker_pid then
        log:error("Failed to spawn sync_branch worker", { error = err })
        local respond_to = payload.respond_to or consts.TOPICS.RESPONSE
        process.send(from, respond_to, {
            success = false,
            error = "Failed to spawn worker: " .. err
        })
        return
    end

    local respond_to = payload.respond_to or consts.TOPICS.RESPONSE
    process.send(from, respond_to, {
        success = true,
        message = "Branch sync initiated",
        worker_pid = worker_pid,
        branch = payload.branch,
        timestamp = time.now():format("RFC3339Nano")
    })
end

local function handle_registry_change(state, from, payload)
    local is_version_operation = payload.is_version_operation or false
    local version = payload.version
    local changeset = payload.changeset or {}
    local respond_to = payload.respond_to

    log:info("Registry change notification", {
        version = version,
        changeset_count = #changeset,
        is_version_operation = is_version_operation
    })

    if not state.database_ready then
        log:warn("Database not ready - triggering reconciliation")
        spawn_reconciliation(state)
        if respond_to then
            process.send(from, respond_to, {
                success = true,
                message = "Reconciliation triggered",
                version = version
            })
        end
        return
    end

    if is_version_operation then
        log:info("Version operation - triggering reconciliation", { version = version })
        spawn_reconciliation(state)
        state.last_sync_version = version
        state.last_sync_time = time.now():format("RFC3339Nano")
        if respond_to then
            process.send(from, respond_to, {
                success = true,
                message = "Reconciliation triggered for version operation",
                version = version
            })
        end
        return
    end

    if #changeset == 0 then
        log:info("No changes to sync")
        state.last_sync_version = version
        state.last_sync_time = time.now():format("RFC3339Nano")
        if respond_to then
            process.send(from, respond_to, {
                success = true,
                changes_made = false,
                version = version
            })
        end
        return
    end

    local spawned = spawn_sync_worker(state, changeset, version, is_version_operation)
    if spawned then
        state.last_sync_version = version
        state.last_sync_time = time.now():format("RFC3339Nano")
        if respond_to then
            process.send(from, respond_to, {
                success = true,
                message = "Sync worker spawned",
                changes_made = true,
                version = version
            })
        end
    else
        log:warn("Failed to spawn sync worker - triggering reconciliation")
        spawn_reconciliation(state)
        if respond_to then
            process.send(from, respond_to, {
                success = true,
                message = "Sync worker failed, reconciliation triggered",
                version = version
            })
        end
    end
end

local function run()
    log:info("Starting State System Orchestrator")

    process.registry.register(consts.PROCESS_NAMES.ORCHESTRATOR, process.pid())

    local state = {
        database_ready = false,
        reconcile_worker_pid = nil,
        sync_worker_pid = nil,
        executor_pid = nil,
        last_sync_version = nil,
        last_sync_time = nil
    }

    log:info("Spawning executor worker")
    local executor_pid, err = process.spawn_linked("keeper.state.service:executor", consts.PROCESS_HOST)
    if not executor_pid then
        log:error("Failed to spawn executor", { error = err })
        return nil, "Failed to spawn executor"
    end

    state.executor_pid = executor_pid
    log:info("Executor worker spawned and linked", { pid = executor_pid })

    local db, err = sql.get(consts.DATABASE.RESOURCE_ID)
    if err then
        log:error("Failed to connect to database", { error = err })
        return nil, "Failed to connect to database"
    end

    local is_empty, err = check_database_empty(db)
    db:release()

    if err then
        log:error("Failed to check database state", { error = err })
        return nil, "Failed to check database state"
    end

    local current_version, err = registry.current_version()
    if err then
        log:error("Failed to get current registry version", { error = err })
        return nil, "Failed to get current registry version"
    end

    state.last_sync_version = current_version:id()
    state.last_sync_time = time.now():format("RFC3339Nano")

    spawn_reconciliation(state)

    log:info("Orchestrator initialized", {
        registry_version = state.last_sync_version,
        database_ready = state.database_ready,
        executor_pid = state.executor_pid
    })

    local inbox = process.inbox()
    local events = process.events()

    while true do
        local result = channel.select({
            inbox:case_receive(),
            events:case_receive()
        })

        if result.channel == inbox then
            local msg = result.value
            local topic = msg:topic()
            local payload = msg:payload():data()
            local from = msg:from()

            if topic == consts.TOPICS.COMMANDS then
                if payload.operation == consts.OPERATIONS.GET_STATE then
                    handle_get_state(state, from, payload.id, payload.respond_to)
                elseif payload.operation == consts.OPERATIONS.EXECUTE_COMMANDS then
                    handle_execute_commands(state, from, payload)
                elseif payload.operation == consts.OPERATIONS.SYNC_BRANCH then
                    handle_sync_branch(state, from, payload)
                else
                    log:warn("Unknown operation", { operation = payload.operation, from = from })
                    process.send(from, payload.respond_to or consts.TOPICS.RESPONSE, {
                        success = false,
                        error = consts.ERRORS.UNKNOWN_OPERATION .. ": " .. tostring(payload.operation),
                        request_id = payload.id
                    })
                end
            elseif topic == consts.TOPICS.REGISTRY_CHANGE then
                handle_registry_change(state, from, payload)
            end
        elseif result.channel == events then
            local event = result.value

            if event.kind == process.event.EXIT then
                handle_worker_exit(state, event)
            elseif event.kind == process.event.CANCEL then
                log:info("Cancellation requested, shutting down")

                if state.reconcile_worker_pid then
                    process.terminate(state.reconcile_worker_pid)
                end
                if state.sync_worker_pid then
                    process.terminate(state.sync_worker_pid)
                end
                if state.executor_pid then
                    process.cancel(state.executor_pid, "1s")
                end

                return {
                    status = "completed",
                    last_sync_version = state.last_sync_version
                }
            end
        end
    end
end

return { run = run }