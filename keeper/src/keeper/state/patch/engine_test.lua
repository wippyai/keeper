local test = require("test")
local engine = require("engine")
local consts = require("patch_consts")

local ERR = consts.ERR

local function define_tests()
    test.describe("engine.apply_one — validation passthrough", function()
        test.it("rejects malformed patch with validator code", function(t)
            local r, e = engine.apply_one("not a table")
            t.expect(r):to_be_nil()
            t.expect(e):not_to_be_nil()
            t.expect(e.code):to_be(ERR.INVALID_PATCH)
        end)

        test.it("rejects entry id without colon", function(t)
            local r, e = engine.apply_one({ target = "entry", id = "noColon", op = "view" })
            t.expect(r):to_be_nil()
            t.expect(e.code):to_be(ERR.INVALID_TARGET)
        end)

        test.it("rejects unknown op for target", function(t)
            local r, e = engine.apply_one({ target = "fs", path = "frontend/x", op = "bogus" })
            t.expect(r):to_be_nil()
            t.expect(e.code):to_be(ERR.INVALID_OP)
        end)
    end)

    test.describe("engine.apply_one — view (no changeset needed)", function()
        test.it("views existing main entry and formats with line numbers", function(t)
            local r, e = engine.apply_one({
                target = "entry",
                id = "keeper.state.patch:engine",
                op = "view",
            })
            t.expect(e):to_be_nil()
            t.expect(r):not_to_be_nil()
            if not r then error("view result missing") end
            t.expect(type(r.content)):to_be("string")
            t.expect(r.content:find("1: ")):not_to_be_nil("expects line-numbered output")
        end)

        test.it("returns NOT_FOUND for missing entry", function(t)
            local r, e = engine.apply_one({
                target = "entry",
                id = "nonexistent.ns:missing_entry_xyz",
                op = "view",
            })
            t.expect(r):to_be_nil()
            t.expect(e.code):to_be(ERR.NOT_FOUND)
        end)

        test.it("views local-module frontend files without a changeset", function(t)
            local r, e = engine.apply_one({
                target = "fs",
                path = "plugins/git/frontend/applications/git/package.json",
                op = "view",
            })
            t.expect(e):to_be_nil()
            t.expect(r):not_to_be_nil()
            if not r then error("view result missing") end
            t.expect(r.content:find("@wippy/app-keeper-git", 1, true)):not_to_be_nil()
        end)
    end)

    test.describe("engine.apply_one — branch guard", function()
        test.it("blocks mutation when no active branch (or main)", function(t)
            local r, e = engine.apply_one({
                target = "entry",
                id = "app.scratch:probe_engine",
                op = "delete",
            }, { branch = "main" })
            t.expect(r):to_be_nil()
            t.expect(e.code):to_be(ERR.NO_BRANCH)
        end)
    end)
end

return { define_tests = define_tests }
