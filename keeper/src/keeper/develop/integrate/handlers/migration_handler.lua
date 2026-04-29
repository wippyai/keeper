-- Ported from module-keeper/src/integrate/handlers/migration_handler.lua.
-- Delegates to wippy.migration:runner for per-target_db grouping; runner owns
-- discovery + execution. Rollback uses runner:rollback with count + allowed_ids.

local registry = require("registry")
local runner_lib = require("runner")
local sql = require("sql")

local function string_list(value: unknown): {string}
    local out = {}
    if type(value) ~= "table" then return out end
    for _, item in ipairs(value) do
        if type(item) == "string" and item ~= "" then table.insert(out, item) end
    end
    return out
end

-- Returns a set of migration ids already recorded as applied on target_db.
-- Swallows errors (returns empty set) so the handler keeps working when the
-- migration-tracking table is missing; runner will initialise it on first use.
local function applied_ids(target_db, wanted_ids)
    local out = {}
    if #wanted_ids == 0 then return out end
    local db, err = sql.get(target_db)
    if err or not db then return out end
    local placeholders = {}
    for i = 1, #wanted_ids do placeholders[i] = "?" end
    local rows, qerr = db:query(
        "SELECT id FROM _migrations WHERE id IN (" .. table.concat(placeholders, ",") .. ")",
        wanted_ids)
    db:release()
    if qerr or not rows then return out end
    for _, r in ipairs(rows) do out[r.id] = true end
    return out
end

local function group_by_target_db(entry_ids: {string})
    local groups: {[string]: {unknown}} = {}
    local group_order: {string} = {}

    for _, entry_id in ipairs(entry_ids) do
        local entry, err = registry.get(entry_id)
        if err then
            return nil, nil, "Failed to get migration " .. entry_id .. ": " .. err
        end

        if not entry.meta or type(entry.meta.target_db) ~= "string" or entry.meta.target_db == "" then
            return nil, nil, "Migration " .. entry_id .. " missing target_db metadata"
        end

        local target_db = entry.meta.target_db

        if not groups[target_db] then
            groups[target_db] = {}
            table.insert(group_order, target_db)
        end

        table.insert(groups[target_db], {
            id = entry_id,
            entry = entry
        })
    end

    return groups, group_order
end

-- Merge per-run runner result into a cumulative shape matching what the
-- handler expects downstream (same keys as a batch run: migrations,
-- skipped_details, migrations_applied/skipped/failed). Only rows whose id
-- is in wanted_ids are kept so unrelated migrations do not leak into the
-- handler's result even when they were reported by the runner.
local function merge_run_result(acc, part, wanted_ids)
    if type(part) ~= "table" then return acc end
    for _, m in ipairs(part.migrations or {}) do
        if wanted_ids[m.id] then
            table.insert(acc.migrations, m)
            if m.status == "applied" or m.status == "reverted" then
                acc.migrations_applied = acc.migrations_applied + 1
            elseif m.status == "error" then
                acc.migrations_failed = acc.migrations_failed + 1
            elseif m.status == "skipped" then
                acc.migrations_skipped = acc.migrations_skipped + 1
            end
        end
    end
    for _, s in ipairs(part.skipped_details or {}) do
        if wanted_ids[s.id] then
            table.insert(acc.skipped_details, s)
        end
    end
    return acc
end

local function execute_database_group(target_db: string, migrations, operation)
    local runner = runner_lib.setup(target_db)
    local migration_ids = {}
    local migration_ids_set = {}
    for _, m in ipairs(migrations) do
        table.insert(migration_ids, m.id)
        migration_ids_set[m.id] = true
    end

    -- runner:run ignores allowed_ids and applies every pending migration;
    -- runner:run_next is the correct path that honours the filter. Loop per
    -- wanted id so the handler only touches what integrate actually pushed.
    local accum = {
        status = "complete",
        migrations_applied = 0,
        migrations_skipped = 0,
        migrations_failed = 0,
        migrations = {},
        skipped_details = {},
    }

    if operation == "up" then
        -- Short-circuit: migrations already recorded as applied on target_db
        -- are idempotent no-ops. Synthesise a skipped row so the handler
        -- treats re-push as success without asking the runner.
        local already = applied_ids(target_db, migration_ids)
        for _, wanted_id in ipairs(migration_ids) do
            if already[wanted_id] then
                table.insert(accum.migrations, {
                    id = wanted_id,
                    status = "skipped",
                    skip_type = "already_applied",
                    reason = "Already applied",
                })
                table.insert(accum.skipped_details, {
                    id = wanted_id,
                    reason = "Already applied",
                    skip_type = "already_applied",
                })
                accum.migrations_skipped = accum.migrations_skipped + 1
            else
                local part = runner:run_next({ allowed_ids = { wanted_id } })
                merge_run_result(accum, part, migration_ids_set)
                if accum.migrations_failed > 0 then break end
            end
        end
    else
        -- Rollback is one-shot; runner:rollback respects allowed_ids.
        local part = runner:rollback({
            count = #migration_ids,
            allowed_ids = migration_ids,
        })
        merge_run_result(accum, part, migration_ids_set)
    end

    return accum, migration_ids_set
