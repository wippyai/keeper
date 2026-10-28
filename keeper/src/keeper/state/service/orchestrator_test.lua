local test = require("test")
local orchestrator = require("orchestrator")
local consts = require("consts")
local registry = require("registry")
local uuid = require("uuid")
local reconcile = require("reconcile")
local state_ops = require("state_ops")
local state_reader = require("state_reader")
local materialize = require("materialize")
local engine = require("engine")
local cs_client = require("cs_client")
local cs_consts = require("cs_consts")
local cs_repo = require("cs_repo")

local mocked = {}
local function mock(path, replacement)
    test.mock(path, replacement)
    mocked[#mocked + 1] = path
end

local function restore()
    for i = #mocked, 1, -1 do test.restore_mock(mocked[i]) end
    mocked = {}
end

local function message(topic, payload, from)
    return {
        topic = function() return topic end,
        payload = function() return { data = function() return payload end } end,
        from = function() return from or "observer" end,
    }
end

local function change(version, opts)
    opts = opts or {}
    return message(consts.TOPICS.REGISTRY_CHANGE, {
        version = version,
        changeset = opts.changeset or { { kind = "entry.create", entry = { id = "test:entry" } } },
        is_version_operation = opts.is_version_operation,
        respond_to = "reply." .. tostring(version),
    })
end

local function run_steps(steps, worker)
    local inbox = { case_receive = function(self) return self end }
    local events = { case_receive = function(self) return self end }
    local spawned, sent = {}, {}
    mock("process.pid", function() return "orchestrator-test" end)
    mock("process.registry", { register = function() return true end })
    mock("process.inbox", function() return inbox end)
    mock("process.events", function() return events end)
    mock("process.spawn_monitored", function(id, host, args)
        local pid = "worker-" .. tostring(#spawned + 1)
        local result, err
        if worker then
            result, err = worker(id, args)
            if err then return nil, err end
        else
            result = { success = true, version = args and args.version or registry.current_version():id() }
        end
        spawned[#spawned + 1] = { id = id, args = args, pid = pid, result = result }
        return pid
    end)
    mock("process.send", function(to, topic, body)
        sent[#sent + 1] = { to = to, topic = topic, body = body }
        return true
    end)
    mock("process.terminate", function() return true end)
    mock("channel.select", function()
        local step = table.remove(steps, 1)
        if not step then return { channel = events, value = { kind = process.event.CANCEL } } end
        local value = step(spawned, sent)
        if value.worker then
            local w = spawned[value.worker]
            if not w then error("expected worker " .. tostring(value.worker)) end
            return { channel = events, value = {
                kind = process.event.EXIT, from = w.pid, result = { value = value.result or w.result },
            } }
        end
        return { channel = inbox, value = value }
    end)
    local result = orchestrator.run()
    restore()
    return result, spawned, sent
end

local function reflected(entry_id)
    local reader, err = state_reader.for_branch("main")
    test.is_nil(err)
    local rows, read_err = reader:with_entries(entry_id):include_deleted():include_chunks():all()
    test.is_nil(read_err)
    test.eq(#rows, 1)
    return rows[1]
end

local function startup_change(entry)
    local materialized, err = materialize.entry(entry)
    test.is_nil(err)
    local cmd = materialize.to_set_command(materialized, "main")
    local _, set_err = state_ops.apply_commands({ cmd })
    test.is_nil(set_err)
    local _, delete_err = state_ops.apply_commands({ materialize.to_delete_command(entry.id, "main") })
    test.is_nil(delete_err)
    local version
    local result, spawned, sent = run_steps({
        function()
            local snapshot, snap_err = registry.snapshot()
            test.is_nil(snap_err)
            local changes = snapshot:changes()
            changes:create(entry)
            local committed, commit_err = changes:apply()
            test.is_nil(commit_err)
            version = committed:id()
            return change(version, { changeset = { { kind = "entry.create", entry = entry } } })
        end,
        function() return { worker = 1 } end,
        function(workers)
            if #workers > 1 then return { worker = 2 } end
            return message(consts.TOPICS.COMMANDS, { operation = consts.OPERATIONS.GET_STATE })
        end,
    }, function(id, args)
        test.eq(id, "keeper.state.service:reconcile")
        return reconcile.run(args)
    end)
    return result, spawned, sent, version
end

local function define_tests()
    describe("State orchestrator registration", function()
        test.after_each(function()
            test.restore_mock("process.registry")
            test.restore_mock("process.pid")
        end)

        it("returns the PID error before registering", function()
            test.mock("process.pid", function()
                return nil, "PID unavailable"
            end)
            local registered = false
            test.mock("process.registry", {
                register = function()
                    registered = true
                    error("registration requires a PID")
                end,
            })

            local data, err = orchestrator.run()

            test.is_nil(data)
            test.eq(err, "PID unavailable")
            test.is_false(registered)
        end)

        it("registers the PID without a scope argument", function()
            test.mock("process.pid", function()
                return "test-pid", nil
            end)
            local registration = {}
            test.mock("process.registry", {
                register = function(...)
                    registration = { count = select("#", ...), name = select(1, ...), pid = select(2, ...) }
                    error("registration captured")
                end,
            })

            local ok, err = pcall(orchestrator.run)

            test.is_false(ok)
            test.is_true(tostring(err):find("registration captured", 1, true) ~= nil)
            test.eq(registration.name, consts.PROCESS_NAMES.ORCHESTRATOR)
            test.eq(registration.pid, "test-pid")
            test.eq(registration.count, 2)
        end)
    end)

    describe("State reconciliation registry changes", function()
        local entry
        local workspace
        test.before_each(function()
            entry = {
                id = "test.reflection:entry_" .. uuid.v4():gsub("-", ""),
                kind = "registry.entry",
                data = { value = 42 },
            }
        end)
        test.after_each(function()
            restore()
            if workspace then
                local _, drop_err = cs_client.drop({ changeset_id = workspace.changeset_id })
                test.is_nil(drop_err)
                workspace = nil
            end
            local snapshot, snap_err = registry.snapshot()
            test.is_nil(snap_err)
            local changes = snapshot:changes()
            local entries, read_err = snapshot:entries()
            test.is_nil(read_err)
            for _, existing in ipairs(entries) do
                if existing.id == entry.id then
                    changes:delete(entry.id)
                    local _, apply_err = changes:apply()
                    test.is_nil(apply_err)
                    break
                end
            end
        end)

        it("reflects a registry commit observed before startup reconciliation completes", function()
            local _, spawned, sent, version = startup_change(entry)
            local row = reflected(entry.id)
            test.eq(row.deleted, 0)
            test.eq(row.kind, entry.kind)
            local live, get_err = registry.get(entry.id)
            test.is_nil(get_err)
            local expected, mat_err = materialize.entry(live)
            test.is_nil(mat_err)
            test.eq(row.chunks[1].content, expected.definition)
            test.eq(#spawned, 2)
            test.eq(#sent, 1)
            test.is_true(sent[1].body.success)
            test.eq(sent[1].body.version, version)
        end)

        it("records a workspace delete after a registry commit during startup reconciliation", function()
            startup_change(entry)
            local open_err
            workspace, open_err = cs_client.create({ title = "Delete reflected entry", kind = cs_consts.KINDS.MANUAL })
            test.is_nil(open_err)
            local result, delete_err = engine.apply_one({ target = "entry", id = entry.id, op = "delete" }, {
                branch = workspace.state_branch, changeset_id = workspace.changeset_id,
            })
            test.is_nil(delete_err)
            test.is_true(result.applied)
            local changes, read_err = cs_client.list_changes(workspace.changeset_id)
            test.is_nil(read_err)
            test.eq(#changes.registry, 1)
            test.eq(changes.registry[1].target, entry.id)
            test.eq(changes.registry[1].op, "delete")
            local recorded, journal_err = cs_repo.list_changes_for_changeset(workspace.changeset_id)
            test.is_nil(journal_err)
            test.eq(#recorded, 1)
            test.eq(recorded[1].target, entry.id)
            test.eq(recorded[1].op, "delete")
        end)
    end)

    describe("State orchestrator completion replies", function()
        test.after_each(restore)

        it("does not advertise the startup version before reconciliation succeeds", function()
            local version = registry.current_version():id()
            local _, _, sent = run_steps({
                function()
                    return message(consts.TOPICS.COMMANDS, { operation = consts.OPERATIONS.GET_STATE })
                end,
                function() return { worker = 1 } end,
                function()
                    return message(consts.TOPICS.COMMANDS, { operation = consts.OPERATIONS.GET_STATE })
                end,
            })
            test.is_nil(sent[1].body.state.state_system.last_sync_version)
            test.is_false(sent[1].body.state.state_system.database_ready)
            test.eq(sent[2].body.state.state_system.last_sync_version, version)
            test.is_true(sent[2].body.state.state_system.database_ready)
        end)

        it("retains notifications that do not request a response", function()
            local version = registry.current_version():id()
            local result, spawned, sent = run_steps({
                function() return message(consts.TOPICS.REGISTRY_CHANGE, { version = version + 1 }) end,
                function() return { worker = 1 } end,
                function() return { worker = 2, result = { success = true, version = version + 1 } } end,
            })
            test.eq(#spawned, 2)
            test.eq(#sent, 0)
            test.eq(result.last_sync_version, version + 1)
        end)

        it("reports a reconciliation spawn error to every waiting observer", function()
            local version = registry.current_version():id()
            local calls = 0
            local result, spawned, sent = run_steps({
                function() return change(version + 1) end,
                function() return change(version + 2) end,
                function() return { worker = 1 } end,
            }, function()
                calls = calls + 1
                if calls == 1 then return { success = true, version = version } end
                return nil, "spawn failed"
            end)
            test.eq(#spawned, 1)
            test.eq(#sent, 2)
            test.eq(result.last_sync_version, version)
            for _, response in ipairs(sent) do
                test.is_false(response.body.success)
                test.eq(response.body.error, "spawn failed")
            end
        end)

        it("acknowledges a pending version already covered by the completed snapshot", function()
            local version = registry.current_version():id()
            local result, spawned, sent = run_steps({
                function() return change(version + 1) end,
                function(_, replies)
                    test.eq(#replies, 0)
                    return { worker = 1, result = { success = true, version = version + 1 } }
                end,
            })
            test.eq(#spawned, 1)
            test.eq(#sent, 1)
            test.is_true(sent[1].body.success)
            test.eq(sent[1].body.version, version + 1)
            test.eq(result.last_sync_version, version + 1)
        end)

        it("coalesces changes and keeps reconciling while another change is pending", function()
            local version = registry.current_version():id()
            local result, spawned, sent = run_steps({
                function() return change(version + 1) end,
                function() return change(version + 2, { is_version_operation = true, changeset = {} }) end,
                function(_, replies)
                    test.eq(#replies, 0)
                    return { worker = 1 }
                end,
                function(workers, replies)
                    test.eq(#workers, 2)
                    test.eq(#replies, 0)
                    return change(version + 3)
                end,
                function() return { worker = 2, result = { success = true, version = version + 2 } } end,
                function(workers, replies)
                    test.eq(#workers, 3)
                    test.eq(#replies, 2)
                    test.eq(replies[1].body.version, version + 2)
                    test.eq(replies[2].body.version, version + 2)
                    return { worker = 3, result = { success = true, version = version + 3 } }
                end,
            })
            test.eq(#spawned, 3)
            test.eq(#sent, 3)
            test.eq(result.last_sync_version, version + 3)
            test.eq(sent[3].body.version, version + 3)
            for _, response in ipairs(sent) do test.is_true(response.body.success) end
        end)

        it("acknowledges incremental sync only after completion and serializes newer changes", function()
            local version = registry.current_version():id()
            local result, spawned, sent = run_steps({
                function() return { worker = 1, result = { success = true, version = version } } end,
                function() return change(version + 1) end,
                function(workers, replies)
                    test.eq(workers[2].id, "keeper.state.service:sync")
                    test.eq(#replies, 0)
                    return change(version + 2)
                end,
                function(workers)
                    test.eq(#workers, 2)
                    return { worker = 2 }
                end,
                function(workers, replies)
                    test.eq(workers[3].id, "keeper.state.service:reconcile")
                    test.eq(#replies, 1)
                    return { worker = 3, result = { success = true, version = version + 2 } }
                end,
            })
            test.eq(#spawned, 3)
            test.eq(#sent, 2)
            test.eq(result.last_sync_version, version + 2)
        end)

        it("reports reconciliation failures to observers without claiming a synced version", function()
            local version = registry.current_version():id()
            local result, _, sent = run_steps({
                function() return change(version + 1) end,
                function() return { worker = 1 } end,
                function() return { worker = 2, result = { success = false, error = "write failed" } } end,
            })
            test.eq(#sent, 1)
            test.is_false(sent[1].body.success)
            test.eq(sent[1].body.error, "write failed")
            test.eq(result.last_sync_version, version)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
