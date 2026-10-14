local store = require("store")


local function run(options)
    local test = require("test")
    local flow = require("flow")
    local client = require("client")
    local consts = require("consts")
    local node_reader = require("node_reader")
    local data_reader = require("data_reader")
    local time = require("time")
    local sql = require("sql")
    local dialect = require("sql_dialect")
    return test.run_cases(function()
        describe("Keeper delegation through the real Dataflow runtime", function()
            it("executes the child agent instead of storing a nested control envelope", function()
                local state = assert(store.get("app.delegation:state"))
                assert(state:set("calls", 0))
                state:release()
                local c = assert(client.new())
                local id, err = flow.create()
                    :with_data({})
                    :to("invoke", "trigger")
                    :func("keeper.agents.tools:delegate", { args = {
                        agent_id = "app.delegation:agent", message = "Return the answer.", max_iterations = 2,
                    } })
                    :as("invoke")
                    :to("@success")
                    :start()
                assert(id, tostring(err))
                local ok, failure = pcall(function()
                    local status
                    for _ = 1, 150 do
                        status = c:get_status(id)
                        if status == consts.STATUS.COMPLETED_SUCCESS or status == consts.STATUS.COMPLETED_FAILURE
                            or status == consts.STATUS.CANCELLED or status == consts.STATUS.TERMINATED then break end
                        time.sleep("100ms")
                    end
                    test.eq(status, consts.STATUS.COMPLETED_SUCCESS)
                    local nodes = assert(node_reader.with_dataflow(id):all())
                    test.eq(#nodes, 2, "the function must splice in one real agent node")
                    local rows = assert(data_reader.with_dataflow(id):fetch_options({replace_references = true}):all())
                    local answered = false
                    for _, row in ipairs(rows) do
                        if row.content == "native delegated answer" then answered = true end
                    end
                    test.is_true(answered, "the child answer must be persisted")
                    local metrics = assert(store.get("app.delegation:state"))
                    local calls = metrics:get("calls")
                    metrics:release()
                    test.eq(calls, 1)
                end)
                if not ok then
                    local status = c:get_status(id)
                    if status == consts.STATUS.PENDING or status == consts.STATUS.RUNNING then
                        assert(c:cancel(id, "2s"))
                    end
                end
                local db = assert(sql.get("app:db"))
                local _, cleanup_err = dialect.execute(db, "DELETE FROM dataflows WHERE dataflow_id = ?", {id})
                db:release()
                if not ok then error(failure) end
                assert(not cleanup_err, tostring(cleanup_err))
            end)
        end)
    end)(options)
end

return { run = run }
