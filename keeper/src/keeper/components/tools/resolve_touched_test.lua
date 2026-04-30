local test = require("test")
local funcs = require("funcs")

local TOOL_ID = "keeper.components.tools:resolve_touched"

local function call(params: unknown)
    local executor, err = funcs.new()
    if err then error("funcs.new failed: " .. tostring(err)) end
    local payload, call_err = executor:call(TOOL_ID, params)
    if call_err then return nil, tostring(call_err) end
    if payload == nil then return nil, nil end
    if type(payload) == "table" and payload.data then
        return payload:data()
    end
    return payload
end

local function define_tests()
    describe("resolve_touched", function()
        it("returns empty list when paths is missing", function()
            local result, err = call({})
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result.components, 0)
        end)

        it("returns empty list for non-frontend paths", function()
            local result, err = call({ paths = { "src/keeper/consts.lua", "README.md" } })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result.components, 0)
        end)

        it("does not resolve module-owned keeper app host paths as editable", function()
            local result, err = call({
                paths = { "frontend/applications/keeper/src/app.ts" },
            })
            test.is_nil(err)
            test.not_nil(result)
            test.eq(#result.components, 0)
        end)

        it("deduplicates when multiple paths land in the same component", function()
            local result, err = call({
                paths = {
                    "plugins/git/frontend/applications/git/src/app.ts",
                    "plugins/git/frontend/applications/git/src/app/app.vue",
                    "plugins/git/frontend/applications/git/src/pages/git.vue",
                },
            })
            test.is_nil(err)
            test.not_nil(result)
            -- Three paths all map to the same local plugin app.
            test.eq(#result.components, 1)
        end)

        it("normalizes ./ prefix on inputs", function()
            local result, err = call({
                paths = { "./plugins/git/frontend/applications/git/src/app.ts" },
            })
            test.is_nil(err)
            test.not_nil(result)
            test.is_true(#result.components >= 1)
        end)

        it("resolves local-module frontend applications", function()
            local result, err = call({
                paths = { "plugins/git/frontend/applications/git/src/pages/git.vue" },
            })
            test.is_nil(err)
            test.not_nil(result)
            test.is_true(#result.components >= 1)
            for _, id in ipairs(result.components) do
                test.eq(type(id), "string")
                test.is_true(#id > 0)
            end
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
