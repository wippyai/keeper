local sql = require("sql")
local json = require("json")
local uuid = require("uuid")
local time = require("time")
local consts = require("consts")

local M = {}

-- ============================================================================
-- Connection helper
-- ============================================================================

local function get_db()
    local db, err = sql.get(consts.DATABASE.RESOURCE_ID)
    if err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(err) end
    return db, nil
end

local function now_rfc3339()
    return time.now():format("2006-01-02T15:04:05Z")
end

local function new_id()
    local id, err = uuid.v7()
    if err then return nil, err end
    return id, nil
end

-- ============================================================================
-- Changesets
-- ============================================================================

-- Row -> normalized table (strips NULLs, returns consistent shape)
local function workspace_from_row(row)
    if not row then return nil end
    return {
        changeset_id     = row.changeset_id,
        kind             = row.kind,
        title            = row.title,
        description      = row.description,
        actor_id         = row.actor_id,
        session_id       = row.session_id,
        parent_workspace = row.parent_workspace,
        state            = row.state,
        state_reason     = row.state_reason,
        state_branch     = row.state_branch,
        scratch_fs_path  = row.scratch_fs_path,
        baseline_version = row.baseline_version,
        baseline_fs_hash = row.baseline_fs_hash,
        head_version     = row.head_version,
        head_fs_hash     = row.head_fs_hash,
        task_id          = row.task_id,
        locked_by        = row.locked_by,
        locked_at        = row.locked_at,
        created_at       = row.created_at,
        updated_at       = row.updated_at,
        closed_at        = row.closed_at,
    }
end

-- query_workspaces runs a SELECT against keeper_changesets, maps rows via
-- workspace_from_row, and handles db acquire/release + DB_ERROR wrapping.
local function query_workspaces(query, params)
    local db, err = sql.get(consts.DATABASE.RESOURCE_ID)
    if err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(err) end
    local rows, qerr = db:query(query, params)
    db:release()
    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    local result = {}
    for _, row in ipairs(rows or {}) do
        table.insert(result, workspace_from_row(row))
    end
    return result, nil
end

-- Create a new workspace. Required args: title, kind, state_branch, scratch_fs_path,
-- baseline_version, baseline_fs_hash. Optional: description, actor_id, session_id,
-- parent_workspace, changeset_id (caller-supplied for determinism).
function M.create_changeset(args)
    if not args.title or args.title == "" then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": title"
    end
    if not args.kind then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": kind"
    end
    if not args.state_branch then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": state_branch"
    end
    if not args.scratch_fs_path then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": scratch_fs_path"
    end
    if not args.baseline_version then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": baseline_version"
    end
    if not args.baseline_fs_hash then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": baseline_fs_hash"
    end

    local db, err = get_db()
    if err then return nil, err end

    local changeset_id = args.changeset_id
    if not changeset_id then
        changeset_id, err = new_id()
        if err then
            db:release()
            return nil, err
        end
    end

    local now = now_rfc3339()
    local _, exec_err = db:execute([[
        INSERT INTO keeper_changesets (
            changeset_id, kind, title, description,
            actor_id, session_id, parent_workspace, task_id,
            state, state_reason, state_branch, scratch_fs_path,
            baseline_version, baseline_fs_hash,
            head_version, head_fs_hash,
            created_at, updated_at, closed_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, NULL, ?, ?, NULL)
    ]], {
        changeset_id,
        args.kind,
        args.title,
        args.description,
        args.actor_id,
        args.session_id,
        args.parent_workspace,
        args.task_id,
        consts.STATES.OPEN,
        nil, -- state_reason
        args.state_branch,
        args.scratch_fs_path,
        args.baseline_version,
        args.baseline_fs_hash,
        now,
        now,
    })

    db:release()
    if exec_err then
        return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err)
    end

    return M.get_changeset(changeset_id)
end

function M.get_changeset(changeset_id)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query([[
        SELECT * FROM keeper_changesets WHERE changeset_id = ? LIMIT 1
    ]], { changeset_id })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    if not rows or #rows == 0 then return nil, consts.ERRORS.NOT_FOUND end

    return workspace_from_row(rows[1]), nil
end

-- List workspaces with optional filters: state, actor_id, session_id, kind, limit.
function M.list_changesets(opts)
    opts = opts or {}
    local where = {}
    local params = {}

    if opts.state then
        table.insert(where, "state = ?")
        table.insert(params, opts.state)
    end
    if opts.actor_id then
        table.insert(where, "actor_id = ?")
        table.insert(params, opts.actor_id)
    end
    if opts.session_id then
        table.insert(where, "session_id = ?")
        table.insert(params, opts.session_id)
    end
    if opts.kind then
        table.insert(where, "kind = ?")
        table.insert(params, opts.kind)
    end

    local query = "SELECT * FROM keeper_changesets"
    if #where > 0 then
        query = query .. " WHERE " .. table.concat(where, " AND ")
    end
    query = query .. " ORDER BY created_at DESC LIMIT ?"
    table.insert(params, opts.limit or 100)

    return query_workspaces(query, params)
end

-- Returns changesets in live states (editing, review, rejected) whose
-- updated_at is older than now - ttl_seconds. The 'open' state is handled
-- by list_empty_open_changesets (2h) and list_abandoned_open_changesets
-- (48h) with dedicated reasons, so it is excluded here.
function M.list_stale_changesets(ttl_seconds, limit)
    ttl_seconds = tonumber(ttl_seconds)
    if not ttl_seconds or ttl_seconds <= 0 then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": ttl_seconds"
    end
    return query_workspaces([[
        SELECT * FROM keeper_changesets
        WHERE state IN (?, ?, ?)
          AND datetime(updated_at) < datetime('now', ? || ' seconds')
          AND NOT EXISTS (
              SELECT 1 FROM keeper_tasks t
              WHERE t.task_id = keeper_changesets.task_id
                AND t.archived = 0
                AND t.status IN ('active', 'waiting_for_user', 'error')
          )
        ORDER BY updated_at ASC
        LIMIT ?
    ]], {
        consts.STATES.EDITING,
        consts.STATES.REVIEW,
        consts.STATES.REJECTED,
        "-" .. tostring(ttl_seconds),
        tonumber(limit) or 50,
    })
end

