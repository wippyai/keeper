local json = require("json")
local sql_dialect = require("sql_dialect")

local M = {}

local function failure(code, message, cause)
    local kinds = { BAD_REQUEST = errors.INVALID, NOT_FOUND = errors.NOT_FOUND,
        CONFLICT = errors.CONFLICT }
    return errors.new({ kind = kinds[code] or errors.INTERNAL,
        message = message, details = { code = code, cause = cause and tostring(cause) or nil } })
end

-- Durable install state and single installer lock management.
--
-- Authority: FINAL-DESIGN-v4.md §12.1 lines 840-843 and ACCEPTANCE-IDS.md (MIG-11).
-- "A batch install takes one installer lock across preflight, migration, drain and publish.
-- An interruption resumes from the recorded step and content hash; it cannot publish
-- a different candidate against partially applied schema. PG and SQLite execute the
-- same ordered steps and postconditions."
--
-- Rules:
-- 1. One installer lock spans all steps.
-- 2. Interruption resumes same candidate hash / recorded step.
-- 3. Different candidate cannot publish against partially applied schema.
-- 4. No pcall; return (value, err).
-- 5. No nested sql.get / contract / process calls in open transaction.

local in_memory_store = {}

local function trim(val)
    return string.match(tostring(val or ""), "^%s*(.-)%s*$") or ""
end

local function now_iso()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function exec_query(db, statement, params)
    if not db or type(db.query) ~= "function" then
        return nil, failure("BAD_REQUEST", "database handle with query method required")
    end
    if sql_dialect and sql_dialect.query then
        local rows, err = sql_dialect.query(db, statement, params or {})
        if err then return nil, failure("DATABASE_FAILED", "database query failed", err) end
        return rows, nil
    end
    local rows, err = db:query(statement, params or {})
    if err then return nil, failure("DATABASE_FAILED", "database query failed", err) end
    return rows, nil
end

local function exec_statement(db, statement, params)
    if not db or type(db.execute) ~= "function" then
        return nil, failure("BAD_REQUEST", "database handle with execute method required")
    end
    if params and #params > 0 and sql_dialect and sql_dialect.bind_postgres_placeholders then
        if sql_dialect.is_postgres and sql_dialect.is_postgres(db) then
            local bound, bind_err = sql_dialect.bind_postgres_placeholders(statement, params)
            if not bound then return nil, failure("DATABASE_FAILED", "database bind failed", bind_err) end
            statement = bound
        end
    end
    local result, err = db:execute(statement, params or {})
    if err then return nil, failure("DATABASE_FAILED", "database statement failed", err) end
    return result, nil
end

function M.ensure(db)
    if not db then
        return true, nil
    end

    local ddl = [[
        CREATE TABLE IF NOT EXISTS keeper_hub_install_state (
            lock_token     TEXT PRIMARY KEY,
            candidate_hash TEXT NOT NULL,
            status         TEXT NOT NULL,
            current_step   TEXT NOT NULL,
            steps_json     TEXT NOT NULL,
            metadata_json  TEXT,
            created_at     TEXT NOT NULL,
            updated_at     TEXT NOT NULL
        )
    ]]
    local _, err = exec_statement(db, ddl, {})
    if err then
        return nil, failure("DATABASE_FAILED", "failed to create keeper_hub_install_state", err)
    end

    -- Both PostgreSQL and SQLite enforce one active row at INSERT time.
    -- An application-level SELECT followed by INSERT cannot provide this guarantee.
    local idx_ddl = [[
        CREATE UNIQUE INDEX IF NOT EXISTS keeper_idx_install_state_active
        ON keeper_hub_install_state ((1))
        WHERE status IN ('in_progress', 'fenced')
    ]]
    local _, idx_err = exec_statement(db, idx_ddl, {})
    if idx_err then
        return nil, failure("DATABASE_FAILED", "failed to create index on keeper_hub_install_state", idx_err)
    end

    return true, nil
end

