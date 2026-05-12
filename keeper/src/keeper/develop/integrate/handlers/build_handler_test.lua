local funcs = require("funcs")
local test = require("test")
local subject = require("subject")

local HANDLER_ID = "keeper.develop.integrate.handlers:build_handler"

local function call_handler(args)
    return funcs.new():call(HANDLER_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.integrate.handlers:build_handler", function()
        test.it("returns empty result for empty entry_ids AND empty fs_paths", function()
            local result, err = call_handler({
                operation = "up", entry_ids = {}, fs_paths = {},
            })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result, 0)
        end)

        test.it("down operation with only fs_paths returns empty rows (no entries to unwind)",
            function()
                -- Regression: down path must not blow up when the only input
                -- is a fs_paths list. build_handler rows are keyed to entry
                -- ids on the down direction (there's nothing to record-only
                -- for a raw fs edit), so an empty result is the correct
                -- non-error response.
                local result, err = call_handler({
                    operation = "down",
                    entry_ids = {},
                    fs_paths  = {
                        "frontend/applications/keeper/src/pages/probe-v11.vue",
                    },
                })
                test.is_nil(err)
                test.not_nil(result)
                test.eq(#result, 0,
                    "down path has no per-entry record-only rows for fs-only input")
            end)

        test.it("down operation returns a record-only row per entry", function()
            local result, err = call_handler({
                operation = "down",
                entry_ids = { "app:nonexistent_view" },
            })
            test.is_nil(err)
            test.eq(#result, 1)
            test.is_true(result[1].success)
            test.eq(result[1].data.status, "noop")
        end)

        test.it("resolves only file-backed source paths from entry.data", function()
            local path = subject.__test.source_path({
                source = "top-level-wrong.vue",
                data = { source = "file://frontend/applications/keeper/src/pages/right.vue" },
            })
            test.eq(path, "frontend/applications/keeper/src/pages/right.vue")

            local raw = subject.__test.source_path({
                data = { source = "<template>not a path</template>" },
            })
            test.is_nil(raw, "raw source content must not be treated as a filesystem path")
        end)

        test.it("does not send legacy template.jet sources to component builds", function()
            local path = subject.__test.source_path({
                kind = "template.jet",
                meta = { type = "view.page", name = "approval" },
                data = {
                    source = "file://approval.jet",
                    set = "keeper.gov.hil.views:templates",
                    data_func = "keeper.gov.hil.views:approval.data",
                },
            })
            test.is_nil(path,
                "Jet page source is rendered by wippy/views and must not trigger a Vue component build")
        end)

        test.it("prefers full build error_output over the truncated build error", function()
            local msg = subject.__test.build_error({
                error = "exit 1: stack tail only",
                error_output = "[stderr] Could not resolve \"../pages/missing.vue\" from \"src/router/index.ts\"",
            })
            test.is_true(msg:find("Could not resolve", 1, true) ~= nil,
                "build handler must surface the actionable bundler line")
            test.is_true(msg:find("stack tail only", 1, true) == nil,
                "truncated final.error should not hide error_output")
        end)

        test.it("surfaces a structured error when the entry cannot be loaded", function()
            local result, err = call_handler({
                operation = "up",
                entry_ids = { "nope:does_not_exist" },
            })
            test.is_nil(result)
            test.not_nil(err)
            local err_str = tostring(err or "")
            test.is_true(err_str:find("build_handler", 1, true) ~= nil or
                err_str:find("nope:does_not_exist", 1, true) ~= nil,
                "error should mention handler or missing id; got: " .. err_str)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
