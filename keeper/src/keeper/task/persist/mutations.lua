-- keeper.task.persist:mutations
--
-- Atomic repository operations that span keeper_tasks and keeper_task_nodes.
-- Every public method owns exactly one database transaction. Node/task events
-- are buffered and published only after that transaction commits.

local sql = require("sql")

local nodes_writer = require("nodes_writer")
local task_consts = require("task_consts")
local task_writer = require("task_writer")

local M = {}

local function get_db()
    local db, err = sql.get(task_consts.DATABASE.RESOURCE_ID)
    if err then return nil, "task mutations db: " .. tostring(err) end
    return db, nil
end

local function transact(fn)
    local db, db_err = get_db()
    if db_err then return nil, db_err end

    local tx, tx_err = db:begin()
    if tx_err then
        db:release()
        return nil, "task mutations begin: " .. tostring(tx_err)
    end

    local node_events = {}
    local task_results = {}
    local unit = {}

    function unit:query(query, params)
        local rows, err = tx:query(query, params or {})
        if err then return nil, tostring(err) end
        return rows, nil
    end

    function unit:record_node(spec)
        local row, err, event = nodes_writer.record_in(tx, spec)
        if event then table.insert(node_events, event) end
        return row, err
    end

    function unit:update_node(node_id, fields)
        local row, err, event = nodes_writer.update_in(tx, node_id, fields)
        if event then table.insert(node_events, event) end
        return row, err
    end

    function unit:update_task(task_id, fields)
        local result, err = task_writer.update_in(tx, task_id, fields)
        if result then table.insert(task_results, result) end
        return result, err
    end

    local ok, result, operation_err = pcall(fn, unit)
    if not ok or operation_err then
        local _, rollback_err = tx:rollback()
        db:release()
        local message = not ok and ("task mutations callback: " .. tostring(result)) or tostring(operation_err)
        if rollback_err then
            message = message .. "; rollback: " .. tostring(rollback_err)
        end
        return nil, message
    end

    local _, commit_err = tx:commit()
    if commit_err then
        tx:rollback()
        db:release()
        return nil, "task mutations commit: " .. tostring(commit_err)
    end
    db:release()

    nodes_writer.publish_events(node_events)
    task_writer.publish_results(task_results)
    return result, nil
end

local function next_revision(unit, task_id, node_type)
    local rows, err = unit:query(
        "SELECT COUNT(*) AS c FROM keeper_task_nodes WHERE task_id = ? AND type = ?",
        { task_id, node_type }
    )
    if err then return nil, "revision lookup: " .. err end
    return tostring((tonumber(rows and rows[1] and rows[1].c) or 0) + 1), nil
end

local function update_matching_nodes(unit, query, params, status, label)
    local rows, query_err = unit:query(query, params)
    if query_err then return nil, label .. " lookup: " .. query_err end
    for _, row in ipairs(rows or {}) do
        local _, update_err = unit:update_node(row.node_id, { status = status })
        if update_err then return nil, label .. ": " .. update_err end
    end
    return true, nil
end

