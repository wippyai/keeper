local test = require("test")
local branch = require("branch")

local function define_tests()
    describe("Branch tool", function()
        describe("get", function()
            it("returns main when no branch is active", function()
                local out = branch.get(nil, nil)
                test.eq(out.branch, "main")
                test.is_true(out.message:find("No branch set") ~= nil)
            end)

            it("returns main when overlay_branch is an empty string", function()
                local out = branch.get("", "")
                test.eq(out.branch, "main")
            end)

            it("reports the active branch and changeset_id when set", function()
                local out = branch.get("feature/x", "cs-123")
                test.eq(out.branch, "feature/x")
                test.eq(out.changeset_id, "cs-123")
                test.is_true(out.message:find("Current branch") ~= nil)
                test.is_true(out.message:find("feature/x") ~= nil)
            end)
        end)

        describe("clear", function()
            it("returns main and a session-delete control block", function()
                local out = branch.clear()
                test.eq(out.branch, "main")
                test.is_true(out.message:find("cleared") ~= nil)
                test.not_nil(out._control)
                test.not_nil(out._control.context.session.delete)
                local delete = out._control.context.session.delete
                local has_branch, has_cs = false, false
                for _, k in ipairs(delete) do
                    if k == "overlay_branch" then has_branch = true end
                    if k == "changeset_id" then has_cs = true end
                end
                test.is_true(has_branch, "delete must include overlay_branch")
                test.is_true(has_cs, "delete must include changeset_id")
                test.eq(out._control.context.public_meta.clear, "branch")
            end)
        end)

        describe("set validation", function()
            it("rejects empty branch name", function()
                local out, err = branch.set({ branch = "" })
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("required") ~= nil)
            end)

            it("rejects nil branch", function()
                local out, err = branch.set({})
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("required") ~= nil)
            end)

            it("refuses to set branch to 'main'", function()
                local out, err = branch.set({ branch = "main" })
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("main") ~= nil)
            end)
        end)

        describe("handler action routing", function()
            it("rejects an unknown action", function()
                local out, err = branch.handler({ action = "nuke" })
                test.is_nil(out)
                test.not_nil(err)
                test.is_true(err:find("Invalid action") ~= nil)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
