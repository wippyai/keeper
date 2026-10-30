local test = require("test")
local endpoints = require("endpoints")
local migrations = require("migrations")
local frontend = require("frontend")
local registry = require("registry")
local time = require("time")
local uuid = require("uuid")
local state_consts = require("state_consts")

local function synchronize_state()
    -- These traits read the asynchronous state projection. Wait for its
    -- acknowledgement of the current registry version before reading it.
    local topic = "test.context.ready." .. assert(uuid.v4())
    local replies = process.listen(topic)
    local sent, err = process.send(state_consts.PROCESS_NAMES.ORCHESTRATOR,
        state_consts.TOPICS.REGISTRY_CHANGE, {
            version = assert(registry.current_version()):id(),
            changeset = {},
            respond_to = topic,
        })
    test.is_true(sent, tostring(err))
    local timeout = time.after("30s")
    local response = channel.select({replies:case_receive(), timeout:case_receive()})
    if response.channel == timeout then error("State synchronization acknowledgement timed out") end
    test.is_true(response.value.success, tostring(response.value.error))
end

local function define_tests()
    describe("Context Tree Traits", function()
        before_all(synchronize_state)

        describe("frontend_aware tree", function()
            it("returns non-empty tree with header", function()
                local output = frontend.handler()
                test.not_nil(output)
                test.is_true(type(output) == "string")
                test.is_true(#output > 0)
                test.is_true(output:find("FRONTEND TREE") ~= nil, "header missing")
            end)

            it("lists routes and pages", function()
                local output = frontend.handler()
                test.is_true(output:find("Routes") ~= nil, "Routes section missing")
                test.is_true(output:find("Pages") ~= nil, "Pages section missing")
                test.is_true(output:find("%.vue") ~= nil, "expected at least one .vue file")
            end)
        end)

        describe("endpoints_aware tree", function()
            it("returns non-empty tree with routers and endpoints", function()
                local output = endpoints.handler()
                test.not_nil(output)
                test.is_true(type(output) == "string")
                test.is_true(#output > 0)
                test.is_true(output:find("HTTP ENDPOINTS") ~= nil, "header missing")
            end)

            it("includes at least one known router and endpoint", function()
                local output = endpoints.handler()
                test.is_true(
                    output:find("%.api[^%s]*:[^%s]+%.endpoint") ~= nil or
                    output:find("api:") ~= nil,
                    "expected at least one api endpoint entry"
                )
            end)
        end)

        describe("migrations_aware tree", function()
            it("returns non-empty tree with databases and migrations", function()
                local output = migrations.handler()
                test.not_nil(output)
                test.is_true(type(output) == "string")
                test.is_true(#output > 0)
                test.is_true(output:find("DATABASE MIGRATIONS TREE") ~= nil, "header missing")
            end)

            it("lists APPLIED / PENDING status for at least one migration", function()
                local output = migrations.handler()
                local has_status = output:find("Status: APPLIED") ~= nil
                    or output:find("Status: PENDING") ~= nil
                    or output:find("Status: UNKNOWN") ~= nil
                test.is_true(has_status, "expected at least one migration status line")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
