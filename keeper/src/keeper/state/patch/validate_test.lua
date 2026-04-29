local test = require("test")
local validate = require("patch_validate").validate
local consts = require("patch_consts")

local ERR = consts.ERR

local function expect_err(t, patch, code, label)
    local ok, e = validate(patch)
    t.expect(ok):to_be_nil()
    t.expect(e):not_to_be_nil()
    t.expect(e.code):to_be(code, label)
end

local function expect_ok(t, patch, label)
    local p, e = validate(patch)
    t.expect(e):to_be_nil(label)
    t.expect(p):not_to_be_nil()
end

local function define_tests()
    test.describe("patch validate — shape errors", function()
        test.it("rejects nil patch", function(t)
            expect_err(t, nil, ERR.INVALID_PATCH, "nil")
        end)

        test.it("rejects non-table patch", function(t)
            expect_err(t, "not a table", ERR.INVALID_PATCH, "string")
        end)

        test.it("requires target", function(t)
            expect_err(t, { op = "view" }, ERR.MISSING_FIELD, "no target")
        end)

        test.it("rejects unknown target", function(t)
            expect_err(t, { target = "bogus", op = "view" }, ERR.INVALID_TARGET, "bogus target")
        end)
    end)

    test.describe("patch validate — entry", function()
        test.it("requires entry id", function(t)
            expect_err(t, { target = "entry", op = "view" }, ERR.MISSING_FIELD, "no id")
        end)

        test.it("rejects entry id without colon", function(t)
            expect_err(t, { target = "entry", id = "noColon", op = "view" }, ERR.INVALID_TARGET, "no colon")
        end)

        test.it("requires op", function(t)
            expect_err(t, { target = "entry", id = "ns:name" }, ERR.MISSING_FIELD, "no op")
        end)

        test.it("rejects unknown entry op", function(t)
            expect_err(t, { target = "entry", id = "ns:name", op = "rewrite" }, ERR.INVALID_OP, "rewrite is fs-only")
        end)

        test.it("create requires file_text", function(t)
            expect_err(t, { target = "entry", id = "ns:name", op = "create" }, ERR.MISSING_FIELD, "no file_text")
        end)

        test.it("str_replace requires non-empty replace[]", function(t)
            expect_err(t, { target = "entry", id = "ns:name", op = "str_replace" }, ERR.MISSING_FIELD, "no replace")
            expect_err(t, { target = "entry", id = "ns:name", op = "str_replace", replace = {} },
                ERR.MISSING_FIELD, "empty replace")
        end)

        test.it("str_replace items must be {old,new}", function(t)
            expect_err(t, { target = "entry", id = "ns:name", op = "str_replace", replace = { "x" } },
                ERR.INVALID_PATCH, "non-table item")
            expect_err(t, { target = "entry", id = "ns:name", op = "str_replace", replace = { { old = "x" } } },
                ERR.MISSING_FIELD, "missing new")
        end)

        test.it("accepts well-formed entry view", function(t)
            expect_ok(t, { target = "entry", id = "ns:name", op = "view" })
        end)

        test.it("accepts well-formed entry create", function(t)
            expect_ok(t, { target = "entry", id = "ns:name", op = "create",
                file_text = "<definition>x</definition>" })
        end)

        test.it("accepts well-formed entry str_replace", function(t)
            expect_ok(t, { target = "entry", id = "ns:name", op = "str_replace",
                replace = { { old = "a", new = "b" } } })
        end)
    end)

    test.describe("patch validate — fs", function()
        test.it("requires fs path", function(t)
            expect_err(t, { target = "fs", op = "view" }, ERR.MISSING_FIELD, "no path")
        end)

        test.it("rejects fs path outside frontend roots", function(t)
            expect_err(t, { target = "fs", path = "src/keeper/x.lua", op = "view" },
                ERR.INVALID_TARGET, "non-frontend")
            expect_err(t, { target = "fs", path = "plugins/git/src/keeper/git/x.lua", op = "view" },
                ERR.INVALID_TARGET, "plugin backend")
        end)

        test.it("rejects fs path with ..", function(t)
            expect_err(t, { target = "fs", path = "frontend/../etc/passwd", op = "view" },
                ERR.INVALID_TARGET, "dotdot")
        end)

        test.it("rejects unknown fs op", function(t)
            expect_err(t, { target = "fs", path = "frontend/x", op = "bogus" },
                ERR.INVALID_OP, "bogus op")
        end)

        test.it("fs str_replace requires old_str and new_str", function(t)
            expect_err(t, { target = "fs", path = "frontend/x", op = "str_replace" },
                ERR.MISSING_FIELD, "missing old_str")
            expect_err(t, { target = "fs", path = "frontend/x", op = "str_replace", old_str = "a" },
                ERR.MISSING_FIELD, "missing new_str")
            expect_ok(t, {
                target = "fs",
                path = "frontend/x",
                op = "str_replace",
                old_str = "a",
                new_str = "b",
            })
        end)

        test.it("create/rewrite require content", function(t)
            expect_err(t, { target = "fs", path = "frontend/x", op = "create" },
                ERR.MISSING_FIELD, "no content")
            expect_err(t, { target = "fs", path = "frontend/x", op = "rewrite" },
                ERR.MISSING_FIELD, "no content")
        end)

        test.it("accepts fs delete without content", function(t)
            expect_ok(t, { target = "fs", path = "frontend/x.txt", op = "delete" })
        end)

        test.it("accepts fs view without content", function(t)
            expect_ok(t, { target = "fs", path = "frontend/x.txt", op = "view" })
        end)

        test.it("accepts local-module frontend paths", function(t)
            expect_ok(t, {
                target = "fs",
                path = "plugins/git/frontend/applications/git/src/pages/git.vue",
                op = "view",
            })
        end)
    end)
end

return { define_tests = define_tests }
