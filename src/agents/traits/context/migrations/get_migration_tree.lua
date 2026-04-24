local ctx = require("ctx")
local state_reader = require("state_reader")
local sql = require("sql")
local migration_repo = require("migration_repo")

local function get_active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return { overlay_branch, "main" }
    end
    return { "main" }
end

local function get_database_types()
    local branches = get_active_branch()
    local db_reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return {}
    end

    db_reader = db_reader:with_kinds("db.sql.sqlite", "db.sql.postgres", "db.sql.mysql")
    local db_entries, err = db_reader:all()
    if err then
        return {}
    end

    local types = {}
    for _, entry in ipairs(db_entries) do
        if entry.kind == "db.sql.sqlite" then
            types[entry.id] = "sqlite"
        elseif entry.kind == "db.sql.postgres" then
            types[entry.id] = "postgres"
        elseif entry.kind == "db.sql.mysql" then
            types[entry.id] = "mysql"
        end
    end

    return types
end

local function check_migration_status(db_id, migration_id)
    local db, err = sql.get(db_id)
    if err then
        return "UNKNOWN"
    end

    local exists, err = migration_repo.table_exists(db)
    if err or not exists then
        db:release()
        return "UNKNOWN"
    end

    local applied, err = migration_repo.is_applied(db, migration_id)
    db:release()

    if err then
        return "UNKNOWN"
    end

    return applied and "APPLIED" or "PENDING"
end

local function handler()
    local branches = get_active_branch()
    local db_types = get_database_types()

    local migrations_reader, err = state_reader.for_branch(unpack(branches))
    if err then
        return "Error: " .. err
    end

    migrations_reader = migrations_reader:with_kinds("function.lua")
        :with_attributes({ ["meta.type"] = "migration" })
        :include_attributes()

    local migrations, err = migrations_reader:all()
    if err then
        return "Error: " .. err
    end

    local db_map = {}

    for _, migration in ipairs(migrations) do
        local target_db = migration.attributes and migration.attributes["meta.target_db"]
        if not target_db or target_db == "" then
            target_db = "UNKNOWN_DATABASE"
        end

        if not db_map[target_db] then
            db_map[target_db] = {
                db_id = target_db,
                db_type = db_types[target_db] or "unknown",
                migrations = {}
            }
        end

        local status = check_migration_status(target_db, migration.id)

        table.insert(db_map[target_db].migrations, {
            id = migration.id,
            description = migration.attributes and migration.attributes["meta.description"] or "",
            timestamp = migration.attributes and migration.attributes["meta.timestamp"] or "",
            status = status
        })
    end

    for _, db_data in pairs(db_map) do
        table.sort(db_data.migrations, function(a, b)
            if a.timestamp ~= "" and b.timestamp ~= "" then
                return a.timestamp < b.timestamp
            end
            return a.id < b.id
        end)
    end

    local sorted_dbs = {}
    for _, db_data in pairs(db_map) do
        table.insert(sorted_dbs, db_data)
    end
    table.sort(sorted_dbs, function(a, b)
        return a.db_id < b.db_id
    end)

    local lines = {}
    table.insert(lines, "DATABASE MIGRATIONS TREE")
    table.insert(lines, "")
    table.insert(lines, "Migration ID format: namespace:migration_name")
    table.insert(lines, "Status values: APPLIED (already run), PENDING (not run yet), UNKNOWN (cannot determine)")
    table.insert(lines, "")

    for _, db_data in ipairs(sorted_dbs) do
        local applied = 0
        for _, m in ipairs(db_data.migrations) do
            if m.status == "APPLIED" then
                applied = applied + 1
            end
        end

        table.insert(lines, "DATABASE: " .. db_data.db_id)
        table.insert(lines, "  Type: " .. db_data.db_type)
        table.insert(lines, "  Status: " .. applied .. " of " .. #db_data.migrations .. " migrations applied")
        table.insert(lines, "  Migrations:")
        table.insert(lines, "")

        for _, m in ipairs(db_data.migrations) do
            table.insert(lines, "    Migration ID: " .. m.id)
            table.insert(lines, "      Status: " .. m.status)

            if m.description ~= "" then
                table.insert(lines, "      Description: " .. m.description)
            end
            if m.timestamp ~= "" then
                table.insert(lines, "      Timestamp: " .. m.timestamp)
            end
            table.insert(lines, "")
        end
    end

    return table.concat(lines, "\n")
end

return { handler = handler }
