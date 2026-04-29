-- Unit tests for the new screenshot_ui contract via dependency injection.
--
-- The whole point of the rewrite is: a single blocking call returns the
-- captured image AND structured browser-state evidence; tool errors are
-- reserved for "no page reachable" cases. wait_for failure no longer
-- short-circuits the screenshot — that was the v17 false-positive shape
-- where the verifier reported "page never rendered" while a working PNG
-- of the same page was already on disk.
--
-- We exercise the pure logic via M.run(deps, params) instead of the
-- audited handler wrapper, so tests can swap in fake ui/scanner/helpers
-- without touching the wippy registry loader.

local test          = require("test")
local screenshot_ui = require("screenshot_ui")

local function fakes(opts)
    opts = opts or {}
    local calls = { open = 0, wait_for = 0, screenshot = 0, eval = 0,
                    mint_token = 0, scanner_get = 0 }
    local last = {}

    local deps = {
        scanner = {
            get = function(component_id)
                calls.scanner_get = calls.scanner_get + 1
                last.scanner_component = component_id
                if opts.unknown_component then return nil, "no descriptor" end
                return { component_id = component_id, path = "/components/keeper" }, nil
            end,
        },
        helpers = {
            mint_token = function(scope)
                calls.mint_token = calls.mint_token + 1
                last.token_scope = scope
                return "test-token", nil
            end,
        },
        ui = {
            open = function(args)
                calls.open = calls.open + 1
                last.open = args
                if opts.open_fail then return { success = false, error = "browser crashed" } end
                return { success = true }
            end,
            wait_for = function(selector, o)
                calls.wait_for = calls.wait_for + 1
                last.wait_for = { selector = selector, opts = o }
                if opts.wait_timeout then
                    return { success = false, error = "timeout" }
                end
                return { success = true }
            end,
            screenshot = function(args)
                calls.screenshot = calls.screenshot + 1
                last.screenshot = args
                if opts.shot_fail then return { success = false, error = "disk full" } end
                return { success = true, url = "/previews/test.png" }
            end,
            eval = function(_js)
                calls.eval = calls.eval + 1
                if opts.eval_fail then return { success = false, error = "eval crashed" } end
                return { success = true, value = opts.eval_value or {
                    [".rows-list"] = { present = true, visible = true, text_preview = "row #1" },
                } }
            end,
        },
    }

    return deps, calls, last
end

