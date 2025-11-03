local registry = require("registry")
local runner_lib = require("runner")

local function group_by_target_db(entry_ids)
    local groups = {}
    local group_order = {}

    for _, entry_id in ipairs(entry_ids) do
        local entry, err = registry.get(entry_id)
        if err then
            return nil, "Failed to get migration " .. entry_id .. ": " .. err
        end

        if not entry.meta or not entry.meta.target_db then
            return nil, "Migration " .. entry_id .. " missing target_db metadata"
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

local function execute_database_group(target_db, migrations, operation)
    local runner = runner_lib.setup(target_db)
    local migration_ids = {}
    local migration_ids_set = {}
    for _, m in ipairs(migrations) do
        table.insert(migration_ids, m.id)
        migration_ids_set[m.id] = true
    end

    local result
    if operation == "up" then
        result = runner:run({ allowed_ids = migration_ids })
    else
        result = runner:rollback({ count = #migration_ids, allowed_ids = migration_ids })
    end

    return result, migration_ids_set
end

local function process_results(result, operation, wanted_ids)
    local results = {}
    local applied = {}
    local failed = nil
    local error_details = nil

    for _, migration_result in ipairs(result.migrations or {}) do
        local is_wanted = wanted_ids[migration_result.id]
        local success = migration_result.status == "applied" or migration_result.status == "reverted"
        local is_skipped = migration_result.status == "skipped"

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
    local entry_ids = params.entry_ids or {}

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