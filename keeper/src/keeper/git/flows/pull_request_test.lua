local pr = require("pr_flow")
local test = require("test")

type RemoteMap = {[string]: string}

type PullRequestStatus = {
    cwd: string,
    current_branch: string,
    protected_branch: boolean,
    dirty: boolean,
    status: string,
    remotes: RemoteMap,
    gh_available: boolean,
    gh_authenticated: boolean,
    gh_status: string,
}

local function status(branch)
    local remotes: RemoteMap = { origin = "git@github.com:acme/repo.git" }
    return {
        cwd = "/repo",
        current_branch = branch or "feature/git-pr",
        protected_branch = false,
        dirty = false,
        status = "",
        remotes = remotes,
        gh_available = true,
        gh_authenticated = true,
        gh_status = "",
    } :: PullRequestStatus
end

local function define_tests()
    test.describe("pull_request", function()
        test.it("validates branch refs conservatively", function()
            test.eq(pr._validate_branch("feature/x"), "feature/x")
            local _, err = pr._validate_branch("main", "head_branch")
            test.is_nil(err)
            _, err = pr._validate_branch("../bad")
            test.not_nil(err)
            _, err = pr._validate_branch("bad branch")
            test.not_nil(err)
            _, err = pr._validate_branch("-bad")
            test.not_nil(err)
        end)

        test.it("normalizes repo-relative paths for commit staging", function()
            test.eq(pr._normalize_path("src/app/file.lua"), "src/app/file.lua")
            local _, err = pr._normalize_path("/etc/passwd")
            test.not_nil(err)
            _, err = pr._normalize_path("../secret")
            test.not_nil(err)
            _, err = pr._normalize_path("src//bad.lua")
            test.not_nil(err)
            _, err = pr._normalize_path("-bad")
            test.not_nil(err)
        end)

        test.it("builds a dry-run PR plan without commit when no message is provided", function()
            local plan, err = pr._build_plan({
                base_branch = "main",
                head_branch = "feature/git-pr",
                title = "Add PR flow",
                body = "Details",
            }, status())
            test.is_nil(err)
            test.eq(plan.remote, "origin")
            test.eq(plan.base_branch, "main")
            test.eq(plan.head_branch, "feature/git-pr")
            test.eq(#plan.commands, 2)
            test.eq(plan.commands[1].label, "push branch")
            test.eq(plan.commands[2].label, "create pull request")
            test.contains(plan.commands[2].command, "gh pr create")
            test.contains(plan.commands[2].command, "--base 'main'")
            test.contains(plan.commands[2].command, "--head 'feature/git-pr'")
        end)

        test.it("builds explicit stage/commit/push/create sequence when commit message is provided", function()
            local plan, err = pr._build_plan({
                head_branch = "feature/git-pr",
                title = "Add PR flow",
                commit_message = "Add PR flow",
                paths = { "src/app/a.lua", "frontend/applications/app/src/App.vue" },
                draft = true,
            }, status())
            test.is_nil(err)
            test.eq(#plan.commands, 4)
            test.eq(plan.commands[1].label, "stage files")
            test.eq(plan.commands[2].label, "commit")
            test.eq(plan.commands[3].label, "push branch")
            test.eq(plan.commands[4].label, "create pull request")
            test.contains(plan.commands[1].command, "git -C '/repo' add -- 'src/app/a.lua'")
            test.contains(plan.commands[2].command, "commit -m 'Add PR flow'")
            test.contains(plan.commands[4].command, "--draft")
        end)

        test.it("requires paths when commit_message is set", function()
            local plan, err = pr._build_plan({
                head_branch = "feature/git-pr",
                title = "Add PR flow",
                commit_message = "Add PR flow",
            }, status())
            test.is_nil(plan)
            test.contains(err, "paths[] required")
        end)

        test.it("rejects protected head branches", function()
            local plan, err = pr._build_plan({
                head_branch = "main",
                title = "Bad PR",
            }, status("main"))
            test.is_nil(plan)
            test.contains(err, "protected")
        end)

        test.it("parses push remotes only", function()
            local remotes = pr._parse_remotes("origin\tgit@github.com:a/b.git (fetch)\norigin\tgit@github.com:a/b.git (push)\n")
            test.eq(remotes.origin, "git@github.com:a/b.git")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
