-- keeper.task.persist:abandon
--
-- Side-effects of flipping a task to status='abandoned'. Marking the row
-- alone is not enough: the running dataflow keeps executing (auto-forking
-- new changesets, flushing FS content to disk, hitting integrate). This
-- module performs the cleanup so abandoning a task actually halts work:
--
--   1. Cancel every dataflow the task spawned (via keeper_task_nodes).
--   2. Drop the active session changeset (and any reusable editing one).
--   3. Release the task lock so future flows do not collide.
--
-- All steps are idempotent: re-calling on an already-abandoned task is a
-- no-op. Errors on individual steps are collected and returned for
-- reporting but do not short-circuit the rest of the cleanup.

local sql = require("sql")
local changeset_client = require("changeset_client")
local changeset_repo = require("changeset_repo")
local dataflow_client = require("dataflow_client")
local task_consts = require("task_consts")

local M = {}

-- Pull every dataflow_id that this task's nodes ever referenced. We do not
-- filter by status here — the cancel call below is a no-op on already
-- terminal dataflows, so it is cheaper to send them all than to query
-- live status separately.
local function task_dataflow_ids(task_id)
    local db, err = sql.get(task_consts.DATABASE.RESOURCE_ID)
    if err or not db then return {} end
    local rows, qerr = db:query([[
        SELECT DISTINCT dataflow_id
        FROM keeper_task_nodes
        WHERE task_id = ? AND dataflow_id IS NOT NULL AND dataflow_id != ''
    ]], { task_id })
    db:release()
    if qerr or not rows then return {} end
    local out = {}
    for _, r in ipairs(rows) do
        if r.dataflow_id then table.insert(out, r.dataflow_id) end
    end
    return out
end

local function cancel_dataflow(dataflow_id, _reason)
    local client, cerr = dataflow_client.new()
    if cerr or not client then return false, "client.new: " .. tostring(cerr) end
    local ok, perr = pcall(function() return client:cancel(dataflow_id, "30s") end)
    if not ok then return false, tostring(perr) end
    return true, nil
end

local function drop_changeset(changeset_id, reason)
    -- changeset_client.drop is the canonical drop path — it routes through
    -- the central supervisor + state machine, fires the DROP transition,
    -- writes state='dropped' on the keeper_changesets row, AND tears down
    -- overlay + scratch FS. The lower-level repo.drop_changeset only
    -- cleans the overlay tables but leaves the row state intact, which is
    -- why earlier attempts left zombie open changesets after abandon.
    local _, derr = changeset_client.drop({
        changeset_id = changeset_id,
        reason       = reason or "task abandoned",
    })
    if derr then return false, tostring(derr) end
    return true, nil
end

-- Public: stop all background work attached to a task. Safe to call from
-- the HTTP handler that flips status to abandoned, from the lifecycle
-- close_task path, or from manual recovery scripts. Returns a structured
-- summary so the caller can surface partial failures.
function M.abandon_task(task_id, opts)
    if not task_id or task_id == "" then
        return nil, "task_id is required"
    end
    opts = opts or {}
    local reason = opts.reason or "task abandoned"

    local result = {
        task_id              = task_id,
        cancelled_dataflows  = {},
        cancelled_errors     = {},
        dropped_changeset_id = nil,
        drop_error           = nil,
        lock_released        = false,
    }

    for _, df_id in ipairs(task_dataflow_ids(task_id)) do
        local ok, cerr = cancel_dataflow(df_id, reason)
        if ok then
            table.insert(result.cancelled_dataflows, df_id)
        else
            table.insert(result.cancelled_errors,
                { dataflow_id = df_id, error = cerr })
        end
    end

    local cs = changeset_repo.active_for_task(task_id)
    if cs and cs.changeset_id then
        local ok, derr = drop_changeset(cs.changeset_id, reason)
        if ok then
            result.dropped_changeset_id = cs.changeset_id
        else
            result.drop_error = derr
        end
    end

    -- Lock release. set_task_lock(task_id, nil) is the canonical
    -- "no current owner" form; it returns (true, nil) on success or
    -- (nil, err) on failure per the repo's nil+err convention.
    local lock_ok, lock_err = changeset_repo.set_task_lock(task_id, nil)
    result.lock_released = lock_ok == true
    result.lock_error    = lock_err

    return result, nil
end

return M
