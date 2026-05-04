-- Rebuild handler: manual mode runs sync; ai mode goes async via async_task
-- so the HTTP gateway doesn't block on the LLM call.

local consts = require("git_consts")
local rebuild_flow = require("rebuild_flow")
local async_task = require("async_task")

local M = {}

local function rebuild_args(args)
    return {
        mode               = args.mode,
        model              = args.model,
        max_changes        = args.max_changes,
        sync_first         = args.sync_first,
        tracked_dirs       = args.tracked_dirs,
        managed_namespaces = args.managed_namespaces,
        diff_base          = args.diff_base,
        untracked_mode     = args.untracked_mode,
        change_source      = args.change_source,
        changeset_id       = args.changeset_id,
        states             = args.states,
        kind               = args.kind,
        actor_id           = args.actor_id,
        session_id         = args.session_id,
        limit              = args.limit,
        per_changeset_limit = args.per_changeset_limit,
    }
end

function M.handle(payload, deps)
    local args = payload.args or {}

    if args.mode == "manual" then
        deps.relay(consts.EVENTS.REBUILD_STARTED, { mode = "manual" })
        local snap, row, err = rebuild_flow.run(rebuild_args(args))
        if err then
            deps.relay(consts.EVENTS.REBUILD_FAILED, { error = err })
            return deps.reply(payload, nil, err)
        end
        deps.state:replace_snapshot(snap)
        deps.relay(consts.EVENTS.REBUILD_FINISHED, {
            run_id = row and row.run_id, cluster_count = row and row.cluster_count, mode = "manual",
        })
        return deps.reply(payload, deps.state:summary())
    end

    -- AI mode. If a rebuild is already in flight, return the in-flight summary
    -- without spawning a duplicate task.
    if deps.state.rebuilding_now then
        local s = deps.state:summary()
        s.in_progress = true
        return deps.reply(payload, s)
    end

    deps.state.rebuilding_now = true
    local request_id = async_task.run({
        request_id     = args.request_id,
        started_event  = consts.EVENTS.REBUILD_STARTED,
        finished_event = consts.EVENTS.REBUILD_FINISHED,
        failed_event   = consts.EVENTS.REBUILD_FAILED,
        started_data   = { mode = "ai" },
        relay          = deps.relay,
        log            = deps.log,
        work = function()
            local snap, row, err = rebuild_flow.run(rebuild_args(args))
            if err then return false, { error = err } end
            deps.state:replace_snapshot(snap)
            local s = deps.state:summary()
            return true, {
                run_id        = row and row.run_id,
                cluster_count = row and row.cluster_count,
                mode          = "ai",
                snapshot      = s,
            }
        end,
        on_success = function()
            deps.state.rebuilding_now = false
        end,
        on_failure = function()
            deps.state.rebuilding_now = false
        end,
    })

    local s = deps.state:summary()
    s.in_progress = true
    s.request_id = request_id
    deps.reply(payload, s)
end

return M
