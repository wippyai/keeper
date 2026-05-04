local test = require("test")
local changeset_scan = require("changeset_scan")

local cfg: {
    managed_namespaces: string[],
    tracked_dirs: string[],
    exclude_patterns: string[],
    diff_base: string,
    untracked_mode: string,
    source: string,
} = {
    managed_namespaces = { "app", "tenant.crm" },
    tracked_dirs = {},
    exclude_patterns = {},
    diff_base = "HEAD",
    untracked_mode = "all",
    source = "test",
}

local cases = {
    {
        name = "entry id classification keeps full namespace and root",
        fn = function()
            local row = changeset_scan._change_from_journal({
                change_id = "ch-1",
                changeset_id = "cs-1",
                category = "registry",
                op = "update",
                target = "tenant.crm.contacts:repo",
                status = "pending",
            }, cfg)

            test.eq(row.namespace, "tenant.crm.contacts")
            test.eq(row.ns_root, "tenant")
            test.is_true(row.managed_namespace)
            test.eq(row.source, "changeset")
            test.eq(row.changeset_id, "cs-1")
        end,
    },
    {
        name = "unmanaged registry namespace remains visible but blocked by policy later",
        fn = function()
            local row = changeset_scan._change_from_journal({
                change_id = "ch-2",
                changeset_id = "cs-1",
                category = "registry",
                op = "create",
                target = "userspace.tools:debug",
                status = "pending",
            }, cfg)

            test.eq(row.namespace, "userspace.tools")
            test.is_false(row.managed_namespace)
        end,
    },
    {
        name = "filesystem rows keep changeset identity without fake namespace",
        fn = function()
            local row = changeset_scan._change_from_journal({
                change_id = "ch-3",
                changeset_id = "cs-2",
                category = "filesystem",
                op = "write",
                target = "frontend/applications/app/src/page.vue",
                status = "pending",
            }, cfg)

            test.eq(row.target, "frontend/applications/app/src/page.vue")
            test.eq(row.source, "changeset")
            test.eq(row.changeset_id, "cs-2")
            test.is_nil(row.namespace)
            test.is_nil(row.managed_namespace)
        end,
    },
    {
        name = "managed namespace matching is exact or dotted descendant only",
        fn = function()
            test.is_true(changeset_scan._is_managed_namespace("app", cfg))
            test.is_true(changeset_scan._is_managed_namespace("app.notes", cfg))
            test.is_false(changeset_scan._is_managed_namespace("application.notes", cfg))
            test.is_false(changeset_scan._is_managed_namespace("userspace.app", cfg))
        end,
    },
}

local function define_tests()
    describe("keeper.git.flows:changeset_scan", function()
        for _, case in ipairs(cases) do it(case.name, case.fn) end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