-- Returns 'open'-state changesets past ttl_seconds regardless of overlay
-- content. Complements list_empty_open_changesets: agents that touched a
-- branch (overlay entries present) but never transitioned to 'editing'
-- also need cleanup, otherwise they sit until STALE_TTL (7d). Uses
-- created_at instead of updated_at so set_branch resumes don't mask
-- abandonment — the 'open' state never progresses for a live workspace,
-- so its age is what matters.
function M.list_abandoned_open_changesets(ttl_seconds, limit)
    ttl_seconds = tonumber(ttl_seconds)
    if not ttl_seconds or ttl_seconds <= 0 then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": ttl_seconds"
    end
    return query_workspaces([[
        SELECT * FROM keeper_changesets
        WHERE state = ?
          AND datetime(created_at) < datetime('now', ? || ' seconds')
          AND NOT EXISTS (
              SELECT 1 FROM keeper_tasks t
              WHERE t.task_id = keeper_changesets.task_id
                AND t.archived = 0
                AND t.status IN ('active', 'waiting_for_user', 'error')
          )
        ORDER BY created_at ASC
        LIMIT ?
    ]], {
        consts.STATES.OPEN,
        "-" .. tostring(ttl_seconds),
        tonumber(limit) or 50,
    })
end

-- Returns 'open'-state changesets older than ttl_seconds that have zero
-- overlay entries, zero scratch fs content, zero fs deletes, and zero
-- journal rows. These are workspaces that were created (usually by
-- set_branch) but never received a single edit. The janitor drops them
-- on a shorter cadence than the full stale sweep because they carry no
-- work and should not linger in the UI.
function M.list_empty_open_changesets(ttl_seconds, limit)
    ttl_seconds = tonumber(ttl_seconds)
    if not ttl_seconds or ttl_seconds <= 0 then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": ttl_seconds"
    end
    return query_workspaces([[
        SELECT cs.* FROM keeper_changesets cs
        WHERE cs.state = ?
          AND datetime(cs.updated_at) < datetime('now', ? || ' seconds')
          AND NOT EXISTS (
              SELECT 1 FROM keeper_tasks t
              WHERE t.task_id = cs.task_id
                AND t.archived = 0
                AND t.status IN ('active', 'waiting_for_user', 'error')
          )
          AND NOT EXISTS (SELECT 1 FROM keeper_overlay_entries oe WHERE oe.branch = cs.state_branch)
          AND NOT EXISTS (SELECT 1 FROM keeper_changeset_fs_content fc WHERE fc.changeset_id = cs.changeset_id)
          AND NOT EXISTS (SELECT 1 FROM keeper_changeset_fs_deletes fd WHERE fd.changeset_id = cs.changeset_id)
          AND NOT EXISTS (SELECT 1 FROM keeper_changeset_changes ch WHERE ch.changeset_id = cs.changeset_id)
        ORDER BY cs.updated_at ASC
        LIMIT ?
    ]], {
        consts.STATES.OPEN,
        "-" .. tostring(ttl_seconds),
        tonumber(limit) or 50,
    })
end

-- Returns the live (open or editing) changeset whose state_branch matches the
-- supplied overlay branch name, or nil. Used by set_branch to resume an
-- existing workspace when the agent switches back to a branch name.
function M.find_live_by_branch(state_branch)
    if not state_branch or state_branch == "" then return nil end
    local db, err = get_db()
    if err then return nil end
    local rows, qerr = db:query([[
        SELECT * FROM keeper_changesets
        WHERE state_branch = ? AND state IN (?, ?)
        ORDER BY created_at DESC LIMIT 1
    ]], { state_branch, consts.STATES.OPEN, consts.STATES.EDITING })
    db:release()
    if qerr or not rows or #rows == 0 then return nil end
    return workspace_from_row(rows[1])
end

-- Returns true when the task has at least one merged changeset,
-- regardless of kind. kind=SESSION is the normal path, but rejected session
-- cs's can leave merged sibling cs's on the same branch (manual, forked); a
-- merge is still a merge and the flow must recognise it as terminal progress.
function M.has_merged_for_task(task_id)
    if not task_id or task_id == "" then return false end
    local db, err = get_db()
    if err then return false end
    local rows, qerr = db:query([[
        SELECT 1 FROM keeper_changesets
        WHERE task_id = ? AND state = ?
        LIMIT 1
    ]], { task_id, consts.STATES.MERGED })
    db:release()
    if qerr or not rows then return false end
    return #rows > 0
end

