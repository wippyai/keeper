-- keeper.task.persist:writer
--
-- Lean task-lifecycle writer. Only touches keeper_tasks. Per-task events
-- and payloads (spec / finding / tool_call / phase_started / …) go through
-- keeper.task.persist:nodes_writer, which owns keeper_task_nodes.

local sql = require("sql")
local json = require("json")
local uuid = require("uuid")
local time = require("time")
local consts = require("task_consts")
local notify = require("notify")

local task_writer = {}
local builder_methods = {}
local builder_mt = { __index = builder_methods }

type TaskBuilder = {
    _commands: {unknown},
    _task_id: string,
    update_task: (TaskBuilder, {[string]: unknown}) -> TaskBuilder,
    execute: (TaskBuilder) -> ({task_id: string, results: {unknown}, changes_made: boolean}?, string?),
}

local CMD = {
    CREATE_TASK = "create_task",
    UPDATE_TASK = "update_task",
}

local function get_db()
    local db, err = sql.get(consts.DATABASE.RESOURCE_ID)
    if err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(err) end
    return db, nil
end

local function now()
    return time.now():format("2006-01-02T15:04:05Z")
end

local function new_id()
    local id, err = uuid.v7()
    if err then return nil, err end
    return id, nil
end

local function encode_metadata(metadata)
    if not metadata then return nil end
    local encoded, err = json.encode(metadata)
    if err then return nil, "metadata encode: " .. tostring(err) end
    return encoded, nil
end

local function publish(event, data)
    pcall(function()
        notify.publish(consts.TOPIC, { event = event, data = data })
    end)
end

local handlers = {}

handlers[CMD.CREATE_TASK] = function(tx, cmd)
    local p = cmd.payload
    local task_id = p.task_id or new_id()
    if not task_id then return nil, "uuid generation failed" end

    local meta_str, meta_err = encode_metadata(p.metadata)
    if meta_err then return nil, meta_err end

    local ts = now()
    local _, err = tx:execute([[
        INSERT INTO keeper_tasks (
            task_id, title, description, spec, acceptance, actor_id, session_id,
            status, phase, iteration, metadata, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)
    ]], {
        task_id, p.title, p.description, p.spec, p.acceptance,
        p.actor_id, p.session_id,
        consts.STATUSES.ACTIVE, consts.PHASES.SPEC, meta_str, ts, ts,
    })
    if err then return nil, "create_task: " .. tostring(err) end

    return {
        type    = CMD.CREATE_TASK,
        task_id = task_id,
        event   = consts.EVENTS.TASK_CREATED,
    }
end

handlers[CMD.UPDATE_TASK] = function(tx, cmd)
    local p = cmd.payload
    local sets, params = { "updated_at = ?" }, { now() }

    if p.title then table.insert(sets, "title = ?"); table.insert(params, p.title) end
    if p.description then table.insert(sets, "description = ?"); table.insert(params, p.description) end
    if p.spec then table.insert(sets, "spec = ?"); table.insert(params, p.spec) end
    if p.acceptance then table.insert(sets, "acceptance = ?"); table.insert(params, p.acceptance) end
    if p.phase then
        table.insert(sets, "phase = ?"); table.insert(params, p.phase)
        if p.phase == consts.PHASES.BLOCKED then
            table.insert(sets, "blocked_from = ?"); table.insert(params, p.blocked_from)
        elseif p.phase ~= consts.PHASES.BLOCKED then
            table.insert(sets, "blocked_from = NULL")
        end
    end
    if p.status then
        table.insert(sets, "status = ?"); table.insert(params, p.status)
        if p.status == consts.STATUSES.COMPLETED or p.status == consts.STATUSES.ABANDONED then
            table.insert(sets, "completed_at = ?"); table.insert(params, now())
        end
    end
    if p.increment_iteration then
        table.insert(sets, "iteration = iteration + 1")
    end
    if p.archived ~= nil then
        table.insert(sets, "archived = ?"); table.insert(params, p.archived and 1 or 0)
    end
    if p.metadata then
        local meta_str, meta_err = encode_metadata(p.metadata)
        if meta_err then return nil, meta_err end
        table.insert(sets, "metadata = ?"); table.insert(params, meta_str)
    end

    table.insert(params, p.task_id)
    local _, err = tx:execute(
        "UPDATE keeper_tasks SET " .. table.concat(sets, ", ") .. " WHERE task_id = ?",
        params
    )
    if err then return nil, "update_task: " .. tostring(err) end

    return {
        type          = CMD.UPDATE_TASK,
        task_id       = p.task_id,
        event         = consts.EVENTS.TASK_UPDATED,
        phase_entered = p.phase,
        actor_id      = p.actor_id,
    }
end

function task_writer.create_task(spec)
    if not spec or not spec.title or spec.title == "" then
        error("title is required for create_task")
    end
    local b = setmetatable({
        _commands = {},
        _task_id  = spec.task_id or new_id(),
    }, builder_mt)
    table.insert(b._commands, {
        type    = CMD.CREATE_TASK,
        payload = {
            task_id     = b._task_id,
            title       = spec.title,
            description = spec.description,
            spec        = spec.spec,
            acceptance  = spec.acceptance,
            actor_id    = spec.actor_id,
            session_id  = spec.session_id,
            metadata    = spec.metadata,
        },
    })
    return b :: TaskBuilder
end

function task_writer.for_task(task_id)
    return setmetatable({
        _commands = {},
        _task_id  = task_id,
    }, builder_mt) :: TaskBuilder
end

function builder_methods:update_task(updates)
    updates.task_id = self._task_id
    table.insert(self._commands, {
        type    = CMD.UPDATE_TASK,
        payload = updates,
    })
    return self
end

function builder_methods:execute()
    if #self._commands == 0 then
        return { task_id = self._task_id, results = {}, changes_made = false }
    end

    local db, db_err = get_db()
    if db_err then return nil, db_err end

    local tx, tx_err = db:begin()
    if tx_err then
        db:release()
        return nil, consts.ERRORS.DB_ERROR .. ": begin: " .. tostring(tx_err)
    end

    local results = {}
    for i, cmd in ipairs(self._commands) do
        local handler = handlers[cmd.type]
        if not handler then
            tx:rollback(); db:release()
            return nil, "unknown command type: " .. tostring(cmd.type)
        end
        local result, err = handler(tx, cmd)
        if err then
            tx:rollback(); db:release()
            return nil, "command " .. i .. " (" .. cmd.type .. ") failed: " .. err
        end
        table.insert(results, result)
    end

    local _, commit_err = tx:commit()
    db:release()
    if commit_err then
        return nil, consts.ERRORS.DB_ERROR .. ": commit: " .. tostring(commit_err)
    end

    for _, result in ipairs(results) do
        if result.event then
            publish(result.event, { task_id = result.task_id })
        end
    end

    return {
        task_id      = self._task_id,
        results      = results,
        changes_made = #results > 0,
    }
end

return task_writer
