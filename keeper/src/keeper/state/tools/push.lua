-- keeper.state.tools:push
--
-- Pure governance publisher. Lints the branch, drives the changeset to
-- accepted, publishes through state.publish:governance, flushes scratch fs,
-- journals the change, and fires the changeset state-machine transitions.
--
-- No migration / test / build side effects — those are per-kind handlers
-- owned by keeper.develop.integrate:run. On fs-flush failure the registry
-- is restored to the pre-push version so the branch remains publishable.

local audit = require("audit")
local security = require("security")
local materialize = require("materialize")
local governance = require("governance")
local state_client = require("state_client")
local fs_flush = require("fs_flush")
local branch_ctx = require("branch_ctx")
local entry_lib = require("entry_lib")
local gov_consts = require("gov_consts")
local changeset_consts = require("changeset_consts")

local FIRE_TRANSITION_FN   = "keeper.changeset.service:fire_transition"
local DRIVE_TO_ACCEPTED_FN = "keeper.changeset.service:drive_to_accepted"
local RECORD_CHANGES_FN    = "keeper.changeset.service:record_changes"

local resolve_changeset_id = branch_ctx.resolve_changeset_id
local call_service_fn      = branch_ctx.call_service_fn
local load_branch_entries  = entry_lib.load_branch_entries
local classify_changes     = entry_lib.classify_changes

type PushParams = {
    branch?: string,
    base?: string,
    message?: string,
    skip_merge_transition?: boolean,
}

type ChangeJournalRow = {
    changeset_id?: string,
    category: string,
    op: string,
    target: string,
    source: string,
    status: string,
}

local CS_CATEGORIES      = changeset_consts.CATEGORIES
local CS_SOURCES         = changeset_consts.SOURCES
local CS_OPS             = changeset_consts.OPS
local CS_CHANGE_STATUSES = changeset_consts.CHANGE_STATUSES
local REGISTRY_OPS       = gov_consts.REGISTRY_OPERATIONS

local function fire_transition(changeset_id, event, reason, guard_ctx)
    if not changeset_id or changeset_id == "" then return true, nil end
    local _, err = call_service_fn(FIRE_TRANSITION_FN, {
        changeset_id = changeset_id,
        event        = event,
        reason       = reason,
        guard_ctx    = guard_ctx,
    })
    if err then
        return nil, "transition " .. tostring(event) .. " rejected: " .. err
    end
    return true, nil
end

local function drive_to_accepted(changeset_id, pending_count, lint_success)
    if not changeset_id or changeset_id == "" then return true, nil end
    local _, err = call_service_fn(DRIVE_TO_ACCEPTED_FN, {
        changeset_id  = changeset_id,
        pending_count = pending_count,
        lint_success  = lint_success,
        reason        = "push pre-publish drive",
    })
    if err then return nil, err end
    return true, nil
end

