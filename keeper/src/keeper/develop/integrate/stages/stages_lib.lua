-- Stage handlers for the integrate flow DAG in keeper.develop.integrate:run.
-- Each method is registered as its own `function.lua` entry so the flow
-- builder can reference them by id. Every method records its own
-- `integrate_stage` trail node so the FE Integrations tab renders a row per
-- stage, and the final stages call lifecycle.handle_exit to advance the
-- phase state machine.

local funcs        = require("funcs")
local governance   = require("governance")
local nodes_writer = require("nodes_writer")
local lifecycle    = require("lifecycle")

local STAGE_ICONS = {
    snapshot = "tabler:versions",
    publish  = "tabler:upload",
    handlers = "tabler:plug-connected",
    rollback = "tabler:arrow-back",
    restore  = "tabler:arrow-back-up",
}

local M = {}

local function emit(
    task_id: string,
    parent: string,
    name: string,
    status: string,
    summary: string?,
    metadata: unknown?,
    err_text: string?
)
    nodes_writer.record({
        task_id        = task_id,
        parent_node_id = parent,
        type           = "integrate_stage",
        discriminator  = name,
        title          = name,
        status         = status,
        visibility     = "user",
        result_summary = summary,
        error_message  = err_text,
        metadata       = metadata or { icon = STAGE_ICONS[name] },
    })
end

-- snapshot: capture baseline registry version + emit snapshot stage row.
-- Inputs: { task_id, branch, changeset_id, run_root }
-- Outputs: full context plus { baseline_version }
function M.snapshot(params)
    params = params or {}
    local task_id = params.task_id
    local run_root = params.run_root
    if not task_id or task_id == "" then return nil, "snapshot: task_id required" end
    if not run_root or run_root == "" then return nil, "snapshot: run_root required" end

    local baseline, err = governance.current_version()
    if err then
        emit(task_id, run_root, "snapshot", "failed", nil,
            { icon = STAGE_ICONS.snapshot }, tostring(err))
        return nil, "snapshot failed: " .. tostring(err)
    end

    emit(task_id, run_root, "snapshot", "passed",
        "baseline registry version captured",
        { icon = STAGE_ICONS.snapshot, baseline_version = baseline })

    return {
        task_id          = task_id,
        branch           = params.branch,
        changeset_id     = params.changeset_id,
        run_root         = run_root,
        baseline_version = baseline,
    }
end

-- publish: run state.tools:push + emit publish stage row.
-- Inputs: { task_id, branch, run_root, baseline_version, ... }
-- Outputs on success: { entry_ids, version, baseline_version, ...passthrough }
function M.publish(params)
    params = params or {}
    local task_id  = params.task_id
    local branch   = params.branch
    local run_root = params.run_root
    if not task_id or task_id == "" then return nil, "publish: task_id required" end
    if not branch or branch == "" then return nil, "publish: branch required" end
    if type(run_root) ~= "string" or run_root == "" then return nil, "publish: run_root required" end

    local executor = funcs.new()
    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.state.tools:push", { branch = branch })

    local err
    if not ok then err = "push panic: " .. tostring(result)
    elseif call_err then err = tostring(call_err)
    elseif not result then err = "push returned no result"
    end

    if err then
        emit(task_id, run_root, "publish", "failed", nil,
            { icon = STAGE_ICONS.publish }, err)
        return nil, "publish failed: " .. err
    end

    local entry_ids = result.entry_ids or {}
    emit(task_id, run_root, "publish", "passed",
        string.format("registry version %s published (%d entries)",
            tostring(result.version or "?"), #entry_ids),
        {
            icon              = STAGE_ICONS.publish,
            published_version = result.version,
            entry_count       = #entry_ids,
            branch            = branch,
        })

    return {
        task_id          = task_id,
        branch           = branch,
        changeset_id     = params.changeset_id,
        run_root         = run_root,
        baseline_version = params.baseline_version,
        entry_ids        = entry_ids,
        version          = result.version,
    }
end

-- record_handlers: emit the handlers integrate_stage row. Called on both
-- success and failure paths with the execution payload from pipeline:execute.
-- Inputs: { task_id, run_root, execution, passed }
function M.record_handlers(params)
    params = params or {}
    local task_id  = params.task_id
    local run_root = params.run_root
    if not task_id or task_id == "" then return nil, "record_handlers: task_id required" end
    if not run_root or run_root == "" then return nil, "record_handlers: run_root required" end

    local passed = params.passed and true or false
    emit(task_id, run_root, "handlers",
        passed and "passed" or "failed",
        passed and "all handlers green" or "one or more handlers failed",
        { icon = STAGE_ICONS.handlers, execution = params.execution },
        passed and nil or "handler failure")
    return { ok = passed }
end

-- restore_version: call governance.restore_version + emit restore stage row.
-- Inputs: { task_id, run_root, baseline_version }
function M.restore_version(params)
    params = params or {}
    local task_id  = params.task_id
    local run_root = params.run_root
    local baseline = params.baseline_version
    if not task_id or task_id == "" then return nil, "restore_version: task_id required" end
    if type(run_root) ~= "string" or run_root == "" then return nil, "restore_version: run_root required" end
    if baseline == nil then return nil, "restore_version: baseline_version required" end

    local _, err = governance.restore_version(baseline,
        "integrate handlers up failed")
    if err then
        emit(task_id, run_root, "restore", "failed", nil,
            { icon = STAGE_ICONS.restore, target_version = baseline }, tostring(err))
        return nil, "restore failed: " .. tostring(err)
    end

    emit(task_id, run_root, "restore", "passed",
        "registry restored to version " .. tostring(baseline),
        { icon = STAGE_ICONS.restore, target_version = baseline })
    return { ok = true, baseline_version = baseline }
end

-- finalize: update root integrate_stage + call lifecycle.handle_exit.
-- Inputs: { task_id, run_root, ok (bool), summary, extras (table, optional) }
function M.finalize(params)
    params = params or {}
    local task_id  = params.task_id
    local run_root = params.run_root
    if not task_id or task_id == "" then return nil, "finalize: task_id required" end
    if not run_root or run_root == "" then return nil, "finalize: run_root required" end

    local ok = params.ok and true or false
    nodes_writer.update(run_root, {
        status         = ok and "passed" or "failed",
        result_summary = params.summary,
        error_message  = (not ok) and params.summary or nil,
        metadata       = params.extras,
    })

    local signal = ok and "ok" or "fail"
    local result = { status = signal, summary = params.summary or "" }
    if params.extras then
        for k, v in pairs(params.extras) do result[k] = v end
    end
    lifecycle.handle_exit(task_id, "integrate", result)
    return result
end

return M
