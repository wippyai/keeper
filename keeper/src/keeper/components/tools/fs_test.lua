local test = require("test")
local funcs = require("funcs")

local FS_TOOL_ID = "keeper.components.tools:fs"
local READABLE_FRONTEND_PATH = "plugins/git/frontend/applications/git/package.json"

-- Invoke the fs tool via a funcs executor whose context explicitly clears
-- overlay_branch / changeset_id. The test process inherits an ambient
-- changeset from the MCP session that run_test belongs to; without this
-- override every call would resolve to a live changeset and exercise the
-- fs_view (SQL) path instead of the fe_fs fallback.
local function call_fs(params)
    local executor, err = funcs.new()
    if err then error("funcs.new failed: " .. tostring(err)) end
    executor = executor:with_context({
        overlay_branch = "",
        changeset_id   = "",
    })
    local payload, call_err = executor:call(FS_TOOL_ID, params)
    if call_err then return nil, tostring(call_err) end
    if payload == nil then return nil, nil end
    if type(payload) == "table" and payload.data then
        return payload:data()
    end
    return payload
end

local function define_tests()
    describe("fs tool", function()
        describe("dispatch + path validation", function()
            it("rejects missing command", function()
                local result, err = call_fs({})
                test.is_nil(result)
                test.not_nil(err)
                test.contains(err, "command required")
            end)

            it("rejects unknown command", function()
                local result, err = call_fs({ command = "grep" })
                test.is_nil(result)
                test.not_nil(err)
                test.contains(err, "unknown command")
            end)

            it("rejects paths outside frontend/", function()
                local result, err = call_fs({ command = "view", path = "src/keeper/consts.lua" })
                test.is_nil(result)
                test.contains(err, "frontend/")
            end)

            it("rejects .. traversal", function()
                local result, err = call_fs({
                    command = "view", path = "frontend/../src/keeper/consts.lua"
                })
                test.is_nil(result)
                test.contains(err, "..")
            end)

            it("rejects absolute paths", function()
                local result, err = call_fs({
                    command = "view", path = "/etc/passwd"
                })
                test.is_nil(result)
                test.contains(err, "relative")
            end)
        end)

        describe("view (fe_fs fallback)", function()
            it("reads local-module package.json with line numbers", function()
                local result, err = call_fs({
                    command = "view",
                    path = READABLE_FRONTEND_PATH,
                })
                test.is_nil(err)
                test.not_nil(result)
                test.contains(result, "1: ")
                test.contains(result, "\"name\"")
            end)

            it("honors view_range", function()
                local result, err = call_fs({
                    command = "view",
                    path = READABLE_FRONTEND_PATH,
                    view_range = { 1, 3 },
                })
                test.is_nil(err)
                test.not_nil(result)
                test.contains(result, "1: ")
                -- banner (1 line) + up to 3 content lines = 3 newlines max
                local line_count = 0
                for _ in result:gmatch("\n") do line_count = line_count + 1 end
                test.is_true(line_count <= 3,
                    "expected at most banner + 3 lines, got " .. line_count .. " newlines")
            end)

            it("prepends fs-source provenance banner in non-raw mode", function()
                -- Regression: agents misread their own staged work as
                -- "already on main" because fs view didn't tell them whether
                -- the content came from overlay scratch or fe_fs passthrough.
                -- Now every non-raw read carries a banner identifying the
                -- source so orchestrators can tell what's staged vs landed.
                local result, err = call_fs({
                    command = "view",
                    path = READABLE_FRONTEND_PATH,
                })
                test.is_nil(err)
                test.not_nil(result)
                test.contains(result, "[fs source:")
                -- This test runs without an active changeset, so the banner
                -- should mark the read as coming from main.
                test.contains(result, "main")
            end)

            it("raw mode strips the banner so callers get clean bytes", function()
                local result, err = call_fs({
                    command = "view",
                    path = READABLE_FRONTEND_PATH,
                    raw = true,
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_false(result:sub(1, 12) == "[fs source: ",
                    "raw mode must not prepend the provenance banner")
            end)

            it("raw mode omits line numbers", function()
                local result, err = call_fs({
                    command = "view",
                    path = READABLE_FRONTEND_PATH,
                    view_range = { 1, 1 },
                    raw = true,
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_false(result:sub(1, 3) == "1: ",
                    "raw mode should not prefix with line numbers")
            end)

            it("reports not found for a missing file", function()
                local result, err = call_fs({
                    command = "view",
                    path = "frontend/__definitely_not_there.vue",
                })
                test.is_nil(result)
                test.not_nil(err)
                test.contains(err, "not found")
            end)

            it("reads local-module frontend files", function()
                local result, err = call_fs({
                    command = "view",
                    path = "plugins/git/frontend/applications/git/package.json",
                    view_range = { 1, 6 },
                })
                test.is_nil(err)
                test.not_nil(result)
                test.contains(result, "\"name\"")
                test.contains(result, "@wippy/app-keeper-git")
            end)
        end)

        describe("search", function()
            it("requires query", function()
                local result, err = call_fs({ command = "search" })
                test.is_nil(result)
                test.contains(err, "query")
            end)

            it("finds a literal match in frontend code", function()
                local result, err = call_fs({
                    command = "search",
                    query = "\"name\"",
                    path = "frontend/",
                    limit = 5,
                    full = true,
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(type(result) == "string", "search returns rendered string")
                test.is_true(result:find("fs search '\"name\"'", 1, true) ~= nil,
                    "expected header for \"name\" search; got: " .. tostring(result):sub(1, 200))
                test.is_true(result:find("frontend/", 1, true) ~= nil,
                    "expected at least one frontend/ hit line")
            end)

            it("respects glob filter", function()
                local result, err = call_fs({
                    command = "search",
                    query = "name",
                    path = "frontend/",
                    glob = "**/*.json",
                    limit = 20,
                    full = true,
                })
                test.is_nil(err)
                test.not_nil(result)
                for line in (result .. "\n"):gmatch("([^\n]*)\n") do
                    if line:sub(1, 9) == "frontend/" then
                        local colon = line:find(":", 10, true)
                        local path = colon and line:sub(1, colon - 1) or line
                        test.is_true(path:sub(-5) == ".json",
                            "glob filter should only return .json paths, got " .. path)
                    end
                end
            end)

            it("case-insensitive search matches mixed case", function()
                local result, err = call_fs({
                    command = "search",
                    query = "NAME",
                    path = "frontend/",
                    case_insensitive = true,
                    limit = 3,
                    full = true,
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(result:find("frontend/", 1, true) ~= nil,
                    "case_insensitive NAME should match 'name' in a frontend path")
            end)

            it("searches local-module frontend roots", function()
                local result, err = call_fs({
                    command = "search",
                    query = "@wippy/app-keeper-git",
                    path = "plugins/git/frontend/",
                    limit = 5,
                    full = true,
                })
                test.is_nil(err)
                test.not_nil(result)
                test.contains(result, "plugins/git/frontend/applications/git/package.json")
            end)
        end)

        describe("write ops without a changeset", function()
            it("str_replace errors without active changeset", function()
                local result, err = call_fs({
                    command = "str_replace",
                    path = "frontend/applications/keeper/package.json",
                    old_str = "\"name\"",
                    new_str = "\"nope\"",
                })
                test.is_nil(result)
                test.not_nil(err)
                test.contains(err, "main branch")
            end)

            it("create errors without active changeset", function()
                local result, err = call_fs({
                    command = "create",
                    path = "frontend/__smoke_test.txt",
                    content = "test",
                })
                test.is_nil(result)
                test.not_nil(err)
                test.contains(err, "main branch")
            end)

            it("delete errors without active changeset", function()
                local result, err = call_fs({
                    command = "delete",
                    path = "frontend/applications/keeper/package.json",
                })
                test.is_nil(result)
                test.not_nil(err)
                test.contains(err, "main branch")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
