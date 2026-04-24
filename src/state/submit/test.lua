local test = require("test")
local submit_lib = require("submit_lib")

local function find_error(resp, code)
    for _, e in ipairs(resp.errors or {}) do
        if e.code == code then return e end
    end
    return nil
end

local function define_tests()
    test.describe("keeper.state.submit:library", function()
        test.it("rejects nil params with a structured error", function()
            local resp = submit_lib.run(nil)
            test.is_false(resp.ok)
            test.eq(resp.stage, "validate")
            test.is_true(#resp.errors >= 1)
        end)

        test.it("rejects missing action", function()
            local resp = submit_lib.run({})
            test.is_false(resp.ok)
            test.eq(resp.stage, "validate")
            test.not_nil(find_error(resp, submit_lib.ERR.NO_ACTION))
            local err = resp.errors[1]
            test.not_nil(err.fix_hint)
            test.is_false(err.retryable)
        end)

        test.it("rejects unknown action", function()
            local resp = submit_lib.run({ action = "plot" })
            test.is_false(resp.ok)
            test.not_nil(find_error(resp, submit_lib.ERR.INVALID_ACTION))
        end)

        -- Without active context or with empty patches, submit must fail with structured
        -- errors at the validate stage. Test pool may or may not carry branch context, so
        -- accept either NO_BRANCH, NO_CHANGESET, or NO_PATCHES as the gate that fired.
        test.it("rejects stage with empty patches", function()
            local resp = submit_lib.run({ action = "stage", patches = {} })
            test.is_false(resp.ok)
            test.eq(resp.stage, "validate")
            local gate = find_error(resp, submit_lib.ERR.NO_BRANCH)
                     or find_error(resp, submit_lib.ERR.NO_CHANGESET)
                     or find_error(resp, submit_lib.ERR.NO_PATCHES)
            test.not_nil(gate)
        end)

        -- Commit accepts empty patches (publishes whatever the delegate staged); the
        -- orchestrator uses this to drive a submit-based push without restaging. When
        -- test pool has no branch/changeset context, the gate is NO_BRANCH/NO_CHANGESET —
        -- never NO_PATCHES.
        test.it("rejects removed action=commit (publishing is not an agent-side path)", function()
            local resp = submit_lib.run({ action = "commit", patches = {} })
            test.is_false(resp.ok)
            test.eq(resp.stage, "validate")
            test.not_nil(find_error(resp, submit_lib.ERR.INVALID_ACTION),
                "commit must be rejected at the validate stage — integrate runner owns publishing")
        end)

        test.it("reports errors with structured stage field", function()
            local resp = submit_lib.run({ action = "grape" })
            test.is_false(resp.ok)
            test.eq(resp.stage, "validate")
            test.eq(type(resp.errors), "table")
        end)

        test.describe("validate_patch", function()
            test.it("accepts a well-formed entry create patch", function()
                local ok, err = submit_lib.validate_patch({
                    target = { kind = "entry", id = "ns:thing" },
                    op     = "create",
                    body   = { file_text = "<definition>x</definition>" },
                }, 1)
                test.not_nil(ok)
                test.is_nil(err)
            end)

            test.it("accepts a well-formed entry update with replace list", function()
                local ok, err = submit_lib.validate_patch({
                    target  = { kind = "entry", id = "ns:thing" },
                    op      = "update",
                    replace = { { old = "a", new = "b" } },
                }, 1)
                test.not_nil(ok)
                test.is_nil(err)
            end)

            test.it("accepts a well-formed fs create patch", function()
                local ok, err = submit_lib.validate_patch({
                    target = { kind = "fs", path = "frontend/a.vue" },
                    op     = "create",
                    body   = { content = "hello" },
                }, 1)
                test.not_nil(ok)
                test.is_nil(err)
            end)

            test.it("rejects non-table patch", function()
                local ok, err = submit_lib.validate_patch("not a table", 1)
                test.is_nil(ok)
                test.eq(err.code, submit_lib.ERR.INVALID_PATCH)
            end)

            test.it("rejects missing target", function()
                local ok, err = submit_lib.validate_patch({ op = "create" }, 1)
                test.is_nil(ok)
                test.eq(err.code, submit_lib.ERR.INVALID_TARGET)
            end)

            test.it("rejects unsupported target.kind", function()
                local ok, err = submit_lib.validate_patch({
                    target = { kind = "nuclear", id = "x:y" }, op = "create",
                }, 1)
                test.is_nil(ok)
                test.eq(err.code, submit_lib.ERR.UNSUPPORTED_TARGET)
            end)

            test.it("rejects entry target missing colon", function()
                local ok, err = submit_lib.validate_patch({
                    target = { kind = "entry", id = "bogus" },
                    op     = "create",
                    body   = { file_text = "<definition>x</definition>" },
                }, 1)
                test.is_nil(ok)
                test.eq(err.code, submit_lib.ERR.INVALID_TARGET)
            end)

            test.it("rejects fs target with empty path", function()
                local ok, err = submit_lib.validate_patch({
                    target = { kind = "fs", path = "" },
                    op     = "create",
                    body   = { content = "x" },
                }, 1)
                test.is_nil(ok)
                test.eq(err.code, submit_lib.ERR.INVALID_TARGET)
            end)

            test.it("rejects unknown op", function()
                local ok, err = submit_lib.validate_patch({
                    target = { kind = "entry", id = "ns:x" },
                    op     = "destroy",
                }, 1)
                test.is_nil(ok)
                test.eq(err.code, submit_lib.ERR.INVALID_OP)
            end)

            test.it("rejects entry create without body.file_text", function()
                local ok, err = submit_lib.validate_patch({
                    target = { kind = "entry", id = "ns:x" },
                    op     = "create",
                }, 1)
                test.is_nil(ok)
                test.eq(err.code, submit_lib.ERR.INVALID_PATCH)
            end)

            test.it("rejects entry update without replace", function()
                local ok, err = submit_lib.validate_patch({
                    target = { kind = "entry", id = "ns:x" },
                    op     = "update",
                }, 1)
                test.is_nil(ok)
                test.eq(err.code, submit_lib.ERR.INVALID_PATCH)
            end)

            test.it("rejects replace items that are not {old,new} strings", function()
                local ok, err = submit_lib.validate_patch({
                    target  = { kind = "entry", id = "ns:x" },
                    op      = "update",
                    replace = { { old = "a" } },
                }, 1)
                test.is_nil(ok)
                test.eq(err.code, submit_lib.ERR.INVALID_PATCH)
                test.is_true(err.target:find("replace%[1%]") ~= nil)
            end)

            test.it("rejects fs create without body.content", function()
                local ok, err = submit_lib.validate_patch({
                    target = { kind = "fs", path = "frontend/x.vue" },
                    op     = "create",
                }, 1)
                test.is_nil(ok)
                test.eq(err.code, submit_lib.ERR.INVALID_PATCH)
            end)
        end)

        test.describe("parse_lint", function()
            test.it("returns empty buckets for non-string input", function()
                local out = submit_lib.parse_lint(nil)
                test.is_false(out.has_errors)
                test.eq(#out.errors, 0)
                test.eq(#out.warnings, 0)
                test.eq(#out.infos, 0)
                test.eq(out.raw, "")
            end)

            test.it("collects items under ERRORS / WARNINGS / INFO sections", function()
                local out = submit_lib.parse_lint(
                    "ERRORS:\n  err one\n  err two\n\n" ..
                    "WARNINGS:\n  warn one\n\n" ..
                    "INFO:\n  info one\n")
                test.is_true(out.has_errors)
                test.eq(#out.errors, 2)
                test.eq(out.errors[1], "err one")
                test.eq(out.errors[2], "err two")
                test.eq(#out.warnings, 1)
                test.eq(out.warnings[1], "warn one")
                test.eq(#out.infos, 1)
                test.eq(out.infos[1], "info one")
            end)

            test.it("keeps has_errors=false when only warnings or info exist", function()
                local out = submit_lib.parse_lint("WARNINGS:\n  only warning\n")
                test.is_false(out.has_errors)
                test.eq(#out.warnings, 1)
            end)

            test.it("preserves the raw output", function()
                local raw = "ERRORS:\n  e1\n"
                local out = submit_lib.parse_lint(raw)
                test.eq(out.raw, raw)
            end)

            test.it("ignores lines without 2-space indentation", function()
                local out = submit_lib.parse_lint("ERRORS:\n not-indented\n  real\n")
                test.eq(#out.errors, 1)
                test.eq(out.errors[1], "real")
            end)
        end)

        test.describe("build_persistence", function()
            test.it("returns safe defaults for nil options", function()
                local p = submit_lib.build_persistence(nil)
                test.is_false(p.overlay_applied)
                test.is_false(p.published)
                test.is_false(p.fs_flushed)
                test.is_false(p.rolled_back)
                test.is_nil(p.registry_version)
                test.eq(#p.migrations_applied, 0)
            end)

            test.it("passes through supplied booleans and arrays", function()
                local p = submit_lib.build_persistence({
                    overlay_applied    = true,
                    published          = true,
                    registry_version   = 42,
                    migrations_applied = { "m1", "m2" },
                    fs_flushed         = true,
                    rolled_back        = false,
                })
                test.is_true(p.overlay_applied)
                test.is_true(p.published)
                test.eq(p.registry_version, 42)
                test.eq(#p.migrations_applied, 2)
                test.is_true(p.fs_flushed)
                test.is_false(p.rolled_back)
            end)

            test.it("coerces non-true truthy values to false", function()
                local p = submit_lib.build_persistence({
                    overlay_applied = "yes",
                    published       = 1,
                })
                test.is_false(p.overlay_applied)
                test.is_false(p.published)
            end)
        end)
    end)
end

return {
    define_tests = test.run_cases(define_tests)
}
