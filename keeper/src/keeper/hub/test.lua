local test = require("test")
local hub = require("hub_service")
local planner = require("planner")
local security_scan = require("security_scan")
local hub_dependencies_tool = require("hub_dependencies_tool")
local hub_migrations_tool = require("hub_migrations_tool")
local http_client = require("http_client")
local api_test = require("api_test")
local json = require("json")

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

local function fake_system(hosts, processes_by_host)
    hosts = hosts or {}
    processes_by_host = processes_by_host or {}
    return {
        hosts = {
            list = function()
                return hosts, nil
            end,
            processes = function(host_id)
                return processes_by_host[host_id] or {}, nil
            end,
        },
        supervisor = {
            states = function()
                return {}, nil
            end,
        },
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

-- Builds the registry entries an installed module contributes: a definition
-- marker (so the module reads as installed) plus one module-owned ns.dependency
-- per child component (meta.module == module, data.component == child). This is
-- the installed dependency-edge shape the closure resolver walks.
local function installed_module(module, children, version)
    version = version or "1.0.0"
    local entries = {
        {
            id = module .. ":__def",
            kind = "ns.definition",
            meta = { module = module, module_version = version },
            data = {},
        },
    }
    for _, child in ipairs(children or {}) do
        table.insert(entries, {
            id = module .. ":dep." .. child,
            kind = "ns.dependency",
            meta = { module = module, module_version = version },
            data = { component = child, version = ">=v0.0.0" },
        })
    end
    return entries
end

-- A deployment root ns.dependency entry (meta:{}, no stored resolved graph),
-- as source-declared baseline roots appear in a brownfield app.
local function root_dep(id, component)
    return { id = id, kind = "ns.dependency", meta = {}, data = { component = component, version = ">=v0.0.0" } }
end

local function concat_entries(...)
    local out = {}
    for _, list in ipairs({ ... }) do
        for _, e in ipairs(list) do table.insert(out, e) end
    end
    return out
end

-- A Hub catalog that fails on any call, asserting the closure resolver never
-- consults the Hub when every root resolves from local installed edges.
local function exploding_catalog()
    local function boom()
        error("Hub catalog must not be consulted for locally installed roots")
    end
    return {
        versions = { list = boom, get = boom, inspect = boom },
        dependencies = { get = boom },
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
            open = function(component, opts)
                local items = versions_by_component[component] or {}
                local id = opts and opts.id or ""
                local version = opts and opts.version or ""
                local label = opts and opts.label or ""
                for _, item in ipairs(items) do
                    if (id ~= "" and item.id == id) or
                        (version ~= "" and item.version == version) or
                        (label ~= "" and (item.version == label or item.label == label)) then
                        local artifact = item.open
                        if not artifact then return nil, "artifact unavailable" end
                        return {
                            version = item.version,
                            digest = item.digest,
                            entries = function(_, _)
                                return artifact.entries or {}, nil
                            end,
                            resources = function()
                                return artifact.resources or {}, nil
                            end,
                            metadata = function()
                                return artifact.metadata or {}, nil
                            end,
                            close = function() return true end,
                        }, nil
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

local function security_scan_catalog()
    return fake_catalog({
        ["acme/clean"] = {
            {
                id = "clean-v1",
                version = "v1.0.0",
                entry_kinds = { "function.lua" },
                inspect = {
                    entries = {
                        {
                            id = "acme.clean:handler",
                            kind = "function.lua",
                            meta = { module = "acme/clean", module_version = "v1.0.0" },
                            data = { method = "handler", source = "return { handler = function() return true end }" },
                        },
                    },
                },
            },
        },
        ["acme/risky"] = {
            {
                id = "risky-v1",
                version = "v1.0.0",
                entry_kinds = { "function.lua", "http.endpoint" },
                inspect = {
                    entries = {
                        {
                            id = "acme.risky:run",
                            kind = "function.lua",
                            meta = { module = "acme/risky", module_version = "v1.0.0" },
                            data = { source = "local process = require('process'); process.exec('curl http://evil')" },
                        },
                    },
                },
            },
        },
        ["acme/app"] = {
            {
                id = "app-v1",
                version = "v1.0.0",
                dependencies = {
                    { org = "acme", name = "clean", version = "v1.0.0" },
                    { org = "acme", name = "installed", version = "v1.0.0" },
                },
                inspect = {
                    entries = {
                        {
                            id = "acme.app:handler",
                            kind = "function.lua",
                            meta = { module = "acme/app", module_version = "v1.0.0" },
                            data = { source = "return { handler = function() return 'ok' end }" },
                        },
                    },
                },
            },
        },
        ["acme/installed"] = {
            {
                id = "installed-v1",
                version = "v1.0.0",
                inspect = { entries = {} },
            },
        },
    })
end

local function security_scan_llm(findings_by_module)
    return {
        generate = function()
            local module = ""
            for key in pairs(findings_by_module) do
                module = key
                break
            end
            local findings = findings_by_module[module] or {}
            local status = #findings > 0 and "warnings" or "clean"
            for _, finding in ipairs(findings) do
                if finding.severity == "critical" then status = "critical" end
            end
            return {
                result = json.encode({
                    status = status,
                    summary = #findings > 0 and "Review flagged module risk." or "No risky patterns found.",
                    findings = findings,
                }),
            }, nil
        end,
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
            meta = {
                hub = {
                    resolved_modules = {
                        { name = "wippy/foo", version = "1.2.3", hash = "foo-hash" },
                    },
                },
            },
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
        describe("dependency closure resolver (installed edges)", function()
            it("keeps a transitive still required by another remaining root", function()
                local entries = concat_entries(
                    installed_module("wippy/alpha", { "wippy/shared", "wippy/only-alpha" }),
                    installed_module("wippy/beta", { "wippy/shared" }),
                    installed_module("wippy/shared", {}),
                    installed_module("wippy/only-alpha", {})
                )
                local pl = planner.new({ registry = fake_registry(entries) }) :: any

                local keep, _, err = pl:resolve_dependency_closure({
                    roots = { root_dep("app.deps:beta", "wippy/beta") },
                    mode = "installed",
                })

                test.is_nil(err)
                test.is_true(keep["wippy/beta"])
                test.is_true(keep["wippy/shared"])
                test.is_nil(keep["wippy/alpha"])
                test.is_nil(keep["wippy/only-alpha"])
            end)

            it("does not keep a transitive needed only by the removed root", function()
                local entries = concat_entries(
                    installed_module("wippy/alpha", { "wippy/shared", "wippy/only-alpha" }),
                    installed_module("wippy/shared", {}),
                    installed_module("wippy/only-alpha", {})
                )
                local pl = planner.new({ registry = fake_registry(entries) }) :: any

                -- No remaining roots: uninstalling the only root prunes everything.
                local keep, _, err = pl:resolve_dependency_closure({ roots = {}, mode = "installed" })

                test.is_nil(err)
                test.is_nil(next(keep))
            end)

            it("keeps a diamond transitive reachable from two remaining roots", function()
                local entries = concat_entries(
                    installed_module("wippy/alpha", { "wippy/shared" }),
                    installed_module("wippy/beta", { "wippy/shared" }),
                    installed_module("wippy/gamma", { "wippy/shared" }),
                    installed_module("wippy/shared", {})
                )
                local pl = planner.new({ registry = fake_registry(entries) }) :: any

                local keep, _, err = pl:resolve_dependency_closure({
                    roots = {
                        root_dep("app.deps:beta", "wippy/beta"),
                        root_dep("app.deps:gamma", "wippy/gamma"),
                    },
                    mode = "installed",
                })

                test.is_nil(err)
                test.is_true(keep["wippy/shared"])
                test.is_true(keep["wippy/beta"])
                test.is_true(keep["wippy/gamma"])
                test.is_nil(keep["wippy/alpha"])
            end)

            it("keeps a shared transitive for a baseline root declared with meta:{} (no resolved graph)", function()
                -- The kickside shape: a baseline root carrying only meta:{} depends
                -- on a shared transitive that the removed root also uses. Uninstall
                -- must keep the shared module through the closure, not a stored graph.
                local entries = concat_entries(
                    { root_dep("app.deps:baseline", "wippy/baseline"), root_dep("app.deps:actor", "wippy/actor") },
                    installed_module("wippy/baseline", { "wippy/shared" }),
                    installed_module("wippy/actor", { "wippy/shared" }),
                    installed_module("wippy/shared", {})
                )
                local svc = hub.new({
                    registry = fake_registry(entries),
                    planner = planner,
                }) :: any

                local keep, _, err = svc:plan_uninstall_closure(
                    { id = "app.deps:actor", kind = "ns.dependency", meta = {}, data = { component = "wippy/actor" } }
                )

                test.is_nil(err)
                test.is_true(keep["wippy/shared"])
                test.is_true(keep["wippy/baseline"])
                test.is_nil(keep["wippy/actor"])
            end)

            it("treats a root with recorded edges as complete and flags only dangling edge targets", function()
                -- Partial-edge invariant: governance install writes a module's
                -- complete edge set atomically, so a root that exposes ANY edges is
                -- treated as fully resolved. A recorded edge pointing at a
                -- non-installed module (a dangling ref) surfaces as unresolved and is
                -- handled conservatively downstream; a truly missing edge is
                -- undetectable offline and out of scope (registry corruption). This
                -- test pins that observable behavior.
                local entries = concat_entries(
                    installed_module("wippy/root", { "wippy/installed-child", "wippy/dangling" }),
                    installed_module("wippy/installed-child", {})
                )
                local pl = planner.new({ registry = fake_registry(entries) }) :: any

                local keep, unresolved, err = pl:resolve_dependency_closure({
                    roots = { root_dep("app.deps:root", "wippy/root") },
                    mode = "installed",
                })

                test.is_nil(err)
                local unresolved_set = unresolved :: any
                test.is_true(keep["wippy/root"])
                test.is_nil(unresolved_set["wippy/root"])
                test.is_true(keep["wippy/installed-child"])
                test.is_nil(unresolved_set["wippy/installed-child"])
                test.is_true(keep["wippy/dangling"])
                test.is_true(unresolved_set["wippy/dangling"])
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

            it("expands installed modules into roots and transitives with used_by", function()
                local svc = hub.new({
                    registry = fake_registry(concat_entries(
                        { root_dep("app.deps:alpha", "wippy/alpha") },
                        { root_dep("app.deps:beta", "wippy/beta") },
                        installed_module("wippy/alpha", { "wippy/shared", "wippy/only-alpha" }, "1.0.0"),
                        installed_module("wippy/beta", { "wippy/shared" }, "2.0.0"),
                        installed_module("wippy/shared", {}, "3.0.0"),
                        installed_module("wippy/only-alpha", {}, "4.0.0")
                    )),
                    sql = fake_sql({}),
                    planner = planner,
                }) :: any

                local out, err = svc:list_dependencies({})
                test.is_nil(err)
                -- explicit roots unchanged: count stays the deployment-root count
                test.eq(out.count, 2)
                -- full inventory adds transitive modules
                test.eq(out.module_count, 4)

                local by = {}
                for _, m in ipairs(out.modules) do by[m.name] = m end

                test.is_true(by["wippy/alpha"].is_root)
                test.is_false(by["wippy/alpha"].transitive)
                test.eq(by["wippy/alpha"].version, "1.0.0")
                test.eq(by["wippy/alpha"].used_by_count, 0)

                -- shared transitive: pulled by both roots
                test.is_false(by["wippy/shared"].is_root)
                test.is_true(by["wippy/shared"].transitive)
                test.eq(by["wippy/shared"].used_by_count, 2)
                test.eq(by["wippy/shared"].version, "3.0.0")

                -- transitive needed by exactly one root
                test.eq(by["wippy/only-alpha"].used_by_count, 1)
                test.eq(by["wippy/only-alpha"].used_by[1], "wippy/alpha")

                -- roots carry the shared indicator too
                local alpha_root = out.dependencies[1]
                test.is_true(alpha_root.is_root)
                test.not_nil(alpha_root.used_by)
            end)

            it("returns a stable count on repeated calls without mutating registry slices", function()
                -- A registry that hands back the SAME backing slice per criteria on
                -- every call, so any in-place reader mutation corrupts later reads.
                local base = fake_registry(concat_entries(
                    { root_dep("app.deps:beta", "wippy/beta") },
                    { root_dep("app.deps:alpha", "wippy/alpha") },
                    installed_module("wippy/alpha", { "wippy/zeta", "wippy/aardvark" }),
                    installed_module("wippy/beta", {}),
                    installed_module("wippy/zeta", {}),
                    installed_module("wippy/aardvark", {})
                ))
                local cache = {}
                local function key(criteria)
                    local parts = {}
                    for k, v in pairs(criteria or {}) do table.insert(parts, tostring(k) .. "=" .. tostring(v)) end
                    table.sort(parts)
                    return table.concat(parts, "&")
                end
                local reg = {
                    find = function(criteria)
                        local k = key(criteria)
                        if cache[k] == nil then cache[k] = (base.find(criteria)) end
                        return cache[k], nil
                    end,
                    get = base.get,
                }

                local svc = hub.new({ registry = reg, sql = fake_sql({}), planner = planner }) :: any

                local first, first_err = svc:list_dependencies({})
                local second, second_err = svc:list_dependencies({})
                test.is_nil(first_err)
                test.is_nil(second_err)
                test.eq(first.count, 2)
                -- the defect symptom is count collapsing on a second read
                test.eq(second.count, first.count)
                test.eq(second.module_count, first.module_count)

                -- registry-owned slice keeps its insertion order: readers sort copies
                local slice = cache["meta.module=wippy/alpha"]
                if not slice then error("expected cached alpha module slice") end
                test.eq(slice[1].id, "wippy/alpha:__def")
                test.eq(slice[2].id, "wippy/alpha:dep.wippy/zeta")
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

            it("commits the dependency through governance without filesystem state", function()
                local gov_state = ({ current_version = 12 }) :: any
                local svc = hub.new({
                    planner = graph_planner({
                        { module = "wippy/dummy", version = "0.1.2", digest = "abc123" },
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
                test.is_nil(gov_state.last_changeset[1].entry.meta.hub)
                test.is_nil(gov_state.last_options.branch)
                test.is_nil(out.lock)
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

            it("rejects conflicting duplicate modules in a resolved install graph", function()
                local gov_state = ({ current_version = 25 }) :: any
                local svc = hub.new({
                    planner = graph_planner({
                        { module = "wippy/dummy", version = "0.1.2", digest = "abc123" },
                        { module = "wippy/dummy", version = "0.1.3", digest = "def456" },
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
            end)

            it("blocks uninstall when applied migrations would be orphaned", function()
                local svc = hub.new({
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({ ["wippy.foo.migrations:001"] = true }),
                    planner = planner,
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
                    planner = planner,
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
                    planner = planner,
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

            it("reports the uninstalled module from registry closure after apply", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local svc = hub.new({
                    registry = fake_registry(concat_entries(
                        { root_dep("app.deps:foo", "wippy/foo"), root_dep("app.deps:kept", "wippy/kept") },
                        installed_module("wippy/foo", {}),
                        installed_module("wippy/kept", { "wippy/terminal" }),
                        installed_module("wippy/terminal", {})
                    )),
                    sql = fake_sql({}),
                    planner = planner,
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
                test.is_nil(out.lock)
                test.eq(out.preview.removed[1].name, "wippy/foo")
            end)

            it("resolves an installed uninstall closure without consulting the Hub catalog", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local entries = concat_entries(
                    { root_dep("app.deps:app", "acme/app"), root_dep("app.deps:other", "acme/other") },
                    installed_module("acme/app", { "wippy/shared" }),
                    installed_module("acme/other", {}),
                    installed_module("wippy/shared", {})
                )
                local svc = hub.new({
                    registry = fake_registry(entries),
                    sql = fake_sql({}),
                    planner = planner.new({ registry = fake_registry(entries), catalog = exploding_catalog() }),
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
                test.is_nil(out.lock)
                local removed = {}
                for _, row in ipairs(out.preview.removed) do removed[row.name] = true end
                test.is_true(removed["acme/app"])
                test.is_true(removed["wippy/shared"])
            end)

            it("treats a non-installed remaining root as a leaf instead of failing the closure", function()
                -- A brownfield app can carry a deployment root whose module was
                -- never installed (no registry entries) and is not Hub-resolvable.
                -- Uninstall must still succeed offline, pruning only the removed
                -- root's exclusive modules and never consulting the Hub.
                local files = { ["wippy.lock"] = "initial-lock" }
                local entries = concat_entries(
                    {
                        root_dep("app.deps:app", "acme/app"),
                        root_dep("app.deps:other", "acme/other"),
                        root_dep("app.deps:stale", "vendor/stale"),
                    },
                    installed_module("acme/app", { "wippy/shared", "wippy/only-app" }),
                    installed_module("acme/other", { "wippy/shared" }),
                    installed_module("wippy/shared", {}),
                    installed_module("wippy/only-app", {})
                )
                local svc = hub.new({
                    registry = fake_registry(entries),
                    sql = fake_sql({}),
                    planner = planner.new({ registry = fake_registry(entries), catalog = exploding_catalog() }),
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "acme/app", version = "1.0.0", hash = "app-hash" },
                            { name = "acme/other", version = "1.0.0", hash = "other-hash" },
                            { name = "wippy/shared", version = "1.0.0", hash = "shared-hash" },
                            { name = "wippy/only-app", version = "1.0.0", hash = "only-hash" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance({ current_version = 39 }),
                    funcs = {
                        new = function()
                            return {
                                call = function()
                                    return { ok = true, stage = "push", push = { version = 40 } }, nil
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
                local removed = {}
                for _, row in ipairs(out.preview.removed) do removed[row.name] = true end
                test.is_true(removed["acme/app"])
                test.is_true(removed["wippy/only-app"])
                test.is_nil(removed["wippy/shared"])
                test.eq(out.preview.kept[1].name, "wippy/shared")
                test.is_true(#out.preview.warnings > 0)
            end)

            it("keeps transitive modules still required by another root during uninstall", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local entries = concat_entries(
                    { root_dep("app.deps:app", "acme/app"), root_dep("app.deps:other", "acme/other") },
                    installed_module("acme/app", { "wippy/shared" }),
                    installed_module("acme/other", { "wippy/shared" }),
                    installed_module("wippy/shared", {})
                )
                local svc = hub.new({
                    registry = fake_registry(entries),
                    sql = fake_sql({}),
                    planner = planner.new({ registry = fake_registry(entries), catalog = exploding_catalog() }),
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
                test.eq(out.preview.removed[1].name, "acme/app")
                test.eq(out.preview.kept[1].name, "wippy/shared")
            end)

            it("refuses to uninstall a root still required by another installed root", function()
                local function make_svc()
                    local entries = concat_entries(
                        {
                            root_dep("app.deps:repl", "wippy/repl"),
                            root_dep("app.deps:docs", "wippy/docs"),
                            root_dep("app.deps:shared", "wippy/shared"),
                        },
                        installed_module("wippy/repl", { "wippy/shared" }),
                        installed_module("wippy/docs", { "wippy/shared" }),
                        installed_module("wippy/shared", {})
                    )
                    return hub.new({
                        registry = fake_registry(entries),
                        sql = fake_sql({}),
                        planner = planner,
                        fs = fake_project_fs({ ["wippy.lock"] = "initial-lock" }),
                        yaml = fake_yaml_for_lock({
                            directories = { modules = ".wippy", src = "./src/app" },
                            modules = {
                                { name = "wippy/repl", version = "1.0.0", hash = "repl-hash" },
                                { name = "wippy/docs", version = "1.0.0", hash = "docs-hash" },
                                { name = "wippy/shared", version = "1.0.0", hash = "shared-hash" },
                            },
                            replacements = {},
                        }),
                        governance = fake_governance({ current_version = 50 }),
                        funcs = {
                            new = function()
                                return {
                                    call = function()
                                        return { ok = true, stage = "push", push = { version = 51 } }, nil
                                    end,
                                }, nil
                            end,
                        },
                    }) :: any
                end

                -- dry_run must refuse loudly and list the dependent roots.
                local dry_out, dry_err = make_svc():uninstall({ component = "wippy/shared", dry_run = true })
                test.is_nil(dry_out)
                test.eq(err_code(dry_err), "DEPENDENCY_REQUIRED")
                local dry_details = err_details(dry_err)
                test.not_nil(dry_details.required_by)
                local names = {}
                for _, n in pairs(dry_details.required_by) do names[n] = true end
                test.is_true(names["wippy/repl"])
                test.is_true(names["wippy/docs"])

                -- real mode must refuse identically and never touch the registry/lock.
                local gov_svc = make_svc()
                local real_out, real_err = gov_svc:uninstall({ component = "wippy/shared" })
                test.is_nil(real_out)
                test.eq(err_code(real_err), "DEPENDENCY_REQUIRED")
            end)

            it("uninstalls a root that no other root requires even when it has dependents of its own", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local entries = concat_entries(
                    {
                        root_dep("app.deps:repl", "wippy/repl"),
                        root_dep("app.deps:docs", "wippy/docs"),
                        root_dep("app.deps:shared", "wippy/shared"),
                    },
                    installed_module("wippy/repl", { "wippy/shared" }),
                    installed_module("wippy/docs", { "wippy/shared" }),
                    installed_module("wippy/shared", {})
                )
                local svc = hub.new({
                    registry = fake_registry(entries),
                    sql = fake_sql({}),
                    planner = planner,
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "wippy/repl", version = "1.0.0", hash = "repl-hash" },
                            { name = "wippy/docs", version = "1.0.0", hash = "docs-hash" },
                            { name = "wippy/shared", version = "1.0.0", hash = "shared-hash" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance({ current_version = 50 }),
                    funcs = {
                        new = function()
                            return {
                                call = function()
                                    return { ok = true, stage = "push", push = { version = 51 } }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                -- wippy/repl is required by no other root; shared stays because docs needs it.
                local out, err = svc:uninstall({ component = "wippy/repl", migration_policy = "leave" })
                test.is_nil(err)
                test.eq(out.preview.removed[1].name, "wippy/repl")
                test.eq(out.preview.kept[1].name, "wippy/shared")
            end)

            it("does not keep transitive modules only referenced by the package being removed", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local entries = concat_entries(
                    { root_dep("app.deps:app", "acme/app") },
                    installed_module("acme/app", { "wippy/shared" }),
                    installed_module("wippy/shared", {})
                )
                local svc = hub.new({
                    registry = fake_registry(entries),
                    sql = fake_sql({}),
                    planner = planner.new({ registry = fake_registry(entries), catalog = exploding_catalog() }),
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
                test.eq(#out.preview.removed, 2)
                test.eq(out.preview.removed[1].name, "acme/app")
                test.eq(out.preview.removed[2].name, "wippy/shared")
            end)

            it("reports unresolved remaining registry roots in the uninstall preview", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local entries = concat_entries(
                    {
                        root_dep("app.deps:target", "wippy/target"),
                        root_dep("app.deps:consumer", "wippy/consumer"),
                    },
                    installed_module("wippy/target", { "wippy/only-target" }),
                    installed_module("wippy/only-target", {})
                )
                local svc = hub.new({
                    registry = fake_registry(entries),
                    sql = fake_sql({}),
                    planner = planner.new({ registry = fake_registry(entries), catalog = exploding_catalog() }),
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "wippy/target", version = "1.0.0", hash = "t" },
                            { name = "wippy/only-target", version = "1.0.0", hash = "o" },
                            { name = "wippy/consumer", version = "1.0.0", hash = "c" },
                            { name = "wippy/shared", version = "1.0.0", hash = "s" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance({ current_version = 50 }),
                    funcs = {
                        new = function()
                            return {
                                call = function()
                                    return { ok = true, stage = "push", push = { version = 51 } }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:uninstall({
                    component = "wippy/target",
                    migration_policy = "leave",
                })

                test.is_nil(err)
                test.not_nil(out.apply)
                local removed = {}
                for _, row in ipairs(out.preview.removed) do removed[row.name] = true end
                test.is_true(removed["wippy/target"])
                test.is_true(removed["wippy/only-target"])
                test.is_nil(removed["wippy/shared"])
                test.is_nil(removed["wippy/consumer"])
                test.is_true(#out.preview.warnings > 0)
                test.contains(out.preview.warnings[1], "wippy/consumer")
            end)

            it("removes a dependency-free target while reporting an unresolved remaining root", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local entries = concat_entries(
                    {
                        root_dep("app.deps:target", "wippy/target"),
                        root_dep("app.deps:consumer", "wippy/consumer"),
                    },
                    installed_module("wippy/target", {})
                )
                local svc = hub.new({
                    registry = fake_registry(entries),
                    sql = fake_sql({}),
                    planner = planner.new({ registry = fake_registry(entries), catalog = exploding_catalog() }),
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "wippy/target", version = "1.0.0", hash = "t" },
                            { name = "wippy/consumer", version = "1.0.0", hash = "c" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance({ current_version = 50 }),
                    funcs = {
                        new = function()
                            return {
                                call = function()
                                    return { ok = true, stage = "push", push = { version = 51 } }, nil
                                end,
                            }, nil
                        end,
                    },
                }) :: any

                local out, err = svc:uninstall({
                    component = "wippy/target",
                    migration_policy = "leave",
                })

                test.is_nil(err)
                test.not_nil(out.apply)
                local removed = {}
                for _, row in ipairs(out.preview.removed) do removed[row.name] = true end
                test.is_true(removed["wippy/target"])
                test.is_nil(removed["wippy/consumer"])
                test.is_true(#out.preview.warnings > 0)
                test.contains(out.preview.warnings[1], "wippy/consumer")
            end)

        end)

        describe("install planner", function()
                it("returns clean when the reviewer finds no issues", function()
                    local scanner = security_scan.new({
                        planner = planner,
                        catalog = security_scan_catalog(),
                        registry = fake_registry({}),
                        llm = security_scan_llm({}),
                    }) :: any

                    local out, err = scanner:scan({ component = "acme/clean", version = "v1.0.0" })

                    test.is_nil(err)
                    test.eq(out.success, true)
                    test.eq(out.overall_status, "clean")
                    test.eq(out.scanned, 1)
                    test.eq(out.total, 1)
                    test.eq(out.modules[1].status, "clean")
                    test.eq(#out.modules[1].findings, 0)
                end)

                it("uses the fast model class by default", function()
                    local requested_model = nil
                    local scanner = security_scan.new({
                        config = {
                            read_default = function(name)
                                test.eq(name, "hub_security_scan_model")
                                return nil, "not configured"
                            end,
                        },
                        llm = {
                            generate = function(_, options)
                                requested_model = options.model
                                return { result = '{"status":"clean","findings":[]}' }, nil
                            end,
                        },
                    }) :: any

                    local result = scanner:review_module(
                        { module = "acme/clean", version = "v1.0.0" },
                        { entries = {} }
                    )

                    test.eq(result.status, "clean")
                    test.eq(scanner.model, "class:fast")
                    test.eq(requested_model, "class:fast")
                end)

                it("honors the declared security scan model override", function()
                    local requested_model = nil
                    local scanner = security_scan.new({
                        config = {
                            read_default = function(name)
                                test.eq(name, "hub_security_scan_model")
                                return "class:security", nil
                            end,
                        },
                        llm = {
                            generate = function(_, options)
                                requested_model = options.model
                                return { result = '{"status":"clean","findings":[]}' }, nil
                            end,
                        },
                    }) :: any

                    local result = scanner:review_module(
                        { module = "acme/clean", version = "v1.0.0" },
                        { entries = {} }
                    )

                    test.eq(result.status, "clean")
                    test.eq(scanner.model, "class:security")
                    test.eq(requested_model, "class:security")
                end)

                it("promotes dangerous reviewer findings to the overall status", function()
                    local scanner = security_scan.new({
                        planner = planner,
                        catalog = security_scan_catalog(),
                        registry = fake_registry({}),
                        llm = security_scan_llm({
                            ["acme/risky"] = {
                                {
                                    severity = "critical",
                                    title = "Shell execution reaches the network",
                                    detail = "The module shells out to curl from runtime code.",
                                    location = "acme.risky:run",
                                },
                            },
                        }),
                    }) :: any

                    local out, err = scanner:scan({ component = "acme/risky", version = "v1.0.0" })

                    test.is_nil(err)
                    test.eq(out.overall_status, "critical")
                    test.eq(out.modules[1].status, "critical")
                    test.eq(out.modules[1].findings[1].severity, "critical")
                    test.eq(out.modules[1].findings[1].title, "Shell execution reaches the network")
                    test.eq(out.modules[1].findings[1].location, "acme.risky:run")
                end)

                it("reports LLM unavailability as an honest scan error", function()
                    local scanner = security_scan.new({
                        planner = planner,
                        catalog = security_scan_catalog(),
                        registry = fake_registry({}),
                        llm = {
                            generate = function()
                                return nil, "model unavailable"
                            end,
                        },
                    }) :: any

                    local out, err = scanner:scan({ component = "acme/clean", version = "v1.0.0" })

                    test.is_nil(err)
                    test.eq(out.success, true)
                    test.eq(out.overall_status, "warnings")
                    test.eq(out.modules[1].status, "error")
                    test.eq(out.modules[1].findings[1].severity, "warning")
                    test.contains(out.modules[1].findings[1].title, "Security review unavailable")
                    test.contains(out.modules[1].findings[1].detail, "model unavailable")
                    test.contains(out.overall_summary, "unavailable")
                end)

                it("reviews large modules in chunks without truncation findings", function()
                    local calls = 0
                    local long_source = string.rep("local ok = true\n", 5000)
                    local scanner = security_scan.new({
                        planner = planner,
                        catalog = fake_catalog({
                            ["acme/large"] = {
                                {
                                    id = "large-v1",
                                    version = "v1.0.0",
                                    entry_kinds = { "function.lua" },
                                    inspect = {
                                        entries = {
                                            {
                                                id = "acme.large:handler",
                                                kind = "function.lua",
                                                meta = { module = "acme/large", module_version = "v1.0.0" },
                                                data = { source = long_source },
                                            },
                                        },
                                    },
                                },
                            },
                        }),
                        registry = fake_registry({}),
                        content_limit = 20000,
                        llm = {
                            generate = function()
                                calls = calls + 1
                                return {
                                    result = json.encode({
                                        status = "clean",
                                        summary = "No risky patterns found.",
                                        findings = {},
                                    }),
                                }, nil
                            end,
                        },
                    }) :: any

                    local out, err = scanner:scan({ component = "acme/large", version = "v1.0.0" })

                    test.is_nil(err)
                    test.eq(out.success, true)
                    test.eq(out.modules[1].status, "clean")
                    test.eq(#out.modules[1].findings, 0)
                    test.is_true(calls > 1, "large module should be reviewed across multiple chunks")
                end)

                it("scans only new modules while reporting installed modules as skipped", function()
                    local scanner = security_scan.new({
                        planner = planner,
                        catalog = security_scan_catalog(),
                        registry = fake_registry(installed_module("acme/installed", {})),
                        llm = security_scan_llm({}),
                    }) :: any

                    local out, err = scanner:scan({ component = "acme/app", version = "v1.0.0" })

                    test.is_nil(err)
                    test.eq(out.overall_status, "clean")
                    test.eq(out.total, 3)
                    test.eq(out.scanned, 2)
                    local by_module = {}
                    for _, row in ipairs(out.modules) do by_module[row.module] = row end
                    test.eq(by_module["acme/app"].status, "clean")
                    test.eq(by_module["acme/clean"].status, "clean")
                    test.eq(by_module["acme/installed"].status, "clean")
                    test.contains(by_module["acme/installed"].summary, "already installed")
                end)

                it("reviews the target module even when updating an installed component", function()
                    local scanner = security_scan.new({
                        planner = planner,
                        catalog = security_scan_catalog(),
                        registry = fake_registry(installed_module("acme/clean", {})),
                        llm = security_scan_llm({}),
                    }) :: any

                    local out, err = scanner:scan({ component = "acme/clean", version = "v1.0.0" })

                    test.is_nil(err)
                    test.eq(out.total, 1)
                    test.eq(out.scanned, 1)
                    test.eq(out.modules[1].module, "acme/clean")
                    test.eq(out.modules[1].status, "clean")
                end)

                it("fetches scan artifacts through the planner-resolved version ref", function()
                    local inspect_refs = {}
                    local catalog = fake_catalog({
                        ["wippy/actor"] = {
                            {
                                id = "actor-version-row",
                                version = "v0.4.0",
                                entry_kinds = { "function.lua" },
                                inspect = {
                                    entries = {
                                        {
                                            id = "wippy.actor:run",
                                            kind = "function.lua",
                                            meta = { module = "wippy/actor", module_version = "v0.4.0" },
                                            data = { source = "return { handler = function() return true end }" },
                                        },
                                    },
                                },
                            },
                        },
                    })
                    local original_inspect = catalog.versions.inspect
                    catalog.versions.inspect = function(component, ref)
                        table.insert(inspect_refs, { component = component, ref = ref })
                        if ref and ref.id then
                            return nil, "invalid version format"
                        end
                        return original_inspect(component, ref)
                    end

                    local scanner = security_scan.new({
                        planner = planner,
                        catalog = catalog,
                        registry = fake_registry({}),
                        llm = security_scan_llm({}),
                    }) :: any

                    local out, err = scanner:scan({ component = "wippy/actor", version = "0.4.0" })

                    test.is_nil(err)
                    test.eq(out.success, true)
                    test.eq(out.overall_status, "clean")
                    test.eq(out.scanned, 1)
                    test.eq(out.modules[1].module, "wippy/actor")
                    test.eq(out.modules[1].status, "clean")
                    local first_ref = inspect_refs[1] :: any
                    test.not_nil(first_ref)
                    test.eq(first_ref.component, "wippy/actor")
                    test.eq(first_ref.ref.version, "v0.4.0")
                    test.is_nil(first_ref.ref.id)
                end)

                it("degrades honestly when a scan artifact is genuinely unavailable", function()
                    local scanner = security_scan.new({
                        planner = planner,
                        catalog = fake_catalog({
                            ["wippy/missing"] = {
                                { id = "missing-version-row", version = "v1.0.0", entry_kinds = { "function.lua" } },
                            },
                        }),
                        registry = fake_registry({}),
                        llm = security_scan_llm({}),
                    }) :: any

                    local out, err = scanner:scan({ component = "wippy/missing", version = "1.0.0" })

                    test.is_nil(err)
                    test.eq(out.success, true)
                    test.eq(out.overall_status, "warnings")
                    test.eq(out.modules[1].status, "error")
                    test.contains(out.modules[1].findings[1].title, "Module artifact unavailable")
                end)

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

            it("preserves inspected requirement metadata for declared security scope suggestions", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["acme/secure"] = {
                            {
                                version = "v1.0.0",
                                entry_kinds = { "ns.requirement" },
                                requirements = {
                                    {
                                        name = "user_security_scope",
                                        default = "",
                                        targets = {
                                            { entry = "acme.secure.security:endpoint_access", path = ".groups +=" },
                                        },
                                    },
                                },
                                inspect = {
                                    entries = {
                                        {
                                            id = "acme.secure.security:user_security_scope",
                                            kind = "ns.requirement",
                                            data = {
                                                meta = {
                                                    value_kind = "security.scope",
                                                    comment = "Application security group that may reach secure endpoints.",
                                                },
                                                targets = {
                                                    { entry = "acme.secure.security:endpoint_access", path = ".groups +=" },
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    }),
                    registry = fake_registry({
                        {
                            id = "app.security:role_user",
                            kind = "registry.entry",
                            meta = {
                                type = "kickside.security.role",
                                title = "User",
                                comment = "Standard signed-in member.",
                            },
                            data = {
                                role_id = "app.security:user",
                            },
                        },
                    }),
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/secure",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                local req = find_requirement(plan, "acme.secure.security:user_security_scope")
                test.not_nil(req)
                test.eq(req.expected_kind, "security.scope")
                test.eq(req.description, "Application security group that may reach secure endpoints.")
                test.eq(req.suggestions[1].value, "app.security:user")
                test.eq(req.suggestions[1].label, "User")
                test.eq(req.suggestions[1].kind, "security.scope")
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
                test.eq(plan.dependency.id, "app.plugins:app")
                test.eq(plan.dependency.namespace, "app.plugins")
                test.eq(plan.install_payload.namespace, "app.plugins")
            end)

            it("ignores existing dependency clusters when governance manages no namespaces", function()
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
                    }),
                    gov = {
                        get_managed_namespaces = function()
                            return {}
                        end,
                        is_namespace_managed = function()
                            return false
                        end,
                    },
                }) :: any

                local plan, err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                test.eq(plan.dependency.id, "app.deps:app")
                test.eq(plan.dependency.namespace, "app.deps")
                test.eq(plan.install_payload.namespace, "app.deps")
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

            it("rejects supplied full-id parameters that target a transitive module", function()
                local full_id = "wippy.bootloader" .. ":env_storage"
                local file_store = "app.env" .. ":file"
                local svc = planner.new({
                    catalog = planner_catalog(),
                    registry = fake_registry({
                        { id = "app.env:store", kind = "env.storage.router", meta = {}, data = {} },
                        { id = "app.env:file", kind = "env.storage.file", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, plan_err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                    parameters = {
                        { name = full_id, value = file_store },
                    },
                })

                test.is_nil(plan)
                test.eq(err_code(plan_err), "PARAMETER_TARGET_TRANSITIVE")
                test.contains(err_message(plan_err), "wippy/bootloader")
                test.contains(err_message(plan_err), "explicit root")
                local details = err_details(plan_err)
                test.eq(details.parameter, full_id)
                test.eq(details.module, "wippy/bootloader")
            end)

            it("rejects install when a supplied parameter targets a transitive module", function()
                local governance_state = {}
                local real = planner.new({
                    catalog = planner_catalog(),
                    registry = fake_registry({
                        { id = "app.env:store", kind = "env.storage.router", meta = {}, data = {} },
                    }),
                }) :: any
                local svc = hub.new({
                    registry = fake_registry({}),
                    planner = { new = function() return real end },
                    governance = fake_governance(governance_state),
                    fs = fake_project_fs({ ["wippy.lock"] = "x" }),
                    yaml = fake_yaml_for_lock({ modules = {}, replacements = {} }),
                }) :: any

                local out, install_err = svc:install({
                    component = "acme/app",
                    version = "v1.0.0",
                    parameters = {
                        { name = "wippy.bootloader:env_storage", value = "app.env:store" },
                    },
                }, { actor_id = "admin-1" })

                test.is_nil(out)
                test.eq(err_code(install_err), "PARAMETER_TARGET_TRANSITIVE")
                test.contains(err_message(install_err), "wippy/bootloader")
                test.is_nil(governance_state.publish_calls)
            end)

            it("accepts supplied full-id parameters for the root module's own requirement", function()
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
                                        targets = { { entry = "acme.app:service", path = ".router" } },
                                    },
                                },
                            },
                        },
                        ["wippy/bootloader"] = {
                            { version = "v0.1.0", requirements = {} },
                        },
                    }),
                    registry = fake_registry({
                        { id = "app:api", kind = "http.router", meta = {}, data = {} },
                    }),
                }) :: any

                local plan, plan_err = svc:plan_install({
                    component = "acme/app",
                    version = "v1.0.0",
                    parameters = {
                        { name = "acme.app:router", value = "app:api" },
                    },
                })

                test.is_nil(plan_err)
                local req = find_requirement(plan, "acme.app:router")
                test.not_nil(req)
                test.eq(req.value, "app:api")
                test.eq(req.value_source, "provided")
                local param = find_parameter(plan.install_payload.parameters, "acme.app:router")
                test.not_nil(param)
                test.eq(param.value, "app:api")
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
                test.is_nil(param)
                test.eq(plan.parameter_values["wippy.bootloader:env_storage"], "app.env:store")
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

            it("flags installed and shared modules in the install graph", function()
                local lock_doc = {
                    modules = {
                        { name = "wippy/other", version = "1.0.0" },
                        { name = "wippy/shared", version = "1.0.0" },
                    },
                    replacements = {},
                }
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["acme/app"] = {
                            {
                                version = "v1.0.0",
                                dependencies = {
                                    { org = "wippy", name = "shared", version = "v1.0.0" },
                                    { org = "wippy", name = "brandnew", version = "v1.0.0" },
                                },
                            },
                        },
                        ["wippy/shared"] = { { version = "v1.0.0" } },
                        ["wippy/brandnew"] = { { version = "v1.0.0" } },
                    }),
                    registry = fake_registry(concat_entries(
                        { root_dep("app.deps:other", "wippy/other") },
                        installed_module("wippy/other", { "wippy/shared" }),
                        installed_module("wippy/shared", {})
                    )),
                    fs = fake_project_fs({ ["wippy.lock"] = "x" }),
                    yaml = fake_yaml_for_lock(lock_doc),
                }) :: any

                local graph, err = svc:resolve_install_graph("acme/app", "v1.0.0", {})
                test.is_nil(err)

                local nodes = {}
                for _, node in ipairs(graph) do nodes[node.module] = node end

                -- shared transitive: already in the lock AND reused by another root
                test.is_true(nodes["wippy/shared"].installed)
                test.is_true(nodes["wippy/shared"].shared)

                -- brand-new transitive: neither installed nor shared
                test.is_false(nodes["wippy/brandnew"].installed)
                test.is_false(nodes["wippy/brandnew"].shared)

                -- the module being installed is itself neither installed nor shared
                test.is_false(nodes["acme/app"].installed)
                test.is_false(nodes["acme/app"].shared)
            end)
            it("surfaces resolution error details naming the unresolvable component", function()
                local svc = planner.new({
                    catalog = fake_catalog({}),
                    registry = fake_registry({}),
                }) :: any

                local plan, plan_err = svc:plan_install({
                    component = "acme/ghost",
                    version = ">=v1.0.0",
                })

                test.is_nil(plan)
                test.eq(err_code(plan_err), "CONFLICT")
                test.contains(err_message(plan_err), "acme/ghost")
                local details = err_details(plan_err)
                test.not_nil(details)
                -- Error details survive a string-keyed conversion only, so the
                -- resolution errors are keyed by 1-based position as strings.
                local resolution = details.errors
                test.not_nil(resolution)
                test.not_nil(resolution["1"])
                test.eq(resolution["1"].module, "acme/ghost")
                test.eq(resolution["1"].constraint, ">=v1.0.0")
                test.contains(tostring(resolution["1"].message), "no versions available")
            end)

            it("fails the plan when a resolved version conflicts with an installed root constraint", function()
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["kickside/demo"] = {
                            {
                                version = "0.1.0",
                                dependencies = {
                                    { org = "kickside", name = "component", version_constraint = "0.1.8" },
                                },
                            },
                        },
                        ["kickside/component"] = {
                            { version = "0.1.2" },
                            { version = "0.1.8" },
                        },
                    }),
                    registry = fake_registry({
                        {
                            id = "app.deps:component",
                            kind = "ns.dependency",
                            meta = {},
                            data = { component = "kickside/component", version = "0.1.2" },
                        },
                    }),
                }) :: any

                local plan, plan_err = svc:plan_install({
                    component = "kickside/demo",
                    version = "0.1.0",
                })

                test.is_nil(plan)
                test.eq(err_code(plan_err), "CONFLICT")
                test.contains(err_message(plan_err), "conflicting version constraints for kickside/component")
                test.contains(err_message(plan_err), "0.1.2 (required by root)")
                test.contains(err_message(plan_err), "0.1.8 (required by kickside/demo)")
                local details = err_details(plan_err)
                test.not_nil(details.conflicts)
                test.eq(details.conflicts["1"].module, "kickside/component")
                test.eq(details.conflicts["1"].installed_constraint, "0.1.2")
                test.eq(details.conflicts["1"].resolved_version, "0.1.8")
            end)

            it("plans a compatible version against installed root constraints with correct flags", function()
                local lock_doc = {
                    modules = {
                        { name = "kickside/component", version = "0.1.8" },
                    },
                    replacements = {},
                }
                local svc = planner.new({
                    catalog = fake_catalog({
                        ["kickside/demo"] = {
                            {
                                version = "0.1.0",
                                dependencies = {
                                    { org = "kickside", name = "component", version_constraint = "^0.1.0" },
                                },
                            },
                        },
                        ["kickside/component"] = {
                            { version = "0.1.2" },
                            { version = "0.1.8" },
                        },
                    }),
                    registry = fake_registry(concat_entries(
                        {
                            {
                                id = "app.deps:component",
                                kind = "ns.dependency",
                                meta = {},
                                data = { component = "kickside/component", version = "^0.1.0" },
                            },
                        },
                        installed_module("kickside/component", {})
                    )),
                    fs = fake_project_fs({ ["wippy.lock"] = "x" }),
                    yaml = fake_yaml_for_lock(lock_doc),
                }) :: any

                local plan, plan_err = svc:plan_install({
                    component = "kickside/demo",
                    version = "0.1.0",
                })

                test.is_nil(plan_err)
                local nodes = {}
                for _, node in ipairs(plan.graph) do nodes[node.module] = node end
                test.eq(nodes["kickside/component"].version, "0.1.8")
                test.is_true(nodes["kickside/component"].installed)
                test.is_true(nodes["kickside/component"].shared)
                test.is_false(nodes["kickside/demo"].installed)
                test.is_false(nodes["kickside/demo"].shared)
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
                if not called then error("expected migration handler call") end
                local called_params = called.params :: any
                if not called_params then error("expected migration handler params") end
                test.eq(called.id, hub.MIGRATION_HANDLER_FN)
                test.eq(called_params.operation, "up")
                test.eq(called_params.entry_ids[1], "wippy.foo.migrations:001")
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

            it("refuses planned bindings to missing contracts before publish", function()
                local gov_state = ({}) :: any
                local svc = hub.new({
                    registry = fake_registry({}),
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
                                    parameters = {},
                                    migration_policy = "none",
                                },
                                planned_entries = {
                                    {
                                        id = "wippy.bad:driver",
                                        kind = "contract.binding",
                                        data = {
                                            contracts = {
                                                {
                                                    contract = "wippy.missing:contract",
                                                    methods = { run = "wippy.bad:run" },
                                                },
                                            },
                                        },
                                    },
                                },
                            }, nil
                        end,
                    },
                    governance = fake_governance(gov_state),
                }) :: any

                local out, err = svc:install({
                    component = "wippy/bad",
                    version = "v1.0.0",
                })

                test.is_nil(out)
                test.not_nil(err)
                test.eq(err_code(err), "PRE_APPLY_VALIDATION_FAILED")
                test.eq(gov_state.publish_calls or 0, 0)
                local details = err_details(err)
                test.not_nil(details)
                test.eq(details.issue_count, 1)
                test.eq(details.issues_by_entry["wippy.bad:driver"].reference, "wippy.missing:contract")
            end)

            it("allows valid planned bindings and requirement targets before publish", function()
                local gov_state = ({}) :: any
                local svc = hub.new({
                    registry = fake_registry({
                        { id = "wippy.good:contract", kind = "contract.definition", meta = {}, data = {} },
                    }),
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
                                    parameters = {},
                                    migration_policy = "none",
                                },
                                planned_entries = {
                                    {
                                        id = "wippy.good:run",
                                        kind = "function.lua",
                                        data = { source = "return {}", method = "handler" },
                                    },
                                    {
                                        id = "wippy.good:driver",
                                        kind = "contract.binding",
                                        data = {
                                            contracts = {
                                                {
                                                    contract = "wippy.good:contract",
                                                    methods = { run = "wippy.good:run" },
                                                },
                                            },
                                        },
                                    },
                                    {
                                        id = "wippy.good:router",
                                        kind = "ns.requirement",
                                        data = {
                                            targets = {
                                                { entry = "wippy.good:run", path = ".meta.router" },
                                            },
                                        },
                                    },
                                },
                            }, nil
                        end,
                    },
                    governance = fake_governance(gov_state),
                }) :: any

                local out, err = svc:install({
                    component = "wippy/good",
                    version = "v1.0.0",
                })

                test.is_nil(err)
                test.not_nil(out)
                test.eq(gov_state.publish_calls, 1)
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

        describe("install and uninstall execution ledger", function()
            local function last_event(sent, event)
                local found
                for _, item in ipairs(sent) do
                    if item.payload and item.payload.event == event then found = item.payload end
                end
                return found
            end

            local function step_by_name(execution, name)
                for _, row in ipairs(execution or {}) do
                    if row.step == name then return row end
                end
                return nil
            end

            it("returns an ordered ok ledger on a successful install", function()
                local files = { ["wippy.lock"] = "initial-lock" }
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
                    governance = fake_governance({ current_version = 12 }),
                }) :: any

                local out, err = svc:install({
                    component = "wippy/dummy",
                    version = ">=v0.0.0",
                    parameters = { ["wippy.dummy:router"] = "app:api" },
                })

                test.is_nil(err)
                test.not_nil(out.execution)
                test.eq(#out.execution, 3)
                test.eq(out.execution[1].step, "validation")
                test.eq(out.execution[1].status, "ok")
                test.eq(out.execution[2].step, "governance")
                test.eq(out.execution[2].status, "ok")
                test.eq(out.execution[3].step, "restart affected services")
                test.eq(out.execution[3].status, "ok")
            end)

            it("restarts a running service whose process source is in an installed module namespace", function()
                local terminations = {}
                local files = { ["wippy.lock"] = "initial-lock" }
                local svc = hub.new({
                    registry = fake_registry({
                        {
                            id = "wippy.dummy:worker.service",
                            kind = "process.service",
                            meta = {},
                            data = { process = "worker", host = "keeper.gov:processes" },
                        },
                    }),
                    planner = {
                        plan_install = function(args)
                            local entry, build_err = hub.build_dependency_entry(args)
                            if not entry then return nil, build_err end
                            return {
                                dependency = hub.dependency_summary(entry),
                                graph = {
                                    { module = "wippy/dummy", version = "0.1.2", digest = "abc123" },
                                },
                                missing_requirements = {},
                                requirements = {},
                                install_payload = {
                                    id = entry.id,
                                    component = entry.data.component,
                                    version = entry.data.version,
                                    parameters = {},
                                    migration_policy = "none",
                                },
                                planned_entries = {
                                    {
                                        id = "wippy.dummy:worker",
                                        kind = "process.lua",
                                        meta = { module = "wippy/dummy", module_version = "0.1.2" },
                                        data = { source = "return {}", method = "run" },
                                    },
                                },
                            }, nil
                        end,
                    },
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {},
                        replacements = {},
                    }),
                    governance = fake_governance({ current_version = 12 }),
                    system = fake_system(
                        { { id = "keeper.gov:processes" } },
                        {
                            ["keeper.gov:processes"] = {
                                {
                                    pid = "keeper.gov:processes:pid-1",
                                    host = "keeper.gov:processes",
                                    source = "wippy.dummy:worker",
                                    state = "idle",
                                },
                            },
                        }
                    ),
                    process = {
                        terminate = function(pid)
                            table.insert(terminations, pid)
                            return true, nil
                        end,
                    },
                }) :: any

                local out, err = svc:install({
                    component = "wippy/dummy",
                    version = ">=v0.0.0",
                })

                test.is_nil(err)
                test.eq(#terminations, 1)
                test.eq(terminations[1], "keeper.gov:processes:pid-1")
                test.not_nil(out.restart)
                test.eq(out.restart.outcomes[1].service_id, "wippy.dummy:worker.service")
                test.eq(out.restart.outcomes[1].source, "wippy.dummy:worker")
                test.eq(out.restart.outcomes[1].mechanism, "respawn")
                test.eq(out.restart.outcomes[1].status, "restarted")
            end)

            it("lists affected running services in install dry-run preview", function()
                local svc = hub.new({
                    registry = fake_registry({
                        {
                            id = "wippy.dummy:worker.service",
                            kind = "process.service",
                            meta = {},
                            data = { process = "wippy.dummy:worker", host = "keeper.gov:processes" },
                        },
                    }),
                    planner = {
                        plan_install = function(args)
                            local entry, build_err = hub.build_dependency_entry(args)
                            if not entry then return nil, build_err end
                            return {
                                dependency = hub.dependency_summary(entry),
                                graph = {},
                                missing_requirements = {},
                                requirements = {},
                                install_payload = {
                                    id = entry.id,
                                    component = entry.data.component,
                                    version = entry.data.version,
                                    parameters = {},
                                    migration_policy = "none",
                                },
                                planned_entries = {
                                    { id = "wippy.dummy:worker", kind = "process.lua", data = {} },
                                },
                            }, nil
                        end,
                    },
                    system = fake_system(
                        { { id = "keeper.gov:processes" } },
                        {
                            ["keeper.gov:processes"] = {
                                {
                                    pid = "keeper.gov:processes:pid-1",
                                    host = "keeper.gov:processes",
                                    source = "wippy.dummy:worker",
                                    state = "idle",
                                },
                            },
                        }
                    ),
                }) :: any

                local out, err = svc:install({
                    component = "wippy/dummy",
                    version = ">=v0.0.0",
                    dry_run = true,
                })

                test.is_nil(err)
                test.is_true(out.dry_run)
                test.not_nil(out.restart_preview)
                test.eq(out.restart_preview.services[1].service_id, "wippy.dummy:worker.service")
                test.eq(out.restart_preview.services[1].source, "wippy.dummy:worker")
            end)

            it("reports restart failures as warnings without rolling back the published install", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local gov_state = ({ current_version = 12 }) :: any
                local svc = hub.new({
                    registry = fake_registry({
                        {
                            id = "wippy.dummy:worker.service",
                            kind = "process.service",
                            meta = {},
                            data = { process = "worker", host = "keeper.gov:processes" },
                        },
                    }),
                    planner = {
                        plan_install = function(args)
                            local entry, build_err = hub.build_dependency_entry(args)
                            if not entry then return nil, build_err end
                            return {
                                dependency = hub.dependency_summary(entry),
                                graph = {
                                    { module = "wippy/dummy", version = "0.1.2", digest = "abc123" },
                                },
                                missing_requirements = {},
                                requirements = {},
                                install_payload = {
                                    id = entry.id,
                                    component = entry.data.component,
                                    version = entry.data.version,
                                    parameters = {},
                                    migration_policy = "none",
                                },
                                planned_entries = {
                                    { id = "wippy.dummy:worker", kind = "process.lua", data = {} },
                                },
                            }, nil
                        end,
                    },
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {},
                        replacements = {},
                    }),
                    governance = fake_governance(gov_state),
                    system = fake_system(
                        { { id = "keeper.gov:processes" } },
                        {
                            ["keeper.gov:processes"] = {
                                {
                                    pid = "keeper.gov:processes:pid-1",
                                    host = "keeper.gov:processes",
                                    source = "wippy.dummy:worker",
                                    state = "idle",
                                },
                            },
                        }
                    ),
                    process = {
                        terminate = function()
                            return nil, "terminate denied"
                        end,
                    },
                }) :: any

                local out, err = svc:install({
                    component = "wippy/dummy",
                    version = ">=v0.0.0",
                })

                test.is_nil(err)
                test.not_nil(out.restart)
                test.eq(out.restart.outcomes[1].status, "failed")
                test.contains(out.restart.outcomes[1].error, "terminate denied")
                test.not_nil(out.warnings)
                test.contains(out.warnings[1], "failed to restart")
                test.eq(gov_state.publish_calls, 1)
                test.is_nil(gov_state.restore_calls)
            end)

            it("uses the service upgrade signal before respawn when an affected service opts in", function()
                local sent_upgrade = {}
                local terminations = {}
                local files = { ["wippy.lock"] = "initial-lock" }
                local svc = hub.new({
                    registry = fake_registry({
                        {
                            id = "wippy.dummy:worker.service",
                            kind = "process.service",
                            meta = {
                                upgradable = true,
                                upgrade_target = "wippy.dummy.worker",
                                upgrade_topic = "system.upgrade",
                            },
                            data = { process = "worker", host = "keeper.gov:processes" },
                        },
                    }),
                    planner = {
                        plan_install = function(args)
                            local entry, build_err = hub.build_dependency_entry(args)
                            if not entry then return nil, build_err end
                            return {
                                dependency = hub.dependency_summary(entry),
                                graph = {
                                    { module = "wippy/dummy", version = "0.1.2", digest = "abc123" },
                                },
                                missing_requirements = {},
                                requirements = {},
                                install_payload = {
                                    id = entry.id,
                                    component = entry.data.component,
                                    version = entry.data.version,
                                    parameters = {},
                                    migration_policy = "none",
                                },
                                planned_entries = {
                                    { id = "wippy.dummy:worker", kind = "process.lua", data = {} },
                                },
                            }, nil
                        end,
                    },
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {},
                        replacements = {},
                    }),
                    governance = fake_governance({ current_version = 12 }),
                    system = fake_system(
                        { { id = "keeper.gov:processes" } },
                        {
                            ["keeper.gov:processes"] = {
                                {
                                    pid = "keeper.gov:processes:pid-1",
                                    host = "keeper.gov:processes",
                                    source = "wippy.dummy:worker",
                                    state = "idle",
                                },
                            },
                        }
                    ),
                    process = {
                        send = function(target, topic, payload)
                            table.insert(sent_upgrade, { target = target, topic = topic, payload = payload })
                            return true, nil
                        end,
                        terminate = function(pid)
                            table.insert(terminations, pid)
                            return true, nil
                        end,
                    },
                }) :: any

                local out, err = svc:install({
                    component = "wippy/dummy",
                    version = ">=v0.0.0",
                })

                test.is_nil(err)
                test.eq(#sent_upgrade, 1)
                local first_upgrade = sent_upgrade[1] :: any
                test.eq(first_upgrade.target, "wippy.dummy.worker")
                test.eq(first_upgrade.topic, "system.upgrade")
                test.eq(first_upgrade.payload.process, "wippy.dummy:worker")
                test.eq(#terminations, 0)
                test.eq(out.restart.outcomes[1].mechanism, "upgrade")
                test.eq(out.restart.outcomes[1].status, "upgrade_signaled")
            end)

            it("restarts a remaining running service whose source namespace is removed by uninstall", function()
                local terminations = {}
                local files = { ["wippy.lock"] = "initial-lock" }
                local svc = hub.new({
                    registry = fake_registry({
                        root_dep("app.deps:foo", "wippy/foo"),
                        {
                            id = "wippy.foo:worker",
                            kind = "process.lua",
                            meta = { module = "wippy/foo", module_version = "1.2.3" },
                            data = {},
                        },
                        {
                            id = "app.services:foo_worker",
                            kind = "process.service",
                            meta = {},
                            data = { process = "wippy.foo:worker", host = "keeper.gov:processes" },
                        },
                    }),
                    sql = fake_sql({}),
                    planner = planner,
                    fs = fake_project_fs(files),
                    yaml = fake_yaml_for_lock({
                        directories = { modules = ".wippy", src = "./src/app" },
                        modules = {
                            { name = "wippy/foo", version = "1.2.3", hash = "foo-hash" },
                        },
                        replacements = {},
                    }),
                    governance = fake_governance({ current_version = 30 }),
                    system = fake_system(
                        { { id = "keeper.gov:processes" } },
                        {
                            ["keeper.gov:processes"] = {
                                {
                                    pid = "keeper.gov:processes:pid-9",
                                    host = "keeper.gov:processes",
                                    source = "wippy.foo:worker",
                                    state = "idle",
                                },
                            },
                        }
                    ),
                    process = {
                        terminate = function(pid)
                            table.insert(terminations, pid)
                            return true, nil
                        end,
                    },
                }) :: any

                local out, err = svc:uninstall({
                    component = "wippy/foo",
                    migration_policy = "leave",
                })

                test.is_nil(err)
                test.eq(#terminations, 1)
                test.eq(terminations[1], "keeper.gov:processes:pid-9")
                test.eq(out.restart.outcomes[1].service_id, "app.services:foo_worker")
                test.eq(out.restart.outcomes[1].source, "wippy.foo:worker")
                test.eq(out.restart.outcomes[1].status, "restarted")
                test.eq(out.execution[#out.execution].step, "restart affected services")
            end)

            it("returns an ordered ok ledger on a successful uninstall", function()
                local files = { ["wippy.lock"] = "initial-lock" }
                local svc = hub.new({
                    registry = fake_registry(concat_entries(
                        { root_dep("app.deps:foo", "wippy/foo"), root_dep("app.deps:kept", "wippy/kept") },
                        installed_module("wippy/foo", {}),
                        installed_module("wippy/kept", { "wippy/terminal" }),
                        installed_module("wippy/terminal", {})
                    )),
                    sql = fake_sql({}),
                    planner = planner,
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
                test.not_nil(out.execution)
                test.eq(out.execution[1].step, "governance")
                test.eq(out.execution[1].status, "ok")
                test.eq(out.execution[2].step, "restart affected services")
                test.eq(out.execution[2].status, "ok")
            end)

            local function migration_failure_deps(gov_state, order, sent)
                local gov = fake_governance(gov_state)
                local base_restore = gov.restore_version
                gov.restore_version = function(version, reason)
                    table.insert(order, "registry_restore")
                    return base_restore(version, reason)
                end
                return {
                    registry = fake_registry(fixture_entries()),
                    sql = fake_sql({}),
                    planner = graph_planner({
                        { module = "wippy/foo", version = "1.2.3", digest = "foo-digest" },
                    }),
                    governance = gov,
                    process = fake_process(sent),
                    uuid = fake_uuid(),
                    funcs = {
                        new = function()
                            return {
                                call = function(_, id)
                                    if id == hub.MIGRATION_HANDLER_FN then
                                        return nil, "migration boom"
                                    end
                                    return nil, "unexpected call"
                                end,
                            }, nil
                        end,
                    },
                }
            end

            it("restores the registry when install migrations fail", function()
                local order = {}
                local svc = hub.new(migration_failure_deps({ current_version = 55 }, order, {})) :: any

                local out, err = svc:install({
                    component = "wippy/foo",
                    version = ">=v1.0.0",
                    run_migrations = true,
                }, { actor_id = "admin-1" })

                test.is_nil(out)
                test.eq(err_code(err), "MIGRATIONS_FAILED")
                test.eq(#order, 1)
                test.eq(order[1], "registry_restore")
                local execution = err_details(err).execution
                test.eq(execution["1"].step, "validation")
                test.eq(execution["2"].step, "governance")
                test.eq(execution["2"].status, "rolled_back")
                test.eq(execution["3"].step, "migrations")
                test.eq(execution["3"].status, "failed")
            end)

            it("marks the step rollback_failed when the install registry restore fails", function()
                local order = {}
                local sent = {}
                local svc = hub.new(migration_failure_deps(
                    { current_version = 55, restore_error = "registry offline" }, order, sent)) :: any

                local out, err = svc:install({
                    component = "wippy/foo",
                    version = ">=v1.0.0",
                    run_migrations = true,
                }, { actor_id = "admin-1" })

                test.is_nil(out)
                test.eq(err_code(err), "ROLLBACK_FAILED")
                test.eq(order[1], "registry_restore")

                local failed = last_event(sent, hub.EVENTS.INSTALL_FAILED)
                test.not_nil(failed)
                local execution = failed.data.execution
                test.not_nil(execution)
                test.eq(step_by_name(execution, "governance").status, "rollback_failed")
                test.eq(step_by_name(execution, "governance").inverse, "restore_registry_version")
                test.eq(step_by_name(execution, "migrations").status, "failed")
            end)

        end)

        describe("security scan API", function()
            it("requires an authenticated admin actor", function()
                local res, err = http_client.post(api_test.endpoint("/api/keeper/hub/scan"), {
                    headers = { ["Content-Type"] = "application/json" },
                    body = json.encode({ component = "acme/clean", version = "v1.0.0" }),
                })

                test.is_nil(err)
                test.eq(res.status_code, 401)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
