local test = require("test")
local diff_render = require("diff_render")

local function define_tests()
    describe("diff_render helpers", function()
        describe("language_from_kind", function()
            it("maps function.lua/library.lua to lua", function()
                test.eq(diff_render.language_from_kind("function.lua"), "lua")
                test.eq(diff_render.language_from_kind("library.lua"), "lua")
                test.eq(diff_render.language_from_kind("process.lua"), "lua")
            end)

            it("maps migration to lua", function()
                test.eq(diff_render.language_from_kind("migration"), "lua")
            end)

            it("maps template.jet to html", function()
                test.eq(diff_render.language_from_kind("template.jet"), "html")
            end)

            it("maps other template.* to html", function()
                test.eq(diff_render.language_from_kind("template.mustache"), "html")
            end)

            it("returns plaintext for unknown", function()
                test.eq(diff_render.language_from_kind("custom.kind"), "plaintext")
                test.eq(diff_render.language_from_kind("http.endpoint"), "plaintext")
            end)

            it("returns plaintext for nil or empty", function()
                test.eq(diff_render.language_from_kind(nil), "plaintext")
                test.eq(diff_render.language_from_kind(""), "plaintext")
            end)
        end)

        describe("detect_fs_language", function()
            it("maps .lua to lua", function()
                test.eq(diff_render.detect_fs_language("src/app/main.lua"), "lua")
            end)

            it("maps .vue to html", function()
                test.eq(diff_render.detect_fs_language("components/app.vue"), "html")
            end)

            it("maps .ts to typescript", function()
                test.eq(diff_render.detect_fs_language("src/app.ts"), "typescript")
            end)

            it("maps .js to javascript", function()
                test.eq(diff_render.detect_fs_language("src/app.js"), "javascript")
            end)

            it("maps .json to json", function()
                test.eq(diff_render.detect_fs_language("package.json"), "json")
            end)

            it("maps .yaml and .yml to yaml", function()
                test.eq(diff_render.detect_fs_language("_index.yaml"), "yaml")
                test.eq(diff_render.detect_fs_language("config.yml"), "yaml")
            end)

            it("maps .css to css", function()
                test.eq(diff_render.detect_fs_language("app.css"), "css")
            end)

            it("maps .md to markdown", function()
                test.eq(diff_render.detect_fs_language("README.md"), "markdown")
            end)

            it("returns plaintext for unknown extension", function()
                test.eq(diff_render.detect_fs_language("notes.txt"), "plaintext")
                test.eq(diff_render.detect_fs_language("Makefile"), "plaintext")
            end)

            it("returns plaintext for non-string input", function()
                test.eq(diff_render.detect_fs_language(nil), "plaintext")
                test.eq(diff_render.detect_fs_language(42), "plaintext")
            end)
        end)

        describe("validate_params", function()
            it("returns nil on valid registry params", function()
                test.is_nil(diff_render.validate_params({
                    changeset_id = "cs-1",
                    target = "app.users:svc",
                    part = "definition",
                }))
            end)

            it("returns nil when part omitted", function()
                test.is_nil(diff_render.validate_params({
                    changeset_id = "cs-1",
                    target = "app.users:svc",
                }))
            end)

            it("treats empty-string part as unset", function()
                test.is_nil(diff_render.validate_params({
                    changeset_id = "cs-1",
                    target = "app.users:svc",
                    part = "",
                }))
            end)

            it("rejects missing changeset_id", function()
                local err = diff_render.validate_params({ target = "x" })
                test.eq(err.code, diff_render.ERR.BAD_REQUEST)
                test.is_true(err.message:find("workspace", 1, true) ~= nil)
            end)

            it("rejects empty changeset_id", function()
                local err = diff_render.validate_params({ changeset_id = "", target = "x" })
                test.eq(err.code, diff_render.ERR.BAD_REQUEST)
            end)

            it("rejects missing target", function()
                local err = diff_render.validate_params({ changeset_id = "cs-1" })
                test.eq(err.code, diff_render.ERR.BAD_REQUEST)
                test.is_true(err.message:find("target", 1, true) ~= nil)
            end)

            it("rejects empty target", function()
                local err = diff_render.validate_params({ changeset_id = "cs-1", target = "" })
                test.eq(err.code, diff_render.ERR.BAD_REQUEST)
            end)

            it("rejects non-table params", function()
                local err = diff_render.validate_params(nil)
                test.eq(err.code, diff_render.ERR.BAD_REQUEST)
                test.is_true(err.message:find("params", 1, true) ~= nil)
            end)

            it("rejects invalid part value", function()
                local err = diff_render.validate_params({
                    changeset_id = "cs-1",
                    target = "x",
                    part = "bogus",
                })
                test.eq(err.code, diff_render.ERR.BAD_REQUEST)
                test.is_true(err.message:find("invalid part", 1, true) ~= nil)
            end)
        end)

        describe("ERR constants", function()
            it("exposes bad_request/not_found/internal codes", function()
                test.eq(diff_render.ERR.BAD_REQUEST, "bad_request")
                test.eq(diff_render.ERR.NOT_FOUND, "not_found")
                test.eq(diff_render.ERR.INTERNAL, "internal")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
