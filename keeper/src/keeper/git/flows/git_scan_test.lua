local test = require("test")
local git_scan = require("git_scan")
local git_config = require("git_config")
local gov_consts = require("gov_consts")

local cfg: { tracked_dirs: string[], managed_namespaces: string[], exclude_patterns: string[], diff_base: string, source: string } = {
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
        name = "git_config derives default tracked dirs from managed namespaces",
        fn = function()
            local dirs = git_config._tracked_dirs_from_managed_namespaces({ "app", "tenant.crm" })
            test.eq(#dirs, 2)
            test.eq(dirs[1], "src/app/")
            test.eq(dirs[2], "src/tenant/crm/")
        end,
    },
    {
        name = "git_config resolve uses governance managed namespaces by default",
        fn = function()
            local before = gov_consts.get_managed_namespaces()
            local _, set_err = gov_consts.set_managed_namespaces({ "app" })
            test.is_nil(set_err)

            local resolved = git_config.resolve({
                exclude_patterns = cfg.exclude_patterns,
                diff_base = "HEAD",
            })

            gov_consts.set_managed_namespaces(before)

            test.eq(resolved.source, "managed_namespaces")
            test.eq(#resolved.tracked_dirs, 1)
            test.eq(resolved.tracked_dirs[1], "src/app/")
        end,
    },
    {
        name = "git_config resolve carries managed namespaces and untracked mode",
        fn = function()
            local resolved = git_config.resolve({
                managed_namespaces = { "app.demo" },
                untracked_mode = "normal",
                exclude_patterns = cfg.exclude_patterns,
                diff_base = "HEAD",
            })

            test.eq(#resolved.managed_namespaces, 1)
            test.eq(resolved.managed_namespaces[1], "app.demo")
            test.eq(resolved.tracked_dirs[1], "src/app/demo/")
            test.eq(resolved.untracked_mode, "normal")
        end,
    },
    {
        name = "pathspec args are shell escaped and empty tracked dirs scan nothing",
        fn = function()
            test.eq(git_scan._pathspec_args({}), "")
            test.eq(git_scan._pathspec_args({ "src/app/", "src/tenant crm/" }), " -- 'src/app/' 'src/tenant crm/'")
        end,
    },
    {
        name = "list_changes returns empty immediately for empty tracked dirs",
        fn = function()
            local changes, resolved = git_scan.list_changes({
                tracked_dirs = {},
                managed_namespaces = { "app" },
                exclude_patterns = cfg.exclude_patterns,
                diff_base = "HEAD",
            })

            test.not_nil(changes)
            test.eq(#changes, 0)
            test.not_nil(resolved)
            test.eq(#resolved.tracked_dirs, 0)
        end,
    },
    {
        name = "parse_status_z handles spaces, newlines, and rename records",
        fn = function()
            local rows = git_scan._parse_status_z(
                " M src/app/file with spaces.lua\0" ..
                "?? src/app/line\nbreak.lua\0" ..
                "R  src/app/new.lua\0src/app/old.lua\0"
            )

            test.eq(#rows, 3)
            test.eq(rows[1].xy, " M")
            test.eq(rows[1].path, "src/app/file with spaces.lua")
            test.eq(rows[2].path, "src/app/line\nbreak.lua")
            test.eq(rows[3].xy, "R ")
            test.eq(rows[3].path, "src/app/new.lua")
        end,
    },
    {
        name = "parse_numstat_z indexes normal and renamed paths by final path",
        fn = function()
            local stats = git_scan._parse_numstat_z(
                "5\t2\tsrc/app/a.lua\0" ..
                "1\t0\t\0src/app/old.lua\0src/app/new.lua\0" ..
                "-\t-\tsrc/app/bin.dat\0"
            )

            test.eq(stats["src/app/a.lua"].added, 5)
            test.eq(stats["src/app/a.lua"].removed, 2)
            test.eq(stats["src/app/new.lua"].added, 1)
            test.eq(stats["src/app/new.lua"].removed, 0)
            test.eq(stats["src/app/bin.dat"].added, 0)
            test.eq(stats["src/app/bin.dat"].removed, 0)
        end,
    },
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
        name = "should_include_change excludes filesystem paths outside derived app scope",
        fn = function()
            local ok, reason = git_scan._should_include_change("src/keeper/gov/gov.spec.md", {
                tracked_dirs = { "src/app/" },
                managed_namespaces = ({ "app" } :: string[]),
                exclude_patterns = cfg.exclude_patterns,
                diff_base = "HEAD",
            })
            test.is_false(ok)
            test.eq(reason, "excluded")
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
