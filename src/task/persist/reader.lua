-- keeper.task.persist:reader
--
-- Lean task-lifecycle reader. Only queries keeper_tasks. All per-task
-- events/payloads (spec, finding, tool_call, phase_started, integrate_stage)
-- live in keeper_task_nodes and go through keeper.task.persist:nodes_reader.

local sql = require("sql")
local json = require("json")
local consts = require("task_consts")

local task_reader = {}
local methods = {}
local reader_mt = { __index = methods }

local function get_db()
    local db, err = sql.get(consts.DATABASE.RESOURCE_ID)
    if err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(err) end
    return db, nil
end

local function decode_metadata(row)
    if row and row.metadata and type(row.metadata) == "string" and row.metadata ~= "" then
        local decoded, err = json.decode(row.metadata)
        if not err then row.metadata = decoded end
    end
    return row
end

local function decode_rows(rows)
    local result = {}
    for _, row in ipairs(rows or {}) do
        table.insert(result, decode_metadata(row))
    end
    return result
end

function methods:_copy()
    local new = {}
    for k, v in pairs(self) do new[k] = v end
    return setmetatable(new, reader_mt)
end

function task_reader.tasks()
    return setmetatable({
        _status    = nil,
        _actor_id  = nil,
        _archived  = false,
        _limit     = nil,
        _order     = "created_at DESC",
    }, reader_mt)
end

function methods:with_status(status)
    local c = self:_copy(); c._status = status; return c
end

function methods:with_actor(actor_id)
    local c = self:_copy(); c._actor_id = actor_id; return c
end

function methods:with_archived(archived)
    local c = self:_copy(); c._archived = archived; return c
end

function methods:order_by_created(dir)
    local c = self:_copy(); c._order = "created_at " .. (dir or "ASC"); return c
end

function methods:limit(n)
    local c = self:_copy(); c._limit = n; return c
end

local function build_query(self)
    local where, params = {}, {}
    if self._status then
        table.insert(where, "status = ?"); table.insert(params, self._status)
    end
    if self._actor_id then
        table.insert(where, "actor_id = ?"); table.insert(params, self._actor_id)
    end
    if self._archived == false then
        table.insert(where, "archived = 0")
    elseif self._archived == true then
        table.insert(where, "archived = 1")
    end
    local q = "SELECT * FROM keeper_tasks"
    if #where > 0 then q = q .. " WHERE " .. table.concat(where, " AND ") end
    q = q .. " ORDER BY " .. self._order .. " LIMIT ?"
    table.insert(params, self._limit or 100)
    return q, params
end

function methods:all()
    local db, db_err = get_db()
    if db_err then return nil, db_err end
    local q, params = build_query(self)
    local rows, qerr = db:query(q, params)
    db:release()
    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    return decode_rows(rows), nil
end

function methods:one()
    local c = self:_copy(); c._limit = 1
    local rows, err = c:all()
    if err then return nil, err end
    if not rows or #rows == 0 then return nil, nil end
    return rows[1], nil
end

function methods:count()
    local rows, err = self:all()
    if err then return nil, err end
    return #(rows or {}), nil
end

function task_reader.get_task(task_id)
    if not task_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": task_id" end
    local db, err = get_db()
    if err then return nil, err end
    local rows, qerr = db:query("SELECT * FROM keeper_tasks WHERE task_id = ? LIMIT 1", { task_id })
    db:release()
    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    if not rows or #rows == 0 then return nil, consts.ERRORS.NOT_FOUND end
    return decode_metadata(rows[1]), nil
end

return task_reader
