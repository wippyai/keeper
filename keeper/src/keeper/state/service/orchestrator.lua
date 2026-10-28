local registry = require("registry")
local time = require("time")
local logger = require("logger")
local sql = require("sql")
local consts = require("consts")

local log = logger:named("state.service.orchestrator")

type RegistryChange = {
    kind: string?,
    id: string?,
    entry: unknown?,
}

local function check_database_empty(db)
    local check_query = "SELECT COUNT(*) as count FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    local result, err = db:query(check_query)
    if err then
        return nil, err
    end
    return (result[1] and result[1].count or 0) == 0
end

local function respond_to_changes(responses, result)
    for topic, from in pairs(responses) do
        process.send(from, topic, {
            success = result.success == true,
            error = result.error,
            message = result.success and "Registry changes synchronized" or "State synchronization failed",
            changes_made = result.changes_made,
            version = result.version
        })
    end
end

local function spawn_reconciliation(state)
    if state.reconcile_worker_pid or state.sync_worker_pid then
        return
    end

    state.database_ready = false
    log:info("Spawning reconciliation worker", { version = state.pending_version })
    local pid, err = process.spawn_monitored("keeper.state.service:reconcile", consts.PROCESS_HOST)
    if not pid then
        log:error("Failed to spawn reconciliation worker", { error = err })
        respond_to_changes(state.pending_responses, { success = false, error = err })
        state.pending_responses = {}
        state.pending_version = nil
        return
    end

    state.reconcile_worker_pid = pid
    state.worker_responses = state.pending_responses
    state.pending_responses = {}
    state.pending_version = nil
    log:info("Reconciliation worker spawned", { pid = pid })
end

local function spawn_sync_worker(state, changeset: {RegistryChange}, version, is_version_operation)
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
    state.worker_responses = state.pending_responses
    state.pending_responses = {}
    state.pending_version = nil
    log:info("Sync worker spawned", { pid = pid })
    return true
end

local function handle_worker_exit(state, event)
    local is_reconciliation = event.from == state.reconcile_worker_pid
    if not is_reconciliation and event.from ~= state.sync_worker_pid then
        return
    end
    local result = event.result and event.result.value
        or { success = false, error = event.result and event.result.error or "Unknown error" }

    if is_reconciliation then
        state.reconcile_worker_pid = nil
    else
        state.sync_worker_pid = nil
    end

    respond_to_changes(state.worker_responses, result)
    state.worker_responses = {}

    if result.success then
        state.database_ready = true
        state.last_sync_version = result.version
        state.last_sync_time = time.now():format("RFC3339Nano")
        log:info("Registry state synchronized", {
            version = result.version,
            changes_made = result.changes_made
        })
        if state.pending_version ~= nil and state.pending_version ~= result.version then
            spawn_reconciliation(state)
        else
            respond_to_changes(state.pending_responses, result)
            state.pending_responses = {}
            state.pending_version = nil
        end
    else
        local error_msg = result.error or "Unknown error"
        state.database_ready = false
        log:error("State synchronization failed", { error = error_msg })
        if is_reconciliation then
            respond_to_changes(state.pending_responses, result)
            state.pending_responses = {}
            state.pending_version = nil
            if error_msg:find("no such table") then
                error("Tables not ready: " .. error_msg)
            end
        else
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
                sync_worker_pid = state.sync_worker_pid
            }
        },
        request_id = request_id,
        timestamp = time.now():format("RFC3339Nano")
    })
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
    local version = payload.version
    local changeset: table = payload.changeset or {}
    local is_version_operation = payload.is_version_operation or false

    log:info("Registry change notification", {
        version = version,
        changeset_count = #changeset,
        is_version_operation = is_version_operation
    })

    state.pending_version = version
    if payload.respond_to then
        state.pending_responses[payload.respond_to] = from
    end

    if state.reconcile_worker_pid or state.sync_worker_pid then
        return
    end

    if not state.database_ready or is_version_operation then
        spawn_reconciliation(state)
    elseif #changeset == 0 then
        state.last_sync_version = version
        state.last_sync_time = time.now():format("RFC3339Nano")
        respond_to_changes(state.pending_responses, { success = true, changes_made = false, version = version })
        state.pending_responses = {}
        state.pending_version = nil
    elseif not spawn_sync_worker(state, changeset :: {RegistryChange}, version, is_version_operation) then
        spawn_reconciliation(state)
    end
end

local function run()
    log:info("Starting State System Orchestrator")

    local pid, err = process.pid()
    if err then
        return nil, err
    end
    process.registry.register(consts.PROCESS_NAMES.ORCHESTRATOR, pid)

    local state = {
        database_ready = false,
        reconcile_worker_pid = nil,
        sync_worker_pid = nil,
        last_sync_version = nil,
        last_sync_time = nil,
        pending_version = nil,
        pending_responses = {},
        worker_responses = {}
    }

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

    state.pending_version = current_version:id()

    spawn_reconciliation(state)

    log:info("Orchestrator initialized", {
        registry_version = current_version:id(),
        database_ready = state.database_ready
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

                return {
                    status = "completed",
                    last_sync_version = state.last_sync_version
                }
            end
        end
    end
end

return { run = run }
