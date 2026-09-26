local hash = require("hash")
local digest = require("install_digest")

local M = {}

local ERROR_KIND = {
    BAD_REQUEST = errors.INVALID,
    NOT_FOUND = errors.NOT_FOUND,
    CONFLICT = errors.CONFLICT,
    INSTALL_CONFLICT = errors.CONFLICT,
    MIGRATIONS_REQUIRED = errors.CONFLICT,
    MIGRATION_STATUS_UNKNOWN = errors.UNKNOWN,
    CANDIDATE_RUNNER_UNAVAILABLE = errors.UNAVAILABLE,
    INSTALL_STATE_UNAVAILABLE = errors.UNAVAILABLE,
}

local function failure(code, message, info)
    local details = { code = code }
    if type(info) == "table" then
        for key, value in pairs(info) do details[key] = value end
    elseif info ~= nil then
        details.cause = tostring(info)
    end
    return errors.new({ kind = ERROR_KIND[code] or errors.INTERNAL,
        message = message, details = details })
end

local function error_text(value)
    if type(value) == "table" then return tostring(value.message or value) end
    if type(value) == "userdata" then return tostring(value:message()) end
    return tostring(value)
end

local function event_error(value)
    if type(value) == "table" then return { code = value.code, message = value.message } end
    return { message = error_text(value) }
end

local function dependency_summary(entries)
    local first = entries and entries[1]
    local data = first and first.data or {}
    return { id = first and first.id or nil, component = data.component, version = data.version }
end

local STEPS = { "preflight", "quiescence", "candidate_migrations",
    "publication", "bootloaders", "startup", "fence_release" }