function M.write_plan(task_id, params)
    return transact(function(unit)
        local next_rev, rev_err = next_revision(unit, task_id, "plan")
        if rev_err then return nil, rev_err end

        local _, supersede_err = update_matching_nodes(
            unit,
            "SELECT node_id FROM keeper_task_nodes " ..
            "WHERE task_id = ? AND type = 'plan' AND status = 'active'",
            { task_id },
            "superseded",
            "Failed to supersede prior plan"
        )
        if supersede_err then return nil, supersede_err end

        local _, cancel_err = update_matching_nodes(
            unit,
            "SELECT node_id FROM keeper_task_nodes " ..
            "WHERE task_id = ? AND type = 'step' " ..
            "AND status IN ('pending','in_progress','blocked')",
            { task_id },
            "cancelled",
            "Failed to cancel prior plan steps"
        )
        if cancel_err then return nil, cancel_err end

        local plan_row, plan_err = unit:record_node({
            task_id       = task_id,
            type          = "plan",
            discriminator = next_rev,
            title         = params.title or ("Implementation Plan (rev " .. next_rev .. ")"),
            content       = params.summary,
            content_type  = "text/markdown",
            status        = "active",
            visibility    = "user",
            metadata      = {
                revision    = next_rev,
                step_count  = #params.steps,
                description = params.summary,
            },
        })
        if plan_err or not plan_row then
            return nil, "Failed to record plan node: " .. tostring(plan_err)
        end

        for i, step in ipairs(params.steps) do
            local _, step_err = unit:record_node({
                task_id        = task_id,
                parent_node_id = plan_row.node_id,
                type           = "step",
                discriminator  = step.id,
                title          = step.title,
                content        = step.task,
                content_type   = "text/markdown",
                status         = "pending",
                visibility     = "user",
                metadata       = {
                    kind              = step.kind,
                    target            = step.target,
                    needs             = step.needs or {},
                    agent_id          = step.agent_id,
                    produces_prompt   = step.produces_prompt,
                    acceptance        = step.acceptance,
                    verification_tool = step.verification_tool,
                    position          = i,
                    plan_node_id      = plan_row.node_id,
                    plan_revision     = next_rev,
                },
            })
            if step_err then
                return nil, "Failed to record step '" .. step.id .. "': " .. step_err
            end
        end

        return { revision = next_rev, inserted = #params.steps }, nil
    end)
end

function M.write_spec(task_id, params)
    return transact(function(unit)
        local next_rev, rev_err = next_revision(unit, task_id, "spec")
        if rev_err then return nil, rev_err end

        local _, supersede_err = update_matching_nodes(
            unit,
            "SELECT node_id FROM keeper_task_nodes " ..
            "WHERE task_id = ? AND type = 'spec' AND status = 'active'",
            { task_id },
            "superseded",
            "Failed to supersede prior spec"
        )
        if supersede_err then return nil, supersede_err end

        local _, node_err = unit:record_node({
            task_id       = task_id,
            type          = "spec",
            discriminator = next_rev,
            title         = params.title or ("Implementation Specification (rev " .. next_rev .. ")"),
            content       = params.content,
            content_type  = "text/markdown",
            status        = "active",
            visibility    = "user",
            metadata      = { is_final = params.is_final ~= false, revision = next_rev },
        })
        if node_err then return nil, "Failed to record spec node: " .. node_err end

        local _, task_err = unit:update_task(task_id, {
            phase = "design",
            spec = params.content,
        })
        if task_err then return nil, "Failed to update task: " .. task_err end

        return { revision = next_rev }, nil
    end)
end

local function find_open_step(unit, task_id, step_id)
    local rows, err = unit:query([[
        SELECT node_id, status FROM keeper_task_nodes
        WHERE task_id = ? AND type = 'step' AND discriminator = ?
          AND status IN ('pending', 'active')
        ORDER BY seq DESC LIMIT 1
    ]], { task_id, step_id })
    if err then return nil, "step lookup: " .. err end
    if rows and rows[1] then return rows[1], nil end

    local latest, latest_err = unit:query([[
        SELECT status FROM keeper_task_nodes
        WHERE task_id = ? AND type = 'step' AND discriminator = ?
        ORDER BY seq DESC LIMIT 1
    ]], { task_id, step_id })
    if latest_err then return nil, "step lookup: " .. latest_err end
    if latest and latest[1] then
        return nil, "step '" .. step_id .. "' is " .. (latest[1].status or "closed")
    end
    return nil, "step '" .. step_id .. "' not found"
end

function M.block_step(task_id, params)
    return transact(function(unit)
        local step, step_err = find_open_step(unit, task_id, params.step_id)
        if not step then return nil, step_err end

        local ask, ask_err = unit:record_node({
            task_id        = task_id,
            parent_node_id = step.node_id,
            type           = "ask_user",
            discriminator  = params.step_id,
            title          = "Blocked on " .. params.step_id,
            content        = params.question,
            content_type   = "text/markdown",
            status         = "active",
            visibility     = "user",
            agent_id       = params.agent_id,
            metadata       = { step_id = params.step_id, phase = params.phase },
        })
        if ask_err or not ask then
            return nil, "Failed to emit ask_user: " .. tostring(ask_err)
        end

        local _, update_err = unit:update_node(step.node_id, {
            status         = "blocked",
            result_summary = "blocked: awaiting user response",
            error_message  = params.question,
            agent_id       = params.agent_id,
            metadata       = { blocker_node_id = ask.node_id },
        })
        if update_err then return nil, "Failed to update step: " .. update_err end

        return { blocker_node_id = ask.node_id }, nil
    end)
end

return M
