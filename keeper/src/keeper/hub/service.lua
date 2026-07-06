local registry = require("registry")
local materialize = require("materialize")
local funcs = require("funcs")
local sql = require("sql")
local uuid = require("uuid")
local process = require("process")
local system = require("system")
local fs = require("fs")
local yaml = require("yaml")
local planner = require("planner")
local governance = require("governance")
local gov_consts = require("gov_consts")
local lockfile = require("lockfile")
local step_runner = require("step_runner")

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
    system: unknown?,
    fs: unknown?,
    yaml: unknown?,
    planner: unknown?,
    governance: unknown?,
    gov_consts: unknown?,
    lockfile: unknown?,
}

type HubService = {
    registry: unknown,
    materialize: unknown,
    funcs: unknown,
    sql: unknown,
    uuid: unknown,
    process: unknown,
    system: unknown,
    fs: unknown,
    yaml: unknown,
    planner: unknown,
    governance: unknown,
    gov_consts: unknown,
    lockfile: unknown,
    list_dependencies: (HubService, unknown) -> (unknown, unknown?),
    list_migrations: (HubService, unknown) -> (unknown, unknown?),
    install: (HubService, unknown, unknown?) -> (unknown, unknown?),
    uninstall: (HubService, unknown, unknown?) -> (unknown, unknown?),
    migration_rows: (HubService, unknown) -> (unknown, unknown?),
    run_migrations: (HubService, unknown, unknown?) -> (unknown, unknown?),
}

M.DEFAULT_DEP_NAMESPACE = "app.deps"
M.DEFAULT_VERSION = ">=v0.0.0"
M.MIGRATION_HANDLER_FN = "keeper.develop.integrate.handlers:migration_handler"
M.USER_HUB_PREFIX = "user."
M.EVENT_TOPIC = "keeper.hub"
M.PROJECT_FS_ID = "keeper.components:project_fs"
M.LOCK_PATH = lockfile.LOCK_PATH
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

local function trim(value: unknown): string
    return string.match(tostring(value or ""), "^%s*(.-)%s*$") or ""
end

local function shallow_copy(src)
    local out = {}
    for k, v in pairs(src or {}) do out[k] = v end
    return out
end

local function string_set(values)
    local out = {}
    for _, value in ipairs(values or {}) do
        out[tostring(value)] = true
    end
    return out
end

local function is_module_owned_dependency(entry)
    return entry and entry.meta and trim(entry.meta.module) ~= ""
end

local ERROR_KIND_BY_CODE = {
    BAD_REQUEST = errors.INVALID,
    NOT_FOUND = errors.NOT_FOUND,
    CONFLICT = errors.CONFLICT,
    REQUIREMENTS_MISSING = errors.CONFLICT,
    PRE_APPLY_VALIDATION_FAILED = errors.CONFLICT,
    MIGRATIONS_APPLIED = errors.CONFLICT,
    DEPENDENCY_GRAPH_FAILED = errors.CONFLICT,
    DEPENDENCY_REQUIRED = errors.CONFLICT,
}

local function err(code, message, details)
    local d = {}
    if type(details) == "table" then
        for k, v in pairs(details) do d[k] = v end
    elseif details ~= nil then
        d.value = details
    end
    d.code = code
    return errors.new({
        kind = ERROR_KIND_BY_CODE[code] or errors.INTERNAL,
        message = tostring(message or "unknown error"),
        details = d,
    })
end