function M.get_active_install(db)
    if not db then
        for _, rec in pairs(in_memory_store) do
            if rec.status == "in_progress" or rec.status == "fenced" then
                return rec, nil
            end
        end
        return nil, nil
    end

    local query = [[
        SELECT lock_token, candidate_hash, status, current_step, steps_json, metadata_json, created_at, updated_at
        FROM keeper_hub_install_state
        WHERE status IN ('in_progress', 'fenced')
        LIMIT 1
    ]]
    local rows, q_err = exec_query(db, query, {})
    if q_err then
        return nil, failure("DATABASE_FAILED", "failed to query active install", q_err)
    end
    if not rows or #rows == 0 then
        return nil, nil
    end

    local row = rows[1]
    local steps = {}
    if row.steps_json and row.steps_json ~= "" then
        steps = json.decode(row.steps_json) or {}
    end
    local metadata = {}
    if row.metadata_json and row.metadata_json ~= "" then
        metadata = json.decode(row.metadata_json) or {}
    end

    return {
        lock_token = row.lock_token,
        candidate_hash = row.candidate_hash,
        status = row.status,
        current_step = row.current_step,
        steps = steps,
        metadata = metadata,
        created_at = row.created_at,
        updated_at = row.updated_at,
    }, nil
end

function M.begin_install(db, args)
    if type(args) ~= "table" then
        return nil, failure("BAD_REQUEST", "args must be a table")
    end
    local lock_token = trim(args.lock_token)
    if lock_token == "" then
        return nil, failure("BAD_REQUEST", "lock_token is required")
    end
    local candidate_hash = trim(args.candidate_hash)
    if candidate_hash == "" then
        return nil, failure("BAD_REQUEST", "candidate_hash is required")
    end

    if not db then
        local active, active_err = M.get_active_install(nil)
        if active_err then return nil, active_err end
        if active then
            if active.candidate_hash ~= candidate_hash then
                return nil, failure("CONFLICT", "installer lock held by different candidate")
            end
            return {
                resumed = true, status = active.status, lock_token = active.lock_token,
                candidate_hash = active.candidate_hash, current_step = active.current_step,
                steps = active.steps, metadata = active.metadata,
            }, nil
        end
    end

    -- Prepare initial step list
    local initial_steps = {}
    for _, s in ipairs(args.steps or {}) do
        local name = type(s) == "table" and (s.name or s.op or s.label) or tostring(s)
        table.insert(initial_steps, {
            name = name,
            status = "pending",
        })
    end
    local current_step = initial_steps[1] and initial_steps[1].name or "preflight"
    local steps_json = json.encode(initial_steps)
    local metadata_json = json.encode(args.metadata or {})
    local created_at = now_iso()

    if not db then
        local rec = {
            lock_token = lock_token,
            candidate_hash = candidate_hash,
            status = "in_progress",
            current_step = current_step,
            steps = initial_steps,
            metadata = args.metadata or {},
            created_at = created_at,
            updated_at = created_at,
        }
        in_memory_store[lock_token] = rec
        return {
            resumed = false,
            lock_token = lock_token,
            candidate_hash = candidate_hash,
            current_step = current_step,
            steps = initial_steps,
            metadata = args.metadata or {},
        }, nil
    end

    local insert_sql = [[
        INSERT INTO keeper_hub_install_state
        (lock_token, candidate_hash, status, current_step, steps_json, metadata_json, created_at, updated_at)
        VALUES (?, ?, 'in_progress', ?, ?, ?, ?, ?)
        ON CONFLICT DO NOTHING
    ]]
    local insertion, ins_err = exec_statement(db, insert_sql, {
        lock_token, candidate_hash, current_step, steps_json, metadata_json, created_at, created_at,
    })
    if ins_err then
        return nil, failure("DATABASE_FAILED", "failed to record install state", ins_err)
    end
    local active, active_err = M.get_active_install(db)
    if active_err then return nil, active_err end
    if not active then return nil, failure("CONFLICT", "install row was not acquired") end
    if active.candidate_hash ~= candidate_hash then
        return nil, failure("CONFLICT", "installer lock held by different candidate", { active = active.candidate_hash, requested = candidate_hash })
    end
    return {
        resumed = insertion.rows_affected == 0,
        status = active.status,
        lock_token = active.lock_token,
        candidate_hash = active.candidate_hash,
        current_step = active.current_step,
        steps = active.steps,
        metadata = active.metadata,
    }, nil
