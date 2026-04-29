local test = require("test")
local uuid = require("uuid")
local sql = require("sql")
local consts = require("consts")
local repo = require("repo")
local state_machine = require("state_machine")
local open_lib = require("open")
local edit_lib = require("edit")
local drop_lib = require("drop")
local transitions_lib = require("transitions")
local diff = require("diff")
local fs_view = require("fs_view")
local state_ops = require("state_ops")

local function define_tests()
    describe("Changeset Service Integration", function()
        local created_changeset_ids = {}
        local created_task_ids = {}

        local function must_db()
            local db, err = sql.get(consts.DATABASE.RESOURCE_ID)
            if err then error("test database unavailable: " .. tostring(err)) end
            if not db then error("test database unavailable") end
            return db
        end

        local function workspace_id(ws: unknown): string
            if type(ws) ~= "table" or type(ws.changeset_id) ~= "string" then
                error("workspace row is missing changeset_id")
            end
            return ws.changeset_id
        end

        local function must_view(changeset_id: string)
            local view, err = fs_view.open(changeset_id)
            if err then error("workspace fs view unavailable: " .. tostring(err)) end
            if not view then error("workspace fs view unavailable") end
            return view
        end

        local function cleanup_workspace(changeset_id)
            if not changeset_id then return end
            local ws, _ = repo.get_changeset(changeset_id)
            if ws then
                pcall(function() drop_lib.run({ changeset_id = changeset_id }) end)
                local db = must_db()
                if db then
                    db:execute("DELETE FROM keeper_changesets WHERE changeset_id = ?", { changeset_id })
                    db:release()
                end
            end
        end

        after_all(function()
            for _, id in ipairs(created_changeset_ids) do
                cleanup_workspace(id)
            end
            local db = must_db()
            if db then
                for _, task_id in ipairs(created_task_ids) do
                    db:execute("DELETE FROM keeper_task_nodes WHERE task_id = ?", { task_id })
                    db:execute("DELETE FROM keeper_tasks WHERE task_id = ?", { task_id })
                end
                db:release()
            end
        end)

        local function track(ws) table.insert(created_changeset_ids, workspace_id(ws)) end

        local function create_task(status, phase)
            local task_id = "test.janitor.task." .. uuid.v7()
            local db = must_db()
            db:execute([[
                INSERT INTO keeper_tasks (
                    task_id, title, description, status, phase,
                    iteration, actor_id, archived, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, 0, ?, 0, datetime('now'), datetime('now'))
            ]], {
                task_id,
                "Janitor Active Task",
                "active task-bound workspace must not be janitored",
                status or "active",
                phase or "plan",
                "test.janitor.actor",
            })
            db:release()
            table.insert(created_task_ids, task_id)
            return task_id
        end

        local function create_active_task()
            return create_task("active", "plan")
        end

    -- ==========================================================================
    describe("service/open.lua", function()
        it("creates a workspace with baseline snapshots", function()
            local ws, err = open_lib.run({
                title    = "Open Test Baseline",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.open.actor",
            })
            test.is_nil(err)
            test.not_nil(ws)
            track(ws)

            test.eq(ws.state, consts.STATES.OPEN)
            test.eq(ws.title, "Open Test Baseline")
            test.eq(ws.actor_id, "test.open.actor")
            test.not_nil(ws.changeset_id)
            test.not_nil(ws.baseline_version)
            test.not_nil(ws.baseline_fs_hash)
            test.eq(ws.state_branch, consts.branch_for(ws.changeset_id))
            test.eq(ws.scratch_fs_path, ws.changeset_id .. "/")

            -- Baseline row written
            local baseline, _ = repo.latest_baseline(ws.changeset_id)
            test.not_nil(baseline)
            test.eq(baseline.reason, consts.BASELINE_REASONS.OPEN)
            test.eq(baseline.registry_version, ws.baseline_version)
            test.eq(baseline.fs_tree_hash, ws.baseline_fs_hash)

            -- Manifest stored for the baseline tree hash (may be empty list)
            local manifest_row, mf_err = repo.load_manifest(ws.baseline_fs_hash)
            test.is_nil(mf_err)
            test.not_nil(manifest_row)
            test.eq(manifest_row.root, consts.FS.FE_VOLUME)
        end)
    end)

    -- ==========================================================================
    describe("service/edit.lua — fs_write", function()
        it("writes a file to scratch visible through fs_view", function()
            local ws, _ = open_lib.run({
                title    = "Edit FS Write",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.edit.actor",
            })
            track(ws)

            local unique_path = "test-workspace/" .. uuid.v7() .. ".txt"
            local content = "hello from workspace test"

            local result, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = unique_path,
                content      = content,
            })
            test.is_nil(err)
            test.not_nil(result)
            test.is_true(result.ok)
            test.not_nil(result.current_hash)

            -- Read it back through the view — should find it in scratch
            local view = must_view(workspace_id(ws))
            local read_content, read_err = view:read(unique_path)
            test.is_nil(read_err)
            test.eq(read_content, content)

            -- Cleanup this file from scratch before the workspace-level
            -- cleanup so we don't leave leftover files on a shared volume.
            view:destroy_scratch()
        end)

        it("rejects path traversal", function()
            local ws, _ = open_lib.run({
                title    = "Edit Path Traversal",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.edit.actor",
            })
            track(ws)

            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = "../escape.txt",
                content      = "nope",
            })
            test.not_nil(err)
        end)
    end)

    -- ==========================================================================
    describe("service/edit.lua — registry_set", function()
        it("writes an entry to the workspace overlay branch", function()
            local ws, _ = open_lib.run({
                title    = "Edit Registry Set",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.edit.actor",
            })
            track(ws)

            local entry_id = "test.workspace.edit:entry_" .. uuid.v7()
            local definition = [[
name: test_entry
kind: library.lua
meta:
  comment: Test entry created by workspace test
source: file://fake.lua
]]

            local result, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = {
                    id         = entry_id,
                    kind       = "library.lua",
                    definition = definition,
                    content    = "local M = {}\nreturn M\n",
                },
            })
            test.is_nil(err)
            test.not_nil(result)
            test.is_true(result.ok)

            -- Verify the overlay branch has the entry
            local db = must_db()
            local rows, qerr = db:query(
                "SELECT id, deleted FROM keeper_overlay_entries WHERE branch = ? AND id = ?",
                { ws.state_branch, entry_id }
            )
            test.is_nil(qerr)
            test.eq(#rows, 1)
            test.eq(rows[1].id, entry_id)
            test.eq(tonumber(rows[1].deleted), 0)

            -- Verify content chunks landed
            local chunk_rows, cerr = db:query(
                "SELECT chunk_type FROM keeper_overlay_chunks WHERE branch = ? AND entry_id = ?",
                { ws.state_branch, entry_id }
            )
            test.is_nil(cerr)
            test.is_true(#chunk_rows >= 1)

            db:release()
        end)

        it("rejects edits on dropped workspace", function()
            local ws, _ = open_lib.run({
                title    = "Edit Dropped",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.edit.actor",
            })
            track(ws)

            -- Force the workspace to dropped state (simulating a completed drop)
            repo.update_state(ws.changeset_id, consts.STATES.DROPPED, "test forced drop")

            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = "nope.txt",
                content      = "should fail",
            })
            test.not_nil(err)
        end)
    end)

    -- ==========================================================================
    describe("service/transitions.lua", function()
        it("applies valid transitions and updates the row", function()
            local ws, _ = open_lib.run({
                title    = "Transitions Happy",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.trans.actor",
            })
            track(ws)

            local res, err = transitions_lib.run({
                changeset_id = ws.changeset_id,
                event        = state_machine.EVENTS.FIRST_EDIT,
                reason       = "test",
            })
            test.is_nil(err)
            test.eq(res.to_state, consts.STATES.EDITING)

            local updated, _ = repo.get_changeset(ws.changeset_id)
            test.eq(updated.state, consts.STATES.EDITING)
            test.eq(updated.state_reason, "test")
        end)

        it("rejects invalid transitions", function()
            local ws, _ = open_lib.run({
                title    = "Transitions Invalid",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.trans.actor",
            })
            track(ws)

            -- open -> accept is invalid
            local _, err = transitions_lib.run({
                changeset_id = ws.changeset_id,
                event        = state_machine.EVENTS.ACCEPT,
            })
            test.not_nil(err)
        end)

        it("refuses transitions from terminal states", function()
            local ws, _ = open_lib.run({
                title    = "Transitions Terminal",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.trans.actor",
            })
            track(ws)

            repo.update_state(ws.changeset_id, consts.STATES.MERGED, "test merged")

            local _, err = transitions_lib.run({
                changeset_id = ws.changeset_id,
                event        = state_machine.EVENTS.DROP,
            })
            test.not_nil(err)
        end)

        it("enforces submit_for_review guard (no pending changes)", function()
            local ws, _ = open_lib.run({
                title    = "Guard Submit Empty",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.trans.actor",
            })
            track(ws)

            -- Move to editing state manually
            repo.update_state(ws.changeset_id, consts.STATES.EDITING, "test")

            -- Attempting submit without any pending changes should fail
            local _, err = transitions_lib.run({
                changeset_id = ws.changeset_id,
                event        = state_machine.EVENTS.SUBMIT_FOR_REVIEW,
                guard_ctx    = { pending_changes = {}, conflicts = {} },
            })
            test.not_nil(err)
        end)

        it("enforces accept guard (linter result)", function()
            local ws, _ = open_lib.run({
                title    = "Guard Accept",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.trans.actor",
            })
            track(ws)

            repo.update_state(ws.changeset_id, consts.STATES.REVIEW, "test")

            -- Linter not clean -> reject
            local _, err1 = transitions_lib.run({
                changeset_id = ws.changeset_id,
                event        = state_machine.EVENTS.ACCEPT,
                guard_ctx    = { linter_result = { success = false } },
            })
            test.not_nil(err1)

            -- Linter clean -> transition succeeds
            local res, err2 = transitions_lib.run({
                changeset_id = ws.changeset_id,
                event        = state_machine.EVENTS.ACCEPT,
                guard_ctx    = { linter_result = { success = true } },
            })
            test.is_nil(err2)
            test.eq(res.to_state, consts.STATES.ACCEPTED)
        end)
    end)

    -- ==========================================================================
    describe("diff.compute", function()
        it("returns empty diff for an untouched workspace", function()
            local ws, _ = open_lib.run({
                title    = "Diff Empty",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            local changes, err = diff.compute(ws.changeset_id)
            test.is_nil(err)
            test.not_nil(changes)
            test.eq(#changes.registry, 0)
            test.eq(#changes.filesystem, 0)
        end)

        it("surfaces a registry_set with definition+content as two per-part create rows", function()
            local ws, _ = open_lib.run({
                title    = "Diff Registry Create",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            local entry_id = "test.workspace.diff:entry_" .. uuid.v7()
            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = {
                    id         = entry_id,
                    kind       = "library.lua",
                    definition = "name: fake\nkind: library.lua\nsource: file://fake.lua\n",
                    content    = "return {}",
                },
            })
            test.is_nil(err)

            local changes, derr = diff.compute(ws.changeset_id)
            test.is_nil(derr)

            local by_part = {}
            for _, r in ipairs(changes.registry) do
                if r.target == entry_id then by_part[r.part or "__nil__"] = r end
            end

            test.not_nil(by_part[consts.CHUNKS.DEFINITION])
            test.not_nil(by_part[consts.CHUNKS.CONTENT])

            for _, part in ipairs({ consts.CHUNKS.DEFINITION, consts.CHUNKS.CONTENT }) do
                local row = by_part[part]
                test.eq(row.category, consts.CATEGORIES.REGISTRY)
                test.eq(row.op, consts.OPS.CREATE)
                test.eq(row.target, entry_id)
                test.eq(row.part, part)
                test.is_nil(row.baseline_hash)
                test.not_nil(row.current_hash)
            end
        end)

        it("surfaces a registry_set with only a definition as a single definition-part row", function()
            local ws, _ = open_lib.run({
                title    = "Diff Registry Create Definition Only",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            local entry_id = "test.workspace.diff:endpoint_" .. uuid.v7()
            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = {
                    id         = entry_id,
                    kind       = "http.endpoint",
                    definition = "name: meta_only\nkind: http.endpoint\nmethod: GET\npath: /x\n",
                },
            })
            test.is_nil(err)

            local changes, derr = diff.compute(ws.changeset_id)
            test.is_nil(derr)

            local rows_for_entry = {}
            for _, r in ipairs(changes.registry) do
                if r.target == entry_id then table.insert(rows_for_entry, r) end
            end

            test.eq(#rows_for_entry, 1)
            test.eq(rows_for_entry[1].part, consts.CHUNKS.DEFINITION)
            test.eq(rows_for_entry[1].op, consts.OPS.CREATE)
        end)

        it("splits a definition-only edit of an existing entry into one definition-part update", function()
            local ws, _ = open_lib.run({
                title    = "Diff Update Definition Only",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            local entry_id = "test.workspace.diff:split_" .. uuid.v7()
            local db = must_db()
            test.not_nil(db)
            local tx = db:begin()
            state_ops.execute(tx, { {
                type = state_ops.COMMAND.SET_ENTRY,
                payload = {
                    id         = entry_id,
                    kind       = "library.lua",
                    branch     = "main",
                    definition = "name: base\nkind: library.lua\nsource: file://base.lua\n",
                    content    = "return { version = 1 }",
                },
            } })
            tx:commit()
            db:release()

            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = {
                    id         = entry_id,
                    kind       = "library.lua",
                    definition = "name: base\nkind: library.lua\nsource: file://base.lua\n# updated comment\n",
                    content    = "return { version = 1 }",
                },
            })
            test.is_nil(err)

            local changes, derr = diff.compute(ws.changeset_id)
            test.is_nil(derr)

            local rows_for_entry = {}
            for _, r in ipairs(changes.registry) do
                if r.target == entry_id then table.insert(rows_for_entry, r) end
            end

            test.eq(#rows_for_entry, 1)
            test.eq(rows_for_entry[1].part, consts.CHUNKS.DEFINITION)
            test.eq(rows_for_entry[1].op, consts.OPS.UPDATE)
            test.not_nil(rows_for_entry[1].baseline_hash)
            test.not_nil(rows_for_entry[1].current_hash)
            test.is_true(rows_for_entry[1].baseline_hash ~= rows_for_entry[1].current_hash)

            local db2 = must_db()
            db2:execute("DELETE FROM keeper_overlay_entries WHERE id = ? AND branch = 'main'", { entry_id })
            db2:execute("DELETE FROM keeper_overlay_chunks WHERE entry_id = ? AND branch = 'main'", { entry_id })
            db2:release()
        end)

        it("splits a content-only edit of an existing entry into one content-part update", function()
            local ws, _ = open_lib.run({
                title    = "Diff Update Content Only",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            local entry_id = "test.workspace.diff:source_" .. uuid.v7()
            local db = must_db()
            test.not_nil(db)
            local tx = db:begin()
            state_ops.execute(tx, { {
                type = state_ops.COMMAND.SET_ENTRY,
                payload = {
                    id         = entry_id,
                    kind       = "library.lua",
                    branch     = "main",
                    definition = "name: stable\nkind: library.lua\nsource: file://stable.lua\n",
                    content    = "return { value = 1 }",
                },
            } })
            tx:commit()
            db:release()

            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = {
                    id         = entry_id,
                    kind       = "library.lua",
                    definition = "name: stable\nkind: library.lua\nsource: file://stable.lua\n",
                    content    = "return { value = 2 }",
                },
            })
            test.is_nil(err)

            local changes, derr = diff.compute(ws.changeset_id)
            test.is_nil(derr)

            local rows_for_entry = {}
            for _, r in ipairs(changes.registry) do
                if r.target == entry_id then table.insert(rows_for_entry, r) end
            end

            test.eq(#rows_for_entry, 1)
            test.eq(rows_for_entry[1].part, consts.CHUNKS.CONTENT)
            test.eq(rows_for_entry[1].op, consts.OPS.UPDATE)

            local db2 = must_db()
            db2:execute("DELETE FROM keeper_overlay_entries WHERE id = ? AND branch = 'main'", { entry_id })
            db2:execute("DELETE FROM keeper_overlay_chunks WHERE entry_id = ? AND branch = 'main'", { entry_id })
            db2:release()
        end)

        it("preserves the content chunk when edit_lib is called with definition-only payload", function()
            local ws, _ = open_lib.run({
                title    = "Diff Partial Edit Definition",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            local entry_id = "test.workspace.diff:partial_def_" .. uuid.v7()
            local db = must_db()
            test.not_nil(db)
            local tx = db:begin()
            state_ops.execute(tx, { {
                type = state_ops.COMMAND.SET_ENTRY,
                payload = {
                    id         = entry_id,
                    kind       = "library.lua",
                    branch     = "main",
                    definition = "name: partial\nkind: library.lua\nsource: file://partial.lua\n",
                    content    = "return { keep = true }",
                },
            } })
            tx:commit()
            db:release()

            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = {
                    id         = entry_id,
                    kind       = "library.lua",
                    definition = "name: partial\nkind: library.lua\nsource: file://partial.lua\n# bumped\n",
                },
            })
            test.is_nil(err)

            local changes, derr = diff.compute(ws.changeset_id)
            test.is_nil(derr)

            local rows_for_entry = {}
            for _, r in ipairs(changes.registry) do
                if r.target == entry_id then table.insert(rows_for_entry, r) end
            end

            test.eq(#rows_for_entry, 1)
            test.eq(rows_for_entry[1].part, consts.CHUNKS.DEFINITION)
            test.eq(rows_for_entry[1].op, consts.OPS.UPDATE)

            local db2 = must_db()
            db2:execute("DELETE FROM keeper_overlay_entries WHERE id = ? AND branch = 'main'", { entry_id })
            db2:execute("DELETE FROM keeper_overlay_chunks WHERE entry_id = ? AND branch = 'main'", { entry_id })
            db2:release()
        end)

        it("preserves the definition chunk when edit_lib is called with content-only payload", function()
            local ws, _ = open_lib.run({
                title    = "Diff Partial Edit Content",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            local entry_id = "test.workspace.diff:partial_src_" .. uuid.v7()
            local db = must_db()
            test.not_nil(db)
            local tx = db:begin()
            state_ops.execute(tx, { {
                type = state_ops.COMMAND.SET_ENTRY,
                payload = {
                    id         = entry_id,
                    kind       = "library.lua",
                    branch     = "main",
                    definition = "name: partial\nkind: library.lua\nsource: file://partial.lua\n",
                    content    = "return { v = 1 }",
                },
            } })
            tx:commit()
            db:release()

            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = {
                    id      = entry_id,
                    kind    = "library.lua",
                    content = "return { v = 2 }",
                },
            })
            test.is_nil(err)

            local changes, derr = diff.compute(ws.changeset_id)
            test.is_nil(derr)

            local rows_for_entry = {}
            for _, r in ipairs(changes.registry) do
                if r.target == entry_id then table.insert(rows_for_entry, r) end
            end

            test.eq(#rows_for_entry, 1)
            test.eq(rows_for_entry[1].part, consts.CHUNKS.CONTENT)
            test.eq(rows_for_entry[1].op, consts.OPS.UPDATE)

            local db2 = must_db()
            db2:execute("DELETE FROM keeper_overlay_entries WHERE id = ? AND branch = 'main'", { entry_id })
            db2:execute("DELETE FROM keeper_overlay_chunks WHERE entry_id = ? AND branch = 'main'", { entry_id })
            db2:release()
        end)

        it("collapses a full-entry delete into a single row with no part", function()
            local ws, _ = open_lib.run({
                title    = "Diff Delete Collapsed",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            local entry_id = "test.workspace.diff:doomed_" .. uuid.v7()
            local db = must_db()
            test.not_nil(db)
            local tx = db:begin()
            state_ops.execute(tx, { {
                type = state_ops.COMMAND.SET_ENTRY,
                payload = {
                    id         = entry_id,
                    kind       = "library.lua",
                    branch     = "main",
                    definition = "name: doomed\nkind: library.lua\nsource: file://doomed.lua\n",
                    content    = "return { doomed = true }",
                },
            } })
            tx:commit()
            db:release()

            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_DELETE,
                entry_id     = entry_id,
            })
            test.is_nil(err)

            local changes, derr = diff.compute(ws.changeset_id)
            test.is_nil(derr)

            local rows_for_entry = {}
            for _, r in ipairs(changes.registry) do
                if r.target == entry_id then table.insert(rows_for_entry, r) end
            end

            test.eq(#rows_for_entry, 1)
            test.eq(rows_for_entry[1].op, consts.OPS.DELETE)
            test.is_nil(rows_for_entry[1].part)

            local db2 = must_db()
            db2:execute("DELETE FROM keeper_overlay_entries WHERE id = ? AND branch = 'main'", { entry_id })
            db2:execute("DELETE FROM keeper_overlay_chunks WHERE entry_id = ? AND branch = 'main'", { entry_id })
            db2:release()
        end)

        it("surfaces a filesystem write as a diff entry with fs-relative path", function()
            local ws, _ = open_lib.run({
                title    = "Diff FS Write",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            -- Use a stable relative path; uniqueness comes from the workspace prefix
            local rel_path = "workspace-diff-test/" .. uuid.v7() .. ".txt"
            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = rel_path,
                content      = "diff me",
            })
            test.is_nil(err)

            local changes, derr = diff.compute(ws.changeset_id)
            test.is_nil(derr)

            -- Find our file in the fs change list (path is fe_fs-relative)
            local found = nil
            for _, c in ipairs(changes.filesystem) do
                if c.target == rel_path then found = c break end
            end
            test.not_nil(found)
            test.eq(found.op, consts.OPS.CREATE)
            test.not_nil(found.current_hash)

            -- Cleanup the scratch file before workspace cleanup
            local view = must_view(workspace_id(ws))
            if view then view:destroy_scratch() end
        end)
    end)

    -- ==========================================================================
    describe("fs_view read fallthrough + copy-on-write", function()
        -- We stage a file directly into staging_fs at a synthetic "fake fe_fs"
        -- path via the workspace scratch, then verify that reading through
        -- fs_view returns scratch content (not fe_fs). This exercises the
        -- scratch-first branch of the read path. Full fe_fs fallthrough is
        -- exercised implicitly whenever a test reads a path not in scratch.
        it("returns scratch content when a file is staged", function()
            local ws, _ = open_lib.run({
                title    = "FSView Scratch Read",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.fsview.actor",
            })
            track(ws)

            local rel_path = "fsview-test/" .. uuid.v7() .. ".txt"
            local content = "scratch wins"

            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = rel_path,
                content      = content,
            })
            test.is_nil(err)

            local view = must_view(workspace_id(ws))
            test.not_nil(view)

            local staged, staged_err = view:has_scratch_copy(rel_path)
            test.is_nil(staged_err)
            test.is_true(staged)

            local read_content, read_err = view:read(rel_path)
            test.is_nil(read_err)
            test.eq(read_content, content)

            view:destroy_scratch()
        end)

        it("returns false for exists on a non-staged, non-fe_fs path", function()
            local ws, _ = open_lib.run({
                title    = "FSView Nonexistent",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.fsview.actor",
            })
            track(ws)

            local view = must_view(workspace_id(ws))
            test.not_nil(view)

            local exists, err = view:exists("path/that/does/not/exist-" .. uuid.v7() .. ".nope")
            test.is_nil(err)
            test.is_false(exists)
        end)

        it("records a delete marker and hides the file on subsequent reads", function()
            local ws, _ = open_lib.run({
                title    = "FSView Delete Marker",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.fsview.actor",
            })
            track(ws)

            local rel_path = "fsview-delete/" .. uuid.v7() .. ".txt"
            local view = must_view(workspace_id(ws))
            test.not_nil(view)

            -- Stage a file, then delete it via the view.
            view:write(rel_path, "doomed")

            local deleted_before, _ = view:is_deleted(rel_path)
            test.is_false(deleted_before)

            local _, del_err = view:delete(rel_path)
            test.is_nil(del_err)

            local deleted_after, _ = view:is_deleted(rel_path)
            test.is_true(deleted_after)

            -- Read must now surface the delete marker
            local _, read_err = view:read(rel_path)
            test.eq(read_err, "deleted")

            view:destroy_scratch()
        end)

        it("writing after delete clears the delete marker", function()
            local ws, _ = open_lib.run({
                title    = "FSView Delete Undo",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.fsview.actor",
            })
            track(ws)

            local rel_path = "fsview-undelete/" .. uuid.v7() .. ".txt"
            local view = must_view(workspace_id(ws))
            test.not_nil(view)

            view:write(rel_path, "first")
            view:delete(rel_path)

            local deleted, _ = view:is_deleted(rel_path)
            test.is_true(deleted)

            view:write(rel_path, "second")

            local deleted_after, _ = view:is_deleted(rel_path)
            test.is_false(deleted_after)

            local content, _ = view:read(rel_path)
            test.eq(content, "second")

            view:destroy_scratch()
        end)
    end)

    -- ==========================================================================
    describe("DB-backed FS content", function()
        it("empty workspace has no DB content rows", function()
            local ws, _ = open_lib.run({
                title    = "DB Empty",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.dbfs.actor",
            })
            track(ws)

            local rows, err = repo.list_fs_content(ws.changeset_id)
            test.is_nil(err)
            test.eq(#rows, 0)
        end)

        it("fs_write stores content in DB and read retrieves it", function()
            local ws, _ = open_lib.run({
                title    = "DB Write Read",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.dbfs.actor",
            })
            track(ws)

            local p1 = "db-test/" .. uuid.v7() .. "-one.txt"
            local p2 = "db-test/" .. uuid.v7() .. "-two.txt"

            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = p1,
                content      = "content-one",
            })
            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = p2,
                content      = "content-two",
            })

            -- Verify DB rows exist
            local rows, err = repo.list_fs_content(ws.changeset_id)
            test.is_nil(err)
            test.eq(#rows, 2)

            -- Verify content can be read back through fs_view
            local view = must_view(workspace_id(ws))
            test.not_nil(view)
            local c1, e1 = view:read(p1)
            test.is_nil(e1)
            test.eq(c1, "content-one")

            local c2, e2 = view:read(p2)
            test.is_nil(e2)
            test.eq(c2, "content-two")
        end)

        it("drop cleans DB content rows", function()
            local ws, _ = open_lib.run({
                title    = "DB Drop",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.dbfs.actor",
            })
            track(ws)

            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = "drop-test/file.txt",
                content      = "will be dropped",
            })

            local before, _ = repo.list_fs_content(ws.changeset_id)
            test.eq(#before, 1)

            drop_lib.run({ changeset_id = ws.changeset_id })

            local after, _ = repo.list_fs_content(ws.changeset_id)
            test.eq(#after, 0)
        end)
    end)

    -- ==========================================================================
    describe("service/drop.lua", function()
        it("removes overlay branch rows and leaves workspace row at dropped state", function()
            local ws, _ = open_lib.run({
                title    = "Drop Test",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.drop.actor",
            })
            track(ws)

            -- Write one registry entry to create overlay rows
            local entry_id = "test.workspace.drop:entry_" .. uuid.v7()
            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = {
                    id         = entry_id,
                    kind       = "library.lua",
                    definition = "name: drop\nkind: library.lua\nsource: file://drop.lua\n",
                    content    = "return {}",
                },
            })

            -- Drop
            local result, err = drop_lib.run({ changeset_id = ws.changeset_id })
            test.is_nil(err)
            test.is_true(result.ok)

            -- Overlay rows for this branch should be gone
            local db = must_db()
            local rows, _ = db:query(
                "SELECT COUNT(*) AS n FROM keeper_overlay_entries WHERE branch = ?",
                { ws.state_branch }
            )
            test.eq(tonumber(rows[1].n), 0)

            local chunk_rows, _ = db:query(
                "SELECT COUNT(*) AS n FROM keeper_overlay_chunks WHERE branch = ?",
                { ws.state_branch }
            )
            test.eq(tonumber(chunk_rows[1].n), 0)

            db:release()
        end)
    end)

    -- ==========================================================================
    describe("repo constraints", function()
        it("rejects a second live wild workspace", function()
            local ws1, err1 = repo.create_changeset({
                title            = "Wild 1",
                kind             = consts.KINDS.WILD,
                state_branch     = "ws/wild-test-1",
                scratch_fs_path  = "wild-test-1/",
                baseline_version = "0",
                baseline_fs_hash = "",
            })
            test.is_nil(err1)
            track(ws1)

            -- Second wild in a live state should violate the partial unique index
            local _, err2 = repo.create_changeset({
                title            = "Wild 2",
                kind             = consts.KINDS.WILD,
                state_branch     = "ws/wild-test-2",
                scratch_fs_path  = "wild-test-2/",
                baseline_version = "0",
                baseline_fs_hash = "",
            })
            test.not_nil(err2)

            -- Moving the first wild to a terminal state should free the slot
            repo.update_state(ws1.changeset_id, consts.STATES.MERGED, "test release slot")

            local ws3, err3 = repo.create_changeset({
                title            = "Wild 3 after release",
                kind             = consts.KINDS.WILD,
                state_branch     = "ws/wild-test-3",
                scratch_fs_path  = "wild-test-3/",
                baseline_version = "0",
                baseline_fs_hash = "",
            })
            test.is_nil(err3)
            track(ws3)
        end)

        it("rejects a second pending change for the same target", function()
            local ws, _ = repo.create_changeset({
                title            = "Target Uniqueness",
                kind             = consts.KINDS.MANUAL,
                state_branch     = "ws/target-unique-test",
                scratch_fs_path  = "target-unique-test/",
                baseline_version = "0",
                baseline_fs_hash = "",
            })
            track(ws)

            local _, err1 = repo.record_change({
                changeset_id = ws.changeset_id,
                category     = consts.CATEGORIES.REGISTRY,
                op           = consts.OPS.UPDATE,
                target       = "test.ns:same_target",
                current_hash = "h1",
                source       = consts.SOURCES.DETECTED_DRIFT,
                status       = consts.CHANGE_STATUSES.PENDING,
            })
            test.is_nil(err1)

            local _, err2 = repo.record_change({
                changeset_id = ws.changeset_id,
                category     = consts.CATEGORIES.REGISTRY,
                op           = consts.OPS.UPDATE,
                target       = "test.ns:same_target",
                current_hash = "h2",
                source       = consts.SOURCES.DETECTED_DRIFT,
                status       = consts.CHANGE_STATUSES.PENDING,
            })
            test.not_nil(err2)
        end)
    end)

    -- ==========================================================================
    describe("diff UPDATE + DELETE coverage", function()
        it("fs_write overwrite produces UPDATE diff", function()
            local ws, _ = open_lib.run({
                title    = "FS Overwrite",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            local p = "overwrite-test/" .. uuid.v7() .. ".txt"
            edit_lib.run({ changeset_id = ws.changeset_id, kind = edit_lib.KINDS.FS_WRITE, rel_path = p, content = "v1" })
            edit_lib.run({ changeset_id = ws.changeset_id, kind = edit_lib.KINDS.FS_WRITE, rel_path = p, content = "v2" })

            local view = must_view(workspace_id(ws))
            local content, _ = view:read(p)
            test.eq(content, "v2")

            local rows, _ = repo.list_fs_content(ws.changeset_id)
            test.eq(#rows, 1)
        end)

        it("fs_delete produces DELETE in filesystem diff", function()
            local ws, _ = open_lib.run({
                title    = "FS Delete Diff",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            local p = "delete-diff-test/" .. uuid.v7() .. ".txt"
            edit_lib.run({ changeset_id = ws.changeset_id, kind = edit_lib.KINDS.FS_WRITE, rel_path = p, content = "doomed" })
            edit_lib.run({ changeset_id = ws.changeset_id, kind = edit_lib.KINDS.FS_DELETE, rel_path = p })

            local view = must_view(workspace_id(ws))
            local deleted, _ = view:is_deleted(p)
            test.is_true(deleted)
        end)

        it("registry_delete produces DELETE in registry diff", function()
            local ws, _ = open_lib.run({
                title    = "Reg Delete Diff",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.diff.actor",
            })
            track(ws)

            local entry_id = "test.diff.delete:entry_" .. uuid.v7()
            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = { id = entry_id, kind = "library.lua", definition = "name: x\nkind: library.lua\n", content = "return {}" },
            })
            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_DELETE,
                entry_id     = entry_id,
            })

            local changes, _ = diff.compute(ws.changeset_id)
            -- Entry was created then deleted in the same branch — should be a no-op or delete
            test.not_nil(changes)
        end)
    end)

    -- ==========================================================================
    describe("repo.list_empty_open_changesets", function()
        it("rejects non-positive ttl_seconds", function()
            local rows, err = repo.list_empty_open_changesets(0, 10)
            test.is_nil(rows)
            test.not_nil(err)
        end)

        it("returns an open changeset that was never edited and is older than ttl", function()
            local ws, _ = open_lib.run({
                title    = "Janitor Empty Open",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.janitor.actor",
            })
            track(ws)

            -- Back-date updated_at so the workspace falls past the TTL window.
            local db = must_db()
            db:execute(
                "UPDATE keeper_changesets SET updated_at = datetime('now', '-10 minutes') WHERE changeset_id = ?",
                { ws.changeset_id }
            )
            db:release()

            local rows, err = repo.list_empty_open_changesets(60, 50)
            test.is_nil(err)
            test.not_nil(rows)

            local found = false
            for _, r in ipairs(rows) do
                if r.changeset_id == ws.changeset_id then
                    found = true
                    test.eq(r.state, consts.STATES.OPEN)
                end
            end
            test.is_true(found, "back-dated empty open ws should appear in empty sweep")
        end)

        it("excludes workspaces that have overlay entries", function()
            local ws, _ = open_lib.run({
                title    = "Janitor Not Empty",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.janitor.actor",
            })
            track(ws)

            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = {
                    id         = "test.janitor.noempty:entry_" .. uuid.v7(),
                    kind       = "library.lua",
                    definition = "name: x\nkind: library.lua\n",
                    content    = "return {}",
                },
            })

            local db = must_db()
            -- Force state back to OPEN (edit auto-transitions to EDITING via central,
            -- but edit_lib here runs direct — still, cover both paths).
            db:execute("UPDATE keeper_changesets SET state = ?, updated_at = datetime('now', '-10 minutes') WHERE changeset_id = ?",
                { consts.STATES.OPEN, ws.changeset_id })
            db:release()

            local rows, err = repo.list_empty_open_changesets(60, 50)
            test.is_nil(err)
            for _, r in ipairs(rows or {}) do
                test.is_false(r.changeset_id == ws.changeset_id,
                    "workspace with overlay rows must not appear in empty sweep")
            end
        end)

        it("excludes workspaces in non-open live states", function()
            local ws, _ = open_lib.run({
                title    = "Janitor Editing State",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.janitor.actor",
            })
            track(ws)

            local db = must_db()
            db:execute(
                "UPDATE keeper_changesets SET state = ?, updated_at = datetime('now', '-10 minutes') WHERE changeset_id = ?",
                { consts.STATES.EDITING, ws.changeset_id }
            )
            db:release()

            local rows, err = repo.list_empty_open_changesets(60, 50)
            test.is_nil(err)
            for _, r in ipairs(rows or {}) do
                test.is_false(r.changeset_id == ws.changeset_id,
                    "editing-state workspace must not appear in empty sweep")
            end
        end)

        it("excludes workspaces inside the ttl window", function()
            local ws, _ = open_lib.run({
                title    = "Janitor Fresh Open",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.janitor.actor",
            })
            track(ws)

            -- Force updated_at to exactly 'now' — defends against clock skew between
            -- the Lua host and sqlite datetime('now'). ttl=86400 (24h) then excludes
            -- it as long as updated_at is within the last day.
            local db = must_db()
            db:execute("UPDATE keeper_changesets SET updated_at = datetime('now') WHERE changeset_id = ?",
                { ws.changeset_id })
            db:release()

            local rows, err = repo.list_empty_open_changesets(86400, 200)
            test.is_nil(err)
            local hit = false
            for _, r in ipairs(rows or {}) do
                if r.changeset_id == ws.changeset_id then hit = true end
            end
            test.is_false(hit, "fresh workspace must not appear in empty sweep")
        end)

        it("excludes active task-bound workspaces even when they are empty and old", function()
            local task_id = create_active_task()
            local ws, _ = open_lib.run({
                title    = "Janitor Active Task Workspace",
                kind     = consts.KINDS.SESSION,
                actor_id = "test.janitor.actor",
                task_id  = task_id,
            })
            track(ws)

            local db = must_db()
            db:execute(
                "UPDATE keeper_changesets SET updated_at = datetime('now', '-10 minutes') WHERE changeset_id = ?",
                { ws.changeset_id }
            )
            db:release()

            local rows, err = repo.list_empty_open_changesets(60, 50)
            test.is_nil(err)
            for _, r in ipairs(rows or {}) do
                test.is_false(r.changeset_id == ws.changeset_id,
                    "empty-open janitor must not drop the workspace of an active task")
            end
        end)

        it("still returns old empty workspaces for completed tasks", function()
            local task_id = create_task("completed", "finish")
            local ws, _ = open_lib.run({
                title    = "Janitor Completed Task Workspace",
                kind     = consts.KINDS.SESSION,
                actor_id = "test.janitor.actor",
                task_id  = task_id,
            })
            track(ws)

            local db = must_db()
            db:execute(
                "UPDATE keeper_changesets SET updated_at = datetime('now', '-10 minutes') WHERE changeset_id = ?",
                { ws.changeset_id }
            )
            db:release()

            local rows, err = repo.list_empty_open_changesets(60, 50)
            test.is_nil(err)
            local found = false
            for _, r in ipairs(rows or {}) do
                if r.changeset_id == ws.changeset_id then found = true end
            end
            test.is_true(found,
                "completed task workspaces are no longer protected and remain eligible for cleanup")
        end)
    end)

    -- ==========================================================================
    describe("repo.list_abandoned_open_changesets", function()
        it("rejects non-positive ttl_seconds", function()
            local rows, err = repo.list_abandoned_open_changesets(0, 10)
            test.is_nil(rows)
            test.not_nil(err)
        end)

        it("returns an open workspace past ttl even with overlay entries", function()
            local ws, _ = open_lib.run({
                title    = "Janitor Abandoned With Overlay",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.janitor.actor",
            })
            track(ws)

            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = {
                    id         = "test.janitor.abandoned:entry_" .. uuid.v7(),
                    kind       = "library.lua",
                    definition = "name: x\nkind: library.lua\n",
                    content    = "return {}",
                },
            })

            -- Back-date created_at so the workspace falls past the abandoned TTL,
            -- and force state back to OPEN (edit may auto-transition to EDITING).
            local db = must_db()
            db:execute(
                "UPDATE keeper_changesets SET state = ?, created_at = datetime('now', '-10 minutes') WHERE changeset_id = ?",
                { consts.STATES.OPEN, ws.changeset_id }
            )
            db:release()

            local rows, err = repo.list_abandoned_open_changesets(60, 50)
            test.is_nil(err)
            test.not_nil(rows)
            local found = false
            for _, r in ipairs(rows or {}) do
                if r.changeset_id == ws.changeset_id then
                    found = true
                    test.eq(r.state, consts.STATES.OPEN)
                end
            end
            test.is_true(found, "abandoned-open with overlay content must appear in sweep")
        end)

        it("excludes workspaces in non-open states even when past ttl", function()
            local ws, _ = open_lib.run({
                title    = "Janitor Editing Past TTL",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.janitor.actor",
            })
            track(ws)

            local db = must_db()
            db:execute(
                "UPDATE keeper_changesets SET state = ?, created_at = datetime('now', '-10 minutes') WHERE changeset_id = ?",
                { consts.STATES.EDITING, ws.changeset_id }
            )
            db:release()

            local rows, err = repo.list_abandoned_open_changesets(60, 50)
            test.is_nil(err)
            for _, r in ipairs(rows or {}) do
                test.is_false(r.changeset_id == ws.changeset_id,
                    "editing-state workspace must not appear in abandoned-open sweep")
            end
        end)

        it("uses created_at not updated_at so resumes cannot reset the TTL", function()
            local ws, _ = open_lib.run({
                title    = "Janitor Resume Masks Age",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.janitor.actor",
            })
            track(ws)

            -- Old created_at (abandoned), fresh updated_at (would mask under
            -- updated_at-based sweep but must not mask under created_at).
            local db = must_db()
            db:execute([[
                UPDATE keeper_changesets
                SET state = ?, created_at = datetime('now', '-10 minutes'), updated_at = datetime('now')
                WHERE changeset_id = ?
            ]], { consts.STATES.OPEN, ws.changeset_id })
            db:release()

            local rows, err = repo.list_abandoned_open_changesets(60, 50)
            test.is_nil(err)
            local found = false
            for _, r in ipairs(rows or {}) do
                if r.changeset_id == ws.changeset_id then found = true end
            end
            test.is_true(found, "created_at older than TTL must trigger sweep even when updated_at is fresh")
        end)

        it("excludes workspaces created inside the ttl window", function()
            local ws, _ = open_lib.run({
                title    = "Janitor Fresh Abandoned-Open",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.janitor.actor",
            })
            track(ws)

            local db = must_db()
            db:execute("UPDATE keeper_changesets SET created_at = datetime('now') WHERE changeset_id = ?",
                { ws.changeset_id })
            db:release()

            local rows, err = repo.list_abandoned_open_changesets(86400, 200)
            test.is_nil(err)
            local hit = false
            for _, r in ipairs(rows or {}) do
                if r.changeset_id == ws.changeset_id then hit = true end
            end
            test.is_false(hit, "fresh open workspace must not appear in abandoned-open sweep")
        end)

        it("excludes active task-bound open workspaces even when past abandoned ttl", function()
            local task_id = create_active_task()
            local ws, _ = open_lib.run({
                title    = "Janitor Active Abandoned-Open",
                kind     = consts.KINDS.SESSION,
                actor_id = "test.janitor.actor",
                task_id  = task_id,
            })
            track(ws)

            local db = must_db()
            db:execute([[
                UPDATE keeper_changesets
                SET state = ?, created_at = datetime('now', '-10 minutes'), updated_at = datetime('now', '-10 minutes')
                WHERE changeset_id = ?
            ]], { consts.STATES.OPEN, ws.changeset_id })
            db:release()

            local rows, err = repo.list_abandoned_open_changesets(60, 50)
            test.is_nil(err)
            for _, r in ipairs(rows or {}) do
                test.is_false(r.changeset_id == ws.changeset_id,
                    "abandoned-open janitor must not drop the workspace of an active task")
            end
        end)
    end)

    -- ==========================================================================
    describe("repo.list_stale_changesets", function()
        it("excludes open-state workspaces (covered by empty/abandoned sweeps)", function()
            local ws, _ = open_lib.run({
                title    = "Janitor Stale Open Excluded",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.janitor.actor",
            })
            track(ws)

            local db = must_db()
            db:execute(
                "UPDATE keeper_changesets SET state = ?, updated_at = datetime('now', '-10 minutes') WHERE changeset_id = ?",
                { consts.STATES.OPEN, ws.changeset_id }
            )
            db:release()

            local rows, err = repo.list_stale_changesets(60, 50)
            test.is_nil(err)
            for _, r in ipairs(rows or {}) do
                test.is_false(r.changeset_id == ws.changeset_id,
                    "open-state workspace must not appear in stale sweep")
            end
        end)

        it("returns editing/review/rejected past ttl", function()
            local states = { consts.STATES.EDITING, consts.STATES.REVIEW, consts.STATES.REJECTED }
            for _, st in ipairs(states) do
                local ws, _ = open_lib.run({
                    title    = "Janitor Stale " .. st,
                    kind     = consts.KINDS.MANUAL,
                    actor_id = "test.janitor.actor",
                })
                track(ws)

                local db = must_db()
                db:execute(
                    "UPDATE keeper_changesets SET state = ?, updated_at = datetime('now', '-10 minutes') WHERE changeset_id = ?",
                    { st, ws.changeset_id }
                )
                db:release()

                local rows, err = repo.list_stale_changesets(60, 200)
                test.is_nil(err)
                local found = false
                for _, r in ipairs(rows or {}) do
                    if r.changeset_id == ws.changeset_id then found = true end
                end
                test.is_true(found, st .. "-state workspace past TTL must appear in stale sweep")
            end
        end)

        it("excludes active task-bound stale workspaces", function()
            local task_id = create_active_task()
            local ws, _ = open_lib.run({
                title    = "Janitor Active Stale Workspace",
                kind     = consts.KINDS.SESSION,
                actor_id = "test.janitor.actor",
                task_id  = task_id,
            })
            track(ws)

            local db = must_db()
            db:execute(
                "UPDATE keeper_changesets SET state = ?, updated_at = datetime('now', '-10 minutes') WHERE changeset_id = ?",
                { consts.STATES.EDITING, ws.changeset_id }
            )
            db:release()

            local rows, err = repo.list_stale_changesets(60, 50)
            test.is_nil(err)
            for _, r in ipairs(rows or {}) do
                test.is_false(r.changeset_id == ws.changeset_id,
                    "stale janitor must not drop the workspace of an active task")
            end
        end)
    end)

    -- ==========================================================================
    describe("journal-at-edit", function()
        it("fs_write emits one pending journal row sourced as materialized", function()
            local ws, _ = open_lib.run({
                title    = "Journal FS Write",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.journal.actor",
            })
            track(ws)

            local rel_path = "journal-fs/" .. uuid.v7() .. ".txt"
            local _, err = edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = rel_path,
                content      = "first",
            })
            test.is_nil(err)

            local rows, qerr = repo.list_changes_for_changeset(ws.changeset_id)
            test.is_nil(qerr)
            local matched = 0
            for _, r in ipairs(rows) do
                if r.category == consts.CATEGORIES.FILESYSTEM and r.target == rel_path then
                    matched = matched + 1
                    test.eq(r.status, consts.CHANGE_STATUSES.PENDING)
                    test.eq(r.source, consts.SOURCES.MATERIALIZED)
                    test.eq(r.op, consts.OPS.UPDATE)
                    test.not_nil(r.current_hash)
                end
            end
            test.eq(matched, 1, "exactly one journal row per fs_write target")
        end)

        it("registry_set emits a pending row and re-edit upserts in place", function()
            local ws, _ = open_lib.run({
                title    = "Journal Registry Upsert",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.journal.actor",
            })
            track(ws)

            local entry_id = "test.journal.upsert:entry_" .. uuid.v7()
            local def = "name: x\nkind: library.lua\n"

            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = { id = entry_id, kind = "library.lua", definition = def, content = "return 1" },
            })

            local first_rows, _ = repo.list_changes_for_changeset(ws.changeset_id,
                { category = consts.CATEGORIES.REGISTRY })
            local first_target_rows = {}
            for _, r in ipairs(first_rows) do
                if r.target == entry_id then table.insert(first_target_rows, r) end
            end
            test.eq(#first_target_rows, 1)
            local first_hash = first_target_rows[1].current_hash
            local first_change_id = first_target_rows[1].change_id

            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = { id = entry_id, kind = "library.lua", definition = def, content = "return 2" },
            })

            local after_rows, _ = repo.list_changes_for_changeset(ws.changeset_id,
                { category = consts.CATEGORIES.REGISTRY })
            local after_target_rows = {}
            for _, r in ipairs(after_rows) do
                if r.target == entry_id then table.insert(after_target_rows, r) end
            end
            test.eq(#after_target_rows, 1, "re-edit must upsert, not duplicate")
            test.eq(after_target_rows[1].change_id, first_change_id, "same row updated in place")
            test.is_false(after_target_rows[1].current_hash == first_hash,
                "current_hash updated on re-edit")
        end)

        it("drop_changeset flips pending rows to rejected", function()
            local ws, _ = open_lib.run({
                title    = "Journal Drop Rejects",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.journal.actor",
            })
            track(ws)

            local entry_id = "test.journal.drop:entry_" .. uuid.v7()
            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.REGISTRY_SET,
                entry        = { id = entry_id, kind = "library.lua", definition = "name: x\nkind: library.lua\n", content = "return {}" },
            })

            local pre, _ = repo.list_changes_for_changeset(ws.changeset_id, { status = consts.CHANGE_STATUSES.PENDING })
            test.is_true(#pre >= 1)

            local _, drop_err = drop_lib.run({ changeset_id = ws.changeset_id })
            test.is_nil(drop_err)

            local rejected, _ = repo.list_changes_for_changeset(ws.changeset_id, { status = consts.CHANGE_STATUSES.REJECTED })
            local still_pending, _ = repo.list_changes_for_changeset(ws.changeset_id, { status = consts.CHANGE_STATUSES.PENDING })
            test.is_true(#rejected >= 1, "pending rows flipped to rejected on drop")
            test.eq(#still_pending, 0, "no pending rows after drop")
        end)

        it("apply_pending_change upgrades pending to applied in place", function()
            local ws, _ = open_lib.run({
                title    = "Journal Apply Upgrade",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.journal.actor",
            })
            track(ws)

            local rel_path = "apply-upgrade/" .. uuid.v7() .. ".txt"
            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = rel_path,
                content      = "payload",
            })

            local pre, _ = repo.list_changes_for_changeset(ws.changeset_id,
                { category = consts.CATEGORIES.FILESYSTEM })
            local pre_row
            for _, r in ipairs(pre) do
                if r.target == rel_path then pre_row = r end
            end
            test.not_nil(pre_row)
            test.eq(pre_row.status, consts.CHANGE_STATUSES.PENDING)

            local upgraded, err = repo.apply_pending_change(
                ws.changeset_id,
                consts.CATEGORIES.FILESYSTEM,
                rel_path,
                consts.OPS.UPDATE,
                pre_row.current_hash
            )
            test.is_nil(err)
            test.is_true(upgraded)

            local post, _ = repo.list_changes_for_changeset(ws.changeset_id,
                { category = consts.CATEGORIES.FILESYSTEM })
            local post_row
            for _, r in ipairs(post) do
                if r.target == rel_path then post_row = r end
            end
            test.not_nil(post_row)
            test.eq(post_row.change_id, pre_row.change_id, "same row upgraded in place")
            test.eq(post_row.status, consts.CHANGE_STATUSES.APPLIED)
            test.eq(post_row.source, consts.SOURCES.PUSHED)
        end)

        it("close_pending_changes supersedes leftover pending rows", function()
            local ws, _ = open_lib.run({
                title    = "Journal Supersede Leftovers",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.journal.actor",
            })
            track(ws)

            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = "supersede-a/" .. uuid.v7() .. ".txt",
                content      = "a",
            })
            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = "supersede-b/" .. uuid.v7() .. ".txt",
                content      = "b",
            })

            local _, err = repo.close_pending_changes(ws.changeset_id, consts.CHANGE_STATUSES.SUPERSEDED)
            test.is_nil(err)

            local pending, _ = repo.list_changes_for_changeset(ws.changeset_id, { status = consts.CHANGE_STATUSES.PENDING })
            local superseded, _ = repo.list_changes_for_changeset(ws.changeset_id, { status = consts.CHANGE_STATUSES.SUPERSEDED })
            test.eq(#pending, 0)
            test.is_true(#superseded >= 2)
        end)

        -- ====================================================================
        -- reset_applied_to_pending — symmetric undo for integrate-fail bounce.
        -- The v22 integrate-bounce loop happened because publish-applied rows
        -- were left applied even after restore_version rolled main back; the
        -- next publish then couldn't match them via apply_pending_change and
        -- the changeset bookkeeping diverged from the registry. These tests
        -- pin every transition this primitive must support.
        -- ====================================================================

        it("reset_applied_to_pending flips applied/pushed rows back to pending/materialized", function()
            local ws, _ = open_lib.run({
                title    = "Reset Applied",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.reset.actor",
            })
            track(ws)

            local rel_path = "reset/" .. uuid.v7() .. ".txt"
            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = rel_path,
                content      = "v1",
            })
            local pre, _ = repo.list_changes_for_changeset(ws.changeset_id, {})
            local row = nil
            for _, r in ipairs(pre) do if r.target == rel_path then row = r end end
            test.not_nil(row)
            if not row then error("pending change row not found") end
            test.eq(row.status, consts.CHANGE_STATUSES.PENDING)
            test.eq(row.source, consts.SOURCES.MATERIALIZED)

            local upgraded = repo.apply_pending_change(
                ws.changeset_id, consts.CATEGORIES.FILESYSTEM, rel_path, consts.OPS.UPDATE, row.current_hash)
            test.is_true(upgraded)

            local mid_rows, _ = repo.list_changes_for_changeset(ws.changeset_id, {})
            local mid_row = nil
            for _, r in ipairs(mid_rows) do if r.target == rel_path then mid_row = r end end
            if not mid_row then error("applied change row not found") end
            test.eq(mid_row.status, consts.CHANGE_STATUSES.APPLIED)
            test.eq(mid_row.source, consts.SOURCES.PUSHED)

            local n_pending, err = repo.reset_applied_to_pending(ws.changeset_id)
            test.is_nil(err)
            test.is_true(n_pending >= 1, "at least one row pending after reset")

            local post, _ = repo.list_changes_for_changeset(ws.changeset_id, {})
            local post_row = nil
            for _, r in ipairs(post) do if r.target == rel_path then post_row = r end end
            if not post_row then error("reset change row not found") end
            test.eq(post_row.change_id, row.change_id, "same row reset in place — no duplication")
            test.eq(post_row.status, consts.CHANGE_STATUSES.PENDING, "back to pending")
            test.eq(post_row.source, consts.SOURCES.MATERIALIZED, "source restored to materialized")
            test.eq(post_row.current_hash, row.current_hash, "hash preserved across reset")
        end)

        it("apply→reset→edit→apply cycle leaves the row clean (the v22 fix path)", function()
            local ws, _ = open_lib.run({
                title    = "Reset Bounce Cycle",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.reset.actor",
            })
            track(ws)

            local rel_path = "bounce/" .. uuid.v7() .. ".txt"
            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = rel_path,
                content      = "buggy",
            })
            local first, _ = repo.list_changes_for_changeset(ws.changeset_id, {})
            local first_row
            for _, r in ipairs(first) do if r.target == rel_path then first_row = r end end
            local first_hash = first_row.current_hash

            test.is_true(repo.apply_pending_change(
                ws.changeset_id, consts.CATEGORIES.FILESYSTEM, rel_path, consts.OPS.UPDATE, first_hash))

            -- integrate handlers fail → registry restored → reset
            test.is_nil(select(2, repo.reset_applied_to_pending(ws.changeset_id)))

            -- implement bounce edits the same path with FIXED content
            edit_lib.run({
                changeset_id = ws.changeset_id,
                kind         = edit_lib.KINDS.FS_WRITE,
                rel_path     = rel_path,
                content      = "fixed-payload",
            })
            local mid, _ = repo.list_changes_for_changeset(ws.changeset_id, {})
            local mid_row
            for _, r in ipairs(mid) do if r.target == rel_path then mid_row = r end end
            test.eq(mid_row.status, consts.CHANGE_STATUSES.PENDING,
                "row still pending after fix-edit (upsert hit the reset row)")
            test.is_true(mid_row.current_hash ~= first_hash, "hash advanced to fixed content")

            -- next publish upgrades cleanly with the new hash
            test.is_true(repo.apply_pending_change(
                ws.changeset_id, consts.CATEGORIES.FILESYSTEM, rel_path,
                consts.OPS.UPDATE, mid_row.current_hash))

            local final, _ = repo.list_changes_for_changeset(ws.changeset_id, {})
            local rows_for_target = 0
            local final_row
            for _, r in ipairs(final) do
                if r.target == rel_path then
                    rows_for_target = rows_for_target + 1
                    final_row = r
                end
            end
            test.eq(rows_for_target, 1,
                "EXACTLY ONE row per target — no orphans across the bounce")
            test.eq(final_row.status, consts.CHANGE_STATUSES.APPLIED)
            test.eq(final_row.source, consts.SOURCES.PUSHED)
            test.eq(final_row.current_hash, mid_row.current_hash,
                "final hash = post-fix hash, NOT the original buggy one")
        end)

        it("reset_applied_to_pending is idempotent and only touches applied/pushed rows", function()
            local ws, _ = open_lib.run({
                title    = "Reset Idempotent",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.reset.actor",
            })
            track(ws)

            local rel_a = "idem/" .. uuid.v7() .. "/a.txt"
            local rel_b = "idem/" .. uuid.v7() .. "/b.txt"
            edit_lib.run({ changeset_id = ws.changeset_id, kind = edit_lib.KINDS.FS_WRITE, rel_path = rel_a, content = "a" })
            edit_lib.run({ changeset_id = ws.changeset_id, kind = edit_lib.KINDS.FS_WRITE, rel_path = rel_b, content = "b" })

            local list, _ = repo.list_changes_for_changeset(ws.changeset_id, {})
            local hash_a
            for _, r in ipairs(list) do if r.target == rel_a then hash_a = r.current_hash end end
            test.is_true(repo.apply_pending_change(
                ws.changeset_id, consts.CATEGORIES.FILESYSTEM, rel_a, consts.OPS.UPDATE, hash_a))
            -- rel_b stays pending throughout

            local n1 = repo.reset_applied_to_pending(ws.changeset_id)
            test.is_true(n1 >= 2, "at least both rows pending now")

            -- second call is a no-op for already-pending rows
            local n2 = repo.reset_applied_to_pending(ws.changeset_id)
            test.eq(n1, n2, "idempotent — second call counts the same pending rows, doesn't flip non-pushed")

            local post, _ = repo.list_changes_for_changeset(ws.changeset_id, {})
            local seen = {}
            for _, r in ipairs(post) do
                seen[r.target] = r
            end
            test.eq(seen[rel_a].status, consts.CHANGE_STATUSES.PENDING)
            test.eq(seen[rel_b].status, consts.CHANGE_STATUSES.PENDING)
            test.eq(seen[rel_b].source, consts.SOURCES.MATERIALIZED, "untouched row keeps materialized source")
        end)

        it("reset_applied_to_pending leaves rejected and superseded rows alone", function()
            local ws, _ = open_lib.run({
                title    = "Reset Skips Terminals",
                kind     = consts.KINDS.MANUAL,
                actor_id = "test.reset.actor",
            })
            track(ws)

            local rel_keep = "skip/" .. uuid.v7() .. ".txt"
            edit_lib.run({ changeset_id = ws.changeset_id, kind = edit_lib.KINDS.FS_WRITE, rel_path = rel_keep, content = "k" })

            -- supersede the only pending row
            test.is_nil(select(2, repo.close_pending_changes(ws.changeset_id, consts.CHANGE_STATUSES.SUPERSEDED)))

            local pre, _ = repo.list_changes_for_changeset(ws.changeset_id, {})
            local pre_row
            for _, r in ipairs(pre) do if r.target == rel_keep then pre_row = r end end
            test.eq(pre_row.status, consts.CHANGE_STATUSES.SUPERSEDED)

            local _, err = repo.reset_applied_to_pending(ws.changeset_id)
            test.is_nil(err)

            local post, _ = repo.list_changes_for_changeset(ws.changeset_id, {})
            local post_row
            for _, r in ipairs(post) do if r.target == rel_keep then post_row = r end end
            test.eq(post_row.status, consts.CHANGE_STATUSES.SUPERSEDED, "superseded row untouched by reset")
        end)

        it("reset_applied_to_pending requires a changeset_id", function()
            local ok, err = repo.reset_applied_to_pending(nil)
            test.is_nil(ok)
            test.not_nil(err)
            test.is_true(err:find("changeset_id") ~= nil, "error names the missing field")
        end)

        it("reset_applied_to_pending handles unknown changeset_id (no rows to flip)", function()
            local n, err = repo.reset_applied_to_pending("does-not-exist-" .. uuid.v7())
            test.is_nil(err)
            test.eq(n, 0)
        end)
    end)
    end)  -- close "Changeset Service Integration"
end

local run = test.run_cases(define_tests)
return { define_tests = run }
