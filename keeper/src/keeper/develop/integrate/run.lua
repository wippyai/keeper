-- keeper.develop.integrate:run
--
-- Function-phase runner for integrate. Drives the deterministic pipeline:
--   snapshot → publish (state.tools:push) → handlers up (pipeline:execute)
--   on failure → handlers down (pipeline:rollback) → restore_version
--   emit phase_exited via lifecycle.handle_exit with signal ok|fail.
--
-- Emits integrate_stage nodes into keeper_task_nodes so the FE Integrations
-- tab renders stage-by-stage. Every stage is a child of the run root so the
-- UI can expand per-stage detail.
--
-- Pipeline:execute + pipeline:rollback are invoked synchronously via
-- funcs.new():call. Keeping them synchronous sidesteps the child-workflow
-- _control yield path whose routing semantics we don't fully control here.
-- Per-handler observability still lives in the inner Execute Integration
-- Pipeline dataflow, just not as nested children of the integrate dataflow.

local funcs = require("funcs")
local governance = require("governance")
local time = require("time")
local fs_flush = require("fs_flush")
local changeset_repo = require("changeset_repo")
local nodes_writer = require("nodes_writer")
local lifecycle = require("lifecycle")

local M = {}

local STAGE_ICONS = {
    snapshot  = "tabler:versions",
    publish   = "tabler:upload",
    handlers  = "tabler:plug-connected",
    rollback  = "tabler:arrow-back",
    fs_revert = "tabler:file-diff",
    restore   = "tabler:arrow-back-up",
}

local function now_iso()
    return time.now():format(time.RFC3339NANO)
end

local function root_stage(task_id, changeset_id)
    local res, err = nodes_writer.record({
        task_id       = task_id,
        changeset_id  = changeset_id,
        type          = "integrate_stage",
        discriminator = "run",
        title         = "Integrate run",
        status        = "running",
        visibility    = "user",
        metadata      = { started_at = now_iso() },
    })
    if err then return nil, err end
    return res.node_id
end

local function stage(
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

local function finalize_root(root: string, ok: boolean, summary: string, err_text: string?, metadata: unknown?)
    nodes_writer.update(root, {
        status         = ok and "passed" or "failed",
        result_summary = summary,
        error_message  = err_text,
        metadata       = metadata,
    })
end

local function advance(task_id, signal, summary, extra)
    local result = { status = signal, summary = summary }
    if extra then
        for k, v in pairs(extra) do result[k] = v end
    end
    lifecycle.handle_exit(task_id, "integrate", result)
    return result
end

local function call_push(branch)
    local executor, exec_err = funcs.new()
    if exec_err then return nil, "funcs.new: " .. tostring(exec_err) end
    -- skip_merge_transition leaves the changeset in `accepted` after a
    -- successful publish; integrate fires push_success only after handlers
    -- validate per-kind side effects, or push_failure+reopen if they fail.
    -- Eliminates the orphan-branch cascade where a pre-handler merge stranded
    -- the changeset in MERGED while restore_version reverted main.
    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.state.tools:push", { branch = branch, skip_merge_transition = true })
    if not ok then return nil, "push panic: " .. tostring(result) end
    if call_err then return nil, tostring(call_err) end
    return result, nil
end

-- Fire a changeset state-machine transition via the existing service fn.
-- Best-effort: failures are logged via an integrate_stage row but don't
-- fail-stop integrate (e.g. push_failure/reopen on an already-terminal
-- changeset would be a no-op for our purposes).
local function fire_cs_transition(task_id, run_root, changeset_id, event, reason)
    if not changeset_id or changeset_id == "" then return end
    local executor, exec_err = funcs.new()
    if exec_err then
        stage(task_id, run_root, event, "failed", nil, nil,
            "funcs.new failed: " .. tostring(exec_err))
        return
    end
    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.changeset.service:fire_transition",
        { changeset_id = changeset_id, event = event, reason = reason })
    if not ok then
        stage(task_id, run_root, event, "failed", nil, nil,
            "transition panic: " .. tostring(result))
        return
    end
    if call_err then
        stage(task_id, run_root, event, "failed", nil, nil,
            "transition error: " .. tostring(call_err))
        return
    end
    stage(task_id, run_root, event, "passed",
        "changeset transition " .. event,
        { icon = "tabler:git-branch", reason = reason })