end

function M.record_step(db, lock_token, step_name, outcome)
    lock_token = trim(lock_token)
    step_name = trim(step_name)
    outcome = outcome or {}
    local updated_at = now_iso()

    if not db then
        local rec = in_memory_store[lock_token]
        if not rec then return nil, failure("NOT_FOUND", "install record not found for lock_token " .. lock_token) end
        rec.current_step = step_name
        rec.updated_at = updated_at
        for _, s in ipairs(rec.steps) do
            if s.name == step_name then
                s.status = outcome.status or "done"
                s.result = outcome.result
                s.error = outcome.error
                s.step_hash = outcome.step_hash
            end
        end
        return rec, nil
    end

    local query = "SELECT steps_json FROM keeper_hub_install_state WHERE lock_token = ?"
    local rows, q_err = exec_query(db, query, { lock_token })
    if q_err or not rows or #rows == 0 then
        return nil, failure(q_err and "DATABASE_FAILED" or "NOT_FOUND", "install record not found", q_err)
    end

    local steps = json.decode(rows[1].steps_json or "[]") or {}
    local found = false
    for _, s in ipairs(steps) do
        if s.name == step_name then
            s.status = outcome.status or "done"
            s.result = outcome.result
            s.error = outcome.error
            s.step_hash = outcome.step_hash
            found = true
            break
        end
    end
    if not found then
        table.insert(steps, {
            name = step_name,
            status = outcome.status or "done",
            result = outcome.result,
            error = outcome.error,
            step_hash = outcome.step_hash,
        })
    end

    local update_sql = [[
        UPDATE keeper_hub_install_state
        SET current_step = ?, steps_json = ?, updated_at = ?
        WHERE lock_token = ?
    ]]
    local _, u_err = exec_statement(db, update_sql, {
        step_name, json.encode(steps), updated_at, lock_token,
    })
    if u_err then
        return nil, failure("DATABASE_FAILED", "failed to update install step", u_err)
    end

    return {
        lock_token = lock_token,
        current_step = step_name,
        steps = steps,
        updated_at = updated_at,
    }, nil
end

function M.complete_install(db, lock_token, result)
    lock_token = trim(lock_token)
    local updated_at = now_iso()

    if not db then
        local rec = in_memory_store[lock_token]
        if rec then
            rec.status = "completed"
            rec.current_step = "done"
            rec.result = result
            rec.updated_at = updated_at
        end
        return true, nil
    end

    local update_sql = [[
        UPDATE keeper_hub_install_state
        SET status = 'completed', current_step = 'done', updated_at = ?
        WHERE lock_token = ? AND status IN ('in_progress', 'fenced')
    ]]
    local updated, err = exec_statement(db, update_sql, { updated_at, lock_token })
    if err or not updated or updated.rows_affected ~= 1 then
        return nil, failure(err and "DATABASE_FAILED" or "CONFLICT", "failed to complete install", err)
    end
    return true, nil
end

function M.fail_install(db, lock_token, err_message)
    lock_token = trim(lock_token)
    local updated_at = now_iso()

    if not db then
        local rec = in_memory_store[lock_token]
        if rec then
            rec.status = "failed"
            rec.error = err_message
            rec.updated_at = updated_at
        end
        return true, nil
    end

    local update_sql = [[
        UPDATE keeper_hub_install_state
        SET status = 'failed', updated_at = ?
        WHERE lock_token = ?
    ]]
    local _, err = exec_statement(db, update_sql, { updated_at, lock_token })
    if err then
        return nil, failure("DATABASE_FAILED", "failed to mark install failed", err)
    end
    return true, nil
end

