local test = require("test")
local hub = require("hub_service")
local planner = require("planner")
local lockfile = require("lockfile")
local hub_dependencies_tool = require("hub_dependencies_tool")
local hub_migrations_tool = require("hub_migrations_tool")

local function fake_registry(entries)
    local by_id = {}
    for _, entry in ipairs(entries or {}) do by_id[entry.id] = entry end

    local function matches(entry, criteria)
        for key, expected in pairs(criteria or {}) do
            if key == ".kind" then
                if entry.kind ~= expected then return false end
            elseif key == "meta.module" then
                if not entry.meta or entry.meta.module ~= expected then return false end
            elseif key == "meta.type" then
                if not entry.meta or entry.meta.type ~= expected then return false end
            else
                if entry[key] ~= expected then return false end
            end
        end
        return true
    end

    return {
        find = function(criteria)
            local out = {}
            for _, entry in ipairs(entries or {}) do
                if matches(entry, criteria or {}) then table.insert(out, entry) end
            end
            return out, nil
        end,
        get = function(id)
            return by_id[id], nil
        end,
    }
end

local function fake_sql(applied)
    applied = applied or {}
    return {
        get = function()
            return {
                query = function(_, _, params)
                    local id = params and params[1]
                    if applied[id] then return { { id = id } }, nil end
                    return {}, nil
                end,
                release = function() end,
            }, nil
        end,
    }
end

local function fake_process(sent)
    sent = sent or {}
    return {
        registry = {
            lookup = function(name)
                if name == "user.admin-1" then return "pid-user-admin-1" end
                return nil, "missing"
            end,
        },
        send = function(pid, topic, payload)
            table.insert(sent, { pid = pid, topic = topic, payload = payload })
            return true
        end,
    }
end

local function fake_uuid()
    local n = 0
    return {
        v7 = function()
            n = n + 1
            return "op-" .. n
        end,
    }
end

local function err_details(e)
    if e == nil then return nil end
    if type(e) == "table" and type(e.details) ~= "function" then return e.details end
    local ok, details = pcall(function() return e:details() end)
    if ok then return details end
    return nil
end

local function err_code(e)
    local details = err_details(e)
    if type(details) == "table" and details.code then return details.code end
    if type(e) == "table" then return e.code end
    return nil
end

local function err_kind(e)
    if e == nil then return nil end
    if type(e) == "table" and type(e.kind) ~= "function" then return e.kind end
    local ok, kind = pcall(function() return e:kind() end)
    if ok then return kind end
    return nil
end

local function err_message(e)
    if e == nil then return nil end
    if type(e) == "table" and type(e.message) ~= "function" then return e.message end
    local ok, message = pcall(function() return e:message() end)
    if ok then return message end
    return tostring(e)
end

local function fake_governance(state)
    state = state or {}
    return {
        current_version = function()
            state.current_calls = (state.current_calls or 0) + 1
            if state.current_error then return nil, state.current_error end
            return state.current_version or 41, nil
        end,
        restore_version = function(version, reason)
            state.restore_calls = (state.restore_calls or 0) + 1
            state.restored_version = version
            state.restore_reason = reason
            if state.restore_error then return nil, state.restore_error end
            return { version = version, reason = reason }, nil
        end,
        publish = function(changeset, options)
            state.publish_calls = (state.publish_calls or 0) + 1
            state.last_changeset = changeset
            state.last_options = options
            if state.publish_error then return nil, state.publish_error end
            return state.publish_result or {
                version = state.publish_version or ((state.current_version or 41) + 1),
                message = "published",
            }, nil
        end,
    }
end

local function deep_copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = deep_copy(v) end
    return out
end

local function fake_project_fs(files, opts)
    files = files or {}
    opts = opts or {}
    return {
        files = files,
        get = function(id)
            if id ~= hub.PROJECT_FS_ID then return nil, "unexpected fs id: " .. tostring(id) end
            return {
                readfile = function(_, path)
                    if files[path] == nil then return nil, "missing: " .. tostring(path) end
                    return files[path], nil
                end,
                writefile = function(_, path, content)
                    if opts.write_error then return nil, opts.write_error end
                    if opts.write_false then return false, opts.write_false end
                    files[path] = content
                    return true, nil
                end,
            }, nil
        end,
    }
end

local function fake_yaml_for_lock(initial_doc)
    return {
        decode = function()
            return deep_copy(initial_doc), nil
        end,
        encode = function(doc)
            local rows = {}
            for _, row in ipairs(doc.modules or {}) do
                table.insert(rows, tostring(row.name) .. "@" .. tostring(row.version) .. "#" .. tostring(row.hash))
            end
            table.sort(rows)
            return table.concat(rows, "\n"), nil
        end,
    }
end

local function graph_planner(graph)
    return {
        plan_install = function(args)
            local entry, entry_err = hub.build_dependency_entry(args)
            if not entry then return nil, entry_err end
            local data = entry.data or {}
            return {
                dependency = hub.dependency_summary(entry),
                graph = graph or {},
                module_count = #(graph or {}),
                requirements = {},
                requirement_count = 0,
                missing_requirements = {},
                parameter_values = {},
                recommended_parameters = data.parameters or {},
                install_payload = {
                    id = entry.id,
                    component = data.component,
                    version = data.version,
                    parameters = data.parameters or {},
                    migration_policy = args.migration_policy or (args.run_migrations == true and "up" or "none"),
                },
            }, nil
        end,
    }
end

local function no_requirements_planner()
    return {
        plan_install = function(args)
            local entry, entry_err = hub.build_dependency_entry(args)
            if not entry then return nil, entry_err end
            local data = entry.data or {}
            return {
                dependency = hub.dependency_summary(entry),
                graph = {},
                module_count = 0,
                requirements = {},
                requirement_count = 0,
                missing_requirements = {},
                parameter_values = {},
                recommended_parameters = data.parameters or {},
                install_payload = {
                    id = entry.id,
                    component = data.component,
                    version = data.version,
                    parameters = data.parameters or {},
                    migration_policy = args.migration_policy or (args.run_migrations == true and "up" or "none"),
                },
            }, nil
        end,
    }
end

local function fake_catalog(versions_by_component)
    local dependencies_by_component = versions_by_component.__dependencies or {}
    versions_by_component.__dependencies = nil
    return {
        versions = {
            list = function(component, opts)
                local items = versions_by_component[component] or {}
                return {
                    items = items,
                    total = #items,
                    page = opts and opts.page or 1,
                    page_size = opts and opts.page_size or #items,
                }, nil
            end,
            get = function(component, opts)
                local items = versions_by_component[component] or {}
                local id = opts and opts.id or ""
                local version = opts and opts.version or ""
                local label = opts and opts.label or ""
                for _, item in ipairs(items) do
                    if (id ~= "" and item.id == id) or
                        (version ~= "" and item.version == version) or
                        (label ~= "" and (item.version == label or item.label == label)) then
                        if item.detail then return item.detail, nil end
                        return item, nil
                    end
                end
                return nil, "not found"
            end,
            inspect = function(component, opts)
                local items = versions_by_component[component] or {}
                local id = opts and opts.id or ""
                local version = opts and opts.version or ""
                local label = opts and opts.label or ""
                for _, item in ipairs(items) do
                    if (id ~= "" and item.id == id) or
                        (version ~= "" and item.version == version) or
                        (label ~= "" and (item.version == label or item.label == label)) then
                        if item.inspect then return item.inspect, nil end
                        return nil, "artifact unavailable"
                    end
                end
                return nil, "not found"
            end,
        },
        dependencies = {
            get = function(component, version)
                local items = dependencies_by_component[component] or {}
                local wanted = tostring(version or "")
                if type(version) == "table" then
                    wanted = tostring(version.version or version.id or version.label or "")
                end
                for _, item in ipairs(items) do
                    if wanted == "" or item.version == wanted then
                        return { items = item.dependencies or {} }, nil
                    end
                end
                return { items = {} }, nil
            end,
        },
    }
end

local function find_requirement(plan, parameter_name)
    for _, row in ipairs(plan.requirements or {}) do
        if row.parameter_name == parameter_name then return row end
    end
    return nil
end

local function find_parameter(params, name)
    for _, row in ipairs(params or {}) do
        if row.name == name then return row end
    end
    return nil
end

local function planner_catalog()
    return fake_catalog({
        ["acme/app"] = {
            {
                version = "v1.0.0",
                dependencies = {
                    { org = "wippy", name = "bootloader", version_constraint = "<v1.0.0" },
                },
                requirements = {},
            },
        },
        ["wippy/bootloader"] = {
            {
                version = "v0.1.0",
                requirements = {
                    {
                        name = "env_storage",
                        description = "Environment storage",
                        targets = { { entry = "wippy.bootloader:service", path = ".env_storage" } },
                    },
                },
            },
            {
                version = "v0.2.0",
                requirements = {
                    {
                        name = "env_storage",
                        description = "Environment storage",
                        targets = { { entry = "wippy.bootloader:service", path = ".env_storage" } },
                    },
                },
            },
            {
                version = "v1.0.0",
                requirements = {},
            },
        },
    })
end

