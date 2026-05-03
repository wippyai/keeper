local test = require("test")
local git_scan = require("git_scan")

local cfg: { tracked_dirs: string[], exclude_patterns: string[], diff_base: string, source: string } = {
    tracked_dirs = { "src/", "frontend/applications/", "plugins/" },
    managed_namespaces = { "keeper" },
    exclude_patterns = {
        "%.wippy/vendor/",
        "static/keeper/",
        "static/public/previews/",
        "%.git/",
    },
    diff_base = "HEAD",
    source = "test",
}

local cases = {
    {
        name = "validate_scan_path accepts tracked source paths",
        fn = function()
            local path, err = git_scan._validate_scan_path("plugins/git/src/keeper/git/flows/git_scan.lua", cfg)
            test.is_nil(err)
            test.eq(path, "plugins/git/src/keeper/git/flows/git_scan.lua")
        end,
    },
    {
        name = "validate_scan_path still accepts root registry source paths",
        fn = function()
            local path, err = git_scan._validate_scan_path("src/keeper/components/consts.lua", cfg)
            test.is_nil(err)
            test.eq(path, "src/keeper/components/consts.lua")
        end,
    },
    {
        name = "validate_scan_path accepts local-module frontend paths",
        fn = function()
            local path, err = git_scan._validate_scan_path(
                "plugins/git/frontend/applications/git/src/pages/git.vue",
                cfg
            )
            test.is_nil(err)
            test.eq(path, "plugins/git/frontend/applications/git/src/pages/git.vue")
        end,
    },
    {
        name = "validate_scan_path normalizes backslashes",
        fn = function()
            local path, err = git_scan._validate_scan_path("frontend\\applications\\keeper\\src\\app.vue", cfg)
            test.is_nil(err)
            test.eq(path, "frontend/applications/keeper/src/app.vue")
        end,
    },
    {
        name = "validate_scan_path rejects absolute paths",
        fn = function()
            local path, err = git_scan._validate_scan_path("/etc/passwd", cfg)
            test.is_nil(path)
            test.not_nil(err)
        end,
    },
    {
        name = "validate_scan_path rejects parent traversal",
        fn = function()
            local path, err = git_scan._validate_scan_path("frontend/../src/keeper/secret.lua", cfg)
            test.is_nil(path)
            test.not_nil(err)
        end,
    },
    {
        name = "validate_scan_path rejects paths outside tracked dirs",
        fn = function()
            local path, err = git_scan._validate_scan_path("keeper.git.json", cfg)
            test.is_nil(path)
            test.not_nil(err)
        end,
    },
    {
        name = "validate_scan_path rejects unmanaged registry namespaces",
        fn = function()
            local path, err = git_scan._validate_scan_path("src/userspace/tools/_index.yaml", cfg)
            test.is_nil(path)
            test.not_nil(err)
        end,
    },
    {
        name = "validate_scan_path rejects excluded paths",
        fn = function()
            local path, err = git_scan._validate_scan_path("static/keeper/assets/app.js", {
                tracked_dirs = {},
                managed_namespaces = { "keeper" },
                exclude_patterns = cfg.exclude_patterns,
                diff_base = "HEAD",
            })
            test.is_nil(path)
            test.not_nil(err)
        end,
    },
    {
        name = "classify_path derives full registry namespace",
        fn = function()
            local info = git_scan._classify_path("plugins/git/src/keeper/git/flows/git_scan.lua", cfg)
            test.eq(info.category, "registry")
            test.eq(info.namespace, "keeper.git.flows")
            test.eq(info.ns_root, "keeper")
            test.is_true(info.managed_namespace)
        end,
    },
    {
        name = "classify_path derives root registry namespace",
        fn = function()
            local info = git_scan._classify_path("src/keeper/components/consts.lua", cfg)
            test.eq(info.category, "registry")
            test.eq(info.namespace, "keeper.components")
            test.eq(info.ns_root, "keeper")
            test.is_true(info.managed_namespace)
        end,
    },
    {
        name = "classify_path treats local-module frontend as filesystem",
        fn = function()
            local info = git_scan._classify_path("plugins/git/frontend/applications/git/src/pages/git.vue", cfg)
            test.eq(info.category, "filesystem")
            test.is_nil(info.namespace)
            test.eq(info.ns_root, "frontend")
        end,
    },
    {
        name = "should_include_change rejects unmanaged registry namespaces",
        fn = function()
            local ok, reason = git_scan._should_include_change("src/userspace/tools/_index.yaml", cfg)
            test.is_false(ok)
            test.eq(reason, "unmanaged_namespace")
        end,
    },
    {
        name = "sync_preflight rejects dirty managed registry files",
        fn = function()
            local ok, blockers = git_scan.sync_preflight({
                {
                    category = "registry",
                    target = "plugins/git/src/keeper/git/flows/git_scan.lua",
                    namespace = "keeper.git.flows",
                    managed_namespace = true,
                },
            })
            test.is_nil(ok)
            test.not_nil(blockers)
            test.eq(#blockers, 1)
        end,
    },
    {
        name = "sync_preflight allows filesystem-only changes",
        fn = function()
            local ok, blockers = git_scan.sync_preflight({
                {
                    category = "filesystem",
                    target = "plugins/git/frontend/applications/git/src/pages/git.vue",
                },
            })
            test.is_true(ok)
            test.is_nil(blockers)
        end,
    },
}

local function define_tests()
    describe("keeper.git.flows:git_scan", function()
        for _, case in ipairs(cases) do it(case.name, case.fn) end
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