-- Returns every changeset attached to a task (any state, any kind). Used by
-- verification paths that need to inspect the full history of changes a task
-- has produced — e.g. the test-phase screenshot gate checks whether any
-- changeset on the task touched frontend/applications/**.
function M.changesets_for_task(task_id)
    if not task_id or task_id == "" then return {} end
    local db, err = get_db()
    if err then return {} end
    local rows, qerr = db:query([[
        SELECT * FROM keeper_changesets WHERE task_id = ? ORDER BY created_at ASC
    ]], { task_id })
    db:release()
    if qerr or not rows then return {} end
    local out = {}
    for _, r in ipairs(rows) do table.insert(out, workspace_from_row(r)) end
    return out
end

-- Returns the active (not terminal) session changeset for a task, or nil.
-- Excludes DROPPED, MERGED, and REJECTED so a push failure on the previous
-- cs forces flow.spawn to auto-fork a fresh session cs with a new branch
-- instead of handing the agent a zombie workspace.
function M.active_for_task(task_id)
    if not task_id then return nil end
    local db, err = get_db()
    if err then return nil end
    local rows, qerr = db:query([[
        SELECT * FROM keeper_changesets
        WHERE task_id = ? AND kind = ? AND state NOT IN (?, ?, ?)
        ORDER BY created_at DESC LIMIT 1
    ]], {
        task_id,
        consts.KINDS.SESSION,
        consts.STATES.DROPPED,
        consts.STATES.MERGED,
        consts.STATES.REJECTED,
    })
    db:release()
    if qerr or not rows or #rows == 0 then return nil end
    return workspace_from_row(rows[1])
end

-- Returns true when the supplied branch already hosted a changeset that
-- reached a terminal state (merged, rejected, dropped). Used by open_or_resume
-- to refuse recycling a consumed branch into a fresh cs — one of the
-- loop-killer bugs where a rejected session cs left the branch open for
-- orphan manual cs's with no task_id.
function M.has_terminal_by_branch(state_branch)
    if not state_branch or state_branch == "" then return false end
    local db, err = get_db()
    if err then return false end
    local rows, qerr = db:query([[
        SELECT state FROM keeper_changesets
        WHERE state_branch = ? AND state IN (?, ?, ?)
        ORDER BY updated_at DESC LIMIT 1
    ]], {
        state_branch,
        consts.STATES.MERGED,
        consts.STATES.REJECTED,
        consts.STATES.DROPPED,
    })
    db:release()
    if qerr or not rows or #rows == 0 then return false, nil end
    return true, rows[1].state
end

-- Update state + state_reason + updated_at atomically. Caller must validate transition first.
function M.update_state(changeset_id, new_state, reason)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not new_state then return nil, consts.ERRORS.MISSING_REQUIRED .. ": new_state" end

    local db, err = get_db()
    if err then return nil, err end

    local now = now_rfc3339()
    local closed_at_sql = ""
    local params = { new_state, reason, now }
    if new_state == consts.STATES.MERGED or new_state == consts.STATES.DROPPED then
        closed_at_sql = ", closed_at = ?"
        table.insert(params, now)
    end
    table.insert(params, changeset_id)

    local _, exec_err = db:execute(
        "UPDATE keeper_changesets SET state = ?, state_reason = ?, updated_at = ?" ..
        closed_at_sql .. " WHERE changeset_id = ?",
        params
    )
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return true, nil
end

-- Update head_version and head_fs_hash after successful push.
function M.set_head(changeset_id, head_version, head_fs_hash)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local db, err = get_db()
    if err then return nil, err end

    local _, exec_err = db:execute([[
        UPDATE keeper_changesets
        SET head_version = ?, head_fs_hash = ?, updated_at = ?
        WHERE changeset_id = ?
    ]], { head_version, head_fs_hash, now_rfc3339(), changeset_id })
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return true, nil
end

-- Drop all overlay + fs content rows owned by a changeset in a single tx.
-- Keeps the workspace row, journal (changes), baselines, and merges intact
-- for audit. Caller owns state-machine transition (DROP event) separately.
function M.drop_changeset(changeset_id, state_branch)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not state_branch or state_branch == "" then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": state_branch"
    end

    local db, err = get_db()
    if err then return nil, err end

    local tx, tx_err = db:begin()
    if tx_err then
        db:release()
        return nil, consts.ERRORS.DB_ERROR .. ": begin: " .. tostring(tx_err)
    end

    local steps = {
        {
            sql = "UPDATE keeper_changeset_changes SET status = ?, updated_at = ? WHERE changeset_id = ? AND status = ?",
            args = { consts.CHANGE_STATUSES.REJECTED, now_rfc3339(), changeset_id, consts.CHANGE_STATUSES.PENDING },
            tag = "journal_reject",
        },
        { sql = "DELETE FROM keeper_overlay_chunks_fts WHERE branch = ?",   args = { state_branch },  tag = "fts" },
        { sql = "DELETE FROM keeper_overlay_chunks WHERE branch = ?",       args = { state_branch },  tag = "chunks" },
        { sql = "DELETE FROM keeper_overlay_attributes WHERE branch = ?",   args = { state_branch },  tag = "attributes" },
        { sql = "DELETE FROM keeper_overlay_edges WHERE branch = ?",        args = { state_branch },  tag = "edges" },
        { sql = "DELETE FROM keeper_overlay_entries WHERE branch = ?",      args = { state_branch },  tag = "entries" },
        { sql = "DELETE FROM keeper_changeset_fs_content WHERE changeset_id = ?", args = { changeset_id }, tag = "fs_content" },
        { sql = "DELETE FROM keeper_changeset_fs_deletes WHERE changeset_id = ?", args = { changeset_id }, tag = "fs_deletes" },
    }

    for _, step in ipairs(steps) do
        local _, step_err = tx:execute(step.sql, step.args)
        if step_err then
            tx:rollback()
            db:release()
            return nil, "drop_changeset: " .. step.tag .. ": " .. tostring(step_err)
        end
    end

    local _, commit_err = tx:commit()
    db:release()
    if commit_err then return nil, consts.ERRORS.DB_ERROR .. ": commit: " .. tostring(commit_err) end
    return true, nil
end

-- ============================================================================
-- Changes (journal — written only for drift, conflicts, merges, push outcomes)
-- ============================================================================

local function change_from_row(row)
    if not row then return nil end
    return {
        change_id     = row.change_id,
        changeset_id  = row.changeset_id,
        sequence      = tonumber(row.sequence),
        category      = row.category,
        op            = row.op,
        target        = row.target,
        baseline_hash = row.baseline_hash,
        current_hash  = row.current_hash,
        source        = row.source,
        status        = row.status,
        conflict_with = row.conflict_with,
        detected_at   = row.detected_at,
        created_at    = row.created_at,
        updated_at    = row.updated_at,
    }
end

-- Record a change row. Used by drift scan, merge, push outcome recorder — NOT by routine edits.
function M.record_change(args)
    if not args.category then return nil, consts.ERRORS.MISSING_REQUIRED .. ": category" end
    if not args.op then return nil, consts.ERRORS.MISSING_REQUIRED .. ": op" end
    if not args.target then return nil, consts.ERRORS.MISSING_REQUIRED .. ": target" end
    if not args.source then return nil, consts.ERRORS.MISSING_REQUIRED .. ": source" end
    if not args.status then return nil, consts.ERRORS.MISSING_REQUIRED .. ": status" end

    local db, err = get_db()
    if err then return nil, err end

    local change_id, id_err = new_id()
    if id_err then
        db:release()
        return nil, id_err
    end

    -- next sequence for this workspace (0 for unattributed rows)
    local seq = 0
    if args.changeset_id then
        local rows, qerr = db:query([[
            SELECT COALESCE(MAX(sequence), 0) + 1 AS next_seq
            FROM keeper_changeset_changes
            WHERE changeset_id = ?
        ]], { args.changeset_id })
        if qerr then
            db:release()
            return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr)
        end
        seq = tonumber(rows[1].next_seq) or 1
    end

    local now = now_rfc3339()
    local _, exec_err = db:execute([[
        INSERT INTO keeper_changeset_changes (
            change_id, changeset_id, sequence,
            category, op, target,
            baseline_hash, current_hash,
            source, status, conflict_with, detected_at,
            created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        change_id,
        args.changeset_id,
        seq,
        args.category,
        args.op,
        args.target,
        args.baseline_hash,
        args.current_hash,
        args.source,
        args.status,
        args.conflict_with,
        args.detected_at,
        now,
        now,
    })
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return change_id, nil
end

function M.get_change(change_id)
    if not change_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": change_id" end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query([[
        SELECT * FROM keeper_changeset_changes WHERE change_id = ? LIMIT 1
    ]], { change_id })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    if not rows or #rows == 0 then return nil, consts.ERRORS.NOT_FOUND end

    return change_from_row(rows[1]), nil
end

-- List recorded changes for a workspace (NOT routine edits — those are computed from the branch diff).
-- Used for: conflicts, drift attribution, merge history, applied/rejected audit.
function M.list_changes_for_changeset(changeset_id, opts)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    opts = opts or {}

    local where = { "changeset_id = ?" }
    local params = { changeset_id }

    if opts.status then
        table.insert(where, "status = ?")
        table.insert(params, opts.status)
    end
    if opts.category then
        table.insert(where, "category = ?")
        table.insert(params, opts.category)
    end

    local query = "SELECT * FROM keeper_changeset_changes WHERE " ..
        table.concat(where, " AND ") ..
        " ORDER BY sequence ASC LIMIT ?"
    table.insert(params, opts.limit or 500)

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query(query, params)
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end

    local result = {}
    for _, row in ipairs(rows or {}) do
        table.insert(result, change_from_row(row))
    end
    return result, nil
end

-- List applied change rows belonging to every MERGED session changeset for a
-- task. Returns the deterministic ground truth of what a task has published to
-- main, so reviewers can enumerate artifacts without guessing via diff. Ordered
-- by merge time ascending, then by sequence within each changeset.
function M.list_applied_for_task(task_id)
    if not task_id or task_id == "" then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": task_id"
    end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query([[
        SELECT ch.*
        FROM keeper_changeset_changes ch
        JOIN keeper_changesets cs ON cs.changeset_id = ch.changeset_id
        WHERE cs.task_id = ?
          AND cs.kind = ?
          AND cs.state = ?
          AND ch.status = ?
        ORDER BY COALESCE(cs.closed_at, cs.updated_at) ASC, ch.sequence ASC
    ]], {
        task_id,
        consts.KINDS.SESSION,
        consts.STATES.MERGED,
        consts.CHANGE_STATUSES.APPLIED,
    })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end

    local result = {}
    for _, row in ipairs(rows or {}) do
        table.insert(result, change_from_row(row))
    end
    return result, nil
end

-- Staged (not yet merged) changes belonging to the task's active overlay.
-- Used by the review phase to verify what the implement phase staged into
-- the overlay changeset before the single end-of-task push runs.
function M.list_staged_for_task(task_id)
    if not task_id or task_id == "" then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": task_id"
    end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query([[
        SELECT ch.*
        FROM keeper_changeset_changes ch
        JOIN keeper_changesets cs ON cs.changeset_id = ch.changeset_id
        WHERE cs.task_id = ?
          AND cs.kind = ?
          AND cs.state NOT IN (?, ?, ?)
        ORDER BY ch.sequence ASC
    ]], {
        task_id,
        consts.KINDS.SESSION,
        consts.STATES.MERGED,
        consts.STATES.DROPPED,
        consts.STATES.REJECTED,
    })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end

    local result = {}
    for _, row in ipairs(rows or {}) do
        table.insert(result, change_from_row(row))
    end
    return result, nil
end

function M.set_change_status(change_id, status)
    if not change_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": change_id" end
    if not status then return nil, consts.ERRORS.MISSING_REQUIRED .. ": status" end

    local db, err = get_db()
    if err then return nil, err end

    local _, exec_err = db:execute([[
        UPDATE keeper_changeset_changes
        SET status = ?, updated_at = ?
        WHERE change_id = ?
    ]], { status, now_rfc3339(), change_id })
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return true, nil
end

-- Upsert a pending journal row for an in-progress edit. Invariant: at most one
-- pending row per (changeset_id, category, target) — enforced by the partial
-- unique index. If a pending row exists for the triple, bump its op and
-- current_hash; otherwise insert a new row sourced as MATERIALIZED.
function M.upsert_pending_change(args)
    if not args.changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not args.category then return nil, consts.ERRORS.MISSING_REQUIRED .. ": category" end
    if not args.op then return nil, consts.ERRORS.MISSING_REQUIRED .. ": op" end
    if not args.target then return nil, consts.ERRORS.MISSING_REQUIRED .. ": target" end

    local db, err = get_db()
    if err then return nil, err end

    local existing, qerr = db:query([[
        SELECT change_id FROM keeper_changeset_changes
        WHERE changeset_id = ? AND category = ? AND target = ? AND status = ?
        LIMIT 1
    ]], { args.changeset_id, args.category, args.target, consts.CHANGE_STATUSES.PENDING })
    if qerr then
        db:release()
        return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr)
    end

    local now = now_rfc3339()
    if existing and #existing > 0 then
        local change_id = existing[1].change_id
        local _, uerr = db:execute([[
            UPDATE keeper_changeset_changes
            SET op = ?, current_hash = ?, baseline_hash = COALESCE(?, baseline_hash), updated_at = ?
            WHERE change_id = ?
        ]], { args.op, args.current_hash, args.baseline_hash, now, change_id })
        db:release()
        if uerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(uerr) end
        return change_id, nil
    end

    local seq_rows, seq_err = db:query([[
        SELECT COALESCE(MAX(sequence), 0) + 1 AS next_seq
        FROM keeper_changeset_changes WHERE changeset_id = ?
    ]], { args.changeset_id })
    if seq_err then
        db:release()
        return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(seq_err)
    end

    local change_id, id_err = new_id()
    if id_err then
        db:release()
        return nil, id_err
    end

    local _, ierr = db:execute([[
        INSERT INTO keeper_changeset_changes (
            change_id, changeset_id, sequence,
            category, op, target,
            baseline_hash, current_hash,
            source, status, conflict_with, detected_at,
            created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, NULL, ?, ?)
    ]], {
        change_id,
        args.changeset_id,
        tonumber(seq_rows[1].next_seq) or 1,
        args.category,
        args.op,
        args.target,
        args.baseline_hash,
        args.current_hash,
        consts.SOURCES.MATERIALIZED,
        consts.CHANGE_STATUSES.PENDING,
        now,
        now,
    })
    db:release()
    if ierr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(ierr) end
    return change_id, nil
end

-- Flip a pending row to applied on push commit, stamping source=pushed and the
-- published content hash. Returns true when a pending row was upgraded, false
-- when no pending row matched (caller decides whether to INSERT a fresh
-- applied row or treat it as a no-op).
function M.apply_pending_change(changeset_id, category, target, op, current_hash)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not category then return nil, consts.ERRORS.MISSING_REQUIRED .. ": category" end
    if not target then return nil, consts.ERRORS.MISSING_REQUIRED .. ": target" end
    if not op then return nil, consts.ERRORS.MISSING_REQUIRED .. ": op" end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query([[
        SELECT change_id FROM keeper_changeset_changes
        WHERE changeset_id = ? AND category = ? AND target = ? AND status = ?
        LIMIT 1
    ]], { changeset_id, category, target, consts.CHANGE_STATUSES.PENDING })
    if qerr then
        db:release()
        return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr)
    end
    if not rows or #rows == 0 then
        db:release()
        return false, nil
    end

    local _, uerr = db:execute([[
        UPDATE keeper_changeset_changes
        SET op = ?, current_hash = COALESCE(?, current_hash),
            source = ?, status = ?, updated_at = ?
        WHERE change_id = ?
    ]], {
        op,
        current_hash,
        consts.SOURCES.PUSHED,
        consts.CHANGE_STATUSES.APPLIED,
        now_rfc3339(),
        rows[1].change_id,
    })
    db:release()
    if uerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(uerr) end
    return true, nil
end

-- Symmetric undo for apply_pending_change. After integrate's handler chain
-- fails and the registry is rolled back, the previously-applied journal rows
-- become liars: they say "this push landed" while main no longer carries
-- those entries. Flipping them back to pending makes the next implement
-- bounce's edit + push naturally re-upgrade them. Without this, the publish
-- writes brand-new applied rows alongside the orphaned ones, leaving the
-- changeset bookkeeping in an inconsistent state and making `apply_pending`
-- match nothing on the rebound. Returns count of rows reset.
function M.reset_applied_to_pending(changeset_id)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local db, err = get_db()
    if err then return nil, err end

    local _, uerr = db:execute([[
        UPDATE keeper_changeset_changes
        SET status = ?,
            source = ?,
            updated_at = ?
        WHERE changeset_id = ?
          AND status = ?
          AND source = ?
    ]], {
        consts.CHANGE_STATUSES.PENDING,
        consts.SOURCES.MATERIALIZED,
        now_rfc3339(),
        changeset_id,
        consts.CHANGE_STATUSES.APPLIED,
        consts.SOURCES.PUSHED,
    })
    if uerr then
        db:release()
        return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(uerr)
    end

    local count_rows, cerr = db:query([[
        SELECT COUNT(*) AS n FROM keeper_changeset_changes
        WHERE changeset_id = ? AND status = ?
    ]], { changeset_id, consts.CHANGE_STATUSES.PENDING })
    db:release()
    if cerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(cerr) end
    return tonumber(count_rows and count_rows[1] and count_rows[1].n) or 0, nil
end

-- Bulk flip all remaining pending rows for a changeset to a terminal status.
-- Push uses this with CHANGE_STATUSES.SUPERSEDED to close net-zero intents
-- after applying the actual diff. Drop uses it with CHANGE_STATUSES.REJECTED.
function M.close_pending_changes(changeset_id, terminal_status)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if terminal_status ~= consts.CHANGE_STATUSES.SUPERSEDED
        and terminal_status ~= consts.CHANGE_STATUSES.REJECTED then
        return nil, "close_pending_changes: terminal_status must be superseded or rejected"
    end

    local db, err = get_db()
    if err then return nil, err end

    local _, uerr = db:execute([[
        UPDATE keeper_changeset_changes
        SET status = ?, updated_at = ?
        WHERE changeset_id = ? AND status = ?
    ]], {
        terminal_status,
        now_rfc3339(),
        changeset_id,
        consts.CHANGE_STATUSES.PENDING,
    })
    db:release()
    if uerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(uerr) end
    return true, nil
end

-- ============================================================================
-- Baselines (append-only snapshot log)
-- ============================================================================

function M.record_baseline(args)
    if not args.changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not args.registry_version then return nil, consts.ERRORS.MISSING_REQUIRED .. ": registry_version" end
    if not args.fs_tree_hash then return nil, consts.ERRORS.MISSING_REQUIRED .. ": fs_tree_hash" end
    if not args.reason then return nil, consts.ERRORS.MISSING_REQUIRED .. ": reason" end

    local db, err = get_db()
    if err then return nil, err end

    local baseline_id, id_err = new_id()
    if id_err then
        db:release()
        return nil, id_err
    end

    local _, exec_err = db:execute([[
        INSERT INTO keeper_changeset_baselines (
            baseline_id, changeset_id, registry_version, fs_tree_hash, captured_at, reason
        ) VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        baseline_id,
        args.changeset_id,
        args.registry_version,
        args.fs_tree_hash,
        now_rfc3339(),
        args.reason,
    })
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return baseline_id, nil
end

function M.latest_baseline(changeset_id)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query([[
        SELECT * FROM keeper_changeset_baselines
        WHERE changeset_id = ?
        ORDER BY captured_at DESC
        LIMIT 1
    ]], { changeset_id })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    if not rows or #rows == 0 then return nil, consts.ERRORS.NOT_FOUND end

    return rows[1], nil
end

-- Return the latest baseline row matching `reason` for `changeset_id`, or nil.
-- Used to find the phase-spawn anchor for a revert.
function M.latest_baseline_by_reason(changeset_id, reason)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not reason then return nil, consts.ERRORS.MISSING_REQUIRED .. ": reason" end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query([[
        SELECT * FROM keeper_changeset_baselines
        WHERE changeset_id = ? AND reason = ?
        ORDER BY captured_at DESC
        LIMIT 1
    ]], { changeset_id, reason })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    if not rows or #rows == 0 then return nil, nil end

    return rows[1], nil
end

-- Revert composition rows created after `since_at` for `changeset_id`.
--
-- Scope (intentionally narrow — correct for the normal case where a phase starts
-- with no prior in-phase edits and all new rows have created_at > since_at):
--   - keeper_overlay_entries on `state_branch` with created_at > since_at are
--     deleted. FK CASCADE removes their chunks/attributes/edges.
--   - keeper_overlay_chunks_fts: rows for the deleted entries are purged
--     (non-FK virtual table).
--   - keeper_overlay_chunks on `state_branch` with created_at > since_at but
--     whose parent entry survived are deleted. Recovers in-phase chunks
--     appended to pre-existing entries.
--   - keeper_overlay_edges on `state_branch` with created_at > since_at are
--     deleted. Recovers in-phase edges added to pre-existing entries.
--   - keeper_changeset_fs_content with updated_at > since_at → row deleted.
--   - keeper_changeset_fs_deletes with deleted_at > since_at → row deleted.
--   - keeper_changeset_changes with created_at > since_at and status='pending'
--     → marked 'reverted' (audit preserved, distinct from push-time 'rejected').
--
-- Known gaps (no per-write history available):
--   - overlay_attributes have no timestamps; attrs added in-phase to a
--     pre-existing entry are NOT reverted. Safe when attrs cascade with the
--     entry deletion, which is the normal path.
--   - fs_content rows that existed before since_at and were updated in-phase
--     are deleted, losing pre-phase content. Acceptable because the overlay
--     branch is typically empty before an implement phase.
--
-- Returns (stats, nil) on success, (nil, error) otherwise.
function M.revert_to_phase_baseline(changeset_id, state_branch, since_at)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not state_branch then return nil, consts.ERRORS.MISSING_REQUIRED .. ": state_branch" end
    if not since_at then return nil, consts.ERRORS.MISSING_REQUIRED .. ": since_at" end

    local db, err = get_db()
    if err then return nil, err end

    local tx, tx_err = db:begin()
    if tx_err then
        db:release()
        return nil, consts.ERRORS.DB_ERROR .. ": begin: " .. tostring(tx_err)
    end

    local stats = {
        entries = 0, chunks = 0, edges = 0,
        fs_content = 0, fs_deletes = 0, journal = 0,
    }

    -- Collect entry ids slated for deletion so we can clean the non-FK FTS table.
    local entry_rows, entry_err = tx:query([[
        SELECT id FROM keeper_overlay_entries
        WHERE branch = ? AND created_at > ?
    ]], { state_branch, since_at })
    if entry_err then
        tx:rollback()
        db:release()
        return nil, "revert: collect entries: " .. tostring(entry_err)
    end

    for _, r in ipairs(entry_rows or {}) do
        local _, fts_err = tx:execute(
            "DELETE FROM keeper_overlay_chunks_fts WHERE branch = ? AND entry_id = ?",
            { state_branch, r.id }
        )
        if fts_err then
            tx:rollback()
            db:release()
            return nil, "revert: fts cleanup: " .. tostring(fts_err)
        end
    end

    local steps = {
        { sql = "DELETE FROM keeper_overlay_entries WHERE branch = ? AND created_at > ?",
          args = { state_branch, since_at }, key = "entries" },
        { sql = "DELETE FROM keeper_overlay_chunks  WHERE branch = ? AND created_at > ?",
          args = { state_branch, since_at }, key = "chunks" },
        { sql = "DELETE FROM keeper_overlay_edges   WHERE branch = ? AND created_at > ?",
          args = { state_branch, since_at }, key = "edges" },
        { sql = "DELETE FROM keeper_changeset_fs_content WHERE changeset_id = ? AND updated_at > ?",
          args = { changeset_id, since_at }, key = "fs_content" },
        { sql = "DELETE FROM keeper_changeset_fs_deletes WHERE changeset_id = ? AND deleted_at > ?",
          args = { changeset_id, since_at }, key = "fs_deletes" },
        { sql = "UPDATE keeper_changeset_changes SET status = ?, updated_at = ? " ..
                "WHERE changeset_id = ? AND created_at > ? AND status = ?",
          args = { consts.CHANGE_STATUSES.REVERTED, now_rfc3339(),
                   changeset_id, since_at, consts.CHANGE_STATUSES.PENDING },
          key = "journal" },
    }

    for _, step in ipairs(steps) do
        local res, step_err = tx:execute(step.sql, step.args)
        if step_err then
            tx:rollback()
            db:release()
            return nil, "revert: " .. step.key .. ": " .. tostring(step_err)
        end
        stats[step.key] = (res and res.rows_affected) or 0
    end

    local _, commit_err = tx:commit()
    db:release()
    if commit_err then return nil, consts.ERRORS.DB_ERROR .. ": commit: " .. tostring(commit_err) end
    return stats, nil
end

-- ============================================================================
-- Merge log
-- ============================================================================

function M.log_merge(args)
    if not args.into_changeset then return nil, consts.ERRORS.MISSING_REQUIRED .. ": into_changeset" end
    if not args.change_ids then return nil, consts.ERRORS.MISSING_REQUIRED .. ": change_ids" end
    if not args.resolution then return nil, consts.ERRORS.MISSING_REQUIRED .. ": resolution" end

    local encoded_ids, enc_err = json.encode(args.change_ids)
    if enc_err then return nil, "failed to encode change_ids: " .. tostring(enc_err) end

    local db, err = get_db()
    if err then return nil, err end

    local merge_id, id_err = new_id()
    if id_err then
        db:release()
        return nil, id_err
    end

    local _, exec_err = db:execute([[
        INSERT INTO keeper_changeset_merges (
            merge_id, from_workspace, into_workspace,
            change_ids, conflict_count, resolution, actor_id, at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        merge_id,
        args.from_changeset,
        args.into_changeset,
        encoded_ids,
        args.conflict_count or 0,
        args.resolution,
        args.actor_id,
        now_rfc3339(),
    })
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return merge_id, nil
end

-- ============================================================================
-- FS manifests (content-addressed cache)
-- ============================================================================

function M.store_manifest(tree_hash, root, manifest_table)
    if not tree_hash then return nil, consts.ERRORS.MISSING_REQUIRED .. ": tree_hash" end
    if not root then return nil, consts.ERRORS.MISSING_REQUIRED .. ": root" end
    if not manifest_table then return nil, consts.ERRORS.MISSING_REQUIRED .. ": manifest" end

    local encoded, enc_err = json.encode(manifest_table)
    if enc_err then return nil, "failed to encode manifest: " .. tostring(enc_err) end

    local db, err = get_db()
    if err then return nil, err end

    local _, exec_err = db:execute([[
        INSERT OR REPLACE INTO keeper_fs_manifests (
            tree_hash, root, entry_count, captured_at, manifest
        ) VALUES (?, ?, ?, ?, ?)
    ]], {
        tree_hash,
        root,
        #manifest_table,
        now_rfc3339(),
        encoded,
    })
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return tree_hash, nil
end

function M.load_manifest(tree_hash)
    if not tree_hash then return nil, consts.ERRORS.MISSING_REQUIRED .. ": tree_hash" end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query([[
        SELECT * FROM keeper_fs_manifests WHERE tree_hash = ? LIMIT 1
    ]], { tree_hash })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    if not rows or #rows == 0 then return nil, consts.ERRORS.NOT_FOUND end

    local manifest = rows[1] and rows[1].manifest
    if type(manifest) ~= "string" then return nil, "manifest missing" end
    local decoded, dec_err = json.decode(manifest)
    if dec_err then return nil, "failed to decode manifest: " .. tostring(dec_err) end

    return {
        tree_hash   = rows[1].tree_hash,
        root        = rows[1].root,
        entry_count = tonumber(rows[1].entry_count),
        captured_at = rows[1].captured_at,
        manifest    = decoded,
    }, nil
end

-- ============================================================================
-- FS deletes (per-workspace delete markers — not tombstone files)
-- ============================================================================

function M.record_fs_delete(changeset_id, rel_path, baseline_hash)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not rel_path then return nil, consts.ERRORS.MISSING_REQUIRED .. ": rel_path" end

    local db, err = get_db()
    if err then return nil, err end

    local _, exec_err = db:execute([[
        INSERT OR REPLACE INTO keeper_changeset_fs_deletes (
            changeset_id, rel_path, baseline_hash, deleted_at
        ) VALUES (?, ?, ?, ?)
    ]], { changeset_id, rel_path, baseline_hash or "", now_rfc3339() })
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return true, nil
end

-- Only removes the staged marker (flushed_at IS NULL). Historical rows stay.
function M.unrecord_fs_delete(changeset_id, rel_path)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not rel_path then return nil, consts.ERRORS.MISSING_REQUIRED .. ": rel_path" end

    local db, err = get_db()
    if err then return nil, err end

    local _, exec_err = db:execute([[
        DELETE FROM keeper_changeset_fs_deletes
        WHERE changeset_id = ? AND rel_path = ? AND flushed_at IS NULL
    ]], { changeset_id, rel_path })
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return true, nil
end

-- Staged-only view. Pass include_history=true for the full row set.
function M.list_fs_deletes(changeset_id, include_history)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local db, err = get_db()
    if err then return nil, err end

    local sqlstr = [[
        SELECT rel_path, baseline_hash, deleted_at, flushed_at, prior_content
        FROM keeper_changeset_fs_deletes
        WHERE changeset_id = ?
    ]]
    if not include_history then
        sqlstr = sqlstr .. " AND flushed_at IS NULL"
    end
    sqlstr = sqlstr .. " ORDER BY rel_path ASC"

    local rows, qerr = db:query(sqlstr, { changeset_id })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    return rows or {}, nil
end

-- Flushed (historical) deletes only — the revert source.
function M.list_fs_deletes_flushed(changeset_id)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query([[
        SELECT rel_path, baseline_hash, prior_content, deleted_at, flushed_at
        FROM keeper_changeset_fs_deletes
        WHERE changeset_id = ? AND flushed_at IS NOT NULL
        ORDER BY rel_path ASC
    ]], { changeset_id })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    return rows or {}, nil
end

-- ============================================================================
-- FS content (DB-backed workspace file storage — replaces staging_fs disk)
-- ============================================================================

-- Stages or updates a row in the pre-flush set. A previously-flushed row for the
-- same (changeset_id, rel_path) is history and would collide on PK, so staging
-- over a flushed row is refused — the caller must open a new changeset.
function M.store_fs_content(changeset_id, rel_path, content, content_hash)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not rel_path then return nil, consts.ERRORS.MISSING_REQUIRED .. ": rel_path" end
    if not content then return nil, consts.ERRORS.MISSING_REQUIRED .. ": content" end

    local db, err = get_db()
    if err then return nil, err end

    local existing, qerr = db:query([[
        SELECT flushed_at FROM keeper_changeset_fs_content
        WHERE changeset_id = ? AND rel_path = ?
        LIMIT 1
    ]], { changeset_id, rel_path })
    if qerr then
        db:release()
        return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr)
    end
    if existing and existing[1] and existing[1].flushed_at then
        db:release()
        return nil, "cannot stage over flushed history row: " .. rel_path
    end

    local _, exec_err = db:execute([[
        INSERT OR REPLACE INTO keeper_changeset_fs_content (
            changeset_id, rel_path, content, content_hash, updated_at
        ) VALUES (?, ?, ?, ?, ?)
    ]], { changeset_id, rel_path, content, content_hash or "", now_rfc3339() })
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return true, nil
end

-- Overlay read: staged content only.
function M.get_fs_content(changeset_id, rel_path)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not rel_path then return nil, consts.ERRORS.MISSING_REQUIRED .. ": rel_path" end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query([[
        SELECT content, content_hash FROM keeper_changeset_fs_content
        WHERE changeset_id = ? AND rel_path = ? AND flushed_at IS NULL
        LIMIT 1
    ]], { changeset_id, rel_path })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    if not rows or #rows == 0 then return nil, nil end
    return rows[1], nil
end

-- Staged-only list. Pass include_history=true for the full set.
function M.list_fs_content(changeset_id, include_history)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local db, err = get_db()
    if err then return nil, err end

    local sqlstr = [[
        SELECT rel_path, content_hash, prior_hash, flushed_at
        FROM keeper_changeset_fs_content
        WHERE changeset_id = ?
    ]]
    if not include_history then
        sqlstr = sqlstr .. " AND flushed_at IS NULL"
    end
    sqlstr = sqlstr .. " ORDER BY rel_path ASC"

    local rows, qerr = db:query(sqlstr, { changeset_id })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    return rows or {}, nil
end

-- Flushed (historical) content only — the revert source.
function M.list_fs_content_flushed(changeset_id)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query([[
        SELECT rel_path, content, content_hash, prior_content, prior_hash, flushed_at
        FROM keeper_changeset_fs_content
        WHERE changeset_id = ? AND flushed_at IS NOT NULL
        ORDER BY rel_path ASC
    ]], { changeset_id })
    db:release()

    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    return rows or {}, nil
end

-- Only drops the staged marker (flushed_at IS NULL). History is preserved.
function M.delete_fs_content(changeset_id, rel_path)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local db, err = get_db()
    if err then return nil, err end

    local _, exec_err = db:execute([[
        DELETE FROM keeper_changeset_fs_content
        WHERE changeset_id = ? AND rel_path = ? AND flushed_at IS NULL
    ]], { changeset_id, rel_path })
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return true, nil
end

-- Total recorded changes for a workspace. Used by flow to detect no-op
-- implement runs (PUSHED with zero new rows).
function M.count_changes(changeset_id)
    if not changeset_id then return 0, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local db, err = get_db()
    if err then return 0, err end

    local rows, qerr = db:query([[
        SELECT COUNT(*) AS c FROM keeper_changeset_changes WHERE changeset_id = ?
    ]], { changeset_id })
    db:release()

    if qerr then return 0, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    return tonumber(rows and rows[1] and rows[1].c) or 0, nil
end

-- ============================================================================
-- Overlay chunk/entry reads (for diff/preserve flows in edit)
-- ============================================================================

function M.read_chunk_text(branch, entry_id, chunk_type)
    local db, err = get_db()
    if err then return nil, err end
    local rows, qerr = db:query([[
        SELECT content FROM keeper_overlay_chunks
        WHERE entry_id = ? AND branch = ? AND chunk_type = ?
    ]], { entry_id, branch, chunk_type })
    db:release()
    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    if not rows or #rows == 0 then return nil, nil end
    return rows[1].content, nil
end

function M.read_entry_kind(branch, entry_id)
    local db, err = get_db()
    if err then return nil, err end
    local rows, qerr = db:query([[
        SELECT kind FROM keeper_overlay_entries
        WHERE id = ? AND branch = ? AND deleted = 0
    ]], { entry_id, branch })
    db:release()
    if qerr then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    if not rows or #rows == 0 then return nil, nil end
    return rows[1].kind, nil
end

-- Run fn(tx) inside a state_db transaction. Commits on success, rolls back on
-- error. fn must return (result, err). All writes to overlay tables should go
-- through this helper so edit-time mutations are atomic.
function M.transact(fn)
    local db, err = get_db()
    if err then return nil, err end
    local tx, tx_err = db:begin()
    if tx_err then
        db:release()
        return nil, consts.ERRORS.DB_ERROR .. ": begin: " .. tostring(tx_err)
    end
    local result, fn_err = fn(tx)
    if fn_err then
        tx:rollback()
        db:release()
        return nil, fn_err
    end
    local _, commit_err = tx:commit()
    db:release()
    if commit_err then return nil, consts.ERRORS.DB_ERROR .. ": commit: " .. tostring(commit_err) end
    return result, nil
end

-- ============================================================================
-- Locking
-- ============================================================================

function M.lock_changeset(changeset_id, locked_by)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end
    if not locked_by or locked_by == "" then return nil, consts.ERRORS.MISSING_REQUIRED .. ": locked_by" end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query("SELECT locked_by FROM keeper_changesets WHERE changeset_id = ?", { changeset_id })
    if qerr then db:release(); return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    if not rows or #rows == 0 then db:release(); return nil, consts.ERRORS.NOT_FOUND end

    local current = rows[1].locked_by
    if current and current ~= "" and current ~= locked_by then
        db:release()
        return nil, consts.ERRORS.LOCKED_BY_OTHER .. ": " .. current
    end

    local now = now_rfc3339()
    local _, exec_err = db:execute(
        "UPDATE keeper_changesets SET locked_by = ?, locked_at = ?, updated_at = ? WHERE changeset_id = ?",
        { locked_by, now, now, changeset_id }
    )
    db:release()
    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return true, nil
end

function M.unlock_changeset(changeset_id, caller_id)
    if not changeset_id then return nil, consts.ERRORS.MISSING_REQUIRED .. ": changeset_id" end

    local db, err = get_db()
    if err then return nil, err end

    local rows, qerr = db:query("SELECT locked_by FROM keeper_changesets WHERE changeset_id = ?", { changeset_id })
    if qerr then db:release(); return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(qerr) end
    if not rows or #rows == 0 then db:release(); return nil, consts.ERRORS.NOT_FOUND end

    local current = rows[1].locked_by
    if not current or current == "" then
        db:release()
        return nil, consts.ERRORS.NOT_LOCKED
    end
    if caller_id and caller_id ~= "" and current ~= caller_id then
        db:release()
        return nil, consts.ERRORS.NOT_LOCK_HOLDER
    end

    local now = now_rfc3339()
    local _, exec_err2 = db:execute(
        "UPDATE keeper_changesets SET locked_by = NULL, locked_at = NULL, updated_at = ? WHERE changeset_id = ?",
        { now, changeset_id }
    )
    db:release()
    if exec_err2 then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err2) end
    return true, nil
end

-- Set or clear the lock on every live (non-dropped, non-merged) changeset owned
-- by a task. Pass nil/empty actor_id to clear the lock. Mirrors the
-- task-scoped lock semantics used by orchestrator spawn + ask_user resume.
function M.set_task_lock(task_id, actor_id)
    if not task_id or task_id == "" then
        return nil, consts.ERRORS.MISSING_REQUIRED .. ": task_id"
    end

    local db, err = get_db()
    if err then return nil, err end

    local exec_err
    if actor_id and actor_id ~= "" then
        local now = now_rfc3339()
        _, exec_err = db:execute(
            "UPDATE keeper_changesets SET locked_by = ?, locked_at = ?, updated_at = ? " ..
            "WHERE task_id = ? AND state NOT IN (?, ?)",
            { actor_id, now, now, task_id, consts.STATES.DROPPED, consts.STATES.MERGED }
        )
    else
        _, exec_err = db:execute(
            "UPDATE keeper_changesets SET locked_by = NULL, locked_at = NULL, updated_at = ? " ..
            "WHERE task_id = ? AND locked_by IS NOT NULL AND state NOT IN (?, ?)",
            { now_rfc3339(), task_id, consts.STATES.DROPPED, consts.STATES.MERGED }
        )
    end
    db:release()

    if exec_err then return nil, consts.ERRORS.DB_ERROR .. ": " .. tostring(exec_err) end
    return true, nil
end

function M.is_locked_by(changeset_id, actor_id)
    if not changeset_id then return false end
    local db, err = get_db()
    if err then return false end

    local rows, qerr = db:query("SELECT locked_by FROM keeper_changesets WHERE changeset_id = ?", { changeset_id })
    db:release()
    if qerr or not rows or #rows == 0 then return false end

    local current = rows[1].locked_by
    if not current or current == "" then return true end
    return current == actor_id
end

return M