local function define_tests()
    test.describe("keeper.components.tools:screenshot_ui — refactored contract", function()
        test.it("rejects missing component_id with a tool error", function()
            local deps = fakes()
            local res, err = screenshot_ui.run(deps, {})
            test.is_nil(res)
            test.not_nil(err)
            test.is_true(tostring(err):find("component_id is required") ~= nil)
        end)

        test.it("returns tool error when ui.open fails (no page reachable)",
            function()
                local deps = fakes({ open_fail = true })
                local res, err = screenshot_ui.run(deps, { component_id = "@wippy/app-keeper" })
                test.is_nil(res)
                test.not_nil(err)
                test.is_true(tostring(err):find("ui open failed") ~= nil)
            end)

        test.it("returns tool error when scanner cannot resolve the component",
            function()
                local deps = fakes({ unknown_component = true })
                local res, err = screenshot_ui.run(deps, { component_id = "@wippy/missing" })
                test.is_nil(res)
                test.not_nil(err)
                test.is_true(tostring(err):find("component not found") ~= nil)
            end)

        test.it("returns image with no wait_for / no selectors when neither passed",
            function()
                local deps, calls = fakes()
                local res, err = screenshot_ui.run(deps, {
                    component_id = "@wippy/app-keeper",
                    route        = "/probe-v17",
                })
                test.is_nil(err)
                test.not_nil(res)
                test.eq(res.screenshot_url, "/previews/test.png")
                test.eq(res.route, "/probe-v17")
                test.is_nil(res.wait_for, "wait_for absent when caller did not pass it")
                test.is_nil(res.selectors, "selectors absent when assert_selectors empty")
                test.eq(calls.wait_for, 0)
                test.eq(calls.eval, 0)
                test.eq(calls.screenshot, 1)
                test.eq(calls.mint_token, 1)
            end)

        test.it("sanitizes explicit screenshot filenames before calling the UI runner",
            function()
                local deps, _, last = fakes()
                local res, err = screenshot_ui.run(deps, {
                    component_id = "@wippy/app-keeper",
                    name = "../../Registry View.PNG",
                })
                test.is_nil(err)
                test.not_nil(res)
                if not last.screenshot then error("screenshot call missing") end
                test.is_true(last.screenshot.name:match("^Registry_View%-%x+$") ~= nil,
                    "screenshot filename should include safe stem plus opaque seed")
                test.eq(last.screenshot.name, res.filename)
                test.eq(last.screenshot.request_id, "screenshots")
            end)

        test.it("captures screenshot AND reports wait_for outcome when wait_for resolves",
            function()
                local deps, calls, last = fakes()
                local res, err = screenshot_ui.run(deps, {
                    component_id    = "@wippy/app-keeper",
                    wait_for        = ".rows-list",
                    wait_timeout_ms = 5000,
                })
                test.is_nil(err)
                test.not_nil(res)
                test.not_nil(res.screenshot_url, "image must always be present on success")
                test.not_nil(res.wait_for)
                test.eq(res.wait_for.selector, ".rows-list")
                test.is_true(res.wait_for.observed,
                    "wait_for.observed must reflect ui.wait_for success")
                test.eq(res.wait_for.source, "probe")
                test.eq(res.wait_for.timeout_ms, 5000)
                test.is_nil(res.wait_for.error)
                test.eq(calls.wait_for, 0,
                    "frame-aware probe should satisfy visible selectors before slow outer-page wait")
                test.is_nil(last.wait_for)
            end)

        test.it("falls back to ui.wait_for when frame-aware probe misses",
            function()
                local deps, calls, last = fakes({
                    eval_value = {
                        [".rows-list"] = { present = false, visible = false },
                    },
                })
                local res, err = screenshot_ui.run(deps, {
                    component_id    = "@wippy/app-keeper",
                    wait_for        = ".rows-list",
                    wait_timeout_ms = 5000,
                })
                test.is_nil(err)
                test.not_nil(res)
                test.is_true(res.wait_for.observed)
                test.eq(calls.wait_for, 1)
                if not last.wait_for then error("wait_for call missing") end
                test.eq(last.wait_for.opts.timeout, 5000)
            end)

        test.it("STILL captures screenshot when wait_for times out (the v17 fix)",
            function()
                -- This is the regression. Old contract returned nil + error
                -- here and the agent never saw what was on screen. New
                -- contract reports observed=false but keeps the image so
                -- the agent can verdict on actual evidence.
                local deps, calls = fakes({
                    wait_timeout = true,
                    eval_value = {
                        [".rows-list"] = { present = false, visible = false },
                    },
                })
                local res, err = screenshot_ui.run(deps, {
                    component_id    = "@wippy/app-keeper",
                    route           = "/probe-v17",
                    wait_for        = ".rows-list",
                    wait_timeout_ms = 8000,
                })
                test.is_nil(err, "wait_for timeout must NOT fail the tool")
                test.not_nil(res)
                test.not_nil(res.screenshot_url,
                    "image must be present even when wait_for never resolved")
                test.not_nil(res.wait_for)
                test.is_false(res.wait_for.observed,
                    "wait_for.observed must be false on timeout")
                test.eq(res.wait_for.timeout_ms, 8000)
                test.eq(res.wait_for.error, "timeout")
                test.eq(calls.screenshot, 1,
                    "screenshot must still be taken after wait_for times out")
            end)

        test.it("populates selectors[] when assert_selectors passed", function()
            local deps, calls = fakes()
            local res, err = screenshot_ui.run(deps, {
                component_id     = "@wippy/app-keeper",
                route            = "/probe-v17",
                assert_selectors = { ".rows-list", "h1" },
            })
            test.is_nil(err)
            test.not_nil(res)
            test.not_nil(res.selectors)
            test.not_nil(res.selectors[".rows-list"])
            test.is_true(res.selectors[".rows-list"].visible)
            test.eq(res.selectors[".rows-list"].text_preview, "row #1")
            test.eq(calls.eval, 1, "one batched eval for the whole selector list")
        end)

        test.it("omits selectors when assert_selectors is empty/missing",
            function()
                local deps, calls = fakes()
                local res, err = screenshot_ui.run(deps, {
                    component_id     = "@wippy/app-keeper",
                    assert_selectors = {},
                })
                test.is_nil(err)
                test.is_nil(res.selectors,
                    "empty assert_selectors must not invoke eval")
                test.eq(calls.eval, 0)
            end)

        test.it("returns tool error when screenshot capture itself fails",
            function()
                local deps = fakes({ shot_fail = true })
                local res, err = screenshot_ui.run(deps, { component_id = "@wippy/app-keeper" })
                test.is_nil(res)
                test.not_nil(err)
                test.is_true(tostring(err):find("screenshot failed") ~= nil)
            end)

        test.it("captures even when assert_selectors eval errors — selectors becomes nil",
            function()
                -- DOM probing is opt-in evidence. If eval blows up, the
                -- screenshot result still ships; we just lose the structured
                -- selectors map. Tool does not error.
                local deps, calls = fakes({ eval_fail = true })
                local res, err = screenshot_ui.run(deps, {
                    component_id     = "@wippy/app-keeper",
                    assert_selectors = { ".rows-list" },
                })
                test.is_nil(err)
                test.not_nil(res)
                test.not_nil(res.screenshot_url)
                test.is_nil(res.selectors,
                    "failed eval must downgrade to no selectors map, not error")
                test.eq(calls.screenshot, 1)
            end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