local function fixture_entries()
    return {
        {
            id = "app.deps:foo",
            kind = "ns.dependency",
            meta = {},
            data = { component = "wippy/foo", version = ">=v1.0.0" },
        },
        {
            id = "wippy.foo:lib",
            kind = "library.lua",
            meta = { module = "wippy/foo", module_version = "v1.2.3" },
            data = {},
        },
        {
            id = "wippy.foo.migrations:001",
            kind = "function.lua",
            meta = {
                module = "wippy/foo",
                module_version = "v1.2.3",
                type = "migration",
                target_db = "app:db",
                timestamp = "2026-01-01T00:00:00Z",
            },
            data = { method = "migrate" },
        },
    }
end

local function define_tests()
    describe("keeper.hub service", function()
        describe("lockfile uninstall semantics", function()
            it("removes root and resolved transitive modules when nothing else keeps them", function()
                local doc = {
                    modules = {
                        { name = "userspace/oauth", version = "0.4.5", hash = "oauth-hash" },
                        { name = "userspace/scheduler", version = "0.4.10", hash = "scheduler-hash" },
                        { name = "userspace/component", version = "0.4.6", hash = "component-hash" },
                        { name = "wippy/facade", version = "0.5.0", hash = "facade-hash" },
                    },
                    replacements = {},
                }

                local changes, err = lockfile.apply_uninstall(doc, "userspace/oauth", {
                    { module = "userspace/oauth" },
                    { module = "userspace/scheduler" },
                    { module = "userspace/component" },
                }, {})

                test.is_nil(err)
                test.eq(#changes.removed, 3)
                test.eq(changes.removed[1].name, "userspace/oauth")
                test.eq(changes.removed[2].name, "userspace/scheduler")
                test.eq(changes.removed[3].name, "userspace/component")
                test.eq(#doc.modules, 1)
                test.eq(doc.modules[1].name, "wippy/facade")
            end)

            it("keeps shared transitive modules and protected replacements", function()
                local doc = {
                    modules = {
                        { name = "userspace/oauth", version = "0.4.5", hash = "oauth-hash" },
                        { name = "userspace/scheduler", version = "0.4.10", hash = "scheduler-hash" },
                        { name = "wippy/terminal", version = "0.4.3", hash = "terminal-hash" },
                    },
                    replacements = {
                        { from = "userspace/scheduler", to = "../userspace/scheduler" },
                    },
                }

                local changes, err = lockfile.apply_uninstall(doc, "userspace/oauth", {
                    { module = "userspace/oauth" },
                    { module = "userspace/scheduler" },
                    { name = "wippy/terminal" },
                }, {
                    ["wippy/terminal"] = true,
                })

                test.is_nil(err)
                test.eq(#changes.removed, 1)
                test.eq(changes.removed[1].name, "userspace/oauth")
                test.eq(#changes.skipped_replacements, 1)
                test.eq(changes.skipped_replacements[1].name, "userspace/scheduler")
                test.eq(#doc.modules, 2)
                test.eq(doc.modules[1].name, "userspace/scheduler")
                test.eq(doc.modules[2].name, "wippy/terminal")
            end)
        end)

        describe("dependency entry shape", function()
            it("stores dependency fields under data, not top-level", function()
                local entry, err = hub.build_dependency_entry({
                    component = "wippy/dataflow",
                    version = ">=v0.4.9",
                    parameters = { target_db = "app:db", enabled = false },
                })
                test.is_nil(err)
                test.eq(entry.id, "app.deps:dataflow")
                test.eq(entry.kind, "ns.dependency")
                test.is_nil((entry :: any).component)
                test.is_nil((entry :: any).version)
                test.eq(entry.data.component, "wippy/dataflow")
                test.eq(entry.data.version, ">=v0.4.9")
                test.eq(entry.data.parameters[1].name, "enabled")
                test.eq(entry.data.parameters[1].value, "false")
                test.eq(entry.data.parameters[2].name, "target_db")
            end)

            it("materializes install as a registry set patch", function()
                local entry, build_err = hub.build_dependency_entry({
                    component = "keeper/keeper",
                    version = ">=v0.3.15",
                })
                test.is_nil(build_err)
                test.not_nil(entry)
                local patch, err = hub.entry_to_set_patch(entry)
                test.is_nil(err)
                test.eq(patch.target, "entry")
                test.eq(patch.op, "set")
                test.eq(patch.kind, "ns.dependency")
                test.is_true(string.find(patch.definition, "component: keeper/keeper", 1, true) ~= nil)
                test.is_nil(patch.content)
            end)

            it("rejects malformed components and duplicate parameters", function()
                local entry, err = hub.build_dependency_entry({ component = "dataflow" })
                test.is_nil(entry)
                test.not_nil(err)
                test.eq(err_code(err), "BAD_REQUEST")
                test.eq(err_kind(err), errors.INVALID)

                entry, err = hub.build_dependency_entry({
                    component = "wippy/dataflow",
                    parameters = {
                        { name = "target_db", value = "app:db" },
                        { name = "target_db", value = "app:other" },
                    },
                })
                test.is_nil(entry)
                test.not_nil(err)
                test.eq(err_code(err), "BAD_REQUEST")
                test.eq(err_kind(err), errors.INVALID)
            end)
        end)

        describe("inventory", function()
            it("lists dependency entries with module entry and migration status", function()
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({ ["wippy.foo.migrations:001"] = true }),
                    planner = no_requirements_planner(),
                }) :: any
                local out, err = svc:list_dependencies({})
                test.is_nil(err)
                test.eq(out.count, 1)
                local dep = out.dependencies[1]
                test.eq(dep.id, "app.deps:foo")
                test.eq(dep.component, "wippy/foo")
                test.is_true(dep.installed)
                test.eq(dep.installed_entries_count, 2)
                test.eq(dep.migrations[1].status, "applied")
            end)

            it("does not list module-owned package dependencies as installed dependencies", function()
                local entries = fixture_entries()
                table.insert(entries, {
                    id = "wippy.foo:dependency.shared",
                    kind = "ns.dependency",
                    meta = { module = "wippy/foo", module_version = "1.2.3" },
                    data = { component = "wippy/shared", version = ">=1.0.0" },
                })
                local svc = hub.new({
                    registry = fake_registry(entries),
                    sql = fake_sql({}),
                    planner = no_requirements_planner(),
                }) :: any

                local out, err = svc:list_dependencies({})

                test.is_nil(err)
                test.eq(out.count, 1)
                test.eq(out.dependencies[1].id, "app.deps:foo")
            end)

            it("does not resolve module-owned dependencies as install roots", function()
                local entries = fixture_entries()
                table.insert(entries, {
                    id = "wippy.foo:dependency.shared",
                    kind = "ns.dependency",
                    meta = { module = "wippy/foo", module_version = "1.2.3" },
                    data = { component = "wippy/shared", version = ">=1.0.0" },
                })
                local svc = hub.new({
                    registry = fake_registry(entries),
                    sql = fake_sql({}),
                    planner = no_requirements_planner(),
                }) :: any

                local by_component, by_component_err = svc:find_dependency({ component = "wippy/shared" })
                test.is_nil(by_component)
                test.not_nil(by_component_err)
                test.eq(err_code(by_component_err), "NOT_FOUND")

                local by_id, by_id_err = svc:find_dependency({ id = "wippy.foo:dependency.shared" })
                test.is_nil(by_id)
                test.not_nil(by_id_err)
                test.eq(err_code(by_id_err), "BAD_REQUEST")
            end)

            it("lists only Hub-owned migrations when no component is supplied", function()
                local entries = fixture_entries()
                table.insert(entries, {
                    id = "app.local.migrations:001",
                    kind = "function.lua",
                    meta = { type = "migration", target_db = "app:db" },
                    data = {},
                })
                local svc = hub.new({
                    registry = fake_registry(entries),
                    sql = fake_sql({}),
                }) :: any
                local rows, err = svc:migration_rows({})
                test.is_nil(err)
                test.eq(#rows, 1)
                test.eq(rows[1].id, "wippy.foo.migrations:001")
            end)

            it("lists explicit migration ids through the service wrapper", function()
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({ ["wippy.foo.migrations:001"] = true }),
                    planner = no_requirements_planner(),
                }) :: any

                local out, err = svc:list_migrations({
                    entry_ids = { "wippy.foo.migrations:001" },
                })

                test.is_nil(err)
                test.eq(out.count, 1)
                test.eq(out.migrations[1].id, "wippy.foo.migrations:001")
                test.eq(out.migrations[1].status, "applied")
            end)
        end)

        describe("install and uninstall plans", function()
            it("dry-runs install without calling the registry", function()
                local svc = hub.new({ planner = no_requirements_planner() }) :: any
                local out, err = svc:install({
                    component = "wippy/terminal",
                    version = ">=v0.0.7",
                    dry_run = true,
                })
                test.is_nil(err)
                test.is_true(out.dry_run)
                test.eq(out.dependency.id, "app.deps:terminal")
                test.eq(out.patches[1].op, "set")
            end)

            it("persists the resolved install graph in wippy.lock after registry apply", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local gov_state = ({ current_version = 12 }) :: any
                local svc = hub.new({
                    planner = graph_planner({
                        { module = "wippy/dummy", version = "0.1.2", digest = "abc123" },
                    }),
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {},
                        replacements = {},
                    }),
                    governance = fake_governance(gov_state),
                }) :: any

                local out, err = svc:install({
                    component = "wippy/dummy",
                    version = ">=v0.0.0",
                    parameters = { ["wippy.dummy:router"] = "app:api" },
                })

                test.is_nil(err)
                test.eq(gov_state.current_calls, 1)
                test.eq(gov_state.publish_calls, 1)
                test.eq(gov_state.last_changeset[1].kind, "entry.create")
                test.eq(gov_state.last_changeset[1].entry.id, "app.deps:dummy")
                test.eq(gov_state.last_changeset[1].entry.meta.hub.resolved_modules[1].name, "wippy/dummy")
                test.is_nil(gov_state.last_options.branch)
                test.eq(out.lock.changed, true)
                test.eq(out.lock.changes.upserted[1].name, "wippy/dummy")
                test.eq(files["wippy.lock"], "wippy/dummy@0.1.2#abc123")
            end)

            it("uses an update op when publishing an existing dependency", function()
                local gov_state = ({}) :: any
                local entry, build_err = hub.build_dependency_entry({
                    component = "wippy/dummy",
                    version = "v2.0.0",
                    parameters = { ["wippy.dummy:router"] = "app:api" },
                })
                test.is_nil(build_err)

                local svc = hub.new({
                    registry = fake_registry({
                        {
                            id = "app.deps:dummy",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "wippy/dummy", version = "v1.0.0" },
                        },
                    }),
                    governance = fake_governance(gov_state),
                }) :: any

                local out, err = svc:publish_dependency_changeset({
                    action = "install",
                    entry = entry,
                    actor_id = "admin-1",
                    message = "upgrade dummy",
                })

                test.is_nil(err)
                test.is_true(out.ok)
                test.eq(gov_state.publish_calls, 1)
                test.eq(gov_state.last_changeset[1].kind, "entry.update")
                test.eq(gov_state.last_changeset[1].entry.id, "app.deps:dummy")
                test.eq(gov_state.last_options.user_id, "admin-1")
                test.is_nil(gov_state.last_options.branch)
            end)

            it("publishes uninstall as one exact dependency delete", function()
                local gov_state = ({}) :: any
                local svc = hub.new({ governance = fake_governance(gov_state) }) :: any

                local out, err = svc:publish_dependency_changeset({
                    action = "uninstall",
                    id = "app.deps:dummy",
                    message = "remove dummy",
                })

                test.is_nil(err)
                test.is_true(out.ok)
                test.eq(gov_state.publish_calls, 1)
                test.eq(#gov_state.last_changeset, 1)
                test.eq(gov_state.last_changeset[1].kind, "entry.delete")
                test.eq(gov_state.last_changeset[1].entry.id, "app.deps:dummy")
                test.eq(gov_state.last_changeset[1].entry.kind, "ns.dependency")
                test.is_nil(gov_state.last_options.branch)
            end)

            it("restores the registry when install cannot persist wippy.lock", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local gov_state = ({ current_version = 21 }) :: any
                local svc = hub.new({
                    planner = graph_planner({
                        { module = "wippy/dummy", version = "0.1.2", digest = "abc123" },
                    }),
                    fs = fake_project_fs(files, { write_error = "disk full" }),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {},
                        replacements = {},
                    }),
                    governance = fake_governance(gov_state),
                    funcs = {
                        new = function()
                            return {
                                call = function()
                                    return { ok = true, stage = "push", push = { version = 22 } }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:install({
                    component = "wippy/dummy",
                    version = ">=v0.0.0",
                    parameters = { ["wippy.dummy:router"] = "app:api" },
                })

                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "LOCK_UPDATE_FAILED")
                test.eq(err_details(err).lock_error.code, "INTERNAL")
                test.contains(err_details(err).lock_error.message, "disk full")
                test.eq(gov_state.restore_calls, 1)
                test.eq(gov_state.restored_version, 21)
                test.eq(files["wippy.lock"], "initial-lock")
            end)

            it("treats false filesystem writes as failed wippy.lock persistence", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local gov_state = ({ current_version = 23 }) :: any
                local svc = hub.new({
                    planner = graph_planner({
                        { module = "wippy/dummy", version = "0.1.2", digest = "abc123" },
                    }),
                    fs = fake_project_fs(files, { write_false = "permission denied" }),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {},
                        replacements = {},
                    }),
                    governance = fake_governance(gov_state),
                    funcs = {
                        new = function()
                            return {
                                call = function()
                                    return { ok = true, stage = "push", push = { version = 24 } }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:install({
                    component = "wippy/dummy",
                    version = ">=v0.0.0",
                    parameters = { ["wippy.dummy:router"] = "app:api" },
                })

                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "LOCK_UPDATE_FAILED")
                test.eq(err_details(err).lock_error.code, "INTERNAL")
                test.contains(err_details(err).lock_error.message, "permission denied")
                test.eq(gov_state.restore_calls, 1)
                test.eq(files["wippy.lock"], "initial-lock")
            end)

            it("rejects conflicting duplicate modules in a resolved install graph", function()
                local gov_state = ({ current_version = 25 }) :: any
                local files = { ["wippy.lock"] = "initial-lock" }
                local svc = hub.new({
                    planner = graph_planner({
                        { module = "wippy/dummy", version = "0.1.2", digest = "abc123" },
                        { module = "wippy/dummy", version = "0.1.3", digest = "def456" },
                    }),
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {},
                        replacements = {},
                    }),
                    governance = fake_governance(gov_state),
                }) :: any

                local out, err = svc:install({
                    component = "wippy/dummy",
                    version = ">=v0.0.0",
                    parameters = { ["wippy.dummy:router"] = "app:api" },
                })

                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "INTERNAL")
                test.contains(err_message(err), "conflicting entries")
                test.eq(gov_state.publish_calls or 0, 0)
                test.eq(files["wippy.lock"], "initial-lock")
            end)

            it("blocks uninstall when applied migrations would be orphaned", function()
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({ ["wippy.foo.migrations:001"] = true }),
                    planner = no_requirements_planner(),
                }) :: any
                local out, err = svc:uninstall({
                    component = "wippy/foo",
                    dry_run = true,
                })
                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "MIGRATIONS_APPLIED")
                test.eq(err_details(err).applied_migrations_count, 1)
            end)

            it("allows explicit leave policy and returns a delete patch", function()
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({ ["wippy.foo.migrations:001"] = true }),
                    planner = no_requirements_planner(),
                }) :: any
                local out, err = svc:uninstall({
                    component = "wippy/foo",
                    migration_policy = "leave",
                    dry_run = true,
                })
                test.is_nil(err)
                test.is_true(out.dry_run)
                test.eq(out.warning, "applied migrations will remain in the database after uninstall")
                local dep_patch
                for _, patch in ipairs(out.patches or {}) do
                    if patch.id == "app.deps:foo" then dep_patch = patch end
                end
                test.not_nil(dep_patch)
                test.eq(dep_patch.op, "delete")
            end)

            it("re-applies down migrations if registry uninstall fails", function()
                local calls = {} :: any
                local gov_state = ({ publish_error = "apply boom" }) :: any
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({ ["wippy.foo.migrations:001"] = true }),
                    fs = fake_project_fs({ ["wippy.lock"] = "initial-lock" }),
                    planner = no_requirements_planner(),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {},
                        replacements = {},
                    }),
                    uuid = fake_uuid(),
                    governance = fake_governance(gov_state),
                    funcs = {
                        new = function()
                            return {
                                call = function(_, id, params)
                                    table.insert(calls, { id = id, params = params })
                                    if id == hub.MIGRATION_HANDLER_FN then
                                        return { ok = true, operation = params.operation }, nil
                                    end
                                    return nil, "unexpected call"
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:uninstall({
                    component = "wippy/foo",
                    migration_policy = "down",
                }, { actor_id = "admin-1" })

                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "UNINSTALL_APPLY_FAILED")
                test.eq(calls[1].id, hub.MIGRATION_HANDLER_FN)
                test.eq(calls[1].params.operation, "down")
                test.eq(calls[1].params.entry_ids[1], "wippy.foo.migrations:001")
                test.eq(gov_state.publish_calls, 1)
                test.eq(calls[2].id, hub.MIGRATION_HANDLER_FN)
                test.eq(calls[2].params.operation, "up")
                test.eq(calls[2].params.only_pending, false)
                test.eq(calls[2].params.entry_ids[1], "wippy.foo.migrations:001")
                test.eq(err_details(err).migration_restore.operation, "up")
            end)

            it("removes the uninstalled module from wippy.lock after registry apply", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({}),
                    planner = graph_planner({
                        { module = "wippy/foo", version = "1.2.3", digest = "foo-hash" },
                    }),
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "wippy/foo", version = "1.2.3", hash = "foo-hash" },
                            { name = "wippy/terminal", version = "0.4.3", hash = "terminal-hash" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance({ current_version = 30 }),
                    funcs = {
                        new = function()
                            return {
                                call = function()
                                    return { ok = true, stage = "push", push = { version = 31 } }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:uninstall({
                    component = "wippy/foo",
                    migration_policy = "leave",
                })

                test.is_nil(err)
                test.eq(out.lock.changed, true)
                test.eq(out.lock.changes.removed[1].name, "wippy/foo")
                test.eq(files["wippy.lock"], "wippy/terminal@0.4.3#terminal-hash")
            end)

            it("re-applies down migrations if uninstall lock update fails after registry restore", function()
                local calls = {} :: any
                local gov_state = { current_version = 41 }
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({ ["wippy.foo.migrations:001"] = true }),
                    planner = graph_planner({
                        { module = "wippy/foo", version = "1.2.3", digest = "foo-hash" },
                    }),
                    fs = fake_project_fs({ ["wippy.lock"] = "initial-lock" }, { write_error = "disk full" }),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "wippy/foo", version = "1.2.3", hash = "foo-hash" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance(gov_state),
                    uuid = fake_uuid(),
                    funcs = {
                        new = function()
                            return {
                                call = function(_, id, params)
                                    table.insert(calls, { id = id, params = params })
                                    if id == hub.MIGRATION_HANDLER_FN then
                                        return { ok = true, operation = params.operation }, nil
                                    end
                                    return nil, "unexpected call"
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:uninstall({
                    component = "wippy/foo",
                    migration_policy = "down",
                }, { actor_id = "admin-1" })

                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "LOCK_UPDATE_FAILED")
                test.eq((gov_state :: any).restore_calls, 1)
                test.eq((gov_state :: any).restored_version, 41)
                test.eq(calls[1].id, hub.MIGRATION_HANDLER_FN)
                test.eq(calls[1].params.operation, "down")
                test.eq((gov_state :: any).publish_calls, 1)
                test.eq(calls[2].id, hub.MIGRATION_HANDLER_FN)
                test.eq(calls[2].params.operation, "up")
                test.eq(calls[2].params.only_pending, false)
                test.eq(err_details(err).migration_restore.operation, "up")
            end)

            it("does not scan remaining dependency graphs for direct-only uninstall", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local calls = {}
                local svc = hub.new({
                    registry = fake_registry({
                        {
                            id = "app.deps:app",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/app", version = ">=v1.0.0" },
                        },
                        {
                            id = "app.deps:other",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/other", version = ">=v1.0.0" },
                        },
                        {
                            id = "acme.app:dependency.shared",
                            kind = "ns.dependency",
                            meta = { module = "acme/app", module_version = "1.0.0" },
                            data = { component = "wippy/shared", version = ">=v1.0.0" },
                        },
                        {
                            id = "acme.app:definition",
                            kind = "ns.definition",
                            meta = { module = "acme/app", module_version = "1.0.0" },
                            data = {},
                        },
                    }),
                    sql = fake_sql({}),
                    planner = {
                        plan_install = function(args)
                            table.insert(calls, args.component)
                            if args.component ~= "acme/app" then
                                return nil, "remaining graph should not be resolved"
                            end
                            return {
                                graph = {
                                    { module = "acme/app", version = "1.0.0", digest = "app-hash" },
                                },
                                missing_requirements = {},
                                install_payload = args,
                            }, nil
                        end,
                    },
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "acme/app", version = "1.0.0", hash = "app-hash" },
                            { name = "acme/other", version = "1.0.0", hash = "other-hash" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance({ current_version = 35 }),
                    funcs = {
                        new = function()
                            return {
                                call = function()
                                    return { ok = true, stage = "push", push = { version = 36 } }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:uninstall({
                    component = "acme/app",
                    migration_policy = "leave",
                })

                test.is_nil(err)
                test.eq(#calls, 1)
                test.eq(out.lock.changes.removed[1].name, "acme/app")
                test.eq(files["wippy.lock"], "acme/other@1.0.0#other-hash")
            end)

            it("refuses uninstall when the removed dependency graph cannot be resolved", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local gov_state = ({ current_version = 38 }) :: any
                local svc = hub.new({
                    registry = fake_registry({
                        {
                            id = "app.deps:app",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/app", version = ">=v1.0.0" },
                        },
                        {
                            id = "acme.app:definition",
                            kind = "ns.definition",
                            meta = { module = "acme/app", module_version = "1.0.0" },
                            data = {},
                        },
                    }),
                    sql = fake_sql({}),
                    planner = {
                        plan_install = function()
                            return nil, "hub resolver unavailable"
                        end,
                    },
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "acme/app", version = "1.0.0", hash = "app-hash" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance(gov_state),
                }) :: any

                local out, err = svc:uninstall({
                    component = "acme/app",
                    migration_policy = "leave",
                })

                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "DEPENDENCY_GRAPH_FAILED")
                test.contains(err_message(err), "failed to resolve dependency graph")
                test.eq(gov_state.publish_calls or 0, 0)
                test.eq(files["wippy.lock"], "initial-lock")
            end)

            it("refuses uninstall when a remaining dependency graph cannot be checked", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local calls = {}
                local gov_state = ({ current_version = 39 }) :: any
                local svc = hub.new({
                    registry = fake_registry({
                        {
                            id = "app.deps:app",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/app", version = ">=v1.0.0" },
                        },
                        {
                            id = "app.deps:other",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/other", version = ">=v1.0.0" },
                        },
                        {
                            id = "acme.app:definition",
                            kind = "ns.definition",
                            meta = { module = "acme/app", module_version = "1.0.0" },
                            data = {},
                        },
                    }),
                    sql = fake_sql({}),
                    planner = {
                        plan_install = function(args)
                            table.insert(calls, args.component)
                            if args.component == "acme/app" then
                                return {
                                    graph = {
                                        { module = "acme/app", version = "1.0.0", digest = "app-hash" },
                                        { module = "wippy/shared", version = "1.0.0", digest = "shared-hash" },
                                    },
                                    missing_requirements = {},
                                    install_payload = args,
                                }, nil
                            end
                            return nil, "cannot resolve " .. tostring(args.component)
                        end,
                    },
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "acme/app", version = "1.0.0", hash = "app-hash" },
                            { name = "wippy/shared", version = "1.0.0", hash = "shared-hash" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance(gov_state),
                }) :: any

                local out, err = svc:uninstall({
                    component = "acme/app",
                    migration_policy = "leave",
                    dry_run = true,
                })

                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "DEPENDENCY_GRAPH_FAILED")
                test.eq(calls[1], "acme/app")
                test.eq(calls[2], "acme/other")
                test.eq(gov_state.publish_calls or 0, 0)
                test.eq(files["wippy.lock"], "initial-lock")
            end)

            it("keeps transitive modules still required by another dependency during uninstall", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local planner_calls = {}
                local svc = hub.new({
                    registry = fake_registry({
                        {
                            id = "app.deps:app",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/app", version = ">=v1.0.0" },
                        },
                        {
                            id = "app.deps:other",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/other", version = ">=v1.0.0" },
                        },
                        {
                            id = "acme.app:dependency.shared",
                            kind = "ns.dependency",
                            meta = { module = "acme/app", module_version = "1.0.0" },
                            data = { component = "wippy/shared", version = ">=v1.0.0" },
                        },
                        {
                            id = "acme.app:definition",
                            kind = "ns.definition",
                            meta = { module = "acme/app", module_version = "1.0.0" },
                            data = {},
                        },
                    }),
                    sql = fake_sql({}),
                    planner = {
                        plan_install = function(args)
                            table.insert(planner_calls, args.component)
                            local graph
                            if args.component == "acme/app" then
                                graph = {
                                    { module = "acme/app", version = "1.0.0", digest = "app-hash" },
                                    { module = "wippy/shared", version = "1.0.0", digest = "shared-hash" },
                                }
                            elseif args.component == "acme/other" then
                                graph = {
                                    { module = "acme/other", version = "1.0.0", digest = "other-hash" },
                                    { module = "wippy/shared", version = "1.0.0", digest = "shared-hash" },
                                }
                            else
                                return nil, "unexpected dependency root: " .. tostring(args.component)
                            end
                            return { graph = graph, missing_requirements = {}, install_payload = args }, nil
                        end,
                    },
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "acme/app", version = "1.0.0", hash = "app-hash" },
                            { name = "acme/other", version = "1.0.0", hash = "other-hash" },
                            { name = "wippy/shared", version = "1.0.0", hash = "shared-hash" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance({ current_version = 40 }),
                    funcs = {
                        new = function()
                            return {
                                call = function()
                                    return { ok = true, stage = "push", push = { version = 41 } }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:uninstall({
                    component = "acme/app",
                    migration_policy = "leave",
                })

                test.is_nil(err)
                test.eq(out.lock.changed, true)
                test.eq(out.lock.changes.removed[1].name, "acme/app")
                test.eq(files["wippy.lock"], "acme/other@1.0.0#other-hash\nwippy/shared@1.0.0#shared-hash")
                test.eq(planner_calls[1], "acme/app")
                test.eq(planner_calls[2], "acme/other")
            end)

            it("does not keep transitive modules only referenced by the package being removed", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local planner_calls = {}
                local svc = hub.new({
                    registry = fake_registry({
                        {
                            id = "app.deps:app",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/app", version = ">=v1.0.0" },
                        },
                        {
                            id = "acme.app:dependency.shared",
                            kind = "ns.dependency",
                            meta = { module = "acme/app", module_version = "1.0.0" },
                            data = { component = "wippy/shared", version = ">=v1.0.0" },
                        },
                        {
                            id = "acme.app:definition",
                            kind = "ns.definition",
                            meta = { module = "acme/app", module_version = "1.0.0" },
                            data = {},
                        },
                    }),
                    sql = fake_sql({}),
                    planner = {
                        plan_install = function(args)
                            table.insert(planner_calls, args.component)
                            if args.component ~= "acme/app" then
                                return nil, "module-owned dependencies must not be scanned as roots"
                            end
                            return {
                                graph = {
                                    { module = "acme/app", version = "1.0.0", digest = "app-hash" },
                                    { module = "wippy/shared", version = "1.0.0", digest = "shared-hash" },
                                },
                                missing_requirements = {},
                                install_payload = args,
                            }, nil
                        end,
                    },
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "acme/app", version = "1.0.0", hash = "app-hash" },
                            { name = "wippy/shared", version = "1.0.0", hash = "shared-hash" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance({ current_version = 40 }),
                    funcs = {
                        new = function()
                            return {
                                call = function()
                                    return { ok = true, stage = "push", push = { version = 41 } }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:uninstall({
                    component = "acme/app",
                    migration_policy = "leave",
                })

                test.is_nil(err)
                test.eq(#planner_calls, 1)
                test.eq(out.lock.changed, true)
                test.eq(#out.lock.changes.removed, 2)
                test.eq(out.lock.changes.removed[1].name, "acme/app")
                test.eq(out.lock.changes.removed[2].name, "wippy/shared")
                test.eq(files["wippy.lock"], "")
            end)

        end)

        describe("install planner", function()
            it("reuses an existing dependency entry for component updates", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["wippy/dummy"] = {
                            { version = "v1.0.0", requirements = {} },
                        },
                    }),
                    registry = fake_registry({
                        {
                            id = "app.plugins:dummy_runtime",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "wippy/dummy", version = "v0.9.0" },
                        },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                test.eq(plan.dependency.id, "app.plugins:dummy_runtime")
                test.eq(plan.dependency.namespace, "app.plugins")
                test.eq(plan.install_payload.id, "app.plugins:dummy_runtime")
                test.eq(plan.install_payload.namespace, "app.plugins")
            end)

            it("places new dependencies in the strongest existing dependency namespace cluster", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["acme/app"] = {
                            { version = "v1.0.0", requirements = {} },
                        },
                    }),
                    registry = fake_registry({
                        {
                            id = "app.plugins:alpha",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/alpha", version = "v1.0.0" },
                        },
                        {
                            id = "app.plugins:beta",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/beta", version = "v1.0.0" },
                        },
                        {
                            id = "app.deps:older",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/older", version = "v1.0.0" },
                        },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                test.eq(plan.dependency.id, "app.plugins:app")
                test.eq(plan.dependency.namespace, "app.plugins")
                test.eq(plan.install_payload.namespace, "app.plugins")
            end)

            it("falls back to a managed dependency namespace when app is not managed", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["acme/app"] = {
                            { version = "v1.0.0", requirements = {} },
                        },
                    }),
                    registry = fake_registry({}),
                    gov = {
                        get_managed_namespaces = function()
                            return { "workspace", "userspace" }
                        end,
                        is_namespace_managed = function(namespace)
                            local function under(root)
                                return namespace == root or namespace:sub(1, #root + 1) == root .. "."
                            end
                            return under("workspace") or under("userspace")
                        end,
                    },
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                test.eq(plan.dependency.id, "workspace.deps:app")
                test.eq(plan.install_payload.namespace, "workspace.deps")
            end)

            it("does not place new dependencies in an unmanaged legacy cluster", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["acme/app"] = {
                            { version = "v1.0.0", requirements = {} },
                        },
                    }),
                    registry = fake_registry({
                        {
                            id = "legacy.deps:alpha",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/alpha", version = "v1.0.0" },
                        },
                        {
                            id = "legacy.deps:beta",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/beta", version = "v1.0.0" },
                        },
                    }),
                    gov = {
                        get_managed_namespaces = function()
                            return { "app" }
                        end,
                        is_namespace_managed = function(namespace)
                            return namespace == "app" or namespace:sub(1, 4) == "app."
                        end,
                    },
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                test.eq(plan.dependency.id, "app.deps:app")
                test.eq(plan.install_payload.namespace, "app.deps")
            end)

            it("keeps an explicit dependency namespace over placement heuristics", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["acme/app"] = {
                            { version = "v1.0.0", requirements = {} },
                        },
                    }),
                    registry = fake_registry({
                        {
                            id = "app.plugins:alpha",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "acme/alpha", version = "v1.0.0" },
                        },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                    namespace = "app.deps",
                })

                test.is_nil(err)
                test.eq(plan.dependency.id, "app.deps:app")
                test.eq(plan.install_payload.namespace, "app.deps")
            end)

            it("emits transitive requirement full ids without inferring registry values", function()
                local svc = planner.new({
                    catalog = planner_catalog(),
                    registry = fake_registry({
                        {
                            id = "app.env:store",
                            kind = "env.storage.router",
                            meta = { title = "App environment store" },
                            data = {},
                        },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                    run_migrations = true,
                })

                test.is_nil(err)
                test.eq(plan.module_count, 2)
                test.eq(plan.migration_policy, "up")
                local req = find_requirement(plan, "wippy.bootloader:env_storage")
                test.not_nil(req)
                test.is_true(req.transitive)
                test.eq(req.module, "wippy/bootloader")
                test.eq(req.value, "")
                test.eq(req.value_source, "empty")
                test.is_true(req.missing)
                test.eq(req.expected_kind, "env.storage")
                test.eq(req.suggestions[1].value, "app.env:store")
                test.eq(req.suggestions[1].kind, "env.storage.router")
                test.eq(plan.missing_requirements[1], "wippy.bootloader:env_storage")

                local param = find_parameter(plan.install_payload.parameters, "wippy.bootloader:env_storage")
                test.is_nil(param)
            end)

            it("returns one total requirement list across direct and transitive modules", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["acme/app"] = {
                            {
                                version = "v1.0.0",
                                dependencies = {
                                    { org = "wippy", name = "bootloader", version = "v0.1.0" },
                                },
                                requirements = {
                                    {
                                        name = "router",
                                        description = "HTTP router",
                                        targets = { { entry = "acme.app:service", path = ".router" } },
                                    },
                                    {
                                        name = "feature_flag",
                                        default = "enabled",
                                        targets = { { entry = "acme.app:service", path = ".feature_flag" } },
                                    },
                                },
                            },
                        },
                        ["wippy/bootloader"] = {
                            {
                                version = "v0.1.0",
                                requirements = {
                                    {
                                        name = "env_storage",
                                        targets = { { entry = "wippy.bootloader:service", path = ".env_storage" } },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "app:api", kind = "http.router", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                test.eq(plan.requirement_count, 3)
                test.eq(#plan.requirements, 3)
                test.eq(#plan.install_payload.parameters, 1)

                local router = find_requirement(plan, "acme.app:router")
                local flag = find_requirement(plan, "acme.app:feature_flag")
                local env_storage = find_requirement(plan, "wippy.bootloader:env_storage")
                test.not_nil(router)
                test.not_nil(flag)
                test.not_nil(env_storage)
                test.is_false(router.transitive)
                test.is_false(flag.transitive)
                test.is_true(env_storage.transitive)
                test.eq(router.value, "")
                test.eq(flag.value, "enabled")
                test.eq(flag.value_source, "default")
                test.is_false(flag.missing)
                test.eq(flag.suggestions[1].value, "enabled")
                test.eq(flag.suggestions[1].source, "default")
                test.eq(plan.missing_requirements[1], "acme.app:router")
                test.eq(plan.missing_requirements[2], "wippy.bootloader:env_storage")

                local param = find_parameter(plan.install_payload.parameters, "acme.app:feature_flag")
                test.not_nil(param)
                test.eq(param.value, "enabled")
            end)

            it("infers router and environment storage values from canonical requirement paths", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["butschster/telegram"] = {
                            {
                                version = "0.3.0",
                                requirements = {
                                    {
                                        name = "webhook_router",
                                        targets = { { entry = "telegram.handler:webhook_endpoint", path = ".meta.router" } },
                                    },
                                    {
                                        name = "env_storage",
                                        targets = {
                                            { entry = "telegram:bot_token", path = ".storage" },
                                            { entry = "telegram:webhook_url", path = ".storage" },
                                        },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "app:api", kind = "http.router", meta = {}, data = {} },
                        { id = "app.env:store", kind = "env.storage.router", meta = {}, data = {} },
                        { id = "app.env:file", kind = "env.storage.file", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "butschster/telegram",
                    version = "0.3.0",
                })

                test.is_nil(err)
                local router = find_requirement(plan, "butschster.telegram:webhook_router")
                local env_storage = find_requirement(plan, "butschster.telegram:env_storage")
                test.not_nil(router)
                test.not_nil(env_storage)
                test.eq(router.expected_kind, "http.router")
                test.eq(router.suggestions[1].value, "app:api")
                test.eq(router.suggestions[1].kind, "http.router")
                test.eq(env_storage.expected_kind, "env.storage")
                test.eq(env_storage.suggestions[1].value, "app.env:file")
                test.eq(env_storage.suggestions[1].kind, "env.storage.file")
                test.eq(env_storage.suggestions[2].value, "app.env:store")
                test.eq(env_storage.suggestions[2].kind, "env.storage.router")
            end)

            it("uses canonical requirement names when target paths are not descriptive", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["acme/webhooks"] = {
                            {
                                version = "v1.0.0",
                                requirements = {
                                    {
                                        name = "webhook_router",
                                        targets = { { entry = "acme.webhooks:endpoint", path = ".value" } },
                                    },
                                    {
                                        name = "env_storage",
                                        targets = { { entry = "acme.webhooks:env", path = ".value" } },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "app:api", kind = "http.router", meta = {}, data = {} },
                        { id = "app.env:os", kind = "env.storage.os", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/webhooks",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                local router = find_requirement(plan, "acme.webhooks:webhook_router")
                local env_storage = find_requirement(plan, "acme.webhooks:env_storage")
                test.not_nil(router)
                test.not_nil(env_storage)
                test.eq(router.expected_kind, "http.router")
                test.eq(router.suggestions[1].value, "app:api")
                test.eq(env_storage.expected_kind, "env.storage")
                test.eq(env_storage.suggestions[1].value, "app.env:os")
                test.eq(env_storage.suggestions[1].kind, "env.storage.os")
            end)

            it("loads selected version detail before building the requirement list", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["wippy/dummy"] = {
                            {
                                id = "dummy-v1",
                                version = "v1.0.0",
                                entry_kinds = { "ns.definition", "ns.requirement", "function.lua" },
                                detail = {
                                    id = "dummy-v1",
                                    version = "v1.0.0",
                                    requirements = {
                                        {
                                            name = "router",
                                            description = "HTTP router for dummy endpoint",
                                            targets = { { entry = "wippy.dummy:ping", path = ".router" } },
                                        },
                                    },
                                }
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "app:api", kind = "http.router", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                test.eq(plan.requirement_count, 1)
                local req = find_requirement(plan, "wippy.dummy:router")
                test.not_nil(req)
                test.eq(req.value, "")
                test.eq(req.value_source, "empty")
                test.is_true(req.missing)
                local param = find_parameter(plan.install_payload.parameters, "wippy.dummy:router")
                test.is_nil(param)
            end)

            it("inspects artifacts when Hub version metadata omits requirement details", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["wippy/dummy"] = {
                            {
                                id = "dummy-v1",
                                version = "v1.0.0",
                                entry_kinds = { "ns.definition", "ns.requirement", "function.lua", "http.endpoint" },
                                requirements = {},
                                inspect = {
                                    version = "v1.0.0",
                                    entry_count = 4,
                                    entry_kinds = { "ns.definition", "ns.requirement", "function.lua", "http.endpoint" },
                                    requirements = {
                                        {
                                            name = "router",
                                            description = "Router to register endpoints on",
                                            default = "app:router",
                                            targets = { { entry = "wippy.dummy:ping", path = "meta.router" } },
                                        },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "app:api", kind = "http.router", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                test.eq(plan.requirement_count, 1)
                local req = find_requirement(plan, "wippy.dummy:router")
                test.not_nil(req)
                test.eq(req.value, "")
                test.eq(req.value_source, "empty")
                test.is_true(req.missing)
                test.eq(req.expected_kind, "http.router")
                test.eq(req.default, "app:router")
                test.eq(req.suggestions[1].value, "app:api")
                test.eq(req.suggestions[1].source, "registry")
                test.eq(req.suggestions[1].kind, "http.router")
                local param = find_parameter(plan.install_payload.parameters, "wippy.dummy:router")
                test.is_nil(param)
            end)

            it("accepts explicit requirement values from arbitrary application namespaces", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["wippy/dummy"] = {
                            {
                                version = "v1.0.0",
                                requirements = {
                                    {
                                        name = "router",
                                        default = "app:router",
                                        targets = { { entry = "wippy.dummy:ping", path = "meta.router" } },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "tenant.web:public", kind = "http.router", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                    parameters = {
                        { name = "wippy.dummy:router", value = "tenant.web:public" },
                    },
                })

                test.is_nil(err)
                local req = find_requirement(plan, "wippy.dummy:router")
                test.not_nil(req)
                test.eq(req.expected_kind, "http.router")
                test.eq(req.value, "tenant.web:public")
                test.eq(req.value_source, "provided")
                test.is_false(req.missing)
                test.eq(#req.suggestions, 1)
                test.eq(req.suggestions[1].value, "tenant.web:public")
                test.eq(req.suggestions[1].source, "registry")
                local param = find_parameter(plan.install_payload.parameters, "wippy.dummy:router")
                test.not_nil(param)
                test.eq(param.value, "tenant.web:public")
            end)

            it("blocks explicit resource values that do not resolve to the expected kind", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["wippy/dummy"] = {
                            {
                                version = "v1.0.0",
                                requirements = {
                                    {
                                        name = "router",
                                        targets = { { entry = "wippy.dummy:ping", path = "meta.router" } },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "tenant.web:public", kind = "http.router", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                    parameters = {
                        { name = "wippy.dummy:router", value = "tenant.web:missing" },
                    },
                })

                test.is_nil(err)
                local req = find_requirement(plan, "wippy.dummy:router")
                test.not_nil(req)
                test.eq(req.value, "tenant.web:missing")
                test.eq(req.value_source, "provided_invalid")
                test.is_true(req.invalid)
                test.eq(req.invalid_reason, "value must reference an existing http.router")
                test.is_true(req.missing)
                test.eq(plan.missing_requirements[1], "wippy.dummy:router")
                test.eq(req.suggestions[1].value, "tenant.web:public")
                local param = find_parameter(plan.install_payload.parameters, "wippy.dummy:router")
                test.is_nil(param)
            end)

            it("uses a package default only when it resolves to the expected registry kind", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["wippy/dummy"] = {
                            {
                                version = "v1.0.0",
                                requirements = {
                                    {
                                        name = "router",
                                        default = "app:router",
                                        targets = { { entry = "wippy.dummy:ping", path = "meta.router" } },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "app:router", kind = "http.router", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                local req = find_requirement(plan, "wippy.dummy:router")
                test.not_nil(req)
                test.eq(req.value, "app:router")
                test.eq(req.value_source, "default")
                test.eq(req.expected_kind, "http.router")
                test.is_false(req.missing)
                test.eq(req.suggestions[1].value, "app:router")
                test.eq(req.suggestions[1].source, "default")
                test.eq(req.suggestions[1].kind, "http.router")
                local param = find_parameter(plan.install_payload.parameters, "wippy.dummy:router")
                test.not_nil(param)
                test.eq(param.value, "app:router")
            end)

            it("uses Hub dependency metadata when version metadata omits dependency edges", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["acme/app"] = {
                            {
                                version = "v1.0.0",
                                entry_kinds = { "ns.definition", "ns.dependency", "function.lua" },
                                dependencies = {},
                            },
                        },
                        ["wippy/bootloader"] = {
                            {
                                version = "v0.1.0",
                                requirements = {
                                    {
                                        name = "env_storage",
                                        targets = { { entry = "wippy.bootloader:service", path = ".env_storage" } },
                                    },
                                },
                            },
                        },
                        __dependencies = {
                            ["acme/app"] = {
                                {
                                    version = "v1.0.0",
                                    dependencies = {
                                        { org = "wippy", name = "bootloader", version = "v0.1.0" },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({}),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                test.eq(plan.module_count, 2)
                test.eq(plan.graph[1].module, "acme/app")
                test.eq(plan.graph[2].module, "wippy/bootloader")
                test.eq(plan.graph[2].parent, "acme/app")
                local req = find_requirement(plan, "wippy.bootloader:env_storage")
                test.not_nil(req)
                test.is_true(req.transitive)
                test.eq(plan.missing_requirements[1], "wippy.bootloader:env_storage")
            end)

            it("preserves explicitly supplied transitive full-id parameters", function()
                local full_id = "wippy.bootloader" .. ":env_storage"
                local file_store = "app.env" .. ":file"
                local svc = planner.new({
                    catalog = planner_catalog(),
                    registry = fake_registry({
                        { id = "app.env:store", kind = "env.storage.router", meta = {}, data = {} },
                        { id = "app.env:file", kind = "env.storage.file", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                    parameters = {
                        { name = full_id, value = file_store },
                    },
                })

                test.is_nil(err)
                local req = find_requirement(plan, full_id)
                test.not_nil(req)
                test.eq(req.value, file_store)
                test.eq(req.value_source, "provided")
                local param = find_parameter(plan.install_payload.parameters, full_id)
                test.not_nil(param)
                test.eq(param.value, file_store)
            end)

            it("does not apply bare supplied names to transitive requirements", function()
                local svc = planner.new({
                    catalog = planner_catalog(),
                    registry = fake_registry({
                        { id = "app.env:store", kind = "env.storage.router", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                    parameters = { env_storage = "app.env:wrong" },
                })

                test.is_nil(err)
                local req = find_requirement(plan, "wippy.bootloader:env_storage")
                test.not_nil(req)
                test.eq(req.value, "")
                test.eq(req.value_source, "empty")
                test.is_true(req.missing)
            end)

            it("reuses bare existing parameters for already-installed transitive components", function()
                local svc = planner.new({
                    catalog = planner_catalog(),
                    registry = fake_registry({
                        { id = "app.env:store", kind = "env.storage.router", meta = {}, data = {} },
                        {
                            id = "app.deps:bootloader",
                            kind = "ns.dependency",
                            meta = {},
                            data = {
                                component = "wippy/bootloader",
                                version = ">=v0.0.9",
                                parameters = { { name = "env_storage", value = "app.env:store" } },
                            },
                        },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                local req = find_requirement(plan, "wippy.bootloader:env_storage")
                test.not_nil(req)
                test.eq(req.value, "app.env:store")
                test.eq(req.value_source, "existing_bare")
                test.is_false(req.missing)

                local param = find_parameter(plan.install_payload.parameters, "wippy.bootloader:env_storage")
                test.not_nil(param)
                test.eq(param.value, "app.env:store")
            end)

            it("does not reuse bare existing parameters from other components", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["wippy/dummy"] = {
                            {
                                version = "v1.0.0",
                                requirements = {
                                    {
                                        name = "router",
                                        default = "app:router",
                                        targets = { { entry = "wippy.dummy:ping", path = "meta.router" } },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "app:router", kind = "http.router", meta = {}, data = {} },
                        { id = "app:api", kind = "http.router", meta = {}, data = {} },
                        {
                            id = "app.deps:other",
                            kind = "ns.dependency",
                            meta = {},
                            data = {
                                component = "acme/other",
                                version = "v1.0.0",
                                parameters = { { name = "router", value = "app:api.public" } },
                            },
                        },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                local req = find_requirement(plan, "wippy.dummy:router")
                test.not_nil(req)
                test.eq(req.value, "app:router")
                test.eq(req.value_source, "default")
                test.is_false(req.missing)
                test.eq(req.suggestions[1].value, "app:router")
                test.eq(req.suggestions[1].source, "default")
            end)

            it("reuses a unique existing full-id parameter", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["wippy/dummy"] = {
                            {
                                version = "v1.0.0",
                                requirements = {
                                    {
                                        name = "router",
                                        targets = { { entry = "wippy.dummy:ping", path = "meta.router" } },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "app:api", kind = "http.router", meta = {}, data = {} },
                        {
                            id = "app.deps:dummy_previous",
                            kind = "ns.dependency",
                            meta = {},
                            data = {
                                component = "wippy/dummy",
                                version = "v1.0.0",
                                parameters = { { name = "wippy.dummy:router", value = "app:api" } },
                            },
                        },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                local req = find_requirement(plan, "wippy.dummy:router")
                test.not_nil(req)
                test.eq(req.value, "app:api")
                test.eq(req.value_source, "existing")
                test.is_false(req.missing)
                local param = find_parameter(plan.install_payload.parameters, "wippy.dummy:router")
                test.not_nil(param)
                test.eq(param.value, "app:api")
            end)

            it("does not reuse existing resource parameters that no longer resolve", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["wippy/dummy"] = {
                            {
                                version = "v1.0.0",
                                requirements = {
                                    {
                                        name = "router",
                                        targets = { { entry = "wippy.dummy:ping", path = "meta.router" } },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        {
                            id = "app.deps:dummy_previous",
                            kind = "ns.dependency",
                            meta = {},
                            data = {
                                component = "wippy/dummy",
                                version = "v1.0.0",
                                parameters = { { name = "wippy.dummy:router", value = "app:missing" } },
                            },
                        },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                local req = find_requirement(plan, "wippy.dummy:router")
                test.not_nil(req)
                test.eq(req.value, "")
                test.eq(req.value_source, "empty")
                test.is_true(req.missing)
                test.eq(#req.suggestions, 0)
            end)

            it("reuses a unique bare existing parameter only for the same direct component", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["wippy/dummy"] = {
                            {
                                version = "v1.0.0",
                                requirements = {
                                    {
                                        name = "router",
                                        targets = { { entry = "wippy.dummy:ping", path = "meta.router" } },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "app:api.public", kind = "http.router", meta = {}, data = {} },
                        {
                            id = "app.deps:dummy",
                            kind = "ns.dependency",
                            meta = {},
                            data = {
                                component = "wippy/dummy",
                                version = "v1.0.0",
                                parameters = { { name = "router", value = "app:api.public" } },
                            },
                        },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                local req = find_requirement(plan, "wippy.dummy:router")
                test.not_nil(req)
                test.eq(req.value, "app:api.public")
                test.eq(req.value_source, "existing_bare")
                test.is_false(req.missing)
            end)

            it("does not choose among conflicting existing values", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["wippy/dummy"] = {
                            {
                                version = "v1.0.0",
                                requirements = {
                                    {
                                        name = "router",
                                        targets = { { entry = "wippy.dummy:ping", path = "meta.router" } },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        { id = "app:api", kind = "http.router", meta = {}, data = {} },
                        { id = "app:api.public", kind = "http.router", meta = {}, data = {} },
                        {
                            id = "app.deps:dummy_a",
                            kind = "ns.dependency",
                            meta = {},
                            data = {
                                component = "wippy/dummy",
                                version = "v1.0.0",
                                parameters = { { name = "wippy.dummy:router", value = "app:api" } },
                            },
                        },
                        {
                            id = "app.deps:dummy_b",
                            kind = "ns.dependency",
                            meta = {},
                            data = {
                                component = "wippy/dummy",
                                version = "v1.0.0",
                                parameters = { { name = "wippy.dummy:router", value = "app:api.public" } },
                            },
                        },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                local req = find_requirement(plan, "wippy.dummy:router")
                test.not_nil(req)
                test.eq(req.value, "")
                test.eq(req.value_source, "conflict")
                test.is_true(req.missing)
                test.eq(#req.suggestions, 2)
            end)

            it("reports missing required values when there is no explicit or existing value", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["acme/needssecret"] = {
                            {
                                version = "v1.0.0",
                                requirements = {
                                    { name = "secret", targets = { { entry = "acme.needs_secret:svc", path = ".secret" } } },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({}),
                }) :: any

                local plan, err = svc:plan_install({ component = "acme/needssecret", version = "v1.0.0" })

                test.is_nil(err)
                local req = find_requirement(plan, "acme.needssecret:secret")
                test.not_nil(req)
                test.is_true(req.missing)
                test.eq(plan.missing_requirements[1], "acme.needssecret:secret")
            end)

            it("selects the highest non-yanked version satisfying a semver constraint", function()
                local svc = planner.new({
                    catalog = planner_catalog(),
                    registry = fake_registry({}),
                }) :: any

                local version, err = svc:select_version("wippy/bootloader", "<v1.0.0")
                test.is_nil(err)
                test.eq(version.version, "v0.2.0")
            end)

            it("resolves cycles once instead of looping forever", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["acme/a"] = {
                            { version = "v1.0.0", dependencies = { { org = "acme", name = "b", version = "v1.0.0" } } },
                        },
                        ["acme/b"] = {
                            { version = "v1.0.0", dependencies = { { org = "acme", name = "a", version = "v1.0.0" } } },
                        },
                    }),
                    registry = fake_registry({}),
                }) :: any

                local graph, err = svc:resolve_install_graph("acme/a", "v1.0.0", {})
                test.is_nil(err)
                test.eq(#graph, 2)
                test.eq(graph[1].module, "acme/a")
                test.eq(graph[2].module, "acme/b")
            end)
        end)

        describe("migration execution", function()
            it("dry-runs pending migrations by component", function()
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({}),
                }) :: any
                local out, err = svc:run_migrations({
                    component = "wippy/foo",
                    operation = "up",
                    dry_run = true,
                })
                test.is_nil(err)
                test.eq(out.count, 1)
                test.eq(out.entry_ids[1], "wippy.foo.migrations:001")
            end)

            it("calls the canonical integrate migration handler", function()
                local called = {}
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({}),
                    funcs = {
                        new = function()
                            return {
                                call = function(_, id, params)
                                    called.id = id
                                    called.params = params
                                    return { { id = params.entry_ids[1], success = true } }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any
                local out, err = svc:run_migrations({
                    component = "wippy/foo",
                    operation = "up",
                })
                test.is_nil(err)
                test.eq(called.id, hub.MIGRATION_HANDLER_FN)
                test.eq(called.params.operation, "up")
                test.eq(called.params.entry_ids[1], "wippy.foo.migrations:001")
                test.eq(out.result[1].success, true)
            end)
        end)

        describe("MCP Hub tools", function()
            it("routes dependency list, plan, install, and uninstall through canonical services", function()
                local calls = {}
                local fake_service = {
                    list_dependencies = function(args)
                        calls.list = args
                        return { count = 1, dependencies = { { component = "wippy/foo" } } }, nil
                    end,
                    install = function(args, opts)
                        calls.install = { args = args, opts = opts }
                        return { dependency = { component = args.component }, dry_run = args.dry_run == true }, nil
                    end,
                    uninstall = function(args, opts)
                        calls.uninstall = { args = args, opts = opts }
                        return { dependency = { component = args.component or "wippy/foo" }, dry_run = args.dry_run == true }, nil
                    end,
                }
                local fake_plan = {
                    plan_install = function(args)
                        calls.plan = args
                        return {
                            module_count = 2,
                            requirement_count = 1,
                            missing_requirements = { "wippy.foo:router" },
                        }, nil
                    end,
                }
                local deps = {
                    hub_service = fake_service,
                    planner = fake_plan,
                    actor_id = "admin-1",
                }

                local out, err = hub_dependencies_tool._handle({ action = "list", component = "wippy/foo" }, deps)
                test.is_nil(err)
                test.eq(out.count, 1)
                test.eq((calls.list :: any).component, "wippy/foo")

                out, err = hub_dependencies_tool._handle({
                    action = "plan",
                    component = "keeper/keeper",
                    version = ">=v0.0.0",
                }, deps)
                test.is_nil(err)
                test.eq(out.module_count, 2)
                test.eq((calls.plan :: any).component, "keeper/keeper")
                test.eq((calls.plan :: any).version, ">=v0.0.0")

                out, err = hub_dependencies_tool._handle({
                    action = "install",
                    component = "wippy/foo",
                    version = "v1.0.0",
                    parameters = { ["wippy.foo:router"] = "app:api" },
                    dry_run = true,
                }, deps)
                test.is_nil(err)
                test.is_true(out.dry_run)
                test.eq((calls.install :: any).args.parameters["wippy.foo:router"], "app:api")
                test.eq((calls.install :: any).opts.actor_id, "admin-1")

                out, err = hub_dependencies_tool._handle({
                    action = "uninstall",
                    component = "wippy/foo",
                    migration_policy = "leave",
                    dry_run = true,
                }, deps)
                test.is_nil(err)
                test.is_true(out.dry_run)
                test.eq((calls.uninstall :: any).args.migration_policy, "leave")
                test.eq((calls.uninstall :: any).opts.actor_id, "admin-1")
            end)

            it("routes migration list and up/down runs through canonical services", function()
                local calls = {}
                local fake_service = {
                    list_migrations = function(args)
                        calls.list = args
                        return {
                            count = 1,
                            migrations = {
                                { id = "wippy.foo.migrations:001", status = "applied" },
                            },
                        }, nil
                    end,
                    run_migrations = function(args, opts)
                        calls.run = { args = args, opts = opts }
                        return {
                            operation = args.operation,
                            count = 1,
                            entry_ids = args.entry_ids or { "wippy.foo.migrations:001" },
                            dry_run = args.dry_run == true,
                        }, nil
                    end,
                }
                local deps = {
                    hub_service = fake_service,
                    actor_id = "admin-1",
                }

                local out, err = hub_migrations_tool._handle({
                    action = "list",
                    component = "wippy/foo",
                }, deps)
                test.is_nil(err)
                test.eq(out.count, 1)
                test.eq((calls.list :: any).component, "wippy/foo")

                out, err = hub_migrations_tool._handle({
                    action = "run",
                    operation = "down",
                    entry_ids = { "wippy.foo.migrations:001" },
                    dry_run = true,
                }, deps)
                test.is_nil(err)
                test.eq(out.operation, "down")
                test.is_true(out.dry_run)
                test.eq((calls.run :: any).args.entry_ids[1], "wippy.foo.migrations:001")
                test.eq((calls.run :: any).opts.actor_id, "admin-1")
            end)
        end)

        describe("user hub events", function()
            it("targets only the active user's relay hub", function()
                local sent = {}
                local svc = hub.new({ process = fake_process(sent), uuid = fake_uuid() }) :: any
                local ok, err = svc:emit_user_event("admin-1", "hub.test", { n = 1 })
                test.is_true(ok)
                test.is_nil(err)
                test.eq(#sent, 1)
                local first = sent[1] :: any
                test.eq(first.pid, "pid-user-admin-1")
                test.eq(first.topic, hub.EVENT_TOPIC)
                test.eq(first.payload.event, "hub.test")
                test.eq(first.payload.actor_id, "admin-1")
                test.eq(first.payload.data.n, 1)
            end)

            it("emits install started and finished around the exact governance publish call", function()
                local sent = {}
                local gov_state = ({}) :: any
                local svc = hub.new({
                    registry = fake_registry({}),
                    process = fake_process(sent),
                    uuid = fake_uuid(),
                    planner = no_requirements_planner(),
                    governance = fake_governance(gov_state),
                }) :: any

                local out, err = svc:install({
                    component = "wippy/terminal",
                    version = ">=v0.0.7",
                }, { actor_id = "admin-1" })

                test.is_nil(err)
                test.eq(out.operation_id, "op-1")
                test.eq(gov_state.publish_calls, 1)
                test.eq(gov_state.last_options.user_id, "admin-1")
                test.eq(gov_state.last_changeset[1].kind, "entry.create")
                test.eq(gov_state.last_changeset[1].entry.id, "app.deps:terminal")
                test.eq(#sent, 2)
                local started = sent[1] :: any
                local finished = sent[2] :: any
                test.eq(started.payload.event, hub.EVENTS.INSTALL_STARTED)
                test.eq(started.payload.data.operation_id, "op-1")
                test.eq(finished.payload.event, hub.EVENTS.INSTALL_FINISHED)
                test.eq(finished.payload.data.operation_id, "op-1")
                test.eq(finished.payload.data.dependency.component, "wippy/terminal")
            end)

            it("publishes the planner install payload parameters", function()
                local gov_state = ({}) :: any
                local svc = hub.new({
                    planner = {
                        plan_install = function(args)
                            local entry, build_err = hub.build_dependency_entry(args)
                            if not entry then return nil, build_err end
                            return {
                                dependency = hub.dependency_summary(entry),
                                missing_requirements = {},
                                requirements = {},
                                install_payload = {
                                    id = entry.id,
                                    component = entry.data.component,
                                    version = entry.data.version,
                                    parameters = {
                                        { name = "wippy.dummy:router", value = "app:api.public" },
                                    },
                                    migration_policy = "none",
                                },
                            }, nil
                        end,
                    },
                    governance = fake_governance(gov_state),
                }) :: any

                local out, err = svc:install({
                    component = "wippy/dummy",
                    version = "v1.0.0",
                    parameters = {
                        router = "app:wrong",
                    },
                })

                test.is_nil(err)
                test.not_nil(out)
                test.eq(gov_state.publish_calls, 1)
                local params = gov_state.last_changeset[1].entry.data.parameters
                test.eq(params[1].name, "wippy.dummy:router")
                test.eq(params[1].value, "app:api.public")
            end)

            it("snapshots before install migrations and restores on migration failure", function()
                local sent = {}
                local gov_state = { current_version = 77 }
                local calls = {}
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({}),
                    process = fake_process(sent),
                    uuid = fake_uuid(),
                    governance = fake_governance(gov_state),
                    planner = no_requirements_planner(),
                    funcs = {
                        new = function()
                            return {
                                call = function(_, id, params)
                                    table.insert(calls, { id = id, params = params })
                                    if id == hub.MIGRATION_HANDLER_FN then
                                        return nil, "migration boom"
                                    end
                                    return nil, "unexpected call"
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:install({
                    component = "wippy/foo",
                    version = "v1.2.3",
                    run_migrations = true,
                }, { actor_id = "admin-1" })

                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "MIGRATIONS_FAILED")
                test.eq(err_details(err).baseline_version, 77)
                test.eq((gov_state :: any).current_calls, 1)
                test.eq((gov_state :: any).restore_calls, 1)
                test.eq((gov_state :: any).restored_version, 77)
                local migration_call = calls[1] :: any
                test.not_nil(migration_call)
                test.eq((gov_state :: any).publish_calls, 1)
                test.eq(migration_call.id, hub.MIGRATION_HANDLER_FN)

                local failed_event
                for _, item in ipairs(sent) do
                    if item.payload and item.payload.event == hub.EVENTS.INSTALL_FAILED then
                        failed_event = item.payload
                    end
                end
                test.not_nil(failed_event)
                test.eq(failed_event.data.rollback.version, 77)
            end)

            it("does not publish when install migrations need a rollback snapshot but snapshot fails", function()
                local called = {}
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({}),
                    governance = fake_governance({ current_error = "registry offline" }),
                    planner = no_requirements_planner(),
                    funcs = {
                        new = function()
                            return {
                                call = function(_, id, params)
                                    table.insert(called, { id = id, params = params })
                                    return { ok = true }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:install({
                    component = "wippy/foo",
                    version = "v1.2.3",
                    migration_policy = "up",
                })

                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "INTERNAL")
                test.eq(#called, 0)
            end)

            it("rejects install when planner reports unresolved requirements", function()
                local svc = hub.new({
                    planner = {
                        plan_install = function(args)
                            local entry, build_err = hub.build_dependency_entry(args)
                            if not entry then return nil, build_err end
                            return {
                                dependency = hub.dependency_summary(entry),
                                missing_requirements = { "wippy.dummy:router" },
                                requirements = {
                                    {
                                        parameter_name = "wippy.dummy:router",
                                        full_id = "wippy.dummy:router",
                                        name = "router",
                                        value = "",
                                        value_source = "empty",
                                        missing = true,
                                    },
                                },
                                install_payload = {
                                    id = entry.id,
                                    component = entry.data.component,
                                    version = entry.data.version,
                                    parameters = {},
                                    migration_policy = "none",
                                },
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:install({
                    component = "wippy/dummy",
                    version = "v0.1.2",
                }, { actor_id = "admin-1" })

                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "REQUIREMENTS_MISSING")
                test.eq(err_details(err).missing_requirements_count, 1)
                test.eq(err_details(err).missing_requirements_by_id["wippy.dummy:router"], true)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
