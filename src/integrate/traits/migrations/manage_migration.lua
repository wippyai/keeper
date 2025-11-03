local json = require("json")
local sql = require("sql")
local time = require("time")
local runner = require("runner")
local repository = require("repository")
local migration_registry = require("migration_registry")

local function handler(input)
    print("=== MANAGE_MIGRATION START ===")
    print("Input:", json.encode(input))

    local migration_id = input.migration_id
    local direction = input.direction or "up"

    print("Migration ID:", migration_id)
    print("Direction:", direction)

    if not migration_id or migration_id == "" then
        print("ERROR: migration_id required")
        return {
            success = false,
            status = "error",
            message = "migration_id required",
            error = "migration_id required"
        }
    end

    if direction ~= "up" and direction ~= "down" then
        print("ERROR: Invalid direction")
        return {
            success = false,
            status = "error",
            message = "direction must be 'up' or 'down'",
            error = "Invalid direction"
        }
    end

    print("Looking up migration in registry...")
    local migration_entry = migration_registry.get(migration_id)
    print("Migration entry:", migration_entry and "FOUND" or "NOT FOUND")

    if not migration_entry then
        print("ERROR: Migration not found in registry")
        return {
            success = false,
            status = "error",
            message = "Migration not found: " .. migration_id,
            migration_id = migration_id,
            direction = direction,
            error = "Migration not found"
        }
    end

    print("Migration meta:", json.encode(migration_entry.meta or {}))

    local database_id = migration_entry.meta and migration_entry.meta.target_db
    print("Database ID:", database_id)

    if not database_id or database_id == "" then
        print("ERROR: No target_db in migration metadata")
        return {
            success = false,
            status = "error",
            message = "Migration missing target_db in metadata",
            migration_id = migration_id,
            direction = direction,
            error = "No target_db in migration metadata"
        }
    end

    print("Connecting to database:", database_id)
    local db, err = sql.get(database_id)
    if err then
        print("ERROR: Database connection failed:", err)
        return {
            success = false,
            status = "error",
            message = "Database connection failed: " .. err,
            migration_id = migration_id,
            database_id = database_id,
            direction = direction,
            error = err
        }
    end
    print("Database connected")

    print("Initializing tracking table...")
    local init_ok, init_err = repository.init_tracking_table(db)
    if not init_ok then
        db:release()
        print("ERROR: Failed to initialize tracking table:", init_err)
        return {
            success = false,
            status = "error",
            message = "Failed to initialize tracking table: " .. init_err,
            migration_id = migration_id,
            database_id = database_id,
            direction = direction,
            error = init_err
        }
    end
    print("Tracking table initialized")

    print("Checking if migration is applied...")
    local is_applied, check_err = repository.is_applied(db, migration_id)
    if check_err then
        db:release()
        print("ERROR: Failed to check migration status:", check_err)
        return {
            success = false,
            status = "error",
            message = "Failed to check migration status: " .. check_err,
            migration_id = migration_id,
            database_id = database_id,
            direction = direction,
            error = check_err
        }
    end
    print("Is applied:", is_applied)

    db:release()

    if direction == "up" and is_applied then
        print("SKIP: Migration already applied")
        return {
            success = false,
            status = "skipped",
            message = "Migration already applied",
            migration_id = migration_id,
            database_id = database_id,
            direction = direction,
            already_applied = true
        }
    end

    if direction == "down" and not is_applied then
        print("SKIP: Migration not applied, cannot rollback")
        return {
            success = false,
            status = "skipped",
            message = "Migration not applied, cannot rollback",
            migration_id = migration_id,
            database_id = database_id,
            direction = direction,
            already_applied = false
        }
    end

    print("Setting up runner for database:", database_id)
    local start_time = time.now()

    local db_runner = runner.setup(database_id)
    local result

    if direction == "up" then
        print("Running next migration with allowed_ids:", migration_id)
        result = db_runner:run_next({
            allowed_ids = { migration_id }
        })
    else
        print("Rolling back migration with allowed_ids:", migration_id)
        result = db_runner:rollback({
            count = 1,
            allowed_ids = { migration_id }
        })
    end

    print("Runner result:", json.encode(result))

    local end_time = time.now()
    local duration = end_time:sub(start_time):milliseconds() / 1000

    print("Duration:", duration, "seconds")

    if result.status == "error" then
        print("ERROR: Migration execution failed")
        return {
            success = false,
            status = "error",
            message = result.error or "Migration execution failed",
            migration_id = migration_id,
            database_id = database_id,
            direction = direction,
            duration = duration,
            error = result.error
        }
    end

    local executed = direction == "up" and result.migrations_applied or result.migrations_reverted
    print("Executed count:", executed)

    if executed and executed > 0 then
        print("SUCCESS: Migration executed")
        return {
            success = true,
            status = direction == "up" and "applied" or "reverted",
            message = direction == "up" and "Migration applied successfully" or "Migration rolled back successfully",
            migration_id = migration_id,
            database_id = database_id,
            direction = direction,
            duration = duration
        }
    else
        local reason = "Unknown"
        if result.migrations and result.migrations[1] and result.migrations[1].reason then
            reason = result.migrations[1].reason
        elseif result.message then
            reason = result.message
        end

        print("SKIP: Migration skipped, reason:", reason)
        return {
            success = false,
            status = "skipped",
            message = reason,
            migration_id = migration_id,
            database_id = database_id,
            direction = direction,
            duration = duration
        }
    end
end

return { handler = handler }
