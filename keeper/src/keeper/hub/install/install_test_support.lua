local test = require("test")
local sql = require("sql")
local hub_service = require("hub_service")
local install_state = require("install_state")

local M = {}

function M.real_migration_source(statement)
    return [[return require("migration").define(function()
        migration("installer e2e fixture", function()
            database("sqlite", function()
                up(function(db)
                    local _, err = db:execute(]] .. string.format("%q", statement) .. [[)
                    if err then error(err) end
                end)
            end)
            database("postgres", function()
                up(function(db)
                    local _, err = db:execute(]] .. string.format("%q", statement) .. [[)
                    if err then error(err) end
                end)
            end)
        end)
    end)]]
end

function M.real_migration(id, timestamp, statement, quiesce)
    return {
        id = id, kind = "function.lua",
        meta = { type = "migration", target_db = "app:db", timestamp = timestamp,
            quiesce_services = quiesce and { "app:worker" } or nil },
        data = {
            source = M.real_migration_source(statement),
            imports = { migration = "wippy.migration:migration" },
            method = "migrate",
        },
    }
end

function M.fixture(label, fail_migration, mode)
    local observed = { "pid-old" }
    local state = { status = "running", desired = "running" }
    local trace = {}
    local receipts = {}
    local entry = { id = "app.deps:example", kind = "ns.dependency",
        data = { component = "example/pkg", version = "1.0.0", parameters = {} }, meta = {} }
    local real = mode == "real"
    local migration = { id = "example.migrations:01", kind = "function.lua",
        meta = { type = "migration", target_db = "app:db",
            quiesce_services = { "app:worker" } }, data = { code = "return true" } }
    if real then
        migration = M.real_migration("example.migrations:01", "2026-03",
            "CREATE TABLE IF NOT EXISTS r5e2e_probe (id TEXT PRIMARY KEY)", true)
    end
    local candidate = { closure = { { module = "example/pkg", version = label,
        hash = label, min_runtime = "0.3.40a", migrations = { migration } } } }
    local deps = {
        sql = sql,
        config = { app_db = function() return "app:db" end },
        uuid = { v4 = function() return "installer-" .. label end },
        registry = { get = function(id)
            if receipts[id] then return receipts[id], nil end
            if id == "app:worker" then
                -- Short same-namespace ref, as real service entries declare
                -- it; quiescence qualifies it against the service namespace.
                return { id = id, kind = "process.service", data = { process = "worker.run" } }, nil
            end
            return nil, nil
        end },
        system = {
            version = function() return "0.3.43a" end,
            supervisor = { state = function()
                if mode == "inspection_error" then return nil, "permission denied" end
                return state, nil
            end },
            hosts = {
                list = function() return { { id = "app:host" } }, nil end,
                processes = function()
                    local rows = {}
                    for _, pid in ipairs(observed) do
                        rows[#rows + 1] = { pid = pid, source = "app:worker.run", state = "running" }
                    end
                    return rows, nil
                end,
            },
        },
        events = { send = function(system_name, kind, id)
            test.eq(system_name, "supervisor")
            test.eq(id, "app:worker")
            trace[#trace + 1] = kind
            if kind == "service.stop" then
                if mode == "stop_timeout" then
                    state = { status = "stopping", desired = "stopped" }
                else
                    state = { status = "stopped", desired = "stopped" }
                    observed = {}
                end
            elseif kind == "service.start" then
                state = { status = "running", desired = "running" }
                observed = { mode == "old_pid_start" and "pid-old" or "pid-new" }
            end
            return true, nil
        end },
        time = { sleep = function() return true, nil end },
    }
    local svc
    if not real then
        -- Failure injection the real runner cannot produce stays on the
        -- test-only double; real-mode fixtures use the production defaults.
        svc = hub_service.new(deps)
        svc.candidate_resolver = { staged = true }
        svc.candidate_migrations_up = function(args)
            trace[#trace + 1] = "migration"
            test.eq(args.target_db, "app:db")
            test.eq(args.installer_lock_token, "installer-" .. label)
            test.not_nil(args.expected_hashes[migration.id])
            if fail_migration then return nil, "injected migration failure" end
            return { applied = { { id = migration.id, hash = args.expected_hashes[migration.id] } }, skipped = {} }, nil
        end
    else
        svc = hub_service.new(deps)
    end
    svc.prepare_install = function()
        return { candidate = candidate, plan = { graph = {} }, args = { migration_policy = "up" },
            entry = entry, entries = { entry }, create_only = {}, patches = {}, patch = {},
            policy = "up" }, nil
    end
    svc.dependency_create_or_update_op = function(_, row)
        return { kind = "entry.create", entry = row }, nil
    end
    svc.bootloader_step_data = function()
        return { baseline_modules = {}, reconfigured = {} }, nil
    end
    svc.validate_planned_entries = function()
        trace[#trace + 1] = "validation"
        return { ok = true }, nil
    end
    if not real then
        svc.migration_status = function()
            return mode == "applied_hash_changed" and "applied" or "pending", nil
        end
    end
    svc.publish_dependency_changeset = function(self, args)
        trace[#trace + 1] = "publication"
        if mode ~= "publish_never_commits" then
            local receipt, receipt_err = self:publication_receipt(args.lock_token, args.candidate_hash, args.entries)
            test.is_nil(receipt_err)
            receipts[receipt.entry.id] = receipt.entry
        end
        return { version = 2 }, nil
    end
    svc.run_installed_bootloaders = function()
        trace[#trace + 1] = "bootloaders"
        return { count = 0 }, nil
    end
    return svc, trace
end

function M.cleanup_install_locks()
    local db, db_err = sql.get("app:db")
    if db_err or not db then return end
    local active, active_err = install_state.get_active_install(db)
    if not active_err and active and active.lock_token
        and string.sub(active.lock_token, 1, 10) == "installer-" then
        install_state.fail_install(db, active.lock_token, "test teardown")
    end
    db:release()
end

return M
