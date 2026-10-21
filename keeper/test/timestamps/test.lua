local test = require("test")
local sql = require("sql")
local time = require("time")
local uuid = require("uuid")
local json = require("json")
local changelog = require("changelog")
local kb_repo = require("kb_repo")
local cs_repo = require("cs_repo")
local cs_consts = require("cs_consts")
local task_writer = require("task_writer")
local task_consts = require("task_consts")
local rebuild = require("rebuild")

local cleanups = {}

local function track(db_id, table_name, key, value)
    table.insert(cleanups, { db_id = db_id, table_name = table_name, key = key, value = value })
end

-- Run with TZ=Etc/GMT-4 and TZ=Etc/GMT+7 to exercise both offset signs.
local function assert_instant(value, earliest, latest)
    test.eq(#value, 20)
    test.eq(value:sub(-1), "Z")
    local instant, err = time.parse(time.RFC3339, value)
    test.is_nil(err)
    if not instant then error("timestamp does not parse: " .. value) end
    test.is_true(instant:unix() >= earliest, value .. " precedes the write")
    test.is_true(instant:unix() <= latest, value .. " follows the write")
end

local function query_one(db_id, table_name, key, value)
    local db, err = sql.get(db_id)
    test.is_nil(err)
    if not db then error("test database unavailable") end
    local rows, qerr = sql.builder.select("*"):from(table_name):where(key .. " = ?", value):run_with(db):query()
    db:release()
    test.is_nil(qerr)
    test.eq(#rows, 1)
    return rows[1]
end

local function new_changeset()
    local id = uuid.v7()
    local row, err = cs_repo.create_changeset({
        changeset_id = id,
        title = "Timestamp test",
        kind = cs_consts.KINDS.MANUAL,
        state_branch = cs_consts.branch_for(id),
        scratch_fs_path = id .. "/",
        baseline_version = "0",
        baseline_fs_hash = "",
    })
    test.is_nil(err)
    if not row then error("changeset is unavailable") end
    track("keeper.state:db", "keeper_changesets", "changeset_id", row.changeset_id)
    return row
end

local function define_tests()
    describe("Stored UTC timestamps", function()
        after_each(function()
            for i = #cleanups, 1, -1 do
                local item = cleanups[i]
                local db, err = sql.get(item.db_id)
                test.is_nil(err)
                if not db then error("test database unavailable") end
                local _, derr = sql.builder.delete(item.table_name):where(item.key .. " = ?", item.value):run_with(db):exec()
                db:release()
                test.is_nil(derr)
            end
            cleanups = {}
        end)

        it("records the UTC instant in both changelog columns", function()
            local entry_id = "test.timestamps:" .. uuid.v7()
            track("app:db", "keeper_changelog", "entry_id", entry_id)
            local earliest = time.now():unix()
            changelog.record_changeset({
                changeset = {{ kind = "entry.create", entry = { id = entry_id, kind = "function.lua" } }},
                result = { success = true, version = earliest },
            })
            local latest = time.now():unix()
            local row = query_one("app:db", "keeper_changelog", "entry_id", entry_id)
            assert_instant(row.timestamp, earliest, latest)
            test.eq(row.created_at, row.timestamp)
        end)

        it("stores UTC instants when creating and updating knowledge", function()
            local earliest = time.now():unix()
            local kb, err = kb_repo.create_kb({ name = "timestamps-" .. uuid.v7() })
            test.is_nil(err)
            if not kb then error("knowledge base is unavailable") end
            track("app:db", "keeper_kbs", "id", kb.id)
            local node, nerr = kb_repo.create({ kb_id = kb.id, title = "Timestamp test" })
            test.is_nil(nerr)
            if not node then error("knowledge node is unavailable") end
            track("app:db", "keeper_kb_nodes", "id", node.id)
            local latest = time.now():unix()
            local stored_kb = kb_repo.get_kb(kb.id)
            local stored_node = kb_repo.get(node.id)
            assert_instant(stored_kb.created_at, earliest, latest)
            assert_instant(stored_kb.updated_at, earliest, latest)
            assert_instant(stored_node.created_at, earliest, latest)
            assert_instant(stored_node.updated_at, earliest, latest)

            earliest = time.now():unix()
            local _, uerr = kb_repo.update_kb(kb.id, { description = "Updated" })
            test.is_nil(uerr)
            local _, nuerr = kb_repo.update(node.id, { title = "Updated" })
            test.is_nil(nuerr)
            latest = time.now():unix()
            assert_instant(kb_repo.get_kb(kb.id).updated_at, earliest, latest)
            assert_instant(kb_repo.get(node.id).updated_at, earliest, latest)
        end)

        it("stores UTC instants when creating and closing changesets", function()
            local earliest = time.now():unix()
            local row = new_changeset()
            local latest = time.now():unix()
            assert_instant(row.created_at, earliest, latest)
            assert_instant(row.updated_at, earliest, latest)

            earliest = time.now():unix()
            local _, err = cs_repo.update_state(row.changeset_id, cs_consts.STATES.DROPPED, "Timestamp test")
            test.is_nil(err)
            latest = time.now():unix()
            row = cs_repo.get_changeset(row.changeset_id)
            assert_instant(row.updated_at, earliest, latest)
            assert_instant(row.closed_at, earliest, latest)
        end)

        it("stores UTC instants when creating and completing tasks", function()
            local earliest = time.now():unix()
            local result, err = task_writer.create_task({ title = "Timestamp test" }):execute()
            test.is_nil(err)
            if not result then error("task is unavailable") end
            track("keeper.state:db", "keeper_tasks", "task_id", result.task_id)
            local latest = time.now():unix()
            local row = query_one("keeper.state:db", "keeper_tasks", "task_id", result.task_id)
            assert_instant(row.created_at, earliest, latest)
            assert_instant(row.updated_at, earliest, latest)

            earliest = time.now():unix()
            local _, uerr = task_writer.for_task(result.task_id):update_task({ status = task_consts.STATUSES.COMPLETED }):execute()
            test.is_nil(uerr)
            latest = time.now():unix()
            row = query_one("keeper.state:db", "keeper_tasks", "task_id", result.task_id)
            assert_instant(row.updated_at, earliest, latest)
            assert_instant(row.completed_at, earliest, latest)
        end)

        it("stores UTC instants for rebuild runs and snapshots", function()
            local changeset = new_changeset()
            local earliest = time.now():unix()
            local _, run, err = rebuild.run({
                mode = "manual", change_source = "changeset", changeset_id = changeset.changeset_id,
            })
            test.is_nil(err)
            if not run then error("rebuild run is unavailable") end
            track("keeper.state:db", "keeper_git_runs", "run_id", run.run_id)
            local latest = time.now():unix()
            local row = query_one("keeper.state:db", "keeper_git_runs", "run_id", run.run_id)
            assert_instant(row.started_at, earliest, latest)
            assert_instant(row.finished_at, earliest, latest)
            local snapshot, jerr = json.decode(row.payload_json)
            test.is_nil(jerr)
            assert_instant(snapshot.built_at, earliest, latest)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