local function merge_candidates(prepared)
    local by_name, identity = {}, {}
    for _, item in ipairs(prepared) do
        if item.candidate then
            for _, artifact in ipairs(item.candidate.closure or {}) do
                local prior = by_name[artifact.module]
                if prior and prior.hash ~= artifact.hash then
                    return nil, failure("CONFLICT", "batch selects two hashes for " .. artifact.module)
                end
                by_name[artifact.module] = artifact
            end
        end
    end
    local closure = {}
    for _, artifact in pairs(by_name) do
        closure[#closure + 1] = artifact
        identity[#identity + 1] = tostring(artifact.module) .. "\0" .. tostring(artifact.version)
            .. "\0" .. tostring(artifact.hash)
    end
    table.sort(closure, function(a, b) return a.module < b.module end)
    table.sort(identity)
    if #identity == 0 then return nil, failure("CANDIDATE_UNAVAILABLE", "resolved closure is empty") end
    local digest, digest_err = hash.sha256(table.concat(identity, "\n"))
    if not digest then return nil, failure("CANDIDATE_HASH_FAILED", error_text(digest_err)) end
    return { closure = closure, hash = digest }, nil
end

local function staged_migrations(svc, closure)
    local rows, expected = {}, {}
    for _, artifact in ipairs(closure) do
        for _, entry in ipairs(artifact.migrations or {}) do
            local content_hash, digest_err = digest.sha256({ id = entry.id, kind = entry.kind,
                meta = entry.meta, data = entry.data })
            if not content_hash then return nil, nil, failure("CANDIDATE_HASH_FAILED", error_text(digest_err)) end
            if expected[entry.id] and expected[entry.id] ~= content_hash then
                return nil, nil, failure("CANDIDATE_HASH_MISMATCH", "duplicate migration id changed", entry.id)
            end
            expected[entry.id] = content_hash
            local status, status_err = svc:migration_status(entry)
            if status == "unknown" then
                return nil, nil, failure("MIGRATION_STATUS_UNKNOWN", "cannot inspect staged migration " .. entry.id, status_err)
            end
            rows[#rows + 1] = { id = entry.id, hash = content_hash, meta = entry.meta,
                status = status, target_db = entry.meta.target_db }
        end
    end
    table.sort(rows, function(a, b) return a.id < b.id end)
    return rows, expected, nil
end

local function run_candidate_migrations(svc, candidate, rows, expected, token)
    if #rows == 0 then return { applied = {}, skipped = {} }, nil end
    local runner = svc.candidate_migrations_up
    local resolver = svc.candidate_resolver
    if not resolver and type(svc.candidate_resolver_for) == "function" then
        local bound, bound_err = svc.candidate_resolver_for(candidate.closure)
        if not bound then
            return nil, failure("CANDIDATE_RUNNER_UNAVAILABLE", "staged resolver unavailable", bound_err)
        end
        resolver = bound
    end
    if not runner or not resolver then
        return nil, failure("CANDIDATE_RUNNER_UNAVAILABLE", "staged migration runner and resolver required")
    end
    local call = type(runner) == "function" and runner or runner.run
    if type(call) ~= "function" then
        return nil, failure("CANDIDATE_RUNNER_UNAVAILABLE", "candidate_migrations_up is not callable")
    end
    local dbs, seen = {}, {}
    for _, row in ipairs(rows) do
        if not seen[row.target_db] then
            seen[row.target_db] = true
            dbs[#dbs + 1] = row.target_db
        end
    end
    table.sort(dbs)
    local all = { applied = {}, skipped = {} }
    for _, target_db in ipairs(dbs) do
        local result, run_err = call({ candidate_closure = candidate.closure,
            target_db = target_db, resolver = resolver, expected_hashes = expected,
            installer_lock_token = token })
        if not result or run_err then
            return nil, failure("CANDIDATE_MIGRATIONS_FAILED", "staged migration failed on " .. target_db, run_err)
        end
        for _, row in ipairs(result.applied or {}) do all.applied[#all.applied + 1] = row end
        for _, row in ipairs(result.skipped or {}) do all.skipped[#all.skipped + 1] = row end
    end
    return all, nil
end

function M.run(svc, input, opts)
    opts = opts or {}
    local candidate, candidate_err = merge_candidates(input.prepared)
    if not candidate then return nil, candidate_err end
    if input.direct then
        local selection = {}
        for _, id in ipairs(input.selected_ids or {}) do selection[#selection + 1] = id end
        table.sort(selection)
        local selected_hash, selected_err = hash.sha256(candidate.hash .. "\n" .. table.concat(selection, "\n"))
        if not selected_hash then return nil, failure("CANDIDATE_HASH_FAILED", tostring(selected_err)) end
        candidate.hash = selected_hash
    else
        local publication_hash, publication_err = digest.sha256({
            closure = candidate.hash, entries = input.entries or {},
            run_migrations = input.run_migrations == true,
        })
        if not publication_hash then
            return nil, failure("CANDIDATE_HASH_FAILED", tostring(publication_err))
        end
        candidate.hash = publication_hash
    end
    if not svc.install_state or not svc.install_quiescence or not svc.config
        or not svc.sql or type(svc.sql.get) ~= "function" then
        return nil, failure("INSTALL_STATE_UNAVAILABLE", "installer state dependencies unavailable")
    end
    local db_id = svc.config.app_db()
    local db, db_err = svc.sql.get(db_id)
    if not db then return nil, failure("INSTALL_STATE_UNAVAILABLE", "installer database unavailable", db_err) end
    local function close(value, err)
        db:release()
        return value, err
    end
    local state = svc.install_state
    local ensured, ensure_err = state.ensure(db)
    if not ensured then return close(nil, failure("INSTALL_STATE_FAILED", "cannot ensure installer lock", ensure_err)) end
    local started, begin_err = state.begin_install(db, { lock_token = svc:new_operation_id(),
        candidate_hash = candidate.hash, steps = STEPS })
    if not started then return close(nil, failure("INSTALL_CONFLICT", "installer lock unavailable", begin_err)) end
    local token = started.lock_token
    -- Operator lifecycle events are best-effort: a missing user hub never
    -- fails the install. Direct migration runs emit no install events.
    local summary = dependency_summary(input.entries)
    local function fail(run_err)
        if not input.direct then
            svc:emit_operation(opts.actor_id, "hub.install.failed", token, {
                dependency = summary, candidate_hash = candidate.hash,
                error = event_error(run_err) })
        end
        return close(nil, run_err)
    end
    if not input.direct then
        svc:emit_operation(opts.actor_id, "hub.install.started", token, {
            dependency = summary, candidate_hash = candidate.hash,
            entry_count = input.entries and #input.entries or 0 })
    end
    local completed = {}
    for _, row in ipairs(started.steps or {}) do completed[row.name] = row end
    local function step(name, fn)
        local prior = completed[name]
        if prior and prior.status == "done" then return prior.result, nil end
        local running, running_err = state.record_step(db, token, name, { status = "running" })
        if not running then return fail(failure("INSTALL_STATE_FAILED", "cannot persist " .. name, running_err)) end
        local result, run_err = fn()
        if not result then
            local blocked, blocked_err = state.record_step(db, token, name,
                { status = "blocked", error = run_err })
            if not blocked then return fail(failure("INSTALL_STATE_FAILED", "cannot persist blocker", blocked_err)) end
            return fail(run_err)
        end
        local done, done_err = state.record_step(db, token, name,
            { status = "done", result = result, step_hash = candidate.hash })
        if not done then return fail(failure("INSTALL_STATE_FAILED", "cannot persist " .. name, done_err)) end
        completed[name] = { status = "done", result = result }
        return result, nil
    end
    local preflight, preflight_err = step("preflight", function()
        if input.direct then return { ok = true }, nil end
        return svc:validate_planned_entries(input.changeset, input.planned_entries)
    end)
    if not preflight then return fail(preflight_err) end
    local rows, expected, rows_err = staged_migrations(svc, candidate.closure)
    if not rows then return fail(rows_err) end
    local pending = {}
    for _, row in ipairs(rows) do if row.status ~= "applied" then pending[#pending + 1] = row end end
    if #pending > 0 and not input.run_migrations then
        return fail(failure("MIGRATIONS_REQUIRED", "candidate has pending migrations"))
    end
    if #rows > 0 and (not svc.candidate_migrations_up
        or (not svc.candidate_resolver
            and type(svc.candidate_resolver_for) ~= "function")) then
        return fail(failure("CANDIDATE_RUNNER_UNAVAILABLE", "staged migration runner unavailable"))
    end
    local fence, fence_err = step("quiescence", function()
        return svc.install_quiescence.acquire(svc, db, token, candidate.hash, pending)
    end)
    if not fence then return fail(fence_err) end
    local migrations, migration_err = step("candidate_migrations", function()
        return run_candidate_migrations(svc, candidate, rows, expected, token)
    end)
    if not migrations then return fail(migration_err) end
    local publication, publish_err = step("publication", function()
        if input.direct then return { skipped = true }, nil end
        local receipt, receipt_err = svc:publication_receipt(token, candidate.hash, input.entries)
        if not receipt then return nil, receipt_err end
        if receipt.committed then
            return { reconciled = true, receipt_id = receipt.entry.id }, nil
        end
        return svc:publish_dependency_changeset({ action = "install", entries = input.entries,
            create_only = input.create_only, actor_id = opts.actor_id,
            message = input.message, lock_token = token, candidate_hash = candidate.hash })
    end)
    if not publication then return fail(publish_err) end
    local bootloaders, boot_err = step("bootloaders", function()
        if input.direct then return { skipped = true }, nil end
        return svc:run_installed_bootloaders(input.bootloader_data.baseline_modules,
            input.bootloader_data.reconfigured)
    end)
    if not bootloaders then return fail(boot_err) end
    local startup, startup_err = step("startup", function()
        return svc.install_quiescence.start(svc, db, token, fence)
    end)
    if not startup then return fail(startup_err) end
    local released, release_err = step("fence_release", function()
        return svc.install_quiescence.release(svc, db, token, startup.fence)
    end)
    if not released then return fail(release_err) end
    local completed_ok, complete_err = state.complete_install(db, token,
        { candidate_hash = candidate.hash })
    if not completed_ok then return fail(failure("INSTALL_STATE_FAILED", "cannot complete install", complete_err)) end
    if not input.direct then
        svc:emit_operation(opts.actor_id, "hub.install.finished", token, {
            dependency = summary, candidate_hash = candidate.hash,
            apply = publication, migrations = migrations, bootloaders = bootloaders })
    end
    return close({ operation_id = token, candidate_hash = candidate.hash,
        apply = publication, migrations = migrations, bootloaders = bootloaders,
        fence = startup.fence, resumed = started.resumed }, nil)
end

function M.run_direct(svc, rows, ids, opts)
    local installed, installed_err = svc.install_candidate.installed(svc.registry)
    if not installed then return nil, installed_err end
    local by_name = {}
    for _, art in ipairs(installed) do by_name[art.name] = art end
    local selected, graph = {}, {}
    for _, id in ipairs(ids) do selected[id] = true end
    local seen = {}
    for _, row in ipairs(rows) do
        if selected[row.id] then
            local art = by_name[row.module]
            if not art then return nil, failure("CANDIDATE_UNAVAILABLE", "installed owner absent for " .. row.id) end
            if not seen[art.name] then
                graph[#graph + 1] = { module = art.name, version = art.version,
                    digest = art.hash, __selected = { version = art.version } }
                seen[art.name] = true
            end
        end
    end
    local staged, stage_err = svc.install_candidate.stage(svc.planner, graph)
    if not staged then return nil, stage_err end
    local found = {}
    for _, art in ipairs(staged.closure) do
        local keep = {}
        for _, migration in ipairs(art.migrations or {}) do
            if selected[migration.id] then
                keep[#keep + 1] = migration
                found[migration.id] = true
            end
        end
        art.migrations = keep
    end
    for id in pairs(selected) do
        if not found[id] then return nil, failure("CANDIDATE_UNAVAILABLE", "staged migration absent: " .. id) end
    end
    local running_version = svc.system and type(svc.system.version) == "function"
        and svc.system.version() or nil
    local accepted, pf_err = svc.preflight.check({ installed_artifacts = installed,
        candidate_closure = staged.closure, binary_version = running_version,
        certified_catalog = svc.floor_catalog })
    if not accepted or pf_err or not accepted.accepted then
        return nil, failure("PREFLIGHT_FAILED", "direct migration preflight refused",
            pf_err or accepted and accepted.blocker)
    end
    return M.run(svc, { prepared = { { candidate = staged } }, direct = true,
        selected_ids = ids, run_migrations = true }, opts)
end

return M
