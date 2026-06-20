local logger = require("logger")
local time = require("time")
local channel = require("channel")
local consts = require("consts")
local repo = require("repo")
local open_lib = require("open")
local edit_lib = require("edit")
local drop_lib = require("drop")
local transitions_lib = require("transitions")
local diff = require("diff")
local events = require("events")
local events_consts = require("events_consts")

local log = logger:named("keeper.changeset.central")

type RequestPayload = {
    id?: string,
    respond_to?: string,
    operation?: string,
    args?: {[string]: unknown},
}

type OperationHandler = (RequestPayload, string) -> unknown

local function normalize_args(value: unknown): {[string]: unknown}?
    if type(value) ~= "table" then return nil end
    local out: {[string]: unknown} = {}
    for k, v in pairs(value) do
        if type(k) == "string" then out[k] = v end
    end
    return out
end

-- ============================================================================
-- Reply helpers
-- ============================================================================

local function send_reply(from: string?, payload: RequestPayload?, result: unknown?, err: unknown?)
    if type(from) ~= "string" or type(payload) ~= "table" or type(payload.respond_to) ~= "string" then
        return
    end
    local topic = payload.respond_to
    if err then
        process.send(from, topic, {
            success    = false,
            error      = tostring(err),
            request_id = payload.id,
        })
        return
    end
    process.send(from, topic, {
        success    = true,
        result     = result,
        request_id = payload.id,
    })
end

local function relay(event, data)
    local ok, err = events.publish(events_consts.TOPICS.CHANGESET, {
        event = event,
        data  = data,
    })
    if not ok then
        log:debug("relay dropped", { event = event, error = tostring(err) })
    end
end

-- ============================================================================
-- Operation handlers — called serially from the main loop
-- ============================================================================

local function handle_create(payload: RequestPayload, from: string)
    local args = payload.args or {}
    log:info("changeset create", {
        title    = args.title,
        kind     = args.kind,
        actor_id = args.actor_id,
    })

    local workspace, err = open_lib.run(args)
    if err then
        log:warn("changeset create failed", { error = err })
        return send_reply(from, payload, nil, err)
    end
    relay(consts.EVENTS.CREATED, { changeset_id = workspace.changeset_id, title = workspace.title, state = workspace.state })
    send_reply(from, payload, workspace, nil)
end

local function handle_open_or_resume(payload: RequestPayload, from: string)
    local args = payload.args or {}
    local branch = args.state_branch or args.branch
    if not branch or branch == "" then
        return send_reply(from, payload, nil, consts.ERRORS.MISSING_REQUIRED .. ": branch")
    end
    if branch == consts.MAIN_BRANCH then
        return send_reply(from, payload, nil, "cannot open workspace on main")
    end

    log:info("changeset open_or_resume", { branch = branch, actor_id = args.actor_id })

    local existing = repo.find_live_by_branch(branch)
    if existing then
        return send_reply(from, payload, {
            resumed      = true,
            changeset_id = existing.changeset_id,
            state_branch = existing.state_branch,
            kind         = existing.kind,
            title        = existing.title,
            state        = existing.state,
        }, nil)
    end

    local consumed, prior_state = repo.has_terminal_by_branch(branch)
    if consumed then
        return send_reply(from, payload, nil,
            "branch '" .. branch .. "' was previously consumed (state=" ..
            tostring(prior_state) .. "); choose a new branch name — do not " ..
            "reuse terminal branches, every changeset must have a fresh branch")
    end

    local workspace, err = open_lib.run({
        title        = args.title or branch,
        description  = args.description,
        kind         = args.kind or consts.KINDS.MANUAL,
        actor_id     = args.actor_id,
        session_id   = args.session_id,
        task_id      = args.task_id,
        state_branch = branch,
    })
    if err then
        log:warn("changeset open_or_resume failed", { branch = branch, error = err })
        return send_reply(from, payload, nil, err)
    end
    relay(consts.EVENTS.CREATED, {
        changeset_id = workspace.changeset_id,
        title        = workspace.title,
        state        = workspace.state,
    })
    send_reply(from, payload, {
        resumed      = false,
        changeset_id = workspace.changeset_id,
        state_branch = workspace.state_branch,
        kind         = workspace.kind,
        title        = workspace.title,
        state        = workspace.state,
    }, nil)
