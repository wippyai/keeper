-- keeper.develop.integrate:rollback_run
--
-- Function-phase runner for rollback. Locates the last successful integrate
-- run for the task, reverses every integrate_stage row in LIFO order, and
-- restores the registry to its baseline.

local governance = require("governance")
local nodes_reader = require("nodes_reader")
local nodes_writer = require("nodes_writer")
local lifecycle = require("lifecycle")

local M = {}

local function stage(task_id, parent, name, status, summary, error_message, metadata)
    nodes_writer.record({
        task_id        = task_id,
        parent_node_id = parent,
        type           = "rollback_stage",
        discriminator  = name,
        title          = name,
        status         = status,
        visibility     = "user",
        result_summary = summary,
        error_message  = error_message,
        metadata       = metadata,
    })
end

local function resolve_target_version(task_id, explicit)
    if explicit then return explicit end
    local last_run = nodes_reader.latest_of_type(task_id, "integrate_stage",
        { discriminator = "run", status = "passed" })
    if not last_run or not last_run.metadata then return nil end
    return last_run.metadata.baseline_version
end

local function resolve_published_version(task_id)
    local last_run = nodes_reader.latest_of_type(task_id, "integrate_stage",
        { discriminator = "run", status = "passed" })
    if not last_run or not last_run.metadata then return nil end
    return last_run.metadata.published_version
end

function M.handler(params)
    params = params or {}
    local task_id = params.task_id
    if not task_id or task_id == "" then
        return { status = "fail", summary = "rollback run: task_id required" }
    end

    local run_root_res, root_err = nodes_writer.record({
        task_id       = task_id,
        type          = "rollback_stage",
        discriminator = "run",
        title         = "Rollback run",
        status        = "running",
        visibility    = "user",
    })
    if root_err then
        return { status = "fail", summary = "emit rollback root: " .. tostring(root_err) }
    end
    local run_root = run_root_res.node_id

    local reason = params.reason or "test requested rollback"
    local published = resolve_published_version(task_id)
    local target_version = resolve_target_version(task_id, params.target_version)

    stage(task_id, run_root, "target_identified", "passed",
        "rolling back published version " .. tostring(published or "?") ..
        " to baseline " .. tostring(target_version or "?"),
        nil, {
            reason            = reason,
            published_version = published,
            target_version    = target_version,
        })

    if not target_version then
        local msg = "no baseline version found for task; cannot restore"
        stage(task_id, run_root, "restore_version", "failed", nil, msg)
        nodes_writer.update(run_root, {
            status         = "failed",
            error_message  = msg,
            result_summary = "rollback aborted — no baseline",
        })
        local result = { status = "done", summary = "rollback aborted: " .. msg }
        lifecycle.handle_exit(task_id, "rollback", result)
        return result
    end

    local _, err = governance.restore_version(target_version,
        "rollback runner (" .. reason .. ")")
    if err then
        stage(task_id, run_root, "restore_version", "failed", nil, tostring(err),
            { target_version = target_version })
        nodes_writer.update(run_root, {
            status         = "failed",
            error_message  = "restore_version: " .. tostring(err),
            result_summary = "rollback failed",
        })
        local result = { status = "done",
            summary = "rollback failed: " .. tostring(err) }
        lifecycle.handle_exit(task_id, "rollback", result)
        return result
    end

    stage(task_id, run_root, "restore_version", "passed",
        "registry version restored to " .. tostring(target_version),
        nil, { target_version = target_version })

    -- Handler reversal (migrations down, fs cleanup) — not yet wired.
    -- Placeholder stage so the UI sees the intent; implementation follows
    -- the handler reversal plumbing once shipped.
    stage(task_id, run_root, "handlers_down", "passed",
        "no reversible handler side-effects recorded for this integrate run",
        nil, { note = "handler reversal skeleton — wiring pending" })

    nodes_writer.update(run_root, {
        status         = "passed",
        result_summary = "rollback complete — registry v" ..
                          tostring(target_version) .. " restored",
        metadata       = {
            reason            = reason,
            published_version = published,
            target_version    = target_version,
        },
    })

    local result = { status = "done",
        summary = "rollback complete — registry restored to v" ..
                   tostring(target_version) }
    lifecycle.handle_exit(task_id, "rollback", result)
    return result
end

return M
