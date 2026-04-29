local test = require("test")
local funcs = require("funcs")

local NODE_ID = "keeper.develop.integrate.pipeline:execute_handler"

local function call_node(args)
    return funcs.new():call(NODE_ID, args or {})
end

local function define_tests()
    test.describe("keeper.develop.integrate.pipeline:execute_handler", function()
        test.it("returns handler_id, entry_ids, and result on success", function()
            local out, err = call_node({
                handler_id = "keeper.develop.integrate.handlers:env_variable_handler",
                entry_ids  = { "ns.a:VAR_ONE" },
                operation  = "up",
            })
            test.is_nil(err)
            test.not_nil(out)
            test.eq(out.handler_id, "keeper.develop.integrate.handlers:env_variable_handler")
            test.not_nil(out.result)
            test.is_nil(out.error)
            test.eq(out.result[1].id, "ns.a:VAR_ONE")
            test.is_true(out.result[1].success)
        end)

        test.it("surfaces handler error in error field, not raised", function()
            local out, err = call_node({
                handler_id = "keeper.develop.integrate.handlers:migration_handler",
                entry_ids  = { "app.fake.does_not_exist:01_missing" },
                operation  = "up",
            })
            test.is_nil(err)
            test.not_nil(out)
            test.not_nil(out.error)
            test.is_nil(out.result)
            test.eq(out.handler_id, "keeper.develop.integrate.handlers:migration_handler")
        end)

        test.it("defaults operation to up and entry_ids to empty when omitted", function()
            local out, err = call_node({
                handler_id = "keeper.develop.integrate.handlers:env_variable_handler",
            })
            test.is_nil(err)
            test.not_nil(out)
            test.not_nil(out.result)
            test.not_nil(out.entry_ids)
            test.eq(#out.entry_ids, 0)
        end)
    end)
end

return { define_tests = define_tests }