end

local function handle_lock(payload: RequestPayload, from: string)
    local args = payload.args or {}
    log:info("changeset lock", { changeset_id = args.changeset_id, actor_id = args.actor_id })

    local result, err = repo.lock_changeset(args.changeset_id, args.actor_id)
    if err then
        log:warn("changeset lock failed", { changeset_id = args.changeset_id, error = err })
        return send_reply(from, payload, nil, err)
    end
    relay(consts.EVENTS.LOCKED, { changeset_id = args.changeset_id, locked_by = args.actor_id })
    send_reply(from, payload, { locked = true }, nil)
end

local function handle_unlock(payload: RequestPayload, from: string)
    local args = payload.args or {}
    log:info("changeset unlock", { changeset_id = args.changeset_id, actor_id = args.actor_id })

    local result, err = repo.unlock_changeset(args.changeset_id, args.actor_id)
    if err then
        log:warn("changeset unlock failed", { changeset_id = args.changeset_id, error = err })
        return send_reply(from, payload, nil, err)
    end
    relay(consts.EVENTS.UNLOCKED, { changeset_id = args.changeset_id })
    send_reply(from, payload, { unlocked = true }, nil)
end

local function handle_edit(payload: RequestPayload, from: string)
    local args = payload.args or {}
    log:debug("changeset edit", {
        changeset_id = args.changeset_id,
        kind         = args.kind,
    })

    -- Enforce exclusive lock: if locked, only the holder can edit
    if args.changeset_id and args.actor_id then
        if not repo.is_locked_by(args.changeset_id, args.actor_id) then
            return send_reply(from, payload, nil, consts.ERRORS.LOCKED_BY_OTHER)
        end
    end

    local result, err = edit_lib.run(args)
    if err then
        log:warn("changeset edit failed", {
            changeset_id = args.changeset_id,
            kind         = args.kind,
            error        = err,
        })
        return send_reply(from, payload, nil, err)
    end

    -- open -> editing on first successful edit
    local ws, _ = repo.get_changeset(args.changeset_id)
    if ws and ws.state == consts.STATES.OPEN then
        local _, trans_err = transitions_lib.run({
            changeset_id = args.changeset_id,
            event        = "first_edit",
            reason       = "first changeset edit",
        })
        if trans_err then
            log:warn("auto-transition to editing failed", {
                changeset_id = args.changeset_id,
                error        = trans_err,
            })
        end
    end

    relay(consts.EVENTS.EDITED, { changeset_id = args.changeset_id, kind = args.kind })
    send_reply(from, payload, result, nil)
end

local function handle_drop(payload: RequestPayload, from: string)
    local args = payload.args or {}
    log:info("changeset drop", { changeset_id = args.changeset_id })

    local result, err = drop_lib.run(args)
    if err then
        log:warn("changeset drop failed", {
            changeset_id = args.changeset_id,
            error        = err,
        })
        return send_reply(from, payload, nil, err)
    end

    -- Transition state to dropped (guards reject terminal states, but drop is
    -- allowed from any live state)
    local _, trans_err = transitions_lib.run({
        changeset_id = args.changeset_id,
        event        = "drop",
        reason       = args.reason or "user-initiated drop",
    })
    if trans_err then
        log:warn("drop state transition failed", {
            changeset_id = args.changeset_id,
            error        = trans_err,
        })
        return send_reply(from, payload, nil, trans_err)
    end

    relay(consts.EVENTS.DROPPED, { changeset_id = args.changeset_id })
    send_reply(from, payload, result, nil)
end

local function handle_transition(payload: RequestPayload, from: string)
    local args = payload.args or {}
    log:info("changeset transition", {
        changeset_id = args.changeset_id,
        event        = args.event,
    })

    local result, err = transitions_lib.run(args)
    if err then
        log:warn("changeset transition failed", {
            changeset_id = args.changeset_id,
            event        = args.event,
            error        = err,
        })
        return send_reply(from, payload, nil, err)
    end
    relay(consts.EVENTS.TRANSITIONED, { changeset_id = args.changeset_id, event = args.event, to_state = result.to_state })
    send_reply(from, payload, result, nil)