end

local function call_pipeline_execute(entry_ids, fs_paths, operation)
    local executor, exec_err = funcs.new()
    if exec_err then return nil, "funcs.new: " .. tostring(exec_err) end
    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.develop.integrate.pipeline:execute",
        { entry_ids = entry_ids, fs_paths = fs_paths or {}, operation = operation })
    if not ok then return nil, "pipeline:execute panic: " .. tostring(result) end
    if call_err then return nil, tostring(call_err) end
    return result, nil
end

-- Pull the filesystem-category change targets for a changeset. build_handler
-- (and any future fs-aware handler) receive these alongside the registry
-- entry ids so raw FS edits (e.g. frontend/**) trigger reactions without
-- needing a parallel registry entry.
local function collect_fs_paths(changeset_id)
    if not changeset_id or changeset_id == "" then return {} end
    local rows, err = changeset_repo.list_changes_for_changeset(changeset_id,
        { category = "filesystem" })
    if err or not rows then return {} end
    local paths, seen = {}, {}
    for _, r in ipairs(rows) do
        local p = r and r.target
        if p and p ~= "" and not seen[p] then
            seen[p] = true
            table.insert(paths, p)
        end
    end
    return paths
end

local function call_pipeline_rollback(execution: unknown)
    local executor, exec_err = funcs.new()
    if exec_err then return nil, "funcs.new: " .. tostring(exec_err) end
    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.develop.integrate.pipeline:rollback",
        { execution = type(execution) == "table" and execution or {} })
    if not ok then return nil, "pipeline:rollback panic: " .. tostring(result) end
    if call_err then return nil, tostring(call_err) end
    return result, nil
end

local function revert_fs_flush(task_id, run_root, changeset_id)
    local result, err = fs_flush.revert_flushed(changeset_id)
    if err then
        stage(task_id, run_root, "fs_revert", "failed", nil,
            { icon = STAGE_ICONS.fs_revert },
            tostring(err))
        return nil, err
    end
    result = result or {}
    local restaged = tonumber(result.restaged) or 0
    stage(task_id, run_root, "fs_revert", "passed",
        "frontend fs restored; " .. tostring(restaged) .. " staged row(s) visible for retry",
        {
            icon     = STAGE_ICONS.fs_revert,
            restored = result.restored or 0,
            restaged = restaged,
            paths    = result.paths or {},
        })
    return result, nil
end

function M.handler(params)
    params = params or {}
    local task_id = params.task_id
    if not task_id or task_id == "" then
        return { status = "fail", summary = "integrate run: task_id required" }
    end

    local cs = changeset_repo.active_for_task(task_id)
    if not cs or not cs.state_branch then
        return advance(task_id, "fail",
            "integrate: task has no active changeset with a state_branch")
    end

    local run_root, root_err = root_stage(task_id, cs.changeset_id)
    if root_err then
        return advance(task_id, "fail", "integrate: emit root: " .. tostring(root_err))
    end

    -- 1. Snapshot baseline registry version for potential rollback.
    local baseline, base_err = governance.current_version()
    if base_err then
        stage(task_id, run_root, "snapshot", "failed", nil, nil, tostring(base_err))
        finalize_root(run_root, false, "snapshot failed", tostring(base_err))
        return advance(task_id, "fail", "integrate: snapshot failed: " .. tostring(base_err))
    end
    stage(task_id, run_root, "snapshot", "passed",
        "baseline registry version captured",
        { icon = STAGE_ICONS.snapshot, baseline_version = baseline })

    -- 2. Publish via the governance pipeline (lint gate + registry apply +
    -- fs flush are owned by state.tools:push; per-kind side effects run
    -- afterwards via the handler chain).
    local push_result, push_err = call_push(cs.state_branch)
    if push_err or not push_result then
        stage(task_id, run_root, "publish", "failed", nil, nil, tostring(push_err or "no result"))
        changeset_repo.reset_applied_to_pending(cs.changeset_id)
        fire_cs_transition(task_id, run_root, cs.changeset_id,
            "push_failure", "integrate: publish step failed: " .. tostring(push_err))
        fire_cs_transition(task_id, run_root, cs.changeset_id,
            "reopen", "integrate: reopen for follow-up implement after publish-fail")
        finalize_root(run_root, false, "publish failed", tostring(push_err))
        return advance(task_id, "fail", "integrate: publish failed: " .. tostring(push_err))
    end
    local entry_ids = push_result.entry_ids or {}
    stage(task_id, run_root, "publish", "passed",
        "registry version " .. tostring(push_result.version or "?") ..
        " published (" .. tostring(#entry_ids) .. " entries)",
        {
            icon              = STAGE_ICONS.publish,
            published_version = push_result.version,
            entry_count       = #entry_ids,
            branch            = cs.state_branch,
        })

    -- 3. Handlers up (migration, fs, view, env, build, test, endpoint) by meta.order.
    local fs_paths = collect_fs_paths(cs.changeset_id)
    if #entry_ids == 0 and #fs_paths == 0 then
        -- genuine empty push: no registry entries AND no FS changes. Treat
        -- as final ok and merge.
        fire_cs_transition(task_id, run_root, cs.changeset_id,
            "push_success", "integrate empty: no entries or fs changes")
        finalize_root(run_root, true, "no changes to integrate",
            nil,
            { baseline_version = baseline, published_version = push_result.version })
        return advance(task_id, "ok",
            "integrate: registry updated with 0 entries (empty push)", {
                baseline_version  = baseline,
                published_version = push_result.version,
            })
    end

    local exec_result, exec_err = call_pipeline_execute(entry_ids, fs_paths, "up")
    if exec_err or not exec_result then
        stage(task_id, run_root, "handlers", "failed", nil, nil, tostring(exec_err or "no result"))
        local rollback_res, rb_err = call_pipeline_rollback({})
        stage(task_id, run_root, "rollback", rb_err and "failed" or "passed",
            rb_err and nil or "handlers down completed",
            { icon = STAGE_ICONS.rollback, execution = rollback_res and rollback_res.execution },
            rb_err and tostring(rb_err) or nil)
        local fs_revert_res, fs_revert_err = revert_fs_flush(task_id, run_root, cs.changeset_id)
        local _, restore_err = governance.restore_version(baseline,
            "integrate handler dispatch failed")
        stage(task_id, run_root, "restore", restore_err and "failed" or "passed",
            restore_err and nil or ("registry restored to version " .. tostring(baseline)),
            { icon = STAGE_ICONS.restore, target_version = baseline },
            restore_err and tostring(restore_err) or nil)

        local recovery_err = rb_err or fs_revert_err or restore_err
        if recovery_err then
            fire_cs_transition(task_id, run_root, cs.changeset_id,
                "push_failure", "integrate: handler dispatch failed and rollback was incomplete")
            finalize_root(run_root, false, "handler dispatch failed; rollback incomplete",
                tostring(recovery_err),
                { rollback = rollback_res, fs_revert = fs_revert_res, fs_revert_error = fs_revert_err })
            return advance(task_id, "fail",
                "integrate: handler dispatch failed; rollback incomplete: " .. tostring(recovery_err))
        end

        changeset_repo.reset_applied_to_pending(cs.changeset_id)
        fire_cs_transition(task_id, run_root, cs.changeset_id,
            "push_failure", "integrate: handler dispatch failed")
        fire_cs_transition(task_id, run_root, cs.changeset_id,
            "reopen", "integrate: reopen for follow-up implement")
        finalize_root(run_root, false, "handlers failed", tostring(exec_err),
            { rollback = rollback_res, fs_revert = fs_revert_res, fs_revert_error = fs_revert_err })
        return advance(task_id, "fail",
            "integrate: handler dispatch failed: " .. tostring(exec_err))
    end

    if exec_result.success == false then
        -- Surface the first failing handler's error into the stage's
        -- error_message column so the UI + SQL queries can see which
        -- handler actually broke without expanding metadata. The full
        -- execution payload stays in metadata for deep inspection.
        local first_err = nil
        local exec_handlers = (exec_result.execution or {}).handlers or {}
        for _, h in ipairs(exec_handlers) do
            if h and h.error ~= nil and h.error ~= "" then
                first_err = tostring(h.handler_id or "?") .. ": " .. tostring(h.error)
                break
            end
        end
        stage(task_id, run_root, "handlers", "failed",
            first_err and ("handler failed: " .. first_err) or "one or more handlers failed",
            { icon = STAGE_ICONS.handlers, execution = exec_result.execution },
            first_err)

        -- Reverse the handlers that succeeded.
        local rb_result, rb_err = call_pipeline_rollback(exec_result.execution)
        stage(task_id, run_root, "rollback", rb_err and "failed" or "passed",
            rb_err and nil or "handlers down completed",
            { icon = STAGE_ICONS.rollback, execution = rb_result and rb_result.execution },
            rb_err and tostring(rb_err) or nil)

        local fs_revert_res, fs_revert_err = revert_fs_flush(task_id, run_root, cs.changeset_id)

        -- Restore registry.
        local _, restore_err = governance.restore_version(baseline,
            "integrate handlers up failed")
        stage(task_id, run_root, "restore", restore_err and "failed" or "passed",
            restore_err and nil or ("registry restored to version " .. tostring(baseline)),
            { icon = STAGE_ICONS.restore, target_version = baseline },
            restore_err and tostring(restore_err) or nil)

        local recovery_err = rb_err or fs_revert_err or restore_err
        if recovery_err then
            fire_cs_transition(task_id, run_root, cs.changeset_id,
                "push_failure", "integrate: handlers failed and rollback was incomplete")
            finalize_root(run_root, false,
                "integrate failed — rollback incomplete",
                tostring(recovery_err),
                { fs_revert = fs_revert_res, fs_revert_error = fs_revert_err })
            return advance(task_id, "fail",
                "integrate: handler failure; rollback incomplete: " .. tostring(recovery_err))
        end

        changeset_repo.reset_applied_to_pending(cs.changeset_id)

        -- Reject + reopen so the next implement reuses this changeset.
        fire_cs_transition(task_id, run_root, cs.changeset_id,
            "push_failure", "integrate: handlers failed, registry restored")
        fire_cs_transition(task_id, run_root, cs.changeset_id,
            "reopen", "integrate: reopen for follow-up implement")

        finalize_root(run_root, false,
            "integrate failed — handlers reversed, registry restored",
            "one or more handlers reported failure",
            { fs_revert = fs_revert_res, fs_revert_error = fs_revert_err })
        return advance(task_id, "fail",
            "integrate: handler failure; rolled back to v" .. tostring(baseline))
    end

    stage(task_id, run_root, "handlers", "passed",
        "all handlers green",
        { icon = STAGE_ICONS.handlers, execution = exec_result.execution })

    -- Handlers green — only now do we merge the changeset. This is the
    -- linchpin of item-8 fix: changeset transitions to merged AFTER per-kind
    -- side effects validate, so a handler-failure → restore_version path no
    -- longer leaves a merged-but-rolled-back changeset behind.
    fire_cs_transition(task_id, run_root, cs.changeset_id,
        "push_success", "integrate: handlers green")

    finalize_root(run_root, true,
        "integrate complete — registry v" .. tostring(push_result.version),
        nil,
        {
            baseline_version  = baseline,
            published_version = push_result.version,
            entry_count       = #entry_ids,
        })

    return advance(task_id, "ok",
        "integrate: " .. tostring(#entry_ids) .. " entries published, handlers green", {
            baseline_version  = baseline,
            published_version = push_result.version,
            entry_count       = #entry_ids,
        })
end

return M