end

local function process_results(result, operation, wanted_ids)
    local results = {}
    local applied = {}
    local failed = nil
    local error_details = nil
    local seen = {}

    for _, migration_result in ipairs(result.migrations or {}) do
        local is_wanted = wanted_ids[migration_result.id]
        local success = migration_result.status == "applied" or migration_result.status == "reverted"
        local is_skipped = migration_result.status == "skipped"

        seen[migration_result.id] = true

        local result_entry = {
            id = migration_result.id,
            success = success,
            error = migration_result.error,
            data = {
                operation = operation,
                status = migration_result.status,
                duration = migration_result.duration,
                reason = migration_result.reason,
                description = migration_result.description or migration_result.name
            }
        }

        table.insert(results, result_entry)

        if success and is_wanted then
            table.insert(applied, migration_result.id)
        elseif is_wanted and not is_skipped and not failed then
            failed = {
                id = migration_result.id,
                description = migration_result.description or migration_result.name or "",
                status = migration_result.status or "error"
            }

            if migration_result.error and migration_result.error ~= "" then
                error_details = migration_result.error
            elseif migration_result.reason and migration_result.reason ~= "" then
                error_details = migration_result.reason
            else
                error_details = "Migration failed with status: " .. failed.status
            end
        end
    end

    -- Record skipped-by-runner-filter rows so they appear in the result payload
    -- with a concrete status instead of vanishing. These are IDs the runner
    -- discovered but excluded (e.g. not in allowed_ids when ran with count/tags).
    for _, skipped in ipairs(result.skipped_details or {}) do
        if not seen[skipped.id] then
            seen[skipped.id] = true
            table.insert(results, {
                id = skipped.id,
                success = false,
                error = nil,
                data = {
                    operation = operation,
                    status = "runner_skipped",
                    reason = skipped.reason,
                    description = skipped.name,
                },
            })
        end
    end

    -- Any wanted id that neither applied, skipped, nor appeared in skipped_details
    -- means the runner did not discover it — classic registry-staleness or
    -- meta-mismatch. Treat as a loud failure, not a silent pass.
    if not failed then
        for wanted_id in pairs(wanted_ids) do
            if not seen[wanted_id] then
                failed = {
                    id = wanted_id,
                    description = "",
                    status = "undiscovered",
                }
                error_details = "migration not discovered by runner (registry stale or meta mismatch): "
                    .. wanted_id
                table.insert(results, {
                    id = wanted_id,
                    success = false,
                    error = error_details,
                    data = { operation = operation, status = "undiscovered" },
                })
                break
            end
        end
    end

    return results, applied, failed, error_details
end

local function build_error_message(failed, error_details, applied)
    local parts = {}

    table.insert(parts, error_details)

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
    local entry_ids = string_list(params.entry_ids)

    if #entry_ids == 0 then
        return {}
    end

    local groups, group_order, err = group_by_target_db(entry_ids)
    if err then
        return nil, err
    end

    local all_results = {}
    local all_applied = {}

    for _, target_db in ipairs(group_order) do
        local result, wanted_ids = execute_database_group(target_db, groups[target_db], operation)

        local db_results, applied, failed, error_details = process_results(result, operation, wanted_ids)

        for _, res in ipairs(db_results) do
            table.insert(all_results, res)
        end

        for _, id in ipairs(applied) do
            table.insert(all_applied, id)
        end

        if failed then
            local error_message = build_error_message(failed, error_details, all_applied)
            return nil, error_message
        end
    end

    return all_results
end

return { handler = handler }