local function error_summary(e: unknown)
    if e == nil then return nil end
    local ok_details, details = pcall(function() return (e :: any):details() end)
    if not ok_details then details = nil end
    local ok_kind, kind = pcall(function() return (e :: any):kind() end)
    if not ok_kind then kind = nil end
    local ok_message, message = pcall(function() return (e :: any):message() end)
    if not ok_message then message = nil end
    local details_table = type(details) == "table" and (details :: any) or nil
    local code = details_table and details_table.code or nil
    local out = { message = tostring(message or e) }
    if code then out.code = code end
    if kind then out.kind = kind end
    return out
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
    namespace = trim(tostring(namespace or ""))
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
        system = deps.system or system,
        fs = deps.fs or fs,
        yaml = deps.yaml or yaml,
        planner = deps.planner or planner,
        governance = deps.governance or governance,
        gov_consts = deps.gov_consts or gov_consts,
        lockfile = deps.lockfile or lockfile,
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
    local deploy_deps = {}
    for _, entry in ipairs(rows) do
        -- Module-owned ns.dependency entries describe a package's dependency
        -- graph. Only deployment dependency entries should be install/uninstall
        -- roots; otherwise uninstall can keep dependencies required only by the
        -- package being removed.
        if not is_module_owned_dependency(entry) then
            table.insert(deploy_deps, entry)
        end
    end
    rows = deploy_deps
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
        if is_module_owned_dependency(entry) then
            return nil, err("BAD_REQUEST", "entry is a module-owned dependency, not an installed dependency root: " .. entry.id)
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
    -- Sort a copy: registry.find may return a backing slice shared with later
    -- readers, so never reorder it in place.
    local out = {}
    for _, entry in ipairs(rows) do table.insert(out, entry) end
    table.sort(out, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return out, nil
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

-- Builds the full installed-module inventory (roots plus every transitive
-- reached through installed edges). Each entry carries roots-vs-transitive
-- provenance and used_by: the deployment roots whose dependency closure includes
-- the module. used_by is the shared indicator -- a module needed by more than one
-- root is reused, not exclusive. Versions and local-replacement provenance come
-- from wippy.lock, the authoritative installed set.
function Service:installed_module_inventory(deps)
    local lock_versions = {}
    local replacements = {}
    local lock_state = self:read_lock()
    if type(lock_state) == "table" and type(lock_state.doc) == "table" then
        for _, row in ipairs(lock_state.doc.modules or {}) do
            local name = trim(row.name)
            if name ~= "" then lock_versions[name] = tostring(row.version or "") end
        end
        for _, rep in ipairs(lock_state.doc.replacements or {}) do
            local from = trim(rep.from)
            if from ~= "" then replacements[from] = trim(rep.to) end
        end
    end

    local by_name = {}
    local order = {}
    local function ensure(name)
        local m = by_name[name]
        if not m then
            m = { name = name, version = lock_versions[name] or "", is_root = false, transitive = true, used_by = {}, used_by_count = 0, __seen = {} }
            local rep = replacements[name]
            if rep and rep ~= "" then
                m.source = "local"
                m.source_path = rep
            else
                m.source = "hub"
            end
            by_name[name] = m
            table.insert(order, name)
        end
        return m
    end

    for name in pairs(lock_versions) do ensure(name) end

    local instance
    if type(self.planner) == "table" and self.planner.new then
        instance = self.planner.new({ registry = self.registry })
    end

    for _, dep in ipairs(deps or {}) do
        local comp = trim(dep.data and dep.data.component)
        if comp ~= "" then
            local root = ensure(comp)
            root.is_root = true
            root.transitive = false
            local keep
            if instance then
                keep = instance:resolve_dependency_closure({ roots = { dep }, mode = "installed" })
            else
                keep = self:resolve_dependency_closure({ dep })
            end
            for member in pairs(keep or {}) do
                if member ~= comp then
                    local m = ensure(member)
                    if not m.__seen[comp] then
                        m.__seen[comp] = true
                        table.insert(m.used_by, comp)
                    end
                end
            end
        end
    end

    table.sort(order)
    local modules = {}
    for _, name in ipairs(order) do
        local m = by_name[name]
        if not m then
            error("installed module inventory lost row for " .. tostring(name))
        end
        table.sort(m.used_by)
        m.used_by_count = #m.used_by
        m.__seen = nil
        table.insert(modules, m)
    end
    return modules, by_name
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
            summary.is_root = true
            if args.include_entries ~= false then summary.entries = entries end
            if args.include_migrations ~= false then summary.migrations = migrations end
            table.insert(out, summary)
        end
    end

    -- Full roots-plus-transitive inventory so the UI can render dependency trees.
    -- Skipped only when the caller opted out with modules=false.
    local modules = {}
    if args.include_modules ~= false then
        local inventory, by_name = self:installed_module_inventory(deps)
        modules = inventory
        for _, summary in ipairs(out) do
            local m = by_name[summary.component]
            if m then
                summary.used_by = m.used_by
                summary.used_by_count = m.used_by_count
            else
                summary.used_by = {}
                summary.used_by_count = 0
            end
        end
    end

    return { dependencies = out, count = #out, modules = modules, module_count = #modules }, nil
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

local function is_not_found_error(e)
    if e == nil then return false end
    local ok, kind = pcall(function() return (e :: any):kind() end)
    if ok and (kind == errors.NOT_FOUND or tostring(kind) == tostring(errors.NOT_FOUND)) then
        return true
    end
    return string.find(string.lower(tostring(e)), "not found", 1, true) ~= nil
end

function Service:dependency_create_or_update_op(entry)
    if not self.registry or not self.registry.get then
        return nil, err("INTERNAL", "registry.get unavailable")
    end
    local existing, get_err = self.registry.get(entry.id)
    if get_err and not is_not_found_error(get_err) then
        return nil, err("INTERNAL", "failed to inspect dependency entry " .. tostring(entry.id) .. ": " .. tostring(get_err))
    end
    local registry_ops = self.gov_consts and self.gov_consts.REGISTRY_OPERATIONS
    if not registry_ops then
        return nil, err("INTERNAL", "governance registry operation constants unavailable")
    end
    local op = existing and registry_ops.UPDATE or registry_ops.CREATE
    return { kind = op, entry = entry }, nil
end

function Service:publish_dependency_changeset(args)
    args = args or {}
    if not self.governance or not self.governance.publish then
        return nil, err("INTERNAL", "governance.publish unavailable")
    end

    local changeset
    local entry_ids = {}
    if args.action == "install" then
        if type(args.entry) ~= "table" then
            return nil, err("BAD_REQUEST", "install dependency entry is required")
        end
        local op, op_err = self:dependency_create_or_update_op(args.entry)
        if not op then return nil, op_err end
        changeset = { op }
        entry_ids = { args.entry.id }
    elseif args.action == "uninstall" then
        local id = trim(args.id)
        if id == "" then return nil, err("BAD_REQUEST", "uninstall dependency id is required") end
        local registry_ops = self.gov_consts and self.gov_consts.REGISTRY_OPERATIONS
        if not registry_ops then
            return nil, err("INTERNAL", "governance registry operation constants unavailable")
        end
        changeset = { { kind = registry_ops.DELETE, entry = { id = id, kind = "ns.dependency" } } }
        entry_ids = { id }
    else
        return nil, err("BAD_REQUEST", "dependency publish action must be install or uninstall")
    end

    local publish_options = {
        user_id = args.actor_id,
        message = args.message,
        source = "keeper.hub",
        request_hil = true,
    }
    local result, publish_err = self.governance.publish(changeset, publish_options)
    if publish_err then
        return nil, err("CONFLICT", "registry publish failed: " .. tostring(publish_err), {
            action = args.action,
            entry_ids = entry_ids,
        })
    end

    return {
        ok = true,
        stage = "governance",
        action = args.action,
        version = result and result.version or nil,
        message = result and result.message or nil,
        result = result,
        entry_ids = entry_ids,
        changeset_count = #changeset,
    }, nil
end

local function entry_data(entry)
    if type(entry) ~= "table" then return {} end
    return type(entry.data) == "table" and entry.data or {}
end

local function add_entry_refs(out, value)
    if type(value) == "string" and trim(value) ~= "" then
        table.insert(out, value)
    end
end

local function binding_contract_refs(entry)
    local refs = {}
    local data = entry_data(entry)
    add_entry_refs(refs, data.contract)
    if type(data.contracts) == "table" then
        for _, row in ipairs(data.contracts) do
            if type(row) == "table" then add_entry_refs(refs, row.contract) end
        end
    end
    return refs
end

local function requirement_target_refs(entry)
    local refs = {}
    local data = entry_data(entry)
    if type(data.targets) == "table" then
        for _, target in ipairs(data.targets) do
            if type(target) == "table" then
                add_entry_refs(refs, target.entry)
                add_entry_refs(refs, target.entry_id)
                add_entry_refs(refs, target.target)
            end
        end
    end
    return refs
end

function Service:registry_entries_by_id()
    if not self.registry or not self.registry.find then
        return nil, err("INTERNAL", "registry.find unavailable")
    end
    local entries, find_err = self.registry.find({})
    if not entries then
        return nil, err("INTERNAL", "failed to load registry snapshot: " .. tostring(find_err))
    end
    local by_id = {}
    for _, entry in ipairs(entries or {}) do
        if type(entry) == "table" and type(entry.id) == "string" then
            by_id[entry.id] = entry
        end
    end
    return by_id, nil
end

function Service:validate_planned_entries(changeset, planned_entries)
    local by_id, load_err = self:registry_entries_by_id()
    if not by_id then return nil, load_err end

    local candidates = {}
    for _, entry in ipairs(planned_entries or {}) do
        if type(entry) == "table" and type(entry.id) == "string" then
            by_id[entry.id] = entry
            table.insert(candidates, entry)
        end
    end
    for _, op in ipairs(changeset or {}) do
        local entry = type(op.entry) == "table" and op.entry or nil
        if entry and type(entry.id) == "string" then
            if op.kind == self.gov_consts.REGISTRY_OPERATIONS.DELETE then
                by_id[entry.id] = nil
            else
                by_id[entry.id] = entry
                table.insert(candidates, entry)
            end
        end
    end

    local issues = {}
    for _, entry in ipairs(candidates) do
        if entry.kind == "contract.binding" then
            for _, ref in ipairs(binding_contract_refs(entry)) do
                if not by_id[ref] then
                    table.insert(issues, {
                        entry_id = entry.id,
                        kind = entry.kind,
                        field = "contract",
                        reference = ref,
                        message = "binding references undefined contract: " .. ref,
                    })
                end
            end
        elseif entry.kind == "ns.requirement" then
            for _, ref in ipairs(requirement_target_refs(entry)) do
                if not by_id[ref] then
                    table.insert(issues, {
                        entry_id = entry.id,
                        kind = entry.kind,
                        field = "targets.entry",
                        reference = ref,
                        message = "requirement target does not resolve: " .. ref,
                    })
                end
            end
        end
    end

    if #issues > 0 then
        local issues_by_entry = {}
        for _, issue in ipairs(issues) do
            issues_by_entry[tostring(issue.entry_id or "unknown")] = issue
        end
        return nil, err("PRE_APPLY_VALIDATION_FAILED",
            "Hub install planned entries failed pre-apply validation", {
                issue_count = #issues,
                issues = issues,
                issues_by_entry = issues_by_entry,
            })
    end

    return { ok = true, issue_count = 0 }, nil
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

function Service:read_lock()
    return self.lockfile.read(self.fs, self.yaml, M.PROJECT_FS_ID, M.LOCK_PATH)
end

function Service:encode_lock(lock_doc)
    return self.lockfile.encode(self.yaml, lock_doc, M.LOCK_PATH)
end

function Service:write_lock(lock_state, content)
    return self.lockfile.write(lock_state, M.LOCK_PATH, content)
end

function Service:prepare_install_lock_update(plan)
    return self.lockfile.prepare_install(self.fs, self.yaml, M.PROJECT_FS_ID, M.LOCK_PATH, plan)
end

function Service:prepare_uninstall_lock_update(plan)
    return self.lockfile.prepare_uninstall(self.fs, self.yaml, M.PROJECT_FS_ID, M.LOCK_PATH, plan)
end

function Service:commit_lock_update(update)
    return self.lockfile.commit(M.LOCK_PATH, update)
end

function Service:restore_lock_update(update)
    return self.lockfile.restore(M.LOCK_PATH, update)
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

-- Resolves the dependency closure of every deployment root except dep. Returns
-- (keep_modules, unresolved_modules): keep_modules is the set of module names
-- still reachable once dep is removed; unresolved_modules is the set of remaining
-- roots reached with no local installed edges. lockfile.prepare_uninstall prunes
-- wippy.lock to keep_modules. The target (dep) is always removed from the lock.
-- When an unresolved root is present in the lock, only the transitive pruning is
-- withheld -- a module such a root could still depend on is kept and reported
-- loudly (never removed under uncertainty), while dep itself is still removed.
function Service:plan_uninstall_closure(dep)
    local deps, deps_err = self:dependency_entries()
    if not deps then return nil, nil, deps_err end

    local remaining = {}
    for _, other in ipairs(deps) do
        if other.id ~= dep.id then table.insert(remaining, other) end
    end

    return self:resolve_dependency_closure(remaining)
end

function Service:resolve_dependency_closure(remaining)
    local p = self.planner
    local closure_args = { roots = remaining, mode = "installed" }
    if type(p) == "table" and p.new then
        local instance = p.new({ registry = self.registry })
        return instance:resolve_dependency_closure(closure_args)
    end
    if type(p) == "table" and p.resolve_dependency_closure then
        return p:resolve_dependency_closure(closure_args)
    end
    return nil, nil, err("INTERNAL", "hub uninstall closure resolver unavailable")
end

-- Step/ledger helpers shared by install and uninstall. The install/uninstall
-- flows build an explicit ordered step list, run it through step_runner, and on
-- failure reverse the successful prefix through step_runner.reverse. Each step's
-- inverse implementation is the corresponding restore_* method, invoked by a
-- service-bound rollback dispatcher so the injected governance/lockfile/funcs
-- dependencies (and the atomic single publish/commit) are honoured.

function Service:ledger_result(ledger, op)
    for _, row in ipairs(ledger.execution.handlers or {}) do
        if row.op == op then return row.result end
    end
    return nil
end

function Service:find_rollback_row(rollback_ledger, op)
    for _, row in ipairs(rollback_ledger.execution.handlers or {}) do
        if row.op == op then return row end
    end
    return nil
end

-- Ordered operator-facing step trace: each forward step is ok or failed, and a
-- forward step whose inverse ran during rollback is marked rolled_back with the
-- inverse operation that undid it. An inverse that itself failed marks the step
-- rollback_failed — the step still stands; a skipped inverse leaves the step ok.
function Service:project_ledger(ledger, rollback_ledger)
    local undone = {}
    if rollback_ledger then
        for _, row in ipairs(rollback_ledger.execution.handlers or {}) do
            if row.forward_label and row.skipped ~= true then
                undone[row.forward_label] = { op = row.op, failed = row.error ~= nil }
            end
        end
    end
    local out = {}
    for _, row in ipairs(ledger.execution.handlers or {}) do
        local label = row.label or row.op
        local inverse = undone[label]
        local status
        if row.error ~= nil then
            status = "failed"
        elseif inverse and inverse.failed then
            status = "rollback_failed"
        elseif inverse then
            status = "rolled_back"
        else
            status = "ok"
        end
        local item = { step = label, status = status }
        if status == "rolled_back" or status == "rollback_failed" then
            item.inverse = inverse.op
        end
        table.insert(out, item)
    end
    return out
end

-- Error details travel through a string-keyed conversion that keeps only
-- string table keys, so the projected ledger is attached keyed by its 1-based
-- position rendered as a string; rows keep the shape events carry and the
-- order is recoverable from the numeric keys.
local function execution_details(execution)
    return planner.position_keyed(execution)
end

-- Hub compensation ordering: the registry restore is the critical invariant, so
-- rows whose inverse restores a registry version run first during rollback; the
-- remaining inverses keep the generic LIFO order. step_runner.reverse stays a
-- plain reverse walk — the ordering lives here by moving registry-restoring
-- rows to the tail of the list it walks.
local function registry_restore_first(execution)
    local ordered = {}
    local registry_rows = {}
    for _, row in ipairs(execution.handlers or {}) do
        local inv = row.inverse
        if type(inv) == "table" and inv.op == "restore_registry_version" then
            table.insert(registry_rows, row)
        else
            table.insert(ordered, row)
        end
    end
    for _, row in ipairs(registry_rows) do table.insert(ordered, row) end
    return ordered
end

local function entry_namespace(id)
    return tostring(id or ""):match("^([^:]+):")
end

local function namespace_from_component(component)
    local parsed = M.parse_component(component)
    if not parsed then return nil end
    return parsed.org .. "." .. parsed.module
end

local function qualify_entry_id(id, default_ns)
    id = trim(id)
    if id == "" then return nil end
    if string.find(id, ":", 1, true) then return id end
    default_ns = trim(default_ns)
    if default_ns == "" then return id end
    return default_ns .. ":" .. id
end

local function sorted_keys(set)
    local out = {}
    for key in pairs(set or {}) do table.insert(out, key) end
    table.sort(out)
    return out
end

local function add_restart_warning(warnings, message)
    if trim(message) ~= "" then table.insert(warnings, tostring(message)) end
end

local function add_namespaces_from_entries(namespaces, entries)
    for _, entry in ipairs(entries or {}) do
        local ns = entry_namespace(entry and entry.id)
        if ns and ns ~= "" then namespaces[ns] = true end
    end
end

local function add_namespaces_from_changeset(namespaces, changeset)
    for _, op in ipairs(changeset or {}) do
        local entry = type(op) == "table" and op.entry or nil
        local ns = entry_namespace(entry and entry.id)
        if ns and ns ~= "" then namespaces[ns] = true end
    end
end

local function add_namespaces_from_graph(namespaces, graph)
    for _, node in ipairs(graph or {}) do
        local ns = trim(node and node.namespace)
        if ns == "" then ns = namespace_from_component(node and node.module) end
        if ns and ns ~= "" then namespaces[ns] = true end
    end
end

function Service:restart_namespaces(data)
    data = data or {}
    local namespaces = {}
    add_namespaces_from_entries(namespaces, data.entries)
    add_namespaces_from_changeset(namespaces, data.changeset)
    add_namespaces_from_graph(namespaces, data.graph)
    return namespaces
end

function Service:list_running_processes()
    local sys = self.system
    if not sys or not sys.hosts or not sys.hosts.list or not sys.hosts.processes then
        return nil, "system.hosts inspector unavailable"
    end

    local hosts, hosts_err = sys.hosts.list()
    if not hosts then return nil, "system.hosts.list: " .. tostring(hosts_err) end

    local out = {}
    for _, host in ipairs(hosts or {}) do
        local host_id = tostring(host.id or "")
        if host_id ~= "" then
            local procs, procs_err = sys.hosts.processes(host_id)
            if not procs then
                return nil, "system.hosts.processes(" .. host_id .. "): " .. tostring(procs_err)
            end
            for _, proc_row in ipairs(procs or {}) do
                table.insert(out, proc_row)
            end
        end
    end

    return out, nil
end

function Service:process_service_entries()
    if not self.registry or not self.registry.find then
        return nil, "registry.find unavailable"
    end
    local services, find_err = self.registry.find({ [".kind"] = "process.service" })
    if not services then return nil, "registry.find process.service: " .. tostring(find_err) end
    return services or {}, nil
end

function Service:restart_preview(data)
    local namespaces = self:restart_namespaces(data)
    local preview = {
        namespaces = sorted_keys(namespaces),
        services = {},
        warnings = {},
    }
    if #preview.namespaces == 0 then return preview end

    local services, svc_err = self:process_service_entries()
    if not services then
        add_restart_warning(preview.warnings, svc_err)
        return preview
    end

    local processes, proc_err = self:list_running_processes()
    if not processes then
        add_restart_warning(preview.warnings, proc_err)
        return preview
    end

    local by_source = {}
    for _, proc_row in ipairs(processes or {}) do
        local source = trim(proc_row.source)
        if source ~= "" then
            by_source[source] = by_source[source] or {}
            table.insert(by_source[source], proc_row)
        end
    end

    local seen = {}
    for _, svc in ipairs(services or {}) do
        local service_id = trim(svc.id)
        local service_ns = entry_namespace(service_id) or ""
        local svc_data = type(svc.data) == "table" and svc.data or svc
        local source = qualify_entry_id(tostring(svc_data.process or ""), service_ns)
        local source_ns = entry_namespace(source)
        if source and source_ns and namespaces[source_ns] then
            for _, proc_row in ipairs(by_source[source] or {}) do
                local pid = trim(proc_row.pid)
                local key = service_id .. "\n" .. pid
                if pid ~= "" and not seen[key] then
                    seen[key] = true
                    local meta = type(svc.meta) == "table" and svc.meta or {}
                    local target = type(meta.upgrade_target) == "string" and trim(meta.upgrade_target) or ""
                    local upgradable = meta.upgradable == true and target ~= ""
                    table.insert(preview.services, {
                        service_id = service_id,
                        source = source,
                        pid = pid,
                        host = tostring(proc_row.host or svc_data.host or ""),
                        state = tostring(proc_row.state or ""),
                        mechanism = upgradable and "upgrade" or "respawn",
                        upgrade_target = upgradable and target or nil,
                        upgrade_topic = upgradable and (meta.upgrade_topic or "system.upgrade") or nil,
                    })
                end
            end
        end
    end

    table.sort(preview.services, function(a, b)
        if a.service_id ~= b.service_id then return a.service_id < b.service_id end
        return tostring(a.pid) < tostring(b.pid)
    end)

    return preview
end

function Service:signal_service_upgrade(row)
    if not self.process or not self.process.send then
        return false, "process.send unavailable"
    end
    local target = row.upgrade_target
    if trim(target) == "" then
        return false, "upgrade target unavailable"
    end
    local topic = trim(row.upgrade_topic) ~= "" and row.upgrade_topic or "system.upgrade"
    local ok, send_err = self.process.send(target, topic, {
        reason = "module.update",
        process = row.source,
        service = row.service_id,
        deadline = "30s",
    })
    if not ok then
        return false, send_err and tostring(send_err) or "process.send returned false"
    end
    return true, nil
end

function Service:terminate_for_respawn(row)
    if not self.process or not self.process.terminate then
        return false, "process.terminate unavailable"
    end
    local ok, terminate_err = self.process.terminate(row.pid)
    if terminate_err then return false, tostring(terminate_err) end
    if ok == false or ok == nil then return false, "process.terminate returned false" end
    return true, nil
end

function Service:restart_affected_services(data)
    local preview = self:restart_preview(data)
    local result = {
        ok = true,
        namespaces = preview.namespaces,
        outcomes = {},
        warnings = {},
        errors = {},
    }
    for _, warning in ipairs(preview.warnings or {}) do
        add_restart_warning(result.warnings, warning)
        table.insert(result.errors, warning)
    end

    for _, row in ipairs(preview.services or {}) do
        local outcome = shallow_copy(row)
        if row.mechanism == "upgrade" then
            local upgrade_ok, upgrade_err = self:signal_service_upgrade(row)
            if upgrade_ok then
                outcome.status = "upgrade_signaled"
            else
                outcome.upgrade_error = upgrade_err
                local respawn_ok, respawn_err = self:terminate_for_respawn(row)
                outcome.mechanism = "respawn"
                if respawn_ok then
                    outcome.status = "restarted"
                    outcome.warning = "upgrade signal failed; respawned instead: " .. tostring(upgrade_err)
                    add_restart_warning(result.warnings,
                        "upgrade signal failed for " .. row.service_id .. "; respawned instead: " .. tostring(upgrade_err))
                else
                    outcome.status = "failed"
                    outcome.error = "upgrade signal failed: " .. tostring(upgrade_err)
                        .. "; respawn failed: " .. tostring(respawn_err)
                end
            end
        else
            local restart_ok, restart_err = self:terminate_for_respawn(row)
            if restart_ok then
                outcome.status = "restarted"
            else
                outcome.status = "failed"
                outcome.error = restart_err
            end
        end

        if outcome.status == "failed" then
            local msg = "failed to restart " .. tostring(row.service_id) .. " (" .. tostring(row.pid) .. "): "
                .. tostring(outcome.error)
            add_restart_warning(result.warnings, msg)
            table.insert(result.errors, msg)
        end
        table.insert(result.outcomes, outcome)
    end

    result.service_count = #result.outcomes
    result.warning_count = #result.warnings
    result.error_count = #result.errors
    return result, nil
end

function Service:append_restart_warnings(payload, restart_result)
    if not restart_result or #(restart_result.warnings or {}) == 0 then return end
    payload.warnings = payload.warnings or {}
    for _, warning in ipairs(restart_result.warnings or {}) do
        table.insert(payload.warnings, warning)
    end
end

function Service:install_step_dispatch(opts)
    local svc = self
    return function(step)
        local op = step.op
        if op == "pre_apply_validate" then
            local result, validation_err = svc:validate_planned_entries(
                step.data.changeset or {}, step.data.planned_entries or {})
            if not result then
                return { op = op, label = step.label, error = validation_err }
            end
            return { op = op, label = step.label, result = result }
        elseif op == "governance_apply" then
            local apply_result, apply_err = svc:publish_dependency_changeset({
                action = step.data.action,
                entry = step.data.entry,
                actor_id = opts.actor_id,
                message = step.data.message,
            })
            if not apply_result then
                return { op = op, label = step.label, error = apply_err }
            end
            return {
                op = op, label = step.label, result = apply_result,
                inverse = { op = "restore_registry_version", data = {
                    version = step.data.baseline_version,
                    reason = "hub install rollback for " .. tostring(step.data.entry.data.component),
                } },
            }
        elseif op == "lockfile_commit" then
            local lock_result, write_err = svc:commit_lock_update(step.data.lock_update)
            if not lock_result then
                return { op = op, label = step.label, error = write_err }
            end
            return {
                op = op, label = step.label, result = lock_result,
                inverse = { op = "restore_lock_update", data = { lock_update = step.data.lock_update } },
            }
        elseif op == "migrations_up" then
            local migration_result, migration_err = svc:run_migrations({
                component = step.data.component,
                operation = "up",
            }, opts)
            if not migration_result then
                return { op = op, label = step.label, error = migration_err }
            end
            return {
                op = op, label = step.label, result = migration_result,
                inverse = { op = "migrations_down", data = { entry_ids = migration_result.entry_ids or {} } },
            }
        elseif op == "restart_affected_services" then
            local restart_result = svc:restart_affected_services(step.data)
            return {
                op = op, label = step.label, result = restart_result,
                inverse = { op = "restart_affected_services_noop" },
            }
        end
        return { op = op, label = step.label, error = err("INTERNAL", "unknown install step: " .. tostring(op)) }
    end
end

-- Install rollback dispatcher: install compensations are unconditional
-- (restore registry + restore lock), matching the original best-effort flow.
function Service:install_rollback_dispatch()
    local svc = self
    return function(row)
        local inv = row.inverse
        if type(inv) ~= "table" then return nil end
        local wrapped = { op = inv.op, forward_label = row.label }
        if inv.op == "restore_registry_version" then
            local r, e = svc:restore_registry_version(inv.data.version, inv.data.reason)
            wrapped.result, wrapped.error = r, e
        elseif inv.op == "restore_lock_update" then
            local r, e = svc:restore_lock_update(inv.data.lock_update)
            wrapped.result, wrapped.error = r, e
        else
            return nil
        end
        return wrapped
    end
end

function Service:install(args, opts)
    args = args or {}
    opts = opts or {}

    local plan, plan_err = self:plan_install(args)
    if not plan then return nil, plan_err end
    if #(plan.missing_requirements or {}) > 0 then
        return nil, err("REQUIREMENTS_MISSING", "Hub dependency requires explicit configuration", {
            dependency = plan.dependency,
            requirements = plan.requirements,
            missing_requirements_by_id = string_set(plan.missing_requirements),
            missing_requirements_count = #(plan.missing_requirements or {}),
        })
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

    local planned_changeset_op, planned_changeset_err = self:dependency_create_or_update_op(entry)
    if not planned_changeset_op then return nil, planned_changeset_err end
    local planned_changeset = { planned_changeset_op }

    local payload = {
        dependency = M.dependency_summary(entry),
        patches = { patch },
        migration_policy = planned.migration_policy or (args.run_migrations == true and "up" or "none"),
        plan = plan,
    }

    local lock_update, lock_err = self:prepare_install_lock_update(plan)
    if not lock_update then return nil, lock_err end
    payload.lock = self.lockfile.summary(M.LOCK_PATH, lock_update)

    local restart_data = {
        action = "install",
        entries = plan.planned_entries or plan.entries or {},
        changeset = planned_changeset,
        graph = plan.graph or {},
    }
    payload.restart_preview = self:restart_preview(restart_data)

    -- Plan and guards are complete. The dry-run short-circuit is the hard
    -- boundary before any step runs — dry_run reaches zero steps.
    if args.dry_run == true then
        payload.dry_run = true
        return payload, nil
    end

    local policy = planned.migration_policy
    if args.run_migrations == true then policy = "up" end

    local baseline_version
    if policy == "up" or lock_update.changed == true then
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

    -- Build the ordered install steps. governance_apply is the one atomic
    -- publish; lockfile_commit and migrations_up only appear when they have
    -- work to do.
    local steps = {
        {
            op = "pre_apply_validate", label = "validation",
            data = {
                changeset = planned_changeset,
                planned_entries = plan.planned_entries or plan.entries or {},
            },
        },
        {
            op = "governance_apply", label = "governance",
            data = {
                action = "install",
                entry = entry,
                message = "hub install " .. entry.id .. " " .. entry.data.component .. " " .. entry.data.version,
                baseline_version = baseline_version,
            },
        },
    }
    if lock_update.changed == true then
        table.insert(steps, { op = "lockfile_commit", label = "lockfile", data = { lock_update = lock_update } })
    end
    if policy == "up" then
        table.insert(steps, { op = "migrations_up", label = "migrations", data = { component = entry.data.component } })
    end
    table.insert(steps, {
        op = "restart_affected_services",
        label = "restart affected services",
        data = restart_data,
    })

    local ledger = step_runner.run(steps, { execute = self:install_step_dispatch(opts) })

    if not ledger.success then
        return self:install_failure(ledger, payload, {
            operation_id = operation_id,
            baseline_version = baseline_version,
        }, opts)
    end

    -- Lift the step results into the payload for API back-compat.
    local apply_result, migration_result, restart_result
    for _, row in ipairs(ledger.execution.handlers) do
        if row.op == "governance_apply" then apply_result = row.result
        elseif row.op == "lockfile_commit" then payload.lock = row.result
        elseif row.op == "migrations_up" then migration_result = row.result
        elseif row.op == "restart_affected_services" then restart_result = row.result end
    end
    payload.apply = apply_result
    payload.migrations = migration_result
    payload.restart = restart_result
    self:append_restart_warnings(payload, restart_result)
    payload.execution = self:project_ledger(ledger, nil)

    self:emit_operation(opts.actor_id, M.EVENTS.INSTALL_FINISHED, operation_id, {
        dependency = payload.dependency,
        apply = apply_result,
        migrations = migration_result,
        restart = restart_result,
        warnings = (payload :: any).warnings,
        execution = payload.execution,
    })

    return payload, nil
end

function Service:install_failure(ledger, payload, ctx, opts)
    local rows = ledger.execution.handlers
    local failed = rows[#rows]
    local failed_op = failed and failed.op
    local failed_err = failed and failed.error

    -- The publish itself failing needs no compensation: nothing was applied.
    if failed_op == "governance_apply" then
        payload.execution = self:project_ledger(ledger, nil)
        self:emit_operation(opts.actor_id, M.EVENTS.INSTALL_FAILED, ctx.operation_id, {
            dependency = payload.dependency,
            error = error_summary(failed_err),
            execution = payload.execution,
        })
        return nil, failed_err
    end

    local rollback_ledger = step_runner.reverse(registry_restore_first(ledger.execution),
        { execute = self:install_rollback_dispatch() })
    local restore = self:find_rollback_row(rollback_ledger, "restore_registry_version")
    local lock_restore = self:find_rollback_row(rollback_ledger, "restore_lock_update")

    payload.rollback = restore and restore.result or nil
    payload.rollback_error = restore and error_summary(restore.error) or nil
    if lock_restore then
        payload.lock_rollback = lock_restore.result
        payload.lock_rollback_error = error_summary(lock_restore.error)
    end
    payload.execution = self:project_ledger(ledger, rollback_ledger)

    local restore_ok = restore ~= nil and restore.result ~= nil and restore.error == nil
    local apply_result = self:ledger_result(ledger, "governance_apply")
    local failure_err
    if failed_op == "lockfile_commit" then
        if restore_ok then
            failure_err = err("LOCK_UPDATE_FAILED",
                "dependency installed but wippy.lock update failed; registry restored to baseline",
                {
                    lock_error = error_summary(failed_err),
                    baseline_version = ctx.baseline_version,
                    rollback = payload.rollback,
                    apply = apply_result,
                    execution = execution_details(payload.execution),
                })
        else
            failure_err = err("ROLLBACK_FAILED",
                "dependency installed, wippy.lock update failed, and registry rollback failed",
                {
                    lock_error = error_summary(failed_err),
                    baseline_version = ctx.baseline_version,
                    rollback_error = payload.rollback_error,
                    apply = apply_result,
                    execution = execution_details(payload.execution),
                })
        end
    elseif failed_op == "migrations_up" then
        if restore_ok then
            failure_err = err("MIGRATIONS_FAILED",
                "migrations failed after dependency install; registry restored to baseline",
                {
                    migration_error = error_summary(failed_err),
                    baseline_version = ctx.baseline_version,
                    rollback = payload.rollback,
                    lock_rollback = payload.lock_rollback,
                    lock_rollback_error = payload.lock_rollback_error,
                    apply = apply_result,
                    execution = execution_details(payload.execution),
                })
        else
            failure_err = err("ROLLBACK_FAILED",
                "migrations failed after dependency install and registry rollback failed",
                {
                    migration_error = error_summary(failed_err),
                    baseline_version = ctx.baseline_version,
                    rollback_error = payload.rollback_error,
                    lock_rollback = payload.lock_rollback,
                    lock_rollback_error = payload.lock_rollback_error,
                    apply = apply_result,
                    execution = execution_details(payload.execution),
                })
        end
    else
        failure_err = failed_err or err("INTERNAL", "hub install failed")
    end

    self:emit_operation(opts.actor_id, M.EVENTS.INSTALL_FAILED, ctx.operation_id, {
        dependency = payload.dependency,
        error = error_summary(failure_err),
        rollback = payload.rollback,
        rollback_error = payload.rollback_error,
        execution = payload.execution,
    })
    return nil, failure_err
end

function Service:plan_uninstall(args)
    args = args or {}
    local dep, dep_err = self:find_dependency(args)
    if not dep then return nil, dep_err end

    local summary = M.dependency_summary(dep)

    -- Refuse to uninstall a root that another installed root still requires. The
    -- installed-closure inventory names, per module, the deployment roots whose
    -- dependency closure reaches it (used_by); a non-empty used_by for the target
    -- means removing it would break those roots. This is the same derivation the
    -- list API reports, and it runs before any registry/lock mutation, so the
    -- target's own row is never removed until the check passes.
    local all_deps, all_err = self:dependency_entries()
    if not all_deps then return nil, all_err end
    local _, inventory_by_name = self:installed_module_inventory(all_deps)
    local target_inventory = inventory_by_name and inventory_by_name[summary.component]
    if target_inventory and #(target_inventory.used_by or {}) > 0 then
        local required_by = {}
        for _, root in ipairs(target_inventory.used_by) do table.insert(required_by, root) end
        table.sort(required_by)
        -- Error details drop numeric-keyed arrays crossing the errors boundary, so
        -- the dependent roots travel as a string-keyed positional map (recover the
        -- list with pairs / Object.values) alongside the human-readable summary.
        local required_by_detail = {}
        for i, root in ipairs(required_by) do required_by_detail[tostring(i)] = root end
        return nil, err("DEPENDENCY_REQUIRED",
            "cannot uninstall " .. tostring(summary.component)
            .. "; still required by " .. table.concat(required_by, ", "),
            {
                dependency = summary,
                required_by = required_by_detail,
                required_by_text = table.concat(required_by, ", "),
            })
    end

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

    local keep_modules, unresolved_modules, keep_err = self:plan_uninstall_closure(dep)
    if not keep_modules then
        return nil, err("DEPENDENCY_GRAPH_FAILED",
            "failed to resolve dependency graph for uninstall; refusing to update registry or wippy.lock",
            {
                dependency = summary,
                graph_error = error_summary(keep_err),
            })
    end

    return {
        dependency = summary,
        entries = entries,
        entries_count = #entries,
        migrations = migrations,
        applied_migrations = applied,
        applied_migrations_count = #applied,
        keep_modules = keep_modules,
        unresolved_modules = unresolved_modules,
        target_module = summary.component,
        patch = { target = "entry", id = dep.id, op = "delete" },
    }, nil
end

-- Projects the raw lock diff into a UI-ready uninstall preview: what is removed,
-- what transitive dependencies of the target are retained because a remaining
-- root still needs them, what is withheld under uncertainty, and any warnings.
-- The UI consumes this directly instead of diffing lock internals.
function Service:build_uninstall_preview(plan, lock_changes)
    lock_changes = lock_changes or {}
    local target = trim(plan.target_module)

    local lock_versions = {}
    local lock_state = self:read_lock()
    if type(lock_state) == "table" and type(lock_state.doc) == "table" then
        for _, row in ipairs(lock_state.doc.modules or {}) do
            local name = trim(row.name)
            if name ~= "" then lock_versions[name] = tostring(row.version or "") end
        end
    end

    local function project(rows)
        local out = {}
        for _, row in ipairs(rows or {}) do
            local name = trim(row.name)
            table.insert(out, { name = name, version = tostring(row.version or lock_versions[name] or "") })
        end
        return out
    end

    local kept = {}
    local target_keep = self:resolve_dependency_closure({ target })
    if target_keep then
        local keep_modules = plan.keep_modules or {}
        local names = {}
        for name in pairs(target_keep) do
            if name ~= target and keep_modules[name] then table.insert(names, name) end
        end
        table.sort(names)
        for _, name in ipairs(names) do
            table.insert(kept, { name = name, version = lock_versions[name] or "" })
        end
    end

    return {
        removed = project(lock_changes.removed),
        kept = kept,
        kept_under_uncertainty = project(lock_changes.kept_under_uncertainty),
        warnings = {},
    }
end

-- Uninstall step dispatcher. migrations_down runs before the registry delete so
-- the down migration can be restored if a later step fails.
function Service:uninstall_step_dispatch(opts)
    local svc = self
    return function(step)
        local op = step.op
        if op == "migrations_down" then
            local migration_result, migration_err = svc:run_migrations({
                entry_ids = step.data.entry_ids,
                operation = "down",
            }, opts)
            if not migration_result then
                return { op = op, label = step.label, error = migration_err }
            end
            return {
                op = op, label = step.label, result = migration_result,
                inverse = { op = "migrations_up_restore", data = { entry_ids = step.data.entry_ids } },
            }
        elseif op == "governance_apply" then
            local apply_result, apply_err = svc:publish_dependency_changeset({
                action = "uninstall",
                id = step.data.id,
                actor_id = opts.actor_id,
                message = step.data.message,
            })
            if not apply_result then
                return { op = op, label = step.label, error = apply_err }
            end
            return {
                op = op, label = step.label, result = apply_result,
                inverse = { op = "restore_registry_version", data = {
                    version = step.data.baseline_version,
                    reason = "hub uninstall rollback for " .. tostring(step.data.id),
                } },
            }
        elseif op == "lockfile_prune" then
            local lock_result, write_err = svc:commit_lock_update(step.data.lock_update)
            if not lock_result then
                return { op = op, label = step.label, error = write_err }
            end
            return {
                op = op, label = step.label, result = lock_result,
                inverse = { op = "restore_lock_update", data = { lock_update = step.data.lock_update } },
            }
        elseif op == "restart_affected_services" then
            local restart_result = svc:restart_affected_services(step.data)
            return {
                op = op, label = step.label, result = restart_result,
                inverse = { op = "restart_affected_services_noop" },
            }
        end
        return { op = op, label = step.label, error = err("INTERNAL", "unknown uninstall step: " .. tostring(op)) }
    end
end

-- Uninstall rollback dispatcher. Unlike install, the down-migration re-apply is
-- only attempted when the registry restore succeeded — the original conservative
-- ordering. That policy lives here (hub domain knowledge); step_runner.reverse
-- stays a generic reverse walk. migration restore outcomes are stitched onto the
-- payload so the failure mapper can report them.
function Service:uninstall_rollback_dispatch(opts, payload)
    local svc = self
    local registry_restored = true
    return function(row)
        local inv = row.inverse
        if type(inv) ~= "table" then return nil end
        local wrapped = { op = inv.op, forward_label = row.label }
        if inv.op == "restore_registry_version" then
            local r, e = svc:restore_registry_version(inv.data.version, inv.data.reason)
            registry_restored = (r ~= nil and e == nil)
            wrapped.result, wrapped.error = r, e
        elseif inv.op == "restore_lock_update" then
            local r, e = svc:restore_lock_update(inv.data.lock_update)
            wrapped.result, wrapped.error = r, e
        elseif inv.op == "migrations_up_restore" then
            if not registry_restored then
                wrapped.skipped = true
                return wrapped
            end
            local r, e = svc:run_migrations({
                entry_ids = inv.data.entry_ids,
                operation = "up",
                only_pending = false,
            }, opts)
            payload.migration_restore = r
            payload.migration_restore_error = error_summary(e)
            wrapped.result, wrapped.error = r, e
        else
            return nil
        end
        return wrapped
    end
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

    local lock_update, lock_err = self:prepare_uninstall_lock_update(plan)
    if not lock_update then return nil, lock_err end
    payload.lock = self.lockfile.summary(M.LOCK_PATH, lock_update)

    -- Surface a withheld transitive prune loudly: a still-needed module of an
    -- unresolved remaining root was kept, so this is never a silent no-op.
    local lock_changes = lock_update.changes or {}
    if lock_changes.uncertain == true then
        local kept_names = {}
        for _, row in ipairs(lock_changes.kept_under_uncertainty or {}) do
            table.insert(kept_names, tostring(row.name))
        end
        payload.uncertain = true
        payload.uncertain_roots = lock_changes.uncertain_modules or {}
        payload.kept_under_uncertainty = kept_names
        payload.lock_warning = "wippy.lock pruning withheld for modules that may still be required by unresolved roots ["
            .. table.concat(lock_changes.uncertain_modules or {}, ", ") .. "]: kept " .. table.concat(kept_names, ", ")
    end

    local preview = self:build_uninstall_preview(plan, lock_changes)
    if payload.lock_warning then table.insert(preview.warnings, payload.lock_warning) end
    if plan.applied_migrations_count > 0 and policy == "leave" then
        table.insert(preview.warnings, "applied migrations will remain in the database after uninstall")
    end
    payload.preview = preview

    local restart_data = {
        action = "uninstall",
        entries = plan.entries or {},
        graph = {},
    }
    payload.restart_preview = self:restart_preview(restart_data)

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

    local baseline_version
    if lock_update.changed == true then
        local version, version_err = self:current_registry_version()
        if not version then return nil, version_err end
        baseline_version = version
        payload.baseline_version = baseline_version
    end

    -- Build the ordered uninstall steps. The down migration (policy=down) runs
    -- before the registry delete; the lockfile prune runs last.
    local steps = {}
    if plan.applied_migrations_count > 0 and policy == "down" then
        local ids = {}
        for _, row in ipairs(plan.applied_migrations) do table.insert(ids, row.id) end
        table.insert(steps, { op = "migrations_down", label = "migrations", data = { entry_ids = ids } })
    elseif plan.applied_migrations_count > 0 and policy == "leave" then
        payload.warning = "applied migrations were left in place"
    end
    table.insert(steps, {
        op = "governance_apply", label = "governance",
        data = {
            id = plan.dependency.id,
            message = "hub uninstall " .. tostring(plan.dependency.id),
            baseline_version = baseline_version,
        },
    })
    if lock_update.changed == true then
        table.insert(steps, { op = "lockfile_prune", label = "lockfile", data = { lock_update = lock_update } })
    end
    table.insert(steps, {
        op = "restart_affected_services",
        label = "restart affected services",
        data = restart_data,
    })

    local ledger = step_runner.run(steps, { execute = self:uninstall_step_dispatch(opts) })

    if not ledger.success then
        return self:uninstall_failure(ledger, payload, {
            operation_id = operation_id,
            baseline_version = baseline_version,
        }, opts)
    end

    local apply_result, migration_result, restart_result
    for _, row in ipairs(ledger.execution.handlers) do
        if row.op == "governance_apply" then apply_result = row.result
        elseif row.op == "lockfile_prune" then payload.lock = row.result
        elseif row.op == "migrations_down" then migration_result = row.result
        elseif row.op == "restart_affected_services" then restart_result = row.result end
    end
    payload.apply = apply_result
    payload.migrations = migration_result
    payload.restart = restart_result
    self:append_restart_warnings(payload, restart_result)
    payload.execution = self:project_ledger(ledger, nil)

    self:emit_operation(opts.actor_id, M.EVENTS.UNINSTALL_FINISHED, operation_id, {
        dependency = payload.dependency,
        apply = apply_result,
        migrations = migration_result,
        warning = payload.warning,
        restart = restart_result,
        warnings = (payload :: any).warnings,
        execution = payload.execution,
    })

    return payload, nil
end

function Service:uninstall_failure(ledger, payload, ctx, opts)
    local rows = ledger.execution.handlers
    local failed = rows[#rows]
    local failed_op = failed and failed.op
    local failed_err = failed and failed.error

    -- The down migration failing first applied nothing to compensate for.
    if failed_op == "migrations_down" then
        payload.execution = self:project_ledger(ledger, nil)
        self:emit_operation(opts.actor_id, M.EVENTS.UNINSTALL_FAILED, ctx.operation_id, {
            dependency = payload.dependency,
            error = error_summary(failed_err),
            execution = payload.execution,
        })
        return nil, failed_err
    end

    local rollback_ledger = step_runner.reverse(registry_restore_first(ledger.execution),
        { execute = self:uninstall_rollback_dispatch(opts, payload) })
    local restore = self:find_rollback_row(rollback_ledger, "restore_registry_version")

    payload.rollback = restore and restore.result or nil
    payload.rollback_error = restore and error_summary(restore.error) or nil
    payload.execution = self:project_ledger(ledger, rollback_ledger)

    local apply_result = self:ledger_result(ledger, "governance_apply")
    local failure_err
    if failed_op == "governance_apply" then
        failure_err = err("UNINSTALL_APPLY_FAILED",
            "dependency migrations were rolled back but registry uninstall failed",
            {
                apply_error = error_summary(failed_err),
                migration_restore = payload.migration_restore,
                migration_restore_error = payload.migration_restore_error,
                execution = execution_details(payload.execution),
            })
    elseif failed_op == "lockfile_prune" then
        local restore_ok = restore ~= nil and restore.result ~= nil and restore.error == nil
        if restore_ok then
            failure_err = err("LOCK_UPDATE_FAILED",
                "dependency uninstalled but wippy.lock update failed; registry restored to baseline",
                {
                    lock_error = error_summary(failed_err),
                    baseline_version = ctx.baseline_version,
                    rollback = payload.rollback,
                    migration_restore = payload.migration_restore,
                    migration_restore_error = payload.migration_restore_error,
                    apply = apply_result,
                    execution = execution_details(payload.execution),
                })
        else
            failure_err = err("ROLLBACK_FAILED",
                "dependency uninstalled, wippy.lock update failed, and registry rollback failed",
                {
                    lock_error = error_summary(failed_err),
                    baseline_version = ctx.baseline_version,
                    rollback_error = payload.rollback_error,
                    apply = apply_result,
                    execution = execution_details(payload.execution),
                })
        end
    else
        failure_err = failed_err or err("INTERNAL", "hub uninstall failed")
    end

    self:emit_operation(opts.actor_id, M.EVENTS.UNINSTALL_FAILED, ctx.operation_id, {
        dependency = payload.dependency,
        error = error_summary(failure_err),
        rollback = payload.rollback,
        rollback_error = payload.rollback_error,
        migration_restore = payload.migration_restore,
        migration_restore_error = payload.migration_restore_error,
        execution = payload.execution,
    })
    return nil, failure_err
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

    local call_params = {
        operation = operation,
        entry_ids = ids,
        actor_id = opts.actor_id,
    }
    if args.only_pending ~= nil then call_params.only_pending = args.only_pending end
    if args.only_applied ~= nil then call_params.only_applied = args.only_applied end

    local result, call_err = self:call_func(M.MIGRATION_HANDLER_FN, call_params)
    if not result then
        self:emit_operation(opts.actor_id, M.EVENTS.MIGRATIONS_FAILED, operation_id, {
            operation = operation,
            entry_ids = ids,
            error = error_summary(call_err),
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

function Service:list_migrations(args)
    local rows, rows_err = self:migration_rows(args or {})
    if not rows then return nil, rows_err end
    return { migrations = rows, count = #rows }, nil
end

function M.install(args, opts)
    return M.new():install(args, opts)
end

function M.uninstall(args, opts)
    return M.new():uninstall(args, opts)
end

function M.list_migrations(args)
    return M.new():list_migrations(args)
end

function M.run_migrations(args, opts)
    return M.new():run_migrations(args, opts)
end

return M