function M.release_lock(db, lock_token)
    lock_token = trim(lock_token)
    local updated_at = now_iso()

    if not db then
        in_memory_store[lock_token] = nil
        return true, nil
    end

    local update_sql = [[
        UPDATE keeper_hub_install_state
        SET status = 'released', updated_at = ?
        WHERE lock_token = ?
    ]]
    local _, err = exec_statement(db, update_sql, { updated_at, lock_token })
    if err then
        return nil, failure("DATABASE_FAILED", "failed to release install lock", err)
    end
    return true, nil
end

function M.record_fence(db, lock_token, fence_data)
    lock_token = trim(lock_token)
    fence_data = fence_data or {}
    local updated_at = now_iso()

    if not db then
        local rec = in_memory_store[lock_token]
        if not rec then
            rec = {
                lock_token = lock_token,
                candidate_hash = fence_data.candidate_hash or "cand_fence",
                status = "fenced",
                current_step = "quiescence",
                steps = {},
                metadata = {},
                created_at = updated_at,
                updated_at = updated_at,
            }
            in_memory_store[lock_token] = rec
        end
        rec.status = "fenced"
        rec.current_step = "quiescence"
        rec.updated_at = updated_at
        rec.metadata = rec.metadata or {}
        rec.metadata.fence = fence_data
        return rec, nil
    end

    local check_query = "SELECT metadata_json FROM keeper_hub_install_state WHERE lock_token = ?"
    local rows, q_err = exec_query(db, check_query, { lock_token })
    if q_err then return nil, failure("DATABASE_FAILED", "failed to read fence owner", q_err) end
    if not rows or #rows == 0 then return nil, failure("NOT_FOUND", "install lock not found for fence") end
    local meta = {}
    if rows and #rows > 0 and rows[1].metadata_json and rows[1].metadata_json ~= "" then
        meta = json.decode(rows[1].metadata_json) or {}
    end
    meta.fence = fence_data

    local update_sql = [[
        UPDATE keeper_hub_install_state
        SET status = 'fenced', current_step = 'quiescence', metadata_json = ?, updated_at = ?
        WHERE lock_token = ? AND status IN ('in_progress', 'fenced')
    ]]
    local updated, u_err = exec_statement(db, update_sql, { json.encode(meta), updated_at, lock_token })
    if u_err or not updated or updated.rows_affected ~= 1 then
        return nil, failure(u_err and "DATABASE_FAILED" or "CONFLICT", "failed to record fence", u_err)
    end

    return {
        lock_token = lock_token,
        status = "fenced",
        current_step = "quiescence",
        metadata = meta,
        updated_at = updated_at,
    }, nil
end

function M.release_fence(db, lock_token)
    lock_token = trim(lock_token)
    local updated_at = now_iso()

    if not db then
        local rec = in_memory_store[lock_token]
        if rec and rec.metadata and rec.metadata.fence then
            rec.metadata.fence.held = false
            rec.metadata.fence.released = true
            rec.metadata.fence.released_at = updated_at
        end
        return true, nil
    end

    local check_query = "SELECT metadata_json FROM keeper_hub_install_state WHERE lock_token = ?"
    local rows, q_err = exec_query(db, check_query, { lock_token })
    if q_err or not rows or #rows == 0 then
        return nil, failure(q_err and "DATABASE_FAILED" or "NOT_FOUND", "fence owner not found", q_err)
    end
    local meta = json.decode(rows[1].metadata_json or "{}") or {}
    if not meta.fence or not meta.fence.held then
        return nil, failure("CONFLICT", "held fence not found for owner")
    end
    meta.fence.held = false
    meta.fence.released = true
    meta.fence.released_at = updated_at
    local update_sql = [[
        UPDATE keeper_hub_install_state
        SET metadata_json = ?, updated_at = ?
        WHERE lock_token = ? AND status = 'fenced'
    ]]
    local updated, update_err = exec_statement(db, update_sql,
        { json.encode(meta), updated_at, lock_token })
    if update_err or not updated or updated.rows_affected ~= 1 then
        return nil, failure(update_err and "DATABASE_FAILED" or "CONFLICT", "failed to release fence", update_err)
    end
    return true, nil
end

function M.reset_in_memory()
    in_memory_store = {}
end

return M
