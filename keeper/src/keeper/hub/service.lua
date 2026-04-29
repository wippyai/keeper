local registry = require("registry")
local materialize = require("materialize")
local funcs = require("funcs")
local sql = require("sql")
local uuid = require("uuid")
local process = require("process")
local planner = require("planner")
local governance = require("governance")

local M = {}

local Service = {}
Service.__index = Service

type ServiceDeps = {
    registry: unknown?,
    materialize: unknown?,
    funcs: unknown?,
    sql: unknown?,
    uuid: unknown?,
    process: unknown?,
    planner: unknown?,
    governance: unknown?,
}

type HubService = {
    registry: unknown,
    materialize: unknown,
    funcs: unknown,
    sql: unknown,
    uuid: unknown,
    process: unknown,
    planner: unknown,
    governance: unknown,
    list_dependencies: (HubService, unknown) -> (unknown, unknown?),
    install: (HubService, unknown, unknown?) -> (unknown, unknown?),
    uninstall: (HubService, unknown, unknown?) -> (unknown, unknown?),
    migration_rows: (HubService, unknown) -> (unknown, unknown?),
    run_migrations: (HubService, unknown, unknown?) -> (unknown, unknown?),
}

M.DEFAULT_DEP_NAMESPACE = "app.deps"
M.DEFAULT_VERSION = ">=v0.0.0"
M.APPLY_FN = "keeper.state.tools:apply"
M.MIGRATION_HANDLER_FN = "keeper.develop.integrate.handlers:migration_handler"
M.USER_HUB_PREFIX = "user."
M.EVENT_TOPIC = "keeper.hub"
M.EVENTS = {
    INSTALL_STARTED = "hub.install.started",
    INSTALL_FINISHED = "hub.install.finished",
    INSTALL_FAILED = "hub.install.failed",
    UNINSTALL_STARTED = "hub.uninstall.started",
    UNINSTALL_FINISHED = "hub.uninstall.finished",
    UNINSTALL_FAILED = "hub.uninstall.failed",
    MIGRATIONS_STARTED = "hub.migrations.started",
    MIGRATIONS_FINISHED = "hub.migrations.finished",
    MIGRATIONS_FAILED = "hub.migrations.failed",
}

local function trim(value)
    return string.match(tostring(value or ""), "^%s*(.-)%s*$")
end

local function shallow_copy(src)
    local out = {}
    for k, v in pairs(src or {}) do out[k] = v end
    return out
end

local function err(code, message, details)
    return { code = code, message = message, details = details }
end

local function is_array(t)
    if type(t) ~= "table" then return false end
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then return false end
        if k > n then n = k end
    end
    for i = 1, n do
        if t[i] == nil then return false end
    end
    return true
end

function M.parse_component(component)
    component = tostring(trim(component))
    if component == "" then
        return nil, err("BAD_REQUEST", "component is required")
    end
    local org, name = string.match(component, "^([%w_.-]+)/([%w_.-]+)$")
    if not org or not name then
        return nil, err("BAD_REQUEST", "component must be in org/module form")
    end
    if org == "" or name == "" then
        return nil, err("BAD_REQUEST", "component must include both org and module")
    end
    return { org = org, module = name, component = org .. "/" .. name }, nil
end

function M.sanitize_dependency_name(name)
    name = string.gsub(string.lower(trim(name)), "[^%w_.-]", "_")
    name = string.gsub(name, "^[_%.%-]+", "")
    name = string.gsub(name, "[_%.%-]+$", "")
    if name == "" then return nil end
    return name
end

function M.validate_namespace(namespace)
    namespace = trim(namespace)
    if namespace == "" then
        return nil, err("BAD_REQUEST", "namespace is required")
    end
    if string.find(namespace, "..", 1, true) or string.sub(namespace, 1, 1) == "." or string.sub(namespace, -1) == "." then
        return nil, err("BAD_REQUEST", "namespace must be dot-separated identifiers")
    end
    for part in string.gmatch(namespace, "[^.]+") do
        if not string.match(part, "^[A-Za-z][A-Za-z0-9_]*$") then
            return nil, err("BAD_REQUEST", "namespace must be dot-separated identifiers")
        end
    end
    if not string.match(namespace, "^[A-Za-z0-9_.]+$") then
        return nil, err("BAD_REQUEST", "namespace must be dot-separated identifiers")
    end
    return namespace, nil
end

function M.resolve_dependency_id(args)
    args = args or {}
    local explicit = tostring(trim(args.id))
    if explicit ~= "" then
        local ns, name = string.match(explicit, "^([^:]+):(.+)$")
        if not ns or not name or name == "" then
            return nil, err("BAD_REQUEST", "id must be namespace:name")
        end
        local ok_ns, ns_err = M.validate_namespace(ns)
        if not ok_ns then return nil, ns_err end
        return explicit, nil
    end

    local parsed, comp_err = M.parse_component(args.component)
    if not parsed then return nil, comp_err end

    local ns, ns_err = M.validate_namespace(args.namespace or M.DEFAULT_DEP_NAMESPACE)
    if not ns then return nil, ns_err end

    local name = trim(tostring(args.name or ""))
    if name == "" then
        name = M.sanitize_dependency_name(parsed.module)
    else
        name = M.sanitize_dependency_name(name)
    end
    if not name then
        return nil, err("BAD_REQUEST", "dependency name cannot be empty")
    end
    return ns .. ":" .. name, nil
end

function M.normalize_parameters(input)
    if input == nil then return {}, nil end
    if type(input) ~= "table" then
        return nil, err("BAD_REQUEST", "parameters must be an array of {name,value} or an object map")
    end

    local out = {}
    local seen = {}

    local function add(name, value)
        name = trim(name)
        if name == "" then
            return err("BAD_REQUEST", "parameter name is required")
        end
        if seen[name] then
            return err("BAD_REQUEST", "duplicate parameter: " .. name)
        end
        seen[name] = true
        if value == nil then value = "" end
        table.insert(out, { name = name, value = tostring(value) })
        return nil
    end

    if is_array(input) then
        for i, item in ipairs(input) do
            if type(item) ~= "table" then
                return nil, err("BAD_REQUEST", "parameters[" .. i .. "] must be an object")
            end
            local add_err = add(item.name, item.value)
            if add_err then return nil, add_err end
        end
    else
        local keys = {}
        for k in pairs(input) do table.insert(keys, k) end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        for _, k in ipairs(keys) do
            local add_err = add(k, input[k])
            if add_err then return nil, add_err end
        end
    end

    return out, nil
end

function M.build_dependency_entry(args)
    args = args or {}
    local parsed, comp_err = M.parse_component(args.component)
    if not parsed then return nil, comp_err end

    local id, id_err = M.resolve_dependency_id(args)
    if not id then return nil, id_err end

    local parameters, param_err = M.normalize_parameters(args.parameters)
    if not parameters then return nil, param_err end

    local data = {
        component = parsed.component,
        version = trim(args.version) ~= "" and trim(args.version) or M.DEFAULT_VERSION,
    }
    if #parameters > 0 then data.parameters = parameters end

    return {
        id = id,
        kind = "ns.dependency",
        meta = shallow_copy(args.meta or {}),
        data = data,
    }, nil
end

function M.entry_to_set_patch(entry)
    local materialized, mat_err = materialize.entry(entry)
    if not materialized then
        return nil, err("INTERNAL", "failed to materialize dependency entry: " .. tostring(mat_err))
    end
    return {
        target = "entry",
        id = materialized.id,
        op = "set",
        kind = materialized.kind,
        definition = materialized.definition,
        content = materialized.content,
    }, nil
end

local function entry_summary(entry)
    return {
        id = entry.id,
        kind = entry.kind,
        type = entry.meta and entry.meta.type or nil,
        module = entry.meta and entry.meta.module or nil,
        module_version = entry.meta and entry.meta.module_version or nil,
        title = entry.meta and entry.meta.title or nil,
        comment = entry.meta and entry.meta.comment or nil,
    }
end

function M.dependency_summary(entry)
    local data = entry and entry.data or {}
    return {
        id = entry.id,
        namespace = (entry.id and string.match(tostring(entry.id), "^([^:]+):")) or nil,
        name = (entry.id and string.match(tostring(entry.id), "^[^:]+:(.+)$")) or nil,
        kind = entry.kind,
        component = data.component,
        version = data.version,
        parameters = data.parameters or {},
        meta = entry.meta or {},
    }
end

function M.new(deps: ServiceDeps?)
    deps = deps or {}
    return setmetatable({
        registry = deps.registry or registry,
        materialize = deps.materialize or materialize,
        funcs = deps.funcs or funcs,
        sql = deps.sql or sql,
        uuid = deps.uuid or uuid,
        process = deps.process or process,
        planner = deps.planner or planner,
        governance = deps.governance or governance,
    }, Service) :: HubService
end

function Service:new_operation_id()
    local id = self.uuid.v7 and self.uuid.v7() or self.uuid.v4()
    return tostring(id)
end

function Service:emit_user_event(actor_id, event, data)
    if not actor_id or actor_id == "" then return false, "actor_id required" end
    if not self.process or not self.process.registry or not self.process.registry.lookup then
        return false, "process registry unavailable"
    end

    local pid, lookup_err = self.process.registry.lookup(M.USER_HUB_PREFIX .. tostring(actor_id))
    if not pid then return false, lookup_err or "user hub not active" end

    local payload = {
        event = event,
        actor_id = actor_id,
        data = data or {},
    }
    local ok, send_result = pcall(function()
        return self.process.send(pid, M.EVENT_TOPIC, payload)
    end)
    if not ok then return false, tostring(send_result) end
    if send_result == false then return false, "process.send returned false" end
    return true, nil
end

function Service:emit_operation(actor_id, event, operation_id, data)
    data = data or {}
    data.operation_id = operation_id
    return self:emit_user_event(actor_id, event, data)
end

function Service:find_entries(criteria)
    local rows, find_err = self.registry.find(criteria or {})
    if find_err then
        return nil, err("INTERNAL", "registry.find failed: " .. tostring(find_err))
    end
    return rows or {}, nil
end

function Service:get_entry(id)
    local entry, get_err = self.registry.get(id)
    if get_err then
        return nil, err("INTERNAL", "registry.get failed for " .. tostring(id) .. ": " .. tostring(get_err))
    end
    if not entry then
        return nil, err("NOT_FOUND", "entry not found: " .. tostring(id))
    end
    return entry, nil
end

function Service:dependency_entries()
    local rows, rows_err = self:find_entries({ [".kind"] = "ns.dependency" })
    if not rows then return nil, rows_err end
    table.sort(rows, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return rows, nil
end

function Service:find_dependency(args)
    args = args or {}
    if args.id and trim(args.id) ~= "" then
        local entry, get_err = self:get_entry(trim(args.id))
        if not entry then return nil, get_err end
        if entry.kind ~= "ns.dependency" then
            return nil, err("BAD_REQUEST", "entry is not an ns.dependency: " .. entry.id)
        end
        return entry, nil
    end

    local parsed, comp_err = M.parse_component(args.component)
    if not parsed then return nil, comp_err end

    local deps, deps_err = self:dependency_entries()
    if not deps then return nil, deps_err end
    for _, entry in ipairs(deps) do
        if entry.data and entry.data.component == parsed.component then
            return entry, nil
        end
    end
    return nil, err("NOT_FOUND", "dependency not found for component: " .. parsed.component)
end

function Service:module_entries(component)
    local rows, rows_err = self:find_entries({ ["meta.module"] = component })
    if not rows then return nil, rows_err end
    table.sort(rows, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return rows, nil
end

function Service:migration_status(entry)
    local target_db = entry.meta and entry.meta.target_db
    if not target_db or target_db == "" then
        return "unknown", "migration missing meta.target_db"
    end

    local db, db_err = self.sql.get(target_db)
    if db_err or not db then
        return "unknown", "db unavailable: " .. tostring(db_err or "nil db")
    end

    local rows, query_err = db:query("SELECT id FROM _migrations WHERE id = ? LIMIT 1", { entry.id })
    db:release()
    if query_err then
        local msg = tostring(query_err)
        if string.find(msg, "no such table", 1, true) or string.find(msg, "_migrations", 1, true) then
            return "pending", nil
        end
        return "unknown", msg
    end
    if rows and #rows > 0 then return "applied", nil end
    return "pending", nil
end

function Service:migration_rows(args)
    args = args or {}
    local entries = {}

    if type(args.entry_ids) == "table" and #args.entry_ids > 0 then
        for _, id in ipairs(args.entry_ids) do
            local entry, get_err = self:get_entry(id)
            if not entry then return nil, get_err end
            if not entry.meta or entry.meta.type ~= "migration" then
                return nil, err("BAD_REQUEST", "entry is not a migration: " .. tostring(id))
            end
            table.insert(entries, entry)
        end
    elseif args.component and trim(args.component) ~= "" then
        local parsed, comp_err = M.parse_component(args.component)
        if not parsed then return nil, comp_err end
        local rows, rows_err = self:find_entries({
            ["meta.module"] = parsed.component,
            ["meta.type"] = "migration",
        })
        if not rows then return nil, rows_err end
        entries = rows
    else
        local rows, rows_err = self:find_entries({ ["meta.type"] = "migration" })
        if not rows then return nil, rows_err end
        for _, entry in ipairs(rows) do
            if entry.meta and entry.meta.module then
                table.insert(entries, entry)
            end
        end
    end

    table.sort(entries, function(a, b)
        local at = a.meta and a.meta.timestamp or ""
        local bt = b.meta and b.meta.timestamp or ""
        if at == bt then return tostring(a.id) < tostring(b.id) end
        return tostring(at) < tostring(bt)
    end)

    local out = {}
    for _, entry in ipairs(entries) do
        local status, status_err = self:migration_status(entry)
        table.insert(out, {
            id = entry.id,
            target_db = entry.meta and entry.meta.target_db or nil,
            module = entry.meta and entry.meta.module or nil,
            module_version = entry.meta and entry.meta.module_version or nil,
            timestamp = entry.meta and entry.meta.timestamp or nil,
            status = status,
            status_error = status_err,
        })
    end
    return out, nil
end

function Service:list_dependencies(args)
    args = args or {}
    local deps, deps_err = self:dependency_entries()
    if not deps then return nil, deps_err end

    local component_filter
    if args.component and trim(args.component) ~= "" then
        local parsed, comp_err = M.parse_component(args.component)
        if not parsed then return nil, comp_err end
        component_filter = parsed.component
    end

    local out = {}
    for _, dep in ipairs(deps) do
        local summary = M.dependency_summary(dep)
        if not component_filter or summary.component == component_filter then
            local entries = {}
            local migrations = {}
            if summary.component and summary.component ~= "" then
                local module_entries, module_err = self:module_entries(summary.component)
                if not module_entries then return nil, module_err end
                for _, entry in ipairs(module_entries) do
                    table.insert(entries, entry_summary(entry))
                    if entry.meta and entry.meta.type == "migration" then
                        local status, status_err = self:migration_status(entry)
                        table.insert(migrations, {
                            id = entry.id,
                            target_db = entry.meta.target_db,
                            module = entry.meta.module,
                            module_version = entry.meta.module_version,
                            timestamp = entry.meta.timestamp,
                            status = status,
                            status_error = status_err,
                        })
                    end
                end
            end
            summary.installed_entries_count = #entries
            summary.installed = #entries > 0
            if args.include_entries ~= false then summary.entries = entries end
            if args.include_migrations ~= false then summary.migrations = migrations end
            table.insert(out, summary)
        end
    end

    return { dependencies = out, count = #out }, nil
end

function Service:call_func(id, params)
    local executor, new_err = self.funcs.new()
    if not executor then
        return nil, err("INTERNAL", "func executor unavailable: " .. tostring(new_err))
    end
    local result, call_err = executor:call(id, params or {})
    if call_err then
        return nil, err("INTERNAL", tostring(call_err))
    end
    return result, nil
end

function Service:apply_patches(args)
    local branch = args.branch
    if not branch or branch == "" then
        local id = (self.uuid.v7 and self.uuid.v7()) or self.uuid.v4()
        branch = "ws/" .. tostring(id)
    end

    local result, apply_err = self:call_func(M.APPLY_FN, {
        branch = branch,
        title = args.title,
        message = args.message,
        kind = "hub",
        actor_id = args.actor_id,
        publish = true,
        patches = args.patches,
        source = "keeper.hub",
    })
    if not result then return nil, apply_err end
    if result.ok == false then
        local first = result.errors and result.errors[1]
        return nil, err("CONFLICT", first and first.message or "registry apply failed", result)
    end
    return result, nil
end

function Service:current_registry_version()
    if not self.governance or not self.governance.current_version then
        return nil, err("INTERNAL", "governance.current_version unavailable")
    end
    local version, version_err = self.governance.current_version()
    if version_err or version == nil then
        return nil, err("INTERNAL", "failed to snapshot registry version: " .. tostring(version_err or "nil version"))
    end
    return version, nil
end

function Service:restore_registry_version(version, reason)
    if not self.governance or not self.governance.restore_version then
        return nil, err("INTERNAL", "governance.restore_version unavailable")
    end
    local result, restore_err = self.governance.restore_version(version, reason)
    if restore_err then
        return nil, err("INTERNAL", "failed to restore registry version " .. tostring(version) .. ": " .. tostring(restore_err))
    end
    return result or { version = version }, nil
end

function Service:plan_install(args)
    local p = self.planner
    if type(p) == "table" and p.new then
        local instance = p.new({ registry = self.registry })
        return instance:plan_install(args)
    end
    if type(p) == "table" and p.plan_install then
        return p.plan_install(args)
    end
    return nil, err("INTERNAL", "hub install planner unavailable")
end

function Service:install(args, opts)
    args = args or {}
    opts = opts or {}

    local plan, plan_err = self:plan_install(args)
    if not plan then return nil, plan_err end
    if #(plan.missing_requirements or {}) > 0 then
        return nil, err("REQUIREMENTS_MISSING", "Hub dependency requires explicit configuration", plan)
    end

    local planned = shallow_copy(args)
    local install_payload = plan.install_payload or {}
    planned.id = install_payload.id or planned.id
    planned.component = install_payload.component or planned.component
    planned.version = install_payload.version or planned.version
    planned.parameters = install_payload.parameters or planned.parameters
    planned.migration_policy = install_payload.migration_policy or planned.migration_policy

    local entry, entry_err = M.build_dependency_entry(planned)
    if not entry then return nil, entry_err end

    local patch, patch_err = M.entry_to_set_patch(entry)
    if not patch then return nil, patch_err end

    local payload = {
        dependency = M.dependency_summary(entry),
        patches = { patch },
        migration_policy = planned.migration_policy or (args.run_migrations == true and "up" or "none"),
        plan = plan,
    }

    if args.dry_run == true then
        payload.dry_run = true
        return payload, nil
    end

    local policy = planned.migration_policy
    if args.run_migrations == true then policy = "up" end

    local baseline_version
    if policy == "up" then
        local version, version_err = self:current_registry_version()
        if not version then return nil, version_err end
        baseline_version = version
        payload.baseline_version = baseline_version
    end

    local operation_id = self:new_operation_id()
    payload.operation_id = operation_id
    self:emit_operation(opts.actor_id, M.EVENTS.INSTALL_STARTED, operation_id, {
        dependency = payload.dependency,
        migration_policy = payload.migration_policy,
    })

    local apply_result, apply_err = self:apply_patches({
        actor_id = opts.actor_id,
        branch = args.branch,
        title = "Install Hub dependency " .. entry.data.component,
        message = "hub install " .. entry.id .. " " .. entry.data.component .. " " .. entry.data.version,
        patches = { patch },
    })
    if not apply_result then
        self:emit_operation(opts.actor_id, M.EVENTS.INSTALL_FAILED, operation_id, {
            dependency = payload.dependency,
            error = apply_err,
        })
        return nil, apply_err
    end
    payload.apply = apply_result

    if policy == "up" then
        local migration_result, migration_err = self:run_migrations({
            component = entry.data.component,
            operation = "up",
        }, opts)
        if not migration_result then
            local restore_result, restore_err = self:restore_registry_version(
                baseline_version,
                "hub install migration failed for " .. tostring(entry.data.component)
            )
            payload.rollback = restore_result
            payload.rollback_error = restore_err

            local failure_err
            if restore_result then
                failure_err = err("MIGRATIONS_FAILED",
                    "migrations failed after dependency install; registry restored to baseline",
                    {
                        migration_error = migration_err,
                        baseline_version = baseline_version,
                        rollback = restore_result,
                        apply = apply_result,
                    })
            else
                failure_err = err("ROLLBACK_FAILED",
                    "migrations failed after dependency install and registry rollback failed",
                    {
                        migration_error = migration_err,
                        baseline_version = baseline_version,
                        rollback_error = restore_err,
                        apply = apply_result,
                    })
            end
            self:emit_operation(opts.actor_id, M.EVENTS.INSTALL_FAILED, operation_id, {
                dependency = payload.dependency,
                error = failure_err,
                rollback = restore_result,
                rollback_error = restore_err,
            })
            return nil, failure_err
        end
        payload.migrations = migration_result
    end

    self:emit_operation(opts.actor_id, M.EVENTS.INSTALL_FINISHED, operation_id, {
        dependency = payload.dependency,
        apply = apply_result,
        migrations = payload.migrations,
    })

    return payload, nil
end

function Service:plan_uninstall(args)
    args = args or {}
    local dep, dep_err = self:find_dependency(args)
    if not dep then return nil, dep_err end

    local summary = M.dependency_summary(dep)
    local module_entries, module_err = self:module_entries(summary.component)
    if not module_entries then return nil, module_err end

    local entries = {}
    local migrations = {}
    local applied = {}
    for _, entry in ipairs(module_entries) do
        table.insert(entries, entry_summary(entry))
        if entry.meta and entry.meta.type == "migration" then
            local status, status_err = self:migration_status(entry)
            local row = {
                id = entry.id,
                target_db = entry.meta.target_db,
                module = entry.meta.module,
                module_version = entry.meta.module_version,
                timestamp = entry.meta.timestamp,
                status = status,
                status_error = status_err,
            }
            table.insert(migrations, row)
            if status == "applied" then table.insert(applied, row) end
        end
    end

    return {
        dependency = summary,
        entries = entries,
        entries_count = #entries,
        migrations = migrations,
        applied_migrations = applied,
        applied_migrations_count = #applied,
        patch = { target = "entry", id = dep.id, op = "delete" },
    }, nil
end

function Service:uninstall(args, opts)
    args = args or {}
    opts = opts or {}

    local plan, plan_err = self:plan_uninstall(args)
    if not plan then return nil, plan_err end

    local policy = args.migration_policy or "block"
    if policy ~= "block" and policy ~= "leave" and policy ~= "down" then
        return nil, err("BAD_REQUEST", "migration_policy must be block, leave, or down")
    end

    if plan.applied_migrations_count > 0 and policy == "block" then
        return nil, err("MIGRATIONS_APPLIED",
            "dependency has applied migrations; choose migration_policy=down or migration_policy=leave",
            plan)
    end

    local payload = {
        dependency = plan.dependency,
        plan = plan,
        migration_policy = policy,
        patches = { plan.patch },
    }

    if args.dry_run == true then
        payload.dry_run = true
        if plan.applied_migrations_count > 0 and policy == "leave" then
            payload.warning = "applied migrations will remain in the database after uninstall"
        end
        return payload, nil
    end

    local operation_id = self:new_operation_id()
    payload.operation_id = operation_id
    self:emit_operation(opts.actor_id, M.EVENTS.UNINSTALL_STARTED, operation_id, {
        dependency = payload.dependency,
        migration_policy = policy,
        applied_migrations_count = plan.applied_migrations_count,
    })

    if plan.applied_migrations_count > 0 and policy == "down" then
        local ids = {}
        for _, row in ipairs(plan.applied_migrations) do table.insert(ids, row.id) end
        local migration_result, migration_err = self:run_migrations({
            entry_ids = ids,
            operation = "down",
        }, opts)
        if not migration_result then
            self:emit_operation(opts.actor_id, M.EVENTS.UNINSTALL_FAILED, operation_id, {
                dependency = payload.dependency,
                error = migration_err,
            })
            return nil, migration_err
        end
        payload.migrations = migration_result
    elseif plan.applied_migrations_count > 0 and policy == "leave" then
        payload.warning = "applied migrations were left in place"
    end

    local apply_result, apply_err = self:apply_patches({
        actor_id = opts.actor_id,
        branch = args.branch,
        title = "Uninstall Hub dependency " .. tostring(plan.dependency.component),
        message = "hub uninstall " .. tostring(plan.dependency.id),
        patches = { plan.patch },
    })
    if not apply_result then
        self:emit_operation(opts.actor_id, M.EVENTS.UNINSTALL_FAILED, operation_id, {
            dependency = payload.dependency,
            error = apply_err,
        })
        return nil, apply_err
    end
    payload.apply = apply_result

    self:emit_operation(opts.actor_id, M.EVENTS.UNINSTALL_FINISHED, operation_id, {
        dependency = payload.dependency,
        apply = apply_result,
        migrations = payload.migrations,
        warning = payload.warning,
    })

    return payload, nil
end

function Service:run_migrations(args, opts)
    args = args or {}
    opts = opts or {}
    local operation = args.operation or "up"
    if operation ~= "up" and operation ~= "down" then
        return nil, err("BAD_REQUEST", "operation must be up or down")
    end

    local rows, rows_err = self:migration_rows(args)
    if not rows then return nil, rows_err end

    local ids = {}
    for _, row in ipairs(rows) do
        if operation == "up" then
            if args.only_pending == false or row.status ~= "applied" then
                table.insert(ids, row.id)
            end
        elseif args.only_applied == false or row.status == "applied" then
            table.insert(ids, row.id)
        end
    end

    local payload = {
        operation = operation,
        entry_ids = ids,
        migrations = rows,
        count = #ids,
    }
    if args.dry_run == true or #ids == 0 then
        payload.dry_run = args.dry_run == true
        payload.result = {}
        return payload, nil
    end

    local operation_id = self:new_operation_id()
    payload.operation_id = operation_id
    self:emit_operation(opts.actor_id, M.EVENTS.MIGRATIONS_STARTED, operation_id, {
        operation = operation,
        entry_ids = ids,
        count = #ids,
    })

    local result, call_err = self:call_func(M.MIGRATION_HANDLER_FN, {
        operation = operation,
        entry_ids = ids,
        actor_id = opts.actor_id,
    })
    if not result then
        self:emit_operation(opts.actor_id, M.EVENTS.MIGRATIONS_FAILED, operation_id, {
            operation = operation,
            entry_ids = ids,
            error = call_err,
        })
        return nil, call_err
    end
    payload.result = result
    self:emit_operation(opts.actor_id, M.EVENTS.MIGRATIONS_FINISHED, operation_id, {
        operation = operation,
        entry_ids = ids,
        result = result,
    })
    return payload, nil
end

function M.list_dependencies(args)
    return M.new():list_dependencies(args)
end

function M.install(args, opts)
    return M.new():install(args, opts)
end

function M.uninstall(args, opts)
    return M.new():uninstall(args, opts)
end

function M.list_migrations(args)
    local svc = M.new()
    local rows, rows_err = svc:migration_rows(args or {})
    if not rows then return nil, rows_err end
    return { migrations = rows, count = #rows }, nil
end

function M.run_migrations(args, opts)
    return M.new():run_migrations(args, opts)
end

return M
