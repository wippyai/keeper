local test = require("test")
local api_test = require("api_test")
local http_client = require("http_client")
local json = require("json")
local process = require("process")
local channel = require("channel")
local time = require("time")

local topic_count = 0

-- Each case listens on its own topic: a worker whose client disconnected outlives the case.
local function listen_steps()
    topic_count = topic_count + 1
    local topic = "hub.install.step." .. tostring(topic_count)
    return process.listen(topic), topic
end

local URL = api_test.endpoint("/api/keeper-test/hub/install")

local function post(args, topic, timeout)
    args.observer = process.pid()
    args.topic = topic
    return http_client.post(URL, {
        headers = { ["Content-Type"] = "application/json" },
        body = json.encode(args),
        timeout = timeout,
    })
end

local function next_step(steps)
    local timeout = time.after("5s")
    local result = channel.select({ steps:case_receive(), timeout:case_receive() })
    if result.channel == timeout then return nil end
    return result.value
end

local function assert_steps(steps, expected)
    for _, step in ipairs(expected) do
        test.eq(next_step(steps), step)
    end
end

local INSTALL_STEPS = { "apply_started", "apply_done", "migrations", "bootloaders" }

local function define_tests()
    test.describe("Hub install request lifetime", function()
        test.it("finishes migrations and bootloaders after the client disconnects during apply", function()
            local steps, topic = listen_steps()
            local _, client_err = post({ apply_for = "800ms" }, topic, "200ms")
            test.not_nil(client_err)
            assert_steps(steps, INSTALL_STEPS)
        end)

        test.it("answers a connected client with the install payload", function()
            local steps, topic = listen_steps()
            local res, client_err = post({}, topic, "5s")
            test.is_nil(client_err)
            assert_steps(steps, INSTALL_STEPS)
            test.eq(res.status_code, 200)
            test.contains(res.headers["Content-Type"] or res.headers["content-type"], "application/json")
            local body = json.decode(res.body)
            test.eq(body.success, true)
            test.eq(body.operation_id, "op-1")
            test.contains(res.body, '"warnings":' .. json.encode({}))
        end)

        test.it("keeps the caller's actor and scope in the install", function()
            local _, topic = listen_steps()
            local res, client_err = post({}, topic, "5s")
            test.is_nil(client_err)
            local body = json.decode(res.body)
            test.eq(body.actor_option, "hub-install-fixture")
            test.eq(body.actor, "hub-install-fixture")
            test.eq(body.can_report, true)
        end)

        test.it("answers a service error with its status, code and details", function()
            local _, topic = listen_steps()
            local res, client_err = post({ fail = true }, topic, "5s")
            test.is_nil(client_err)
            test.eq(res.status_code, 500)
            local body = json.decode(res.body)
            test.eq(body.success, false)
            test.eq(body.code, "MIGRATIONS_FAILED")
            test.eq(body.error, "migrations failed")
            test.eq(body.details.baseline_version, 7)
        end)

        test.it("answers an unreadable body with BAD_REQUEST", function()
            local res, client_err = http_client.post(URL, {
                headers = { ["Content-Type"] = "application/json" },
                body = "{not json",
                timeout = "5s",
            })
            test.is_nil(client_err)
            test.eq(res.status_code, 400)
            test.eq(json.decode(res.body).code, "BAD_REQUEST")
        end)

        test.it("rejects an install while another one runs, even with its client gone, then admits the next", function()
            local steps, topic = listen_steps()
            local _, client_err = post({ apply_for = "800ms" }, topic, "200ms")
            test.not_nil(client_err)
            test.eq(next_step(steps), "apply_started")

            local rejected, rejected_err = post({}, topic, "5s")
            test.is_nil(rejected_err)
            test.eq(rejected.status_code, 409)
            test.eq(json.decode(rejected.body).code, "CONFLICT")

            assert_steps(steps, { "apply_done", "migrations", "bootloaders" })

            local admitted, admitted_err
            for _ = 1, 20 do
                admitted, admitted_err = post({}, topic, "5s")
                if admitted_err or admitted.status_code ~= 409 then break end
                time.sleep("50ms")
            end
            test.is_nil(admitted_err)
            test.eq(admitted.status_code, 200)
            assert_steps(steps, INSTALL_STEPS)
        end)

        test.it("runs a dry run alongside an install", function()
            local steps, topic = listen_steps()
            local _, client_err = post({ apply_for = "800ms" }, topic, "200ms")
            test.not_nil(client_err)
            test.eq(next_step(steps), "apply_started")

            local dry, dry_err = post({ dry_run = true }, topic, "5s")
            test.is_nil(dry_err)
            test.eq(dry.status_code, 200)
            local seen = {}
            for _ = 1, 7 do
                seen[#seen + 1] = next_step(steps)
            end
            test.contains(table.concat(seen, ","), "dry_run")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
