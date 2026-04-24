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

local funcs = require("funcs")
local governance = require("governance")
local changeset_repo = require("changeset_repo")
local nodes_writer = require("nodes_writer")
local lifecycle = require("lifecycle")

local M = {}

local STAGE_ICONS = {
    snapshot  = "tabler:versions",
    publish   = "tabler:upload",
    handlers  = "tabler:plug-connected",
    rollback  = "tabler:arrow-back",
    restore   = "tabler:arrow-back-up",
}

local function now_iso()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
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

local function stage(task_id, parent, name, status, summary, metadata, err_text)
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

local function finalize_root(root, ok, summary, err_text, metadata)
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
    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.state.tools:push", { branch = branch })
    if not ok then return nil, "push panic: " .. tostring(result) end
    if call_err then return nil, tostring(call_err) end
    return result, nil
end

local function call_pipeline_execute(entry_ids, operation)
    local executor, exec_err = funcs.new()
    if exec_err then return nil, "funcs.new: " .. tostring(exec_err) end
    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.develop.integrate.pipeline:execute",
        { entry_ids = entry_ids, operation = operation })
    if not ok then return nil, "pipeline:execute panic: " .. tostring(result) end
    if call_err then return nil, tostring(call_err) end
    return result, nil
end

local function call_pipeline_rollback(execution)
    local executor, exec_err = funcs.new()
    if exec_err then return nil, "funcs.new: " .. tostring(exec_err) end
    local ok, result, call_err = pcall(executor.call, executor,
        "keeper.develop.integrate.pipeline:rollback",
        { execution = execution or {} })
    if not ok then return nil, "pipeline:rollback panic: " .. tostring(result) end
    if call_err then return nil, tostring(call_err) end
    return result, nil
end

function M.handler(params)
    params = params or {}
    local task_id = params.task_id
    if not task_id or task_id == "" then
        return { status = "fail", summary = "integrate run: task_id required" }
    end

    -- Resolve the active changeset so we know which branch to publish.
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
    if #entry_ids == 0 then
        finalize_root(run_root, true, "no entries to integrate",
            { baseline_version = baseline, published_version = push_result.version })
        return advance(task_id, "ok",
            "integrate: registry updated with 0 entries (fs-only push)", {
                baseline_version  = baseline,
                published_version = push_result.version,
            })
    end

    local exec_result, exec_err = call_pipeline_execute(entry_ids, "up")
    if exec_err or not exec_result then
        stage(task_id, run_root, "handlers", "failed", nil, nil, tostring(exec_err or "no result"))
        -- Rollback the registry so main is not left with entries whose side
        -- effects never landed. Handler rows that did apply are the caller's
        -- responsibility to reverse — we go to the down path below.
        local rollback_res = call_pipeline_rollback({})
        local _, restore_err = governance.restore_version(baseline,
            "integrate handler dispatch failed")
        stage(task_id, run_root, "restore", restore_err and "failed" or "passed",
            restore_err and nil or ("registry restored to version " .. tostring(baseline)),
            { icon = STAGE_ICONS.restore, target_version = baseline },
            restore_err and tostring(restore_err) or nil)
        finalize_root(run_root, false, "handlers failed", tostring(exec_err),
            { rollback = rollback_res })
        return advance(task_id, "fail",
            "integrate: handler dispatch failed: " .. tostring(exec_err))
    end

    if exec_result.success == false then
        stage(task_id, run_root, "handlers", "failed",
            "one or more handlers failed",
            { icon = STAGE_ICONS.handlers, execution = exec_result.execution })

        -- Reverse the handlers that succeeded.
        local rb_result, rb_err = call_pipeline_rollback(exec_result.execution)
        stage(task_id, run_root, "rollback", rb_err and "failed" or "passed",
            rb_err and nil or "handlers down completed",
            { icon = STAGE_ICONS.rollback, execution = rb_result and rb_result.execution },
            rb_err and tostring(rb_err) or nil)

        -- Restore registry.
        local _, restore_err = governance.restore_version(baseline,
            "integrate handlers up failed")
        stage(task_id, run_root, "restore", restore_err and "failed" or "passed",
            restore_err and nil or ("registry restored to version " .. tostring(baseline)),
            { icon = STAGE_ICONS.restore, target_version = baseline },
            restore_err and tostring(restore_err) or nil)

        finalize_root(run_root, false,
            "integrate failed — handlers reversed, registry restored",
            "one or more handlers reported failure")
        return advance(task_id, "fail",
            "integrate: handler failure; rolled back to v" .. tostring(baseline))
    end

    stage(task_id, run_root, "handlers", "passed",
        "all handlers green",
        { icon = STAGE_ICONS.handlers, execution = exec_result.execution })

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
