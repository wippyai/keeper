local test = require("test")
local registry = require("registry")
local gov_client = require("gov_client")
local gov_consts = require("gov_consts")

local function with_managed_namespaces(namespaces, fn)
    local before = gov_consts.get_managed_namespaces()
    local _, set_err = gov_consts.set_managed_namespaces(namespaces)
    if set_err then error(set_err) end

    local ok, err = pcall(fn)
    gov_consts.set_managed_namespaces(before)
    if not ok then error(err) end
end

local function define_tests()
    describe("Governance", function()

        describe("consts", function()
            it("defines all registry operations", function()
                test.eq(gov_consts.REGISTRY_OPERATIONS.CREATE, "entry.create")
                test.eq(gov_consts.REGISTRY_OPERATIONS.UPDATE, "entry.update")
                test.eq(gov_consts.REGISTRY_OPERATIONS.DELETE, "entry.delete")
            end)

            it("defines all governance operations", function()
                test.eq(gov_consts.OPERATIONS.APPLY_CHANGES, "apply_changes")
                test.eq(gov_consts.OPERATIONS.APPLY_VERSION, "apply_version")
                test.eq(gov_consts.OPERATIONS.UPLOAD, "upload")
                test.eq(gov_consts.OPERATIONS.DOWNLOAD, "download")
                test.eq(gov_consts.OPERATIONS.GET_STATE, "get_state")
            end)

            it("defines required error messages", function()
                test.not_nil(gov_consts.ERRORS.NO_CHANGESET)
                test.not_nil(gov_consts.ERRORS.INVALID_OPERATION)
                test.not_nil(gov_consts.ERRORS.MISSING_ENTRY_ID)
                test.not_nil(gov_consts.ERRORS.UNMANAGED_NAMESPACE)
                test.not_nil(gov_consts.ERRORS.INVALID_VERSION_ID)
                test.not_nil(gov_consts.ERRORS.VERSION_NOT_FOUND)
                test.not_nil(gov_consts.ERRORS.INVALID_ARGUMENTS)
            end)

            it("defines permission strings", function()
                test.eq(gov_consts.PERMISSIONS.WRITE, "registry.request.write")
                test.eq(gov_consts.PERMISSIONS.VERSION, "registry.request.version")
                test.eq(gov_consts.PERMISSIONS.SYNC, "registry.request.sync")
                test.eq(gov_consts.PERMISSIONS.READ, "registry.request.read")
            end)

            it("defines validation constants", function()
                test.eq(gov_consts.VALIDATION.MAX_CHANGESET_SIZE, 1000)
                test.eq(gov_consts.VALIDATION.MIN_LINTER_LEVEL, 1)
                test.eq(gov_consts.VALIDATION.MAX_LINTER_LEVEL, 100)
                test.not_nil(gov_consts.VALIDATION.NAMESPACE_SEGMENT_PATTERN)
            end)

            it("defines process configuration", function()
                test.eq(gov_consts.PROCESS_NAME, "registry.governance")
                test.not_nil(gov_consts.PROCESS_HOST)
                test.not_nil(gov_consts.TOPICS.COMMANDS)
                test.not_nil(gov_consts.TOPICS.VERSION)
            end)

            it("defines default timeout", function()
                test.eq(gov_consts.DEFAULTS.TIMEOUT, "10m")
            end)

            it("defaults to no managed namespaces", function()
                local defaults = gov_consts.DEFAULTS.MANAGED_NAMESPACES
                test.not_nil(defaults)
                test.eq(#defaults, 0)
            end)

            it("defines filesystem constants", function()
                test.eq(gov_consts.FILESYSTEM.SOURCE_FS_ID, "keeper.gov:source_fs")
                test.eq(gov_consts.FILESYSTEM.INDEX_FILENAME, "_index.yaml")
            end)
        end)

        describe("namespace management", function()
            it("recognizes managed namespace", function()
                with_managed_namespaces({ "app" }, function()
                    test.is_true(gov_consts.is_namespace_managed("app"))
                end)
            end)

            it("recognizes sub-namespace of managed namespace", function()
                with_managed_namespaces({ "app", "keeper" }, function()
                    test.is_true(gov_consts.is_namespace_managed("app.users"))
                    test.is_true(gov_consts.is_namespace_managed("app.settings.theme"))
                    test.is_true(gov_consts.is_namespace_managed("keeper.gov"))
                end)
            end)

            it("rejects unmanaged namespace", function()
                test.eq(gov_consts.is_namespace_managed("random.unmanaged.ns"), false)
                test.eq(gov_consts.is_namespace_managed("system"), false)
            end)

            it("rejects namespace that starts with managed prefix but is not a sub-namespace", function()
                with_managed_namespaces({ "app" }, function()
                    test.eq(gov_consts.is_namespace_managed("application"), false)
                end)
            end)
        end)

        describe("config", function()
            it("normalizes comma-separated managed namespaces", function()
                local namespaces, err = gov_consts.normalize_managed_namespaces(" app, keeper ,app,userspace.data ")
                test.is_nil(err)
                test.eq(#namespaces, 3)
                test.eq(namespaces[1], "app")
                test.eq(namespaces[2], "keeper")
                test.eq(namespaces[3], "userspace.data")
            end)

            it("rejects invalid managed namespaces", function()
                local namespaces, err = gov_consts.normalize_managed_namespaces({ "app", "bad-name", "keeper" })
                test.is_nil(namespaces)
                test.not_nil(err)
            end)

            it("serializes managed namespaces for env storage", function()
                local value, err = gov_consts.serialize_managed_namespaces({ "app", "keeper.tools" })
                test.is_nil(err)
                test.eq(value, "app,keeper.tools")
            end)

            it("returns full configuration table", function()
                local config = gov_consts.get_config()
                test.not_nil(config)
                test.not_nil(config.managed_namespaces)
                test.not_nil(config.linter_level)
                test.eq(config.source_fs_id, "keeper.gov:source_fs")
                test.eq(config.process_host, gov_consts.PROCESS_HOST)
            end)

            it("linter level defaults to 100", function()
                local level = gov_consts.get_linter_level()
                test.eq(level, 100)
            end)

            it("get_managed_namespaces returns a table", function()
                with_managed_namespaces({}, function()
                    local ns = gov_consts.get_managed_namespaces()
                    test.not_nil(ns)
                    test.is_true(type(ns) == "table")
                    test.eq(#ns, 0)
                end)
            end)
        end)

        describe("client", function()
            it("exposes request_changes function", function()
                test.not_nil(gov_client.request_changes)
                test.is_true(type(gov_client.request_changes) == "function")
            end)

            it("exposes request_version function", function()
                test.not_nil(gov_client.request_version)
                test.is_true(type(gov_client.request_version) == "function")
            end)

            it("exposes request_download function", function()
                test.not_nil(gov_client.request_download)
                test.is_true(type(gov_client.request_download) == "function")
            end)

            it("exposes request_upload function", function()
                test.not_nil(gov_client.request_upload)
                test.is_true(type(gov_client.request_upload) == "function")
            end)

            it("exposes get_state function", function()
                test.not_nil(gov_client.get_state)
                test.is_true(type(gov_client.get_state) == "function")
            end)

            it("rejects nil changeset", function()
                local result, err = gov_client.request_changes(nil)
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects empty table changeset", function()
                local result, err = gov_client.request_changes({})
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects string changeset", function()
                local result, err = gov_client.request_changes("not a changeset")
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects number changeset", function()
                local result, err = gov_client.request_changes(42)
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects table without kind field", function()
                local result, err = gov_client.request_changes({ { entry = { id = "app:test" } } })
                test.is_nil(result)
                test.not_nil(err)
            end)
        end)

        describe("observer discovery", function()
            it("list_all returns a table", function()
                local results = registry.find({ ["meta.type"] = "registry.observer" })
                test.not_nil(results)
                test.is_true(type(results) == "table")
            end)

            it("get_stats returns structured statistics", function()
                local stats_query = registry.find({ ["meta.type"] = "registry.observer" }) or {}
                local stats = {
                    total_count = #stats_query,
                    by_namespace = {},
                    priority_range = { min = nil, max = nil }
                }
                test.not_nil(stats)
                test.not_nil(stats.total_count)
                test.not_nil(stats.by_namespace)
                test.not_nil(stats.priority_range)
            end)

            it("observer entries have required meta fields", function()
                local entries = registry.find({ ["meta.type"] = "registry.observer" }) or {}
                for _, entry in ipairs(entries) do
                    test.not_nil(entry.meta)
                    test.eq(entry.meta.type, "registry.observer")
                    test.not_nil(entry.meta.priority)
                end
            end)
        end)

        describe("changeset structure", function()
            it("valid create operation has correct shape", function()
                local op = {
                    kind = gov_consts.REGISTRY_OPERATIONS.CREATE,
                    entry = {
                        id = "app:test_entry",
                        name = "test_entry",
                        namespace = "app",
                        kind = "registry.entry",
                        meta = { comment = "test" }
                    }
                }
                test.eq(op.kind, "entry.create")
                test.not_nil(op.entry)
                test.not_nil(op.entry.id)
            end)

            it("valid update operation has correct shape", function()
                local op = {
                    kind = gov_consts.REGISTRY_OPERATIONS.UPDATE,
                    entry = {
                        id = "app:test_entry",
                        meta = { comment = "updated" }
                    }
                }
                test.eq(op.kind, "entry.update")
                test.not_nil(op.entry.id)
            end)

            it("valid delete operation has correct shape", function()
                local op = {
                    kind = gov_consts.REGISTRY_OPERATIONS.DELETE,
                    entry = {
                        id = "app:test_entry"
                    }
                }
                test.eq(op.kind, "entry.delete")
                test.not_nil(op.entry.id)
            end)

            it("namespace is extracted from entry id", function()
                local entry_id = "app.users:some_entry"
                local namespace = entry_id:match("^([^:]+):")
                test.eq(namespace, "app.users")
            end)

            it("namespace extraction handles single-segment namespace", function()
                local entry_id = "app:entry"
                local namespace = entry_id:match("^([^:]+):")
                test.eq(namespace, "app")
            end)

            it("managed namespace check applies to extracted namespace", function()
                with_managed_namespaces({ "app" }, function()
                    local entry_id = "app.users:some_entry"
                    local namespace = entry_id:match("^([^:]+):")
                    test.is_true(gov_consts.is_namespace_managed(namespace))

                    local unmanaged_id = "system:some_entry"
                    local unmanaged_ns = unmanaged_id:match("^([^:]+):")
                    test.eq(gov_consts.is_namespace_managed(unmanaged_ns), false)
                end)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
