local test = require("test")
local uuid = require("uuid")

local explore = require("explore")
local compare = require("compare")
local edit = require("edit")
local get_entries = require("get_entries")
local manage = require("manage")
local branch = require("branch")
local entry_lib = require("entry_lib")
local function_config = require("function_config")

local function define_tests()
    describe("Agent Tools", function()

        describe("explore", function()
            -- All tests pass full=true to bypass the LLM-backed summarize wrapper.
            -- The summarize path has its own coverage; here we verify the raw
            -- handler contract (routing, formatting, validation).
            local function call(params)
                params.full = true
                return explore.handler(params)
            end

            it("tree operation returns result", function()
                local result, err = call({operation = "tree"})
                test.is_nil(err)
                test.not_nil(result)
            end)

            it("rejects invalid operation", function()
                local result, err = call({operation = "invalid_op"})
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects invalid operation", function()
                local result, err = call({ operation = "invalid" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("namespace operation requires name parameter", function()
                local result, err = call({ operation = "namespace" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("namespace operation rejects empty name", function()
                local result, err = call({ operation = "namespace", name = "" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("entries operation requires ids array", function()
                local result, err = call({ operation = "entries" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("entries operation rejects empty ids", function()
                local result, err = call({ operation = "entries", ids = {} })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("graph operation requires id parameter", function()
                local result, err = call({ operation = "graph" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("graph operation rejects empty id", function()
                local result, err = call({ operation = "graph", id = "" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("tree operation returns results for main branch", function()
                local result, err = call({ operation = "tree", branch = "main" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
                test.is_true(result:find("State Tree") ~= nil)
            end)

            it("tree operation respects depth parameter", function()
                local result, err = call({ operation = "tree", branch = "main", depth = 0 })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
            end)

            it("tree operation with root prefix filters namespaces", function()
                local result, err = call({ operation = "tree", branch = "main", root = "keeper.tools" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
            end)

            it("search operation returns results", function()
                local result, err = call({ operation = "search", branch = "main" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
                test.is_true(result:find("Search:") ~= nil)
            end)

            it("search with kind filter returns results", function()
                local result, err = call({ operation = "search", branch = "main", kind = "function.lua" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
            end)

            it("search with namespace filter returns results", function()
                local result, err = call({ operation = "search", branch = "main", namespace = "keeper.state.tools" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
            end)

            it("search with limit constrains results", function()
                local result, err = call({ operation = "search", branch = "main", limit = 1 })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
            end)

            it("entries operation returns formatted entry data", function()
                local result, err = call({
                    operation = "entries",
                    ids = {"keeper.state.tools:explore"},
                    branch = "main"
                })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
            end)

            it("entries operation with nonexistent id returns no-match message", function()
                local result, err = call({
                    operation = "entries",
                    ids = {"nonexistent.ns:nonexistent_entry"},
                    branch = "main"
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(result:find("No entries found") ~= nil)
            end)

            it("namespace operation returns formatted index for known namespace", function()
                local result, err = call({ operation = "namespace", name = "keeper.state.tools", branch = "main" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
                test.is_true(result:find("namespace: keeper.state.tools") ~= nil)
            end)
        end)

        describe("compare", function()
            it("tree mode compares against main", function()
                local result, err = compare.handler({mode = "tree", target = "main"})
                test.is_nil(err)
                test.not_nil(result)
            end)

            it("rejects invalid mode", function()
                local result, err = compare.handler({mode = "invalid_mode", target = "main"})
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects invalid mode", function()
                local result, err = compare.handler({ mode = "invalid", target = "some-branch" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("tree mode requires target branch", function()
                local result, err = compare.handler({ mode = "tree" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("entries mode requires target branch", function()
                local result, err = compare.handler({ mode = "entries" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("tree mode comparing main to main shows no changes", function()
                local result, err = compare.handler({ mode = "tree", source = "main", target = "main" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
                test.is_true(result:find("No changes detected") ~= nil)
            end)

            it("entries mode comparing main to main shows no changes", function()
                local result, err = compare.handler({ mode = "entries", source = "main", target = "main" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
                test.is_true(result:find("No changes detected") ~= nil)
            end)

            it("tree mode with namespace filter returns results", function()
                local result, err = compare.handler({
                    mode = "tree",
                    source = "main",
                    target = "main",
                    namespace = "keeper.state.tools"
                })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
            end)
        end)

        describe("edit", function()
            it("view command on nonexistent entry", function()
                local result, err = edit.handler({ command = "view", path = "nonexistent:entry_xyz" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("requires path parameter", function()
                local result, err = edit.handler({ command = "view" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects empty command", function()
                local result, err = edit.handler({ command = "", path = "ns:name" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects empty path", function()
                local result, err = edit.handler({ command = "view", path = "" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects invalid command", function()
                local result, err = edit.handler({ command = "invalid", path = "ns:name" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("view command validates entry ID format", function()
                local result, err = edit.handler({ command = "view", path = "no-colon" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("view command returns formatted content for existing entry", function()
                local result, err = edit.handler({ command = "view", path = "keeper.state.tools:explore" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
                test.is_true(#result > 0)
            end)

            it("view command with view_range returns subset of lines", function()
                local result, err = edit.handler({
                    command = "view",
                    path = "keeper.state.tools:explore",
                    view_range = {1, 5}
                })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
            end)

            it("view command returns error for nonexistent entry", function()
                local result, err = edit.handler({ command = "view", path = "nonexistent.ns:missing" })
                test.is_nil(result)
                test.not_nil(err)
            end)
        end)

        describe("validate_function_config", function()
            local v = function_config.validate

            it("accepts a well-formed function.lua", function()
                local err = v({
                    kind = "function.lua",
                    method = "handler",
                    modules = { "fs", "text" },
                    imports = { alias = "namespace:name" },
                })
                test.is_nil(err)
            end)

            it("accepts a library.lua with no method", function()
                local err = v({
                    kind = "library.lua",
                    modules = { "json" },
                })
                test.is_nil(err)
            end)

            it("accepts entries with kinds outside the validator scope", function()
                test.is_nil(v({ kind = "http.endpoint" }))
                test.is_nil(v({ kind = "registry.entry", meta = { type = "agent" } }))
            end)

            it("returns nil when parsed_entry has no kind", function()
                test.is_nil(v({}))
            end)

            it("rejects function.lua missing method", function()
                local err = v({ kind = "function.lua", modules = { "fs" } })
                test.not_nil(err)
                test.contains(err, "method")
            end)

            it("rejects function.lua with empty-string method", function()
                local err = v({ kind = "function.lua", method = "" })
                test.not_nil(err)
                test.contains(err, "method")
            end)

            it("rejects process.wasm missing method", function()
                local err = v({ kind = "process.wasm" })
                test.not_nil(err)
                test.contains(err, "method")
            end)

            it("rejects empty modules table", function()
                local err = v({
                    kind = "function.lua",
                    method = "handler",
                    modules = {},
                })
                test.not_nil(err)
                test.contains(err, "modules")
                test.contains(err, "empty")
            end)

            it("rejects modules with a namespaced module", function()
                local err = v({
                    kind = "function.lua",
                    method = "handler",
                    modules = { "ns:mod" },
                })
                test.not_nil(err)
                test.contains(err, "namespace")
            end)

            it("rejects modules with an empty-string entry", function()
                local err = v({
                    kind = "function.lua",
                    method = "handler",
                    modules = { "" },
                })
                test.not_nil(err)
                test.contains(err, "non-empty")
            end)

            it("rejects modules shaped as a map", function()
                local err = v({
                    kind = "function.lua",
                    method = "handler",
                    modules = { fs = true },
                })
                test.not_nil(err)
                test.contains(err, "list")
            end)

            it("rejects modules that is not a table", function()
                local err = v({
                    kind = "function.lua",
                    method = "handler",
                    modules = "fs",
                })
                test.not_nil(err)
                test.contains(err, "modules")
            end)

            it("rejects empty imports table", function()
                local err = v({
                    kind = "function.lua",
                    method = "handler",
                    imports = {},
                })
                test.not_nil(err)
                test.contains(err, "imports")
                test.contains(err, "empty")
            end)

            it("rejects imports shaped as a list", function()
                local err = v({
                    kind = "function.lua",
                    method = "handler",
                    imports = { "namespace:name" },
                })
                test.not_nil(err)
                test.contains(err, "map")
            end)

            it("rejects imports with non-string value", function()
                local err = v({
                    kind = "function.lua",
                    method = "handler",
                    imports = { alias = 42 },
                })
                test.not_nil(err)
                test.contains(err, "alias")
            end)

            it("rejects imports value without namespace", function()
                local err = v({
                    kind = "function.lua",
                    method = "handler",
                    imports = { alias = "bare_name" },
                })
                test.not_nil(err)
                test.contains(err, "fully qualified")
            end)

            it("rejects non-table parsed_entry", function()
                local err = v("not a table")
                test.not_nil(err)
            end)
        end)

        describe("get_entries", function()
            -- All passing tests use full=true to bypass the LLM-backed summarize
            -- wrapper and keep assertions deterministic. Summarize has its own coverage.
            it("requires ids array", function()
                local result, err = get_entries.handler({})
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects empty ids array", function()
                local result, err = get_entries.handler({ ids = {} })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("returns formatted output for existing entries", function()
                local result, err = get_entries.handler({
                    ids = {"keeper.state.tools:explore"},
                    full = true,
                })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
                test.is_true(result:find("keeper.state.tools:explore") ~= nil)
            end)

            it("returns not-found message for nonexistent entries", function()
                local result, err = get_entries.handler({
                    ids = {"nonexistent.ns:missing"},
                    full = true,
                })
                test.is_nil(err)
                test.not_nil(result)
                test.is_true(result:find("No entries found") ~= nil)
            end)

            it("returns multiple entries", function()
                local result, err = get_entries.handler({
                    ids = {"keeper.state.tools:explore", "keeper.state.tools:compare"},
                    full = true,
                })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(type(result), "string")
                test.is_true(result:find("keeper.state.tools:explore") ~= nil)
                test.is_true(result:find("keeper.state.tools:compare") ~= nil)
            end)
        end)

        describe("branch", function()
            it("get action returns current branch", function()
                local result, err = branch.handler({ action = "get" })
                test.is_nil(err)
                test.not_nil(result)
                test.not_nil(result.branch)
                test.not_nil(result.message)
            end)

            it("set action requires branch name", function()
                local result, err = branch.handler({ action = "set" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("set action rejects empty branch name", function()
                local result, err = branch.handler({ action = "set", branch = "" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("set action rejects main as target", function()
                local result, err = branch.handler({ action = "set", branch = "main" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("set action opens changeset and returns control structure for valid branch", function()
                local test_branch = "test-branch-" .. uuid.v4():sub(1, 8)
                local result, err = branch.handler({ action = "set", branch = test_branch })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(result.branch, test_branch)
                test.not_nil(result.changeset_id)
                test.eq(result.resumed, false)
                test.not_nil(result._control)
                test.not_nil(result._control.context)
                test.not_nil(result._control.context.session)
                test.eq(result._control.context.session.set.overlay_branch, test_branch)
                test.eq(result._control.context.session.set.changeset_id, result.changeset_id)

                local again, again_err = branch.handler({ action = "set", branch = test_branch })
                test.is_nil(again_err)
                test.eq(again.changeset_id, result.changeset_id)
                test.eq(again.resumed, true)
            end)

            it("clear action returns main branch", function()
                local result, err = branch.handler({ action = "clear" })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(result.branch, "main")
                test.not_nil(result._control)
            end)

            it("invalid action is rejected", function()
                local result, err = branch.handler({ action = "bogus" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("default action is set", function()
                local result, err = branch.handler({})
                test.is_nil(result)
                test.not_nil(err)
            end)
        end)

        describe("manage", function()
            it("requires operation parameter", function()
                local result, err = manage.handler({ entry_id = "ns:name" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("requires entry_id parameter", function()
                local result, err = manage.handler({ operation = "delete" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects empty operation", function()
                local result, err = manage.handler({ operation = "", entry_id = "ns:name" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects empty entry_id", function()
                local result, err = manage.handler({ operation = "delete", entry_id = "" })
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("rejects invalid operation", function()
                local result, err = manage.handler({ operation = "invalid", entry_id = "ns:name" })
                test.is_nil(result)
                test.not_nil(err)
            end)

        end)

        describe("validate_entry_id", function()
            local v = entry_lib.validate_entry_id

            it("splits a valid id into namespace and name", function()
                local ns, name = v("foo.bar:baz")
                test.eq(ns, "foo.bar")
                test.eq(name, "baz")
            end)

            it("rejects empty or nil input", function()
                local out, err = v(nil)
                test.is_nil(out)
                test.not_nil(err)

                out, err = v("")
                test.is_nil(out)
                test.not_nil(err)
            end)

            it("rejects non-string input", function()
                local out, err = v(123)
                test.is_nil(out)
                test.is_true(err:find("must be a string") ~= nil)
            end)

            it("rejects ids missing a colon", function()
                local out, err = v("no_colon_here")
                test.is_nil(out)
                test.is_true(err:find("namespace:name") ~= nil)
            end)

            it("rejects ids with empty namespace or name", function()
                local out, err = v(":name")
                test.is_nil(out)
                test.is_true(err:find("empty") ~= nil)

                out, err = v("ns:")
                test.is_nil(out)
                test.is_true(err:find("empty") ~= nil)
            end)
        end)

        describe("extract_kind_from_definition", function()
            local e = entry_lib.extract_kind_from_definition

            it("extracts the kind after the entries section", function()
                local yaml = [[
version: "1.0"
namespace: foo
entries:
  - name: thing
    kind: function.lua
    source: file://thing.lua
]]
                local kind, err = e(yaml)
                test.is_nil(err)
                test.eq(kind, "function.lua")
            end)

            it("errors when entries: section is missing", function()
                local kind, err = e("version: '1.0'\nnamespace: foo\n")
                test.is_nil(kind)
                test.is_true(err:find("entries") ~= nil)
            end)

            it("errors when kind: field is absent", function()
                local yaml = [[
entries:
  - name: thing
    source: file://thing.lua
]]
                local kind, err = e(yaml)
                test.is_nil(kind)
                test.is_true(err:find("kind") ~= nil)
            end)

            it("ignores kind: fields before the entries section", function()
                local yaml = [[
meta:
  kind: should_not_match
entries:
  - name: thing
    kind: library.lua
]]
                local kind = e(yaml)
                test.eq(kind, "library.lua")
            end)
        end)

        describe("entry_content", function()
            local ec = entry_lib.entry_content

            it("returns empty strings when entry has no chunks", function()
                local def, src = ec({})
                test.eq(def, "")
                test.eq(src, "")
            end)

            it("picks up definition and content chunks independently", function()
                local def, src = ec({
                    chunks = {
                        { type = "definition", content = "yaml body" },
                        { type = "content",    content = "source body" },
                    },
                })
                test.eq(def, "yaml body")
                test.eq(src, "source body")
            end)

            it("tolerates nil content on chunks", function()
                local def, src = ec({
                    chunks = { { type = "definition" } },
                })
                test.eq(def, "")
                test.eq(src, "")
            end)
        end)

        describe("content_hash", function()
            local ch = entry_lib.content_hash

            it("produces identical hashes for identical inputs", function()
                local h1 = ch("def", "src")
                local h2 = ch("def", "src")
                test.eq(h1, h2)
            end)

            it("differs when definition changes", function()
                local h1 = ch("def", "src")
                local h2 = ch("DEF", "src")
                test.is_true(h1 ~= h2)
            end)

            it("differs when source changes", function()
                local h1 = ch("def", "src")
                local h2 = ch("def", "SRC")
                test.is_true(h1 ~= h2)
            end)

            it("treats nil definition/source as empty string", function()
                local h1 = ch(nil, nil)
                local h2 = ch("",  "")
                test.eq(h1, h2)
            end)
        end)

        describe("classify_changes", function()
            local classify = entry_lib.classify_changes

            local function entry(id, def, src, deleted)
                return {
                    id      = id,
                    deleted = deleted or 0,
                    chunks  = {
                        { type = "definition", content = def or "" },
                        { type = "content",    content = src or "" },
                    },
                }
            end

            it("classifies added entries (not in base)", function()
                local base = {}
                local target = { ["ns:a"] = entry("ns:a", "def", "src") }
                local added, deleted, modified = classify(base, target)
                test.eq(#added, 1)
                test.eq(added[1].id, "ns:a")
                test.eq(#deleted, 0)
                test.eq(#modified, 0)
            end)

            it("classifies deleted entries (target marked deleted)", function()
                local base   = { ["ns:a"] = entry("ns:a", "def", "src", 0) }
                local target = { ["ns:a"] = entry("ns:a", "def", "src", 1) }
                local added, deleted, modified = classify(base, target)
                test.eq(#added, 0)
                test.eq(#deleted, 1)
                test.eq(deleted[1].id, "ns:a")
                test.eq(#modified, 0)
            end)

            it("classifies modified entries by content hash", function()
                local base   = { ["ns:a"] = entry("ns:a", "def", "src1") }
                local target = { ["ns:a"] = entry("ns:a", "def", "src2") }
                local added, deleted, modified = classify(base, target)
                test.eq(#modified, 1)
                test.eq(modified[1].id, "ns:a")
            end)

            it("skips unchanged entries", function()
                local base   = { ["ns:a"] = entry("ns:a", "def", "src") }
                local target = { ["ns:a"] = entry("ns:a", "def", "src") }
                local added, deleted, modified = classify(base, target)
                test.eq(#added, 0)
                test.eq(#deleted, 0)
                test.eq(#modified, 0)
            end)

            it("treats a resurrection (base deleted, target alive) as added", function()
                local base   = { ["ns:a"] = entry("ns:a", "def", "src", 1) }
                local target = { ["ns:a"] = entry("ns:a", "def", "src", 0) }
                local added, deleted, modified = classify(base, target)
                test.eq(#added, 1)
                test.eq(added[1].id, "ns:a")
            end)

            it("sorts all three buckets by id ascending", function()
                local base = {}
                local target = {
                    ["ns:z"] = entry("ns:z", "d", "s"),
                    ["ns:a"] = entry("ns:a", "d", "s"),
                    ["ns:m"] = entry("ns:m", "d", "s"),
                }
                local added = classify(base, target)
                test.eq(added[1].id, "ns:a")
                test.eq(added[2].id, "ns:m")
                test.eq(added[3].id, "ns:z")
            end)
        end)

    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
