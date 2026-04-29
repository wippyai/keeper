local test = require("test")
local hub = require("hub_service")
local planner = require("planner")

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
                test.eq((err :: any).code, "BAD_REQUEST")

                entry, err = hub.build_dependency_entry({
                    component = "wippy/dataflow",
                    parameters = {
                        { name = "target_db", value = "app:db" },
                        { name = "target_db", value = "app:other" },
                    },
                })
                test.is_nil(entry)
                test.not_nil(err)
                test.eq((err :: any).code, "BAD_REQUEST")
            end)
        end)

        describe("inventory", function()
            it("lists dependency entries with module entry and migration status", function()
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({ ["wippy.foo.migrations:001"] = true }),
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

            it("blocks uninstall when applied migrations would be orphaned", function()
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({ ["wippy.foo.migrations:001"] = true }),
                }) :: any
                local out, err = svc:uninstall({
                    component = "wippy/foo",
                    dry_run = true,
                })
                test.is_nil(out)
                test.not_nil(err)
                test.eq((err :: any).code, "MIGRATIONS_APPLIED")
                test.eq((err :: any).details.applied_migrations_count, 1)
            end)

            it("allows explicit leave policy and returns a delete patch", function()
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({ ["wippy.foo.migrations:001"] = true }),
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

        end)

        describe("install planner", function()
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
                test.eq(#plan.install_payload.parameters, 0)

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
                test.eq(flag.value, "")
                test.eq(flag.suggestions[1].value, "enabled")
                test.eq(flag.suggestions[1].source, "default")
                test.eq(plan.missing_requirements[1], "acme.app:feature_flag")
                test.eq(plan.missing_requirements[2], "acme.app:router")
                test.eq(plan.missing_requirements[3], "wippy.bootloader:env_storage")
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
                test.eq(req.default, "app:router")
                test.eq(req.suggestions[1].value, "app:router")
                test.eq(req.suggestions[1].source, "default")
                local param = find_parameter(plan.install_payload.parameters, "wippy.dummy:router")
                test.is_nil(param)
            end)

            it("preserves explicitly supplied transitive full-id parameters", function()
                local full_id = "wippy.bootloader" .. ":env_storage"
                local file_store = "app.env" .. ":file"
                local svc = planner.new({
                    catalog = planner_catalog(),
                    registry = fake_registry({
                        { id = "app.env:store", kind = "env.storage.router", meta = {}, data = {} },
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
                test.eq(req.value, "")
                test.eq(req.value_source, "empty")
                test.is_true(req.missing)
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

            it("emits install started and finished around the canonical apply call", function()
                local sent = {}
                local called = {}
                local svc = hub.new({
                    process = fake_process(sent),
                    uuid = fake_uuid(),
                    planner = no_requirements_planner(),
                    funcs = {
                        new = function()
                            return {
                                call = function(_, id, params)
                                    called.id = id
                                    called.params = params
                                    return { ok = true, stage = "push", changeset_id = "cs-1", push = { version = 9 } }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:install({
                    component = "wippy/terminal",
                    version = ">=v0.0.7",
                }, { actor_id = "admin-1" })

                test.is_nil(err)
                test.eq(out.operation_id, "op-1")
                test.eq(called.id, hub.APPLY_FN)
                test.eq(called.params.actor_id, "admin-1")
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
                local called = {}
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
                    funcs = {
                        new = function()
                            return {
                                call = function(_, id, params)
                                    called.id = id
                                    called.params = params
                                    return { ok = true, stage = "push", push = { version = 11 } }, nil
                                end,
                            }, nil
                        end,
                    },
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
                test.eq(called.id, hub.APPLY_FN)
                local definition = called.params.patches[1].definition
                test.is_true(string.find(definition, "name: wippy.dummy:router", 1, true) ~= nil)
                test.is_true(string.find(definition, "value: app:api.public", 1, true) ~= nil)
                test.is_true(string.find(definition, "name: router", 1, true) == nil)
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
                                    if id == hub.APPLY_FN then
                                        return { ok = true, stage = "push", push = { version = 78 } }, nil
                                    end
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
                test.eq((err :: any).code, "MIGRATIONS_FAILED")
                test.eq((err :: any).details.baseline_version, 77)
                test.eq((gov_state :: any).current_calls, 1)
                test.eq((gov_state :: any).restore_calls, 1)
                test.eq((gov_state :: any).restored_version, 77)
                local apply_call = calls[1] :: any
                local migration_call = calls[2] :: any
                test.not_nil(apply_call)
                test.not_nil(migration_call)
                test.eq(apply_call.id, hub.APPLY_FN)
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
                test.eq((err :: any).code, "INTERNAL")
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
                test.eq((err :: any).code, "REQUIREMENTS_MISSING")
                test.eq((err :: any).details.missing_requirements[1], "wippy.dummy:router")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
