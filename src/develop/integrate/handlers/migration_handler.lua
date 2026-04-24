-- Migration handler. Groups pushed migration entries by target_db and
-- invokes wippy.migration:runner:run / :rollback per db.
--
-- Adapted from /home/wolfy-j/wippy/keeper/src/integrate/handlers/migration_handler.lua.

local registry = require("registry")
local runner_lib = require("runner")

local function group_by_target_db(entry_ids)
    local groups, order = {}, {}
    for _, entry_id in ipairs(entry_ids) do
        local entry, err = registry.get(entry_id)
        if err then
            return nil, nil, "Failed to get migration " .. entry_id .. ": " .. err
        end
        if not entry.meta or not entry.meta.target_db then
            return nil, nil, "Migration " .. entry_id .. " missing meta.target_db"
        end
        local target_db = entry.meta.target_db
        if not groups[target_db] then
            groups[target_db] = {}
            table.insert(order, target_db)
        end
        table.insert(groups[target_db], { id = entry_id, entry = entry })
    end
    return groups, order
end

local function execute_group(target_db, migrations, operation)
    local runner = runner_lib.setup(target_db)
    local ids, id_set = {}, {}
    for _, m in ipairs(migrations) do
        table.insert(ids, m.id)
        id_set[m.id] = true
    end
    local result
    if operation == "up" then
        -- Run every pending migration for this target_db, not just the ids
        -- freshly pushed in this integrate round. An earlier integrate can
        -- publish a migration entry and return "applied" even though the
        -- runner skipped it (e.g. impl not registered at that moment); the
        -- next integrate that only pushes handler diffs must still execute
        -- the outstanding migration. Filtering by allowed_ids here silently
        -- loses those.
        result = runner:run({})
    else
        -- On rollback keep the scope tight to the ids we were asked to
        -- reverse; the runner's count/allowed_ids pair selects the head of
        -- the applied stack.
        result = runner:rollback({ count = #ids, allowed_ids = ids })
    end
    return result, id_set
end

local function process_results(result, operation, wanted)
    local rows, applied, failed, err_text = {}, {}, nil, nil
    for _, mr in ipairs(result.migrations or {}) do
        local is_wanted = wanted[mr.id]
        local applied_now = mr.status == "applied" or mr.status == "reverted"
        -- Only skip_type == "already_applied" is a benign outcome on re-entry.
        -- Every other "skipped" (skip_type=other, usually a pre-flight error
        -- from wippy.migration:runner such as invalid impl, bad id, or an
        -- unconfigured DB) is a real failure and must flip success=false so
        -- integrate doesn't falsely report green.
        local skipped_ok = mr.status == "skipped" and mr.skip_type == "already_applied"
        local row_success = applied_now or skipped_ok
        if is_wanted then
            table.insert(rows, {
                id      = mr.id,
                success = row_success,
                error   = (not row_success) and (mr.error or mr.reason or "migration skipped: " ..
                            tostring(mr.skip_type or "unknown reason")) or nil,
                data    = {
                    operation   = operation,
                    status      = mr.status,
                    skip_type   = mr.skip_type,
                    duration    = mr.duration,
                    reason      = mr.reason,
                    description = mr.description or mr.name,
                },
            })
        end
        if applied_now and is_wanted then
            table.insert(applied, mr.id)
        elseif is_wanted and not skipped_ok and not failed then
            failed = {
                id          = mr.id,
                description = mr.description or mr.name or "",
                status      = mr.status or "error",
                skip_type   = mr.skip_type,
            }
            if mr.error and mr.error ~= "" then
                err_text = mr.error
            elseif mr.reason and mr.reason ~= "" then
                err_text = mr.reason
            else
                err_text = "Migration failed with status: " .. failed.status ..
                    (failed.skip_type and (" (skip_type=" .. failed.skip_type .. ")") or "")
            end
        end
    end
    return rows, applied, failed, err_text
end

local function build_error(failed, err_text, applied)
    local parts = { err_text or "" }
    if failed.description and failed.description ~= "" then
        table.insert(parts, "[" .. failed.description .. "]")
    end
    if #applied > 0 then
        table.insert(parts, "(applied before failure: " .. table.concat(applied, ", ") .. ";")
        table.insert(parts, "failed at: " .. failed.id .. ")")
    else
        table.insert(parts, "(failed at: " .. failed.id .. ")")
    end
    return table.concat(parts, " ")
end

local function handler(params)
    local operation = params.operation or "up"
    local entry_ids = params.entry_ids or {}
    if #entry_ids == 0 then return {} end

    local groups, order, err = group_by_target_db(entry_ids)
    if err then return nil, err end

    local all_rows, all_applied = {}, {}
    for _, target_db in ipairs(order) do
        local result, wanted = execute_group(target_db, groups[target_db], operation)
        local rows, applied, failed, err_text = process_results(result, operation, wanted)
        for _, r in ipairs(rows) do table.insert(all_rows, r) end
        for _, id in ipairs(applied) do table.insert(all_applied, id) end
        if failed then
            return nil, build_error(failed, err_text, all_applied)
        end
    end
    return all_rows
end

return { handler = handler }