local function record_changes(rows: {[integer]: ChangeJournalRow}?, head_changeset_id: string?, head_version: unknown?)
    if (not rows or #rows == 0) and not head_changeset_id then return true, nil end
    local result, err = call_service_fn(RECORD_CHANGES_FN, {
        rows              = rows or {},
        head_changeset_id = head_changeset_id,
        head_version      = head_version and tostring(head_version) or nil,
    })
    if err then return nil, err end
    return result and result.written or 0, nil
end

local function convert_to_changeset(added, deleted, modified)
    local changeset, conversion_errors = {}, {}

    for _, item in ipairs(added) do
        local registry_entry, err = materialize.state_entry_to_registry(item.entry)
        if err then
            table.insert(conversion_errors, { entry_id = item.id,
                error = "Failed to convert added entry: " .. err })
        else
            table.insert(changeset, { kind = REGISTRY_OPS.CREATE, entry = registry_entry })
        end
    end
    for _, item in ipairs(modified) do
        local registry_entry, err = materialize.state_entry_to_registry(item.entry)
        if err then
            table.insert(conversion_errors, { entry_id = item.id,
                error = "Failed to convert modified entry: " .. err })
        else
            table.insert(changeset, { kind = REGISTRY_OPS.UPDATE, entry = registry_entry })
        end
    end
    for _, item in ipairs(deleted) do
        table.insert(changeset, { kind = REGISTRY_OPS.DELETE, entry = { id = item.id } })
    end

    if #conversion_errors > 0 then
        local msg = "Failed to convert some entries:\n"
        for _, e in ipairs(conversion_errors) do
            msg = msg .. "- " .. e.entry_id .. ": " .. e.error .. "\n"
        end
        return nil, msg
    end
    return changeset, nil
end

local function registry_rows_from_ops(changeset_id: string?, ops): {[integer]: ChangeJournalRow}
    local rows: {[integer]: ChangeJournalRow} = {}
    for _, op in ipairs(ops) do
        local entry = type(op.entry) == "table" and op.entry or {}
        local registry_op = tostring(op.kind or REGISTRY_OPS.CREATE)
        local category = tostring(CS_CATEGORIES.REGISTRY)
        local source   = tostring(CS_SOURCES.PUSHED)
        local status   = tostring(CS_CHANGE_STATUSES.APPLIED)
        table.insert(rows, {
            changeset_id = changeset_id,
            category     = category,
            op           = registry_op,
            target       = tostring(entry.id or ""),
            source       = source,
            status       = status,
        })
    end
    return rows
end

local function fs_rows_from_paths(changeset_id: string?, written, deleted): {[integer]: ChangeJournalRow}
    local rows: {[integer]: ChangeJournalRow} = {}
    for _, w in ipairs(written or {}) do
        table.insert(rows, {
            changeset_id = changeset_id,
            category     = tostring(CS_CATEGORIES.FILESYSTEM),
            op           = tostring(CS_OPS.WRITE),
            target       = tostring(w.path or ""),
            source       = tostring(CS_SOURCES.FS_FLUSHED),
            status       = tostring(CS_CHANGE_STATUSES.APPLIED),
        })
    end
    for _, d in ipairs(deleted or {}) do
        table.insert(rows, {
            changeset_id = changeset_id,
            category     = tostring(CS_CATEGORIES.FILESYSTEM),
            op           = tostring(CS_OPS.DELETE),
            target       = tostring(d.path or ""),
            source       = tostring(CS_SOURCES.FS_FLUSHED),
            status       = tostring(CS_CHANGE_STATUSES.APPLIED),
        })
    end
    return rows
end

local function format_result(result, added, modified, deleted, target_branch, base_branch)
    local lines = {
        "=== BRANCH PUSH RESULT ===", "",
        "Branch: " .. target_branch .. " -> " .. base_branch,
        "Changes: +" .. #added .. " ~" .. #modified .. " -" .. #deleted, "",
    }
    if result.version then table.insert(lines, "Registry version: " .. result.version) end
    if result.message then table.insert(lines, "Message: " .. result.message) end
    return table.concat(lines, "\n")
end

local function sync_branch_with_registry(branch, entry_ids)
    if not entry_ids or #entry_ids == 0 then return nil end
    local success, err = state_client.sync_branch(branch, entry_ids)
    if not success then
        return "Warning: Branch sync failed: " .. (err or "unknown error")
    end
    return nil
end

local function do_handler(params: PushParams)
    local actor = security.actor()
    if not actor then return nil, "Authentication required" end
    local user_id = actor:id()

    local target_branch, err = branch_ctx.require_active_branch(params.branch)
    if err then return nil, err end
    if target_branch == "main" then
        return nil, "Cannot push main branch (specify a feature branch)"
    end

    local base_branch = params.base or "main"
    local base_branches   = base_branch == "main" and {"main"} or {base_branch, "main"}
    local target_branches = { target_branch, "main" }

    local base_map, berr = load_branch_entries(base_branches)
    if berr then return nil, "Failed to load base branch: " .. berr end
    local target_map, terr = load_branch_entries(target_branches)
    if terr then return nil, "Failed to load target branch: " .. terr end

    local added, deleted, modified = classify_changes(base_map, target_map)

    -- Drop deletes targeting unmanaged namespaces (gov rejects them).
    local skipped_deletes = {}
    if #deleted > 0 then
        local kept = {}
        for _, item in ipairs(deleted) do
            local id = item.id or ""
            local ns = id:match("^([^:]+):")
            if ns and not gov_consts.is_namespace_managed(ns) then
                table.insert(skipped_deletes, id)
            else
                table.insert(kept, item)
            end
        end
        deleted = kept
    end

    local total_changes = #added + #deleted + #modified
    local changeset_id = resolve_changeset_id(target_branch)
    local has_changeset = changeset_id and changeset_id ~= ""

    if total_changes == 0 then
        if has_changeset then
            local _, drive_err = drive_to_accepted(changeset_id, 0, true)
            if drive_err then
                return nil, "Failed to drive workspace to accepted: " .. tostring(drive_err)
            end
            local _, start_err = fire_transition(changeset_id, "push_start", "fs-only push initiated")
            if start_err then return nil, "Failed to start push: " .. tostring(start_err) end
        end

        local fs_written, fs_deleted, fs_err, written_paths, deleted_paths = fs_flush.flush(changeset_id)
        if fs_err then
            if has_changeset then
                fire_transition(changeset_id, "push_failure",
                    "fs flush failed: " .. tostring(fs_err))
            end
            return nil, "FS flush failed: " .. tostring(fs_err)
        end

        local summary_line = "No registry changes to push from branch '" .. target_branch .. "'"
        if (fs_written + fs_deleted) > 0 then
            summary_line = summary_line ..
                " (flushed " .. fs_written .. " file(s), deleted " .. fs_deleted .. ")"
            local _, rec_err = record_changes(fs_rows_from_paths(changeset_id, written_paths, deleted_paths))
            if rec_err then return nil, "Failed to record fs changes: " .. tostring(rec_err) end
        end
        if #skipped_deletes > 0 then
            summary_line = summary_line ..
                "; skipped " .. #skipped_deletes ..
                " delete(s) in unmanaged namespaces: " ..
                table.concat(skipped_deletes, ", ")
        end

        -- Caller (e.g. integrate/run.lua) may defer the merge transition until
        -- it has verified per-kind side effects (handlers). When skipped, the
        -- changeset stays in `accepted` state and the caller is responsible
        -- for firing push_success / push_failure based on its own validation.
        if has_changeset and not params.skip_merge_transition then
            fire_transition(changeset_id, "push_success", "pushed to main (fs-only)")
        end

        return {
            entry_ids = {}, summary = summary_line, version = nil,
            added = 0, modified = 0, deleted = 0,
            skipped_unmanaged_deletes = skipped_deletes,
            branch = target_branch, base_branch = base_branch,
            fs = { written = fs_written, deleted = fs_deleted,
                   written_paths = written_paths, deleted_paths = deleted_paths,
                   error = fs_err },
        }, nil
    end

    local changeset, cerr = convert_to_changeset(added, deleted, modified)
    if cerr then return nil, cerr end

    local pre_push_version, base_err = governance.current_version()
    if base_err then return nil, "Failed to snapshot registry version: " .. tostring(base_err) end

    if has_changeset then
        local _, drive_err = drive_to_accepted(changeset_id, total_changes, true)
        if drive_err then
            return nil, "Failed to drive workspace to accepted: " .. tostring(drive_err)
        end
        local _, start_err = fire_transition(changeset_id, "push_start", "push initiated")
        if start_err then return nil, "Failed to start push: " .. tostring(start_err) end
    end

    local publish_options = {
        branch      = target_branch,
        base_branch = base_branch,
        user_id     = user_id,
        message     = params.message or ("Push from branch: " .. target_branch),
        request_hil = true,
    }
    local result, perr = governance.publish(changeset, publish_options)
    if perr then
        if has_changeset then
            fire_transition(changeset_id, "push_failure", "publish failed: " .. tostring(perr))
        end
        return nil, "Branch push failed: " .. perr
    end

    local entry_ids = {}
    for _, item in ipairs(added) do table.insert(entry_ids, item.id) end
    for _, item in ipairs(modified) do table.insert(entry_ids, item.id) end

    local fs_written, fs_deleted, fs_err, written_paths, deleted_paths = fs_flush.flush(changeset_id)
    if fs_err then
        -- Registry is published; fs is reverted. Restore registry so the
        -- branch remains publishable on retry.
        local _, restore_err = governance.restore_version(pre_push_version,
            "fs flush failed: " .. tostring(fs_err))
        if has_changeset then
            fire_transition(changeset_id, "push_failure", "fs flush failed: " .. tostring(fs_err))
        end
        return nil, "FS flush failed: " .. tostring(fs_err) ..
            (restore_err and (" (REGISTRY DRIFT: " .. tostring(restore_err) .. ")")
                or " (registry restored)")
    end

    local sync_warning = sync_branch_with_registry(target_branch, entry_ids)

    -- Journal both registry ops + fs ops for the changes surface.
    local journal_rows: {[integer]: ChangeJournalRow} = registry_rows_from_ops(changeset_id, changeset)
    for _, row in ipairs(fs_rows_from_paths(changeset_id, written_paths or {}, deleted_paths or {})) do
        table.insert(journal_rows, row)
    end
    record_changes(journal_rows, changeset_id, result.version)
    -- Caller may defer the merge transition until handler-chain validation
    -- (see params.skip_merge_transition). Without the flag set, push retains
    -- its historical contract: a successful publish merges the changeset.
    if has_changeset and not params.skip_merge_transition then
        fire_transition(changeset_id, "push_success", "pushed to main")
    end

    local output = format_result(result, added, modified, deleted, target_branch, base_branch)
    if sync_warning then output = output .. "\n\n" .. sync_warning end
    if #skipped_deletes > 0 then
        output = output .. "\n\nSkipped " .. #skipped_deletes ..
            " delete(s) in unmanaged namespaces (governance would reject):\n  - " ..
            table.concat(skipped_deletes, "\n  - ")
    end

    return {
        entry_ids = entry_ids, summary = output, version = result.version,
        added = #added, modified = #modified, deleted = #deleted,
        skipped_unmanaged_deletes = skipped_deletes,
        branch = target_branch, base_branch = base_branch,
        baseline_version = pre_push_version,
        fs = { written = fs_written, deleted = fs_deleted,
               written_paths = written_paths, deleted_paths = deleted_paths,
               error = fs_err },
    }, nil
end

local function handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "push",
        discriminator = "push",
        target        = params.branch,
        params        = { branch = params.branch, base = params.base, message = params.message },
        summarise = function(result, err)
            if err then return "push failed: " .. tostring(err) end
            if type(result) == "table" then
                return "pushed v" .. tostring(result.version or "?") ..
                    " (+" .. (result.added or 0) ..
                    " ~" .. (result.modified or 0) ..
                    " -" .. (result.deleted or 0) .. ")"
            end
            return "push done"
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }
