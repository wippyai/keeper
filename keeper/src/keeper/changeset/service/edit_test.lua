local test = require("test")
local hash = require("hash")
local edit = require("edit")
local consts = require("consts")

local function define_tests()
    describe("edit helpers", function()
        describe("validate_args", function()
            it("returns nil for valid args (every edit kind)", function()
                test.is_nil(edit.validate_args({ changeset_id = "cs-1", kind = consts.EDIT_KINDS.REGISTRY_SET }))
                test.is_nil(edit.validate_args({ changeset_id = "cs-1", kind = consts.EDIT_KINDS.REGISTRY_DELETE }))
                test.is_nil(edit.validate_args({ changeset_id = "cs-1", kind = consts.EDIT_KINDS.FS_WRITE }))
                test.is_nil(edit.validate_args({ changeset_id = "cs-1", kind = consts.EDIT_KINDS.FS_DELETE }))
            end)

            it("rejects non-table args", function()
                local err = edit.validate_args(nil)
                test.is_true(err:find("changeset_id", 1, true) ~= nil)
                err = edit.validate_args("x")
                test.is_true(err:find("changeset_id", 1, true) ~= nil)
            end)

            it("rejects missing changeset_id", function()
                local err = edit.validate_args({ kind = consts.EDIT_KINDS.FS_WRITE })
                test.is_true(err:find("changeset_id", 1, true) ~= nil)
            end)

            it("rejects empty changeset_id", function()
                local err = edit.validate_args({ changeset_id = "", kind = consts.EDIT_KINDS.FS_WRITE })
                test.is_true(err:find("changeset_id", 1, true) ~= nil)
            end)

            it("rejects missing kind", function()
                local err = edit.validate_args({ changeset_id = "cs-1" })
                test.is_true(err:find("kind", 1, true) ~= nil)
            end)

            it("rejects empty kind", function()
                local err = edit.validate_args({ changeset_id = "cs-1", kind = "" })
                test.is_true(err:find("kind", 1, true) ~= nil)
            end)

            it("rejects unknown kind", function()
                local err = edit.validate_args({ changeset_id = "cs-1", kind = "registry_nuke" })
                test.is_true(err:find("unknown edit kind", 1, true) ~= nil)
                test.is_true(err:find("registry_nuke", 1, true) ~= nil)
            end)
        end)

        describe("assert_live", function()
            it("accepts an OPEN changeset", function()
                local ok, err = edit.assert_live({ state = consts.STATES.OPEN })
                test.is_true(ok)
                test.is_nil(err)
            end)

            it("accepts EDITING / REVIEW / ACCEPTED / REJECTED states", function()
                for _, s in ipairs({
                    consts.STATES.EDITING, consts.STATES.REVIEW,
                    consts.STATES.ACCEPTED, consts.STATES.REJECTED,
                }) do
                    local ok, err = edit.assert_live({ state = s })
                    test.is_true(ok)
                    test.is_nil(err)
                end
            end)

            it("rejects nil changeset with NOT_FOUND", function()
                local ok, err = edit.assert_live(nil)
                test.is_nil(ok)
                test.eq(err, consts.ERRORS.NOT_FOUND)
            end)

            it("rejects MERGED state", function()
                local ok, err = edit.assert_live({ state = consts.STATES.MERGED })
                test.is_nil(ok)
                test.is_true(err:find(consts.ERRORS.INVALID_STATE, 1, true) ~= nil)
                test.is_true(err:find(consts.STATES.MERGED, 1, true) ~= nil)
            end)

            it("rejects DROPPED state", function()
                local ok, err = edit.assert_live({ state = consts.STATES.DROPPED })
                test.is_nil(ok)
                test.is_true(err:find(consts.ERRORS.INVALID_STATE, 1, true) ~= nil)
                test.is_true(err:find(consts.STATES.DROPPED, 1, true) ~= nil)
            end)
        end)

        describe("compute_entry_hash", function()
            it("matches sha256(definition .. sep .. content)", function()
                local entry = { definition = "kind: function.lua", content = "return {}" }
                local expected = hash.sha256("kind: function.lua\n---\nreturn {}")
                test.eq(edit.compute_entry_hash(entry), expected)
            end)

            it("treats nil parts as empty strings", function()
                local expected = hash.sha256("\n---\n")
                test.eq(edit.compute_entry_hash({}), expected)
                test.eq(edit.compute_entry_hash({ definition = nil, content = nil }), expected)
            end)

            it("is deterministic across calls", function()
                local a = edit.compute_entry_hash({ definition = "x", content = "y" })
                local b = edit.compute_entry_hash({ definition = "x", content = "y" })
                test.eq(a, b)
            end)

            it("distinguishes definition and content boundaries", function()
                local a = edit.compute_entry_hash({ definition = "ab", content = "c" })
                local b = edit.compute_entry_hash({ definition = "a", content = "bc" })
                test.is_true(a ~= b)
            end)
        end)

        describe("KINDS export", function()
            it("exposes every edit kind from consts", function()
                test.eq(edit.KINDS.REGISTRY_SET, consts.EDIT_KINDS.REGISTRY_SET)
                test.eq(edit.KINDS.REGISTRY_DELETE, consts.EDIT_KINDS.REGISTRY_DELETE)
                test.eq(edit.KINDS.FS_WRITE, consts.EDIT_KINDS.FS_WRITE)
                test.eq(edit.KINDS.FS_DELETE, consts.EDIT_KINDS.FS_DELETE)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
