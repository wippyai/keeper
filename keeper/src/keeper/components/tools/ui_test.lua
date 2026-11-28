-- Unit tests for keeper.components.tools:ui via dependency injection: every
-- navigation the tool drives reaches the page with the caller's auth token.

local test = require("test")
local ui_tool = require("ui_tool")

local function fakes(opts)
    opts = opts or {}
    local calls = { mint_token = 0, open = 0, goto_url = 0 }
    local last = {}
    local deps = {
        mint_token = function()
            calls.mint_token = calls.mint_token + 1
            if opts.mint_fail then return nil, "No security context available" end
            return "caller-token", nil
        end,
        ui = {
            open = function(args)
                calls.open = calls.open + 1
                last.open = args
                return { success = true, url = "http://host/" }
            end,
            goto_url = function(url, wait_until, goto_opts)
                calls.goto_url = calls.goto_url + 1
                last.goto_url = { url = url, wait_until = wait_until, opts = goto_opts }
                return { success = true, url = url }
            end,
        },
    }
    return deps, calls, last
end

local function define_tests()
    test.describe("keeper.components.tools:ui — navigation auth", function()
        test.it("opens a component with the caller's token", function()
            local deps, calls, last = fakes()
            local res, err = ui_tool.run(deps, { action = "open", component_id = "@wippy/app-keeper" })
            test.is_nil(err)
            test.not_nil(res)
            test.eq(calls.mint_token, 1)
            test.eq(last.open.auth_token, "caller-token")
        end)

        test.it("navigates goto_url with the caller's token", function()
            local deps, calls, last = fakes()
            local res, err = ui_tool.run(deps, { action = "goto_url", url = "http://host/c/app:main/", wait_until = "load" })
            test.is_nil(err)
            test.eq(res.url, "http://host/c/app:main/")
            test.eq(calls.mint_token, 1)
            test.eq(last.goto_url.url, "http://host/c/app:main/")
            test.eq(last.goto_url.wait_until, "load")
            test.eq(last.goto_url.opts.auth_token, "caller-token")
        end)

        test.it("accepts the goto alias with the same auth", function()
            local deps, _, last = fakes()
            local _, err = ui_tool.run(deps, { action = "goto", url = "http://host/" })
            test.is_nil(err)
            test.eq(last.goto_url.opts.auth_token, "caller-token")
        end)

        test.it("mints once for a sequence of bound navigations", function()
            local deps, calls = fakes()
            local active_binding
            deps.binding = "first"
            deps.ui.goto_url = function(_, _, opts)
                if opts.auth_token then active_binding = opts.binding end
                if opts.binding ~= active_binding then return { needs_caller_token = true } end
                return { success = true }
            end
            for i = 1, 30 do
                local result = ui_tool.run(deps, { action = "goto", url = "http://host/" })
                test.is_true(result.success)
            end
            test.eq(calls.mint_token, 1)
            deps.binding = "second"
            ui_tool.run(deps, { action = "goto", url = "http://host/" })
            test.eq(calls.mint_token, 2)
        end)

        test.it("refuses goto_url without a security context", function()
            local deps, calls = fakes({ mint_fail = true })
            local res, err = ui_tool.run(deps, { action = "goto_url", url = "http://host/" })
            test.is_nil(res)
            test.contains(tostring(err), "No security context available")
            test.eq(calls.goto_url, 0)
        end)

        test.it("requires a url for goto_url", function()
            local deps, calls = fakes()
            local res, err = ui_tool.run(deps, { action = "goto_url" })
            test.is_nil(res)
            test.contains(tostring(err), "url is required")
            test.eq(calls.mint_token, 0)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
