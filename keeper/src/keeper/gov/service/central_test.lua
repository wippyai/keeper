local test = require("test")
local central = require("central")
local consts = require("gov_consts")

local function now()
    return { unix = function() return 100 end }
end

local function command(payload, from)
    return {
        topic = function() return consts.TOPICS.COMMANDS end,
        payload = function() return { data = function() return payload end } end,
        from = function() return from end,
    }
end

local function exit(worker, result)
    return { kind = "exit", from = worker, result = result }
end

local function run_steps(steps)
    local inbox = { case_receive = function(self) return self end }
    local events = { case_receive = function(self) return self end }
    local sent, spawned = {}, {}
    local selects = 0
    local process = {
        event = { CANCEL = "cancel", EXIT = "exit" },
        registry = { register = function() return true end },
        inbox = function() return inbox end,
        events = function() return events end,
        spawn_monitored = function(worker, host, payload)
            spawned[#spawned + 1] = { worker = worker, host = host, payload = payload }
            return "worker-" .. tostring(#spawned)
        end,
        send = function(to, topic, body)
            sent[#sent + 1] = { to = to, topic = topic, body = body }
            return true
        end,
    }
    local channel = {
        select = function()
            selects = selects + 1
            local step = table.remove(steps, 1)
            if not step then return { ok = false } end
            return { ok = true, channel = step.channel == "inbox" and inbox or events, value = step.value }
        end,
    }
    local registry = {
        current_version = function()
            -- Match the successful worker result so this focused coordinator
            -- test does not publish a real version-change notification.
            return { id = function() return "version-after" end }
        end,
    }
    local result = central._run_with({ process = process, channel = channel, time = { now = now }, registry = registry })
    return result, sent, spawned, selects
end

local function apply(id, respond_to)
    return {
        id = id,
        operation = consts.OPERATIONS.APPLY_CHANGES,
        respond_to = respond_to,
        changeset = {
            { kind = consts.REGISTRY_OPERATIONS.UPDATE, entry = { id = "app:test" } },
        },
        options = {},
    }
end

local function define_tests()
    test.describe("gov.service.central drain", function()
        test.it("delivers the success reply once when cancel arrives before worker exit", function()
            local result, sent, spawned = run_steps({
                { channel = "inbox", value = command(apply("original", "reply.original"), "caller.original") },
                { channel = "events", value = { kind = "cancel" } },
                { channel = "events", value = exit("worker-1", { value = { success = true, version = "version-after" } }) },
            })
            test.eq(result.status, "completed")
            test.eq(#spawned, 1)
            test.eq(spawned[1].worker, "keeper.gov.service:changeset")
            test.eq(spawned[1].payload.changeset[1].entry.id, "app:test")
            test.eq(#sent, 1)
            test.eq(sent[1].to, "caller.original")
            test.eq(sent[1].topic, "reply.original")
            test.eq(sent[1].body.request_id, "original")
            test.is_true(sent[1].body.success)
        end)

        test.it("routes a worker error once to the original reply channel while draining", function()
            local _, sent = run_steps({
                { channel = "inbox", value = command(apply("original", "reply.original"), "caller.original") },
                { channel = "events", value = { kind = "cancel" } },
                { channel = "events", value = exit("worker-1", { error = "worker failed" }) },
            })
            test.eq(#sent, 1)
            test.eq(sent[1].to, "caller.original")
            test.eq(sent[1].topic, "reply.original")
            test.eq(sent[1].body.request_id, "original")
            test.is_false(sent[1].body.success)
            test.eq(sent[1].body.message, "Operation failed")
            test.eq(sent[1].body.timestamp, 100)
            test.is_nil(sent[1].body.error)
            test.is_nil(sent[1].body.changeset)
            test.is_nil(sent[1].body.details)
            test.is_nil(sent[1].body.warnings)
        end)

        test.it("returns promptly when cancellation has no pending worker", function()
            local result, sent, _, selects = run_steps({
                { channel = "events", value = { kind = "cancel" } },
            })
            test.eq(result.status, "completed")
            test.eq(#sent, 0)
            test.eq(selects, 1)
        end)

        test.it("rejects a second mutation while draining the first worker", function()
            local _, sent, spawned = run_steps({
                { channel = "inbox", value = command(apply("original", "reply.original"), "caller.original") },
                { channel = "events", value = { kind = "cancel" } },
                { channel = "inbox", value = command(apply("busy", "reply.busy"), "caller.busy") },
                { channel = "events", value = exit("worker-1", { value = { success = true, version = "version-after" } }) },
            })
            test.eq(#spawned, 1)
            test.eq(#sent, 2)
            test.eq(sent[1].to, "caller.busy")
            test.eq(sent[1].topic, "reply.busy")
            test.is_false(sent[1].body.success)
            test.is_true(sent[1].body.message:find(consts.ERRORS.OPERATION_IN_PROGRESS, 1, true) ~= nil)
            test.eq(sent[2].to, "caller.original")
            test.eq(sent[2].topic, "reply.original")
            test.is_true(sent[2].body.success)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