end

local function handle_list_changes(payload: RequestPayload, from: string)
    local args = payload.args or {}
    if not args.changeset_id then
        return send_reply(from, payload, nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id")
    end

    local changes, err = diff.compute(args.changeset_id)
    if err then
        log:warn("list_changes failed", {
            changeset_id = args.changeset_id,
            error        = err,
        })
        return send_reply(from, payload, nil, err)
    end
    send_reply(from, payload, changes, nil)
end


local function janitor_drop_list(list, reason)
    for _, ws in ipairs(list) do
        local _, drop_err = drop_lib.run({ changeset_id = ws.changeset_id })
        if drop_err then
            log:warn("janitor: drop failed", { changeset_id = ws.changeset_id, error = drop_err })
        else
            local _, trans_err = transitions_lib.run({
                changeset_id = ws.changeset_id,
                event        = "drop",
                reason       = reason,
            })
            if trans_err then
                log:warn("janitor: transition failed", { changeset_id = ws.changeset_id, error = trans_err })
            else
                relay(consts.EVENTS.DROPPED, { changeset_id = ws.changeset_id })
            end
        end
    end
end

-- Janitor sweep. Three passes, each narrower in scope than the last:
--   1. Empty-open (EMPTY_OPEN_TTL, 2h): 'open' workspaces with zero overlay
--      entries, fs content, fs deletes, and changes journal rows. These are
--      set_branch leftovers where the agent bailed before any write.
--   2. Abandoned-open (ABANDONED_OPEN_TTL, 48h): 'open' workspaces past TTL
--      regardless of content. Covers cases where the agent landed overlay
--      entries but the first_edit transition never progressed the state.
--   3. Stale (STALE_TTL, 7d): editing/review/rejected past TTL — the classic
--      catch-all that keeps baselines bounded.
-- Errors are logged, not raised — a janitor failure must never take down the
-- supervisor.
local function janitor_sweep()
    local empty_ttl_dur, empty_parse_err = time.parse_duration(consts.JANITOR.EMPTY_OPEN_TTL)
    if empty_parse_err or not empty_ttl_dur then
        log:warn("janitor: bad EMPTY_OPEN_TTL", { value = consts.JANITOR.EMPTY_OPEN_TTL, error = tostring(empty_parse_err) })
    else
        local empties, empty_err = repo.list_empty_open_changesets(empty_ttl_dur:seconds(), consts.JANITOR.BATCH_LIMIT)
        if empty_err then
            log:warn("janitor: list_empty_open_changesets failed", { error = empty_err })
        elseif empties and #empties > 0 then
            log:info("janitor: dropping empty-open changesets", { count = #empties, ttl = consts.JANITOR.EMPTY_OPEN_TTL })
            janitor_drop_list(empties, consts.JANITOR.EMPTY_OPEN_REASON)
        end
    end

    local abandoned_ttl_dur, abandoned_parse_err = time.parse_duration(consts.JANITOR.ABANDONED_OPEN_TTL)
    if abandoned_parse_err or not abandoned_ttl_dur then
        log:warn("janitor: bad ABANDONED_OPEN_TTL", { value = consts.JANITOR.ABANDONED_OPEN_TTL, error = tostring(abandoned_parse_err) })
    else
        local abandoned, abandoned_err = repo.list_abandoned_open_changesets(abandoned_ttl_dur:seconds(), consts.JANITOR.BATCH_LIMIT)
        if abandoned_err then
            log:warn("janitor: list_abandoned_open_changesets failed", { error = abandoned_err })
        elseif abandoned and #abandoned > 0 then
            log:info("janitor: dropping abandoned-open changesets", { count = #abandoned, ttl = consts.JANITOR.ABANDONED_OPEN_TTL })
            janitor_drop_list(abandoned, consts.JANITOR.ABANDONED_OPEN_REASON)
        end
    end

    local ttl_dur, parse_err = time.parse_duration(consts.JANITOR.STALE_TTL)
    if parse_err or not ttl_dur then
        log:warn("janitor: bad STALE_TTL", { value = consts.JANITOR.STALE_TTL, error = tostring(parse_err) })
        return
    end
    local stale, list_err = repo.list_stale_changesets(ttl_dur:seconds(), consts.JANITOR.BATCH_LIMIT)
    if list_err then
        log:warn("janitor: list_stale_changesets failed", { error = list_err })
        return
    end
    if not stale or #stale == 0 then return end
    log:info("janitor: dropping stale changesets", { count = #stale, ttl = consts.JANITOR.STALE_TTL })
    janitor_drop_list(stale, consts.JANITOR.STALE_REASON)
end

-- Central dispatcher. Handler table lookup is cheaper than a chain of ifs and
-- makes it obvious which operations are supported.
local operation_handlers: {[string]: OperationHandler} = {}
operation_handlers[tostring(consts.OPERATIONS.CREATE)] = handle_create
operation_handlers[tostring(consts.OPERATIONS.OPEN_OR_RESUME)] = handle_open_or_resume
operation_handlers[tostring(consts.OPERATIONS.EDIT)] = handle_edit
operation_handlers[tostring(consts.OPERATIONS.DROP)] = handle_drop
operation_handlers[tostring(consts.OPERATIONS.TRANSITION)] = handle_transition
operation_handlers[tostring(consts.OPERATIONS.LIST_CHANGES)] = handle_list_changes
operation_handlers[tostring(consts.OPERATIONS.LOCK)] = handle_lock
operation_handlers[tostring(consts.OPERATIONS.UNLOCK)] = handle_unlock

local function handle_message(msg)
    local raw_payload = msg:payload():data()
    local from = tostring(msg:from())

    if type(raw_payload) ~= "table" then
        log:warn("received message without operation", { from = from })
        return
    end
    local operation = raw_payload.operation
    if type(operation) ~= "string" or operation == "" then
        log:warn("received message without operation", { from = from })
        return
    end
    local payload: RequestPayload = { operation = operation }
    if type(raw_payload.id) == "string" then payload.id = raw_payload.id end
    if type(raw_payload.respond_to) == "string" then payload.respond_to = raw_payload.respond_to end
    local args = normalize_args(raw_payload.args)
    if args then payload.args = args end

    local handler = operation_handlers[operation]
    if not handler then
        log:warn("unknown operation", { operation = operation, from = from })
        return send_reply(from, payload, nil,
            "unknown operation: " .. operation)
    end

    -- Catch any library-level panics so the supervisor stays alive. A crash
    -- here would stop workspace operations for all callers.
    local ok, err = pcall(handler, payload, from)
    if not ok then
        log:error("handler panicked", {
            operation = operation,
            error     = tostring(err),
        })
        send_reply(from, payload, nil, "internal error: " .. tostring(err))
    end
end

-- ============================================================================
-- Main loop
-- ============================================================================

local function run()
    log:info("Starting workspace central supervisor")

    local ok, reg_err = pcall(function()
        process.registry.register(consts.PROCESS_NAMES.CENTRAL)
    end)
    if not ok then
        log:error("failed to register process name", { error = tostring(reg_err) })
        return { status = "failed", error = tostring(reg_err) }
    end

    local inbox = process.inbox()
    local proc_events = process.events()
    local janitor_ticker = time.ticker(consts.JANITOR.SWEEP_INTERVAL)

    while true do
        local result = channel.select({
            inbox:case_receive(),
            proc_events:case_receive(),
            janitor_ticker:channel():case_receive(),
        })

        if not result.ok then
            log:warn("main loop channel closed, shutting down")
            break
        end

        if result.channel == inbox then
            handle_message(result.value)
        elseif result.channel == proc_events then
            local event = result.value
            if event and event.kind == process.event.CANCEL then
                log:info("received cancel signal")
                break
            end
            -- Phase 1 has no child workers, so non-cancel process events do
            -- not require handling here. Later worker phases can extend this.
        elseif result.channel == janitor_ticker:channel() then
            local ok, err = pcall(janitor_sweep)
            if not ok then
                log:error("janitor sweep panicked", { error = tostring(err) })
            end
        end
    end

    janitor_ticker:stop()
    log:info("Changeset central supervisor stopped")
    return { status = "completed" }
end

return { run = run }
