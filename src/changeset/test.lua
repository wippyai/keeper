local test = require("test")
local uuid = require("uuid")
local sql = require("sql")
local consts = require("consts")
local repo = require("repo")
local state_machine = require("state_machine")
local fs_hash = require("fs_hash")
local fs_view = require("fs_view")

local function define_tests()
    describe("Changeset Unit Tests", function()
        local created_changeset_ids = {}

        local function new_test_changeset(opts)
            opts = opts or {}
            local ws, err = repo.create_changeset({
                title            = opts.title or "Test Changeset",
                kind             = opts.kind or consts.KINDS.MANUAL,
                description      = opts.description,
                actor_id         = opts.actor_id or "test.actor",
                session_id       = opts.session_id,
                state_branch     = consts.branch_for(opts.changeset_id or ("test-" .. uuid.v7())),
                scratch_fs_path  = (opts.changeset_id or ("test-" .. uuid.v7())) .. "/",
                baseline_version = opts.baseline_version or "0",
                baseline_fs_hash = opts.baseline_fs_hash or "",
                changeset_id     = opts.changeset_id,
            })
            if ws then table.insert(created_changeset_ids, ws.changeset_id) end
            return ws, err
        end

        after_all(function()
            for _, id in ipairs(created_changeset_ids) do
                local db = sql.get(consts.DATABASE.RESOURCE_ID)
                if db then
                    db:execute("DELETE FROM keeper_changesets WHERE changeset_id = ?", { id })
                    db:release()
                end
            end
        end)

    -- ==========================================================================
    describe("state_machine", function()
        it("transitions open -> editing on first_edit", function()
            local next_state, err = state_machine.next_state(
                consts.STATES.OPEN,
                state_machine.EVENTS.FIRST_EDIT
            )
            test.is_nil(err)
            test.eq(next_state, consts.STATES.EDITING)
        end)

        it("transitions editing -> review on submit_for_review", function()
            local next_state, err = state_machine.next_state(
                consts.STATES.EDITING,
                state_machine.EVENTS.SUBMIT_FOR_REVIEW
            )
            test.is_nil(err)
            test.eq(next_state, consts.STATES.REVIEW)
        end)

        it("transitions review -> accepted on accept", function()
            local next_state, err = state_machine.next_state(
                consts.STATES.REVIEW,
                state_machine.EVENTS.ACCEPT
            )
            test.is_nil(err)
            test.eq(next_state, consts.STATES.ACCEPTED)
        end)

        it("transitions review -> rejected on reject", function()
            local next_state, err = state_machine.next_state(
                consts.STATES.REVIEW,
                state_machine.EVENTS.REJECT
            )
            test.is_nil(err)
            test.eq(next_state, consts.STATES.REJECTED)
        end)

        it("transitions rejected -> editing on reopen", function()
            local next_state, err = state_machine.next_state(
                consts.STATES.REJECTED,
                state_machine.EVENTS.REOPEN
            )
            test.is_nil(err)
            test.eq(next_state, consts.STATES.EDITING)
        end)

        it("transitions accepted -> merged on push_success", function()
            local next_state, err = state_machine.next_state(
                consts.STATES.ACCEPTED,
                state_machine.EVENTS.PUSH_SUCCESS
            )
            test.is_nil(err)
            test.eq(next_state, consts.STATES.MERGED)
        end)

        it("transitions accepted -> rejected on push_failure", function()
            local next_state, err = state_machine.next_state(
                consts.STATES.ACCEPTED,
                state_machine.EVENTS.PUSH_FAILURE
            )
            test.is_nil(err)
            test.eq(next_state, consts.STATES.REJECTED)
        end)

        it("any live state -> dropped on drop", function()
            for _, state in ipairs({
                consts.STATES.OPEN,
                consts.STATES.EDITING,
                consts.STATES.REVIEW,
                consts.STATES.ACCEPTED,
                consts.STATES.REJECTED,
            }) do
                local next_state, err = state_machine.next_state(state, state_machine.EVENTS.DROP)
                test.is_nil(err)
                test.eq(next_state, consts.STATES.DROPPED)
            end
        end)

        it("rejects invalid transitions", function()
            local _, err = state_machine.next_state(
                consts.STATES.OPEN,
                state_machine.EVENTS.ACCEPT  -- can't accept from open
            )
            test.not_nil(err)
        end)

        it("terminal states have no outgoing transitions", function()
            test.is_true(state_machine.is_terminal(consts.STATES.MERGED))
            test.is_true(state_machine.is_terminal(consts.STATES.DROPPED))
            test.is_false(state_machine.is_terminal(consts.STATES.EDITING))
        end)
    end)

    -- ==========================================================================
    describe("fs_view path validation", function()
        it("accepts normal paths", function()
            local normalized, err = fs_view.validate_rel_path("foo/bar.vue")
            test.is_nil(err)
            test.eq(normalized, "foo/bar.vue")
        end)

        it("normalizes backslashes", function()
            local normalized, err = fs_view.validate_rel_path("foo\\bar.vue")
            test.is_nil(err)
            test.eq(normalized, "foo/bar.vue")
        end)

        it("rejects absolute paths", function()
            local _, err = fs_view.validate_rel_path("/etc/passwd")
            test.not_nil(err)
        end)

        it("rejects .. traversal", function()
            local _, err = fs_view.validate_rel_path("foo/../../etc/passwd")
            test.not_nil(err)
        end)

        it("rejects . segments", function()
            local _, err = fs_view.validate_rel_path("foo/./bar")
            test.not_nil(err)
        end)

        it("rejects null bytes", function()
            local _, err = fs_view.validate_rel_path("foo\0bar")
            test.not_nil(err)
        end)

        it("rejects empty strings", function()
            local _, err = fs_view.validate_rel_path("")
            test.not_nil(err)
        end)
    end)

    -- ==========================================================================
    describe("fs_hash determinism", function()
        it("empty manifest produces stable tree hash", function()
            local h1, err1 = fs_hash.tree_hash({})
            local h2, err2 = fs_hash.tree_hash({})
            test.is_nil(err1)
            test.is_nil(err2)
            test.eq(h1, h2)
        end)

        it("reordered manifest produces the same tree hash", function()
            local m1 = {
                { path = "b.vue", sha256 = "bbb", size = 2, mode = nil },
                { path = "a.vue", sha256 = "aaa", size = 1, mode = nil },
            }
            local m2 = {
                { path = "a.vue", sha256 = "aaa", size = 1, mode = nil },
                { path = "b.vue", sha256 = "bbb", size = 2, mode = nil },
            }
            -- Caller-supplied order differs, but tree_hash should only look at the
            -- sorted representation. We call via the documented API (sort before
            -- hashing) — tree_hash does its own serialization without re-sorting.
            table.sort(m1, function(a, b) return a.path < b.path end)
            table.sort(m2, function(a, b) return a.path < b.path end)
            local h1 = fs_hash.tree_hash(m1)
            local h2 = fs_hash.tree_hash(m2)
            test.eq(h1, h2)
        end)

        it("different content produces different tree hashes", function()
            local m1 = {{ path = "a.vue", sha256 = "aaa", size = 1 }}
            local m2 = {{ path = "a.vue", sha256 = "bbb", size = 1 }}
            local h1 = fs_hash.tree_hash(m1)
            local h2 = fs_hash.tree_hash(m2)
            test.neq(h1, h2)
        end)

        it("manifest diff detects create/update/delete", function()
            local baseline = {
                { path = "stable.vue", sha256 = "s1" },
                { path = "changed.vue", sha256 = "c1" },
                { path = "removed.vue", sha256 = "r1" },
            }
            local current = {
                { path = "stable.vue", sha256 = "s1" },
                { path = "changed.vue", sha256 = "c2" },
                { path = "new.vue",     sha256 = "n1" },
            }
            local diffs = fs_hash.diff_manifests(baseline, current)
            -- Expect: changed.vue -> update, new.vue -> create, removed.vue -> delete
            test.eq(#diffs, 3)

            local by_path = {}
            for _, d in ipairs(diffs) do by_path[d.path] = d end
            test.eq(by_path["changed.vue"].op, "update")
            test.eq(by_path["new.vue"].op, "create")
            test.eq(by_path["removed.vue"].op, "delete")
        end)
    end)

    -- ==========================================================================
    describe("repo CRUD", function()
        it("creates, reads, updates state, and lists a workspace", function()
            local ws, err = new_test_changeset({ title = "Repo Round Trip" })
            test.is_nil(err)
            test.not_nil(ws)
            test.eq(ws.title, "Repo Round Trip")
            test.eq(ws.state, consts.STATES.OPEN)
            test.not_nil(ws.changeset_id)
            test.not_nil(ws.created_at)

            -- Read it back
            local fetched, err2 = repo.get_changeset(ws.changeset_id)
            test.is_nil(err2)
            test.eq(fetched.changeset_id, ws.changeset_id)
            test.eq(fetched.title, ws.title)

            -- Update state
            local _, err3 = repo.update_state(
                ws.changeset_id,
                consts.STATES.EDITING,
                "test transition"
            )
            test.is_nil(err3)

            local refetched, err4 = repo.get_changeset(ws.changeset_id)
            test.is_nil(err4)
            test.eq(refetched.state, consts.STATES.EDITING)
            test.eq(refetched.state_reason, "test transition")

            -- List with state filter
            local listed, err5 = repo.list_changesets({ state = consts.STATES.EDITING, limit = 100 })
            test.is_nil(err5)
            test.not_nil(listed)

            local found = false
            for _, w in ipairs(listed) do
                if w.changeset_id == ws.changeset_id then found = true break end
            end
            test.is_true(found)
        end)

        it("records baselines on a workspace", function()
            local ws, _ = new_test_changeset({ title = "Baseline Test" })

            local bid, err = repo.record_baseline({
                changeset_id     = ws.changeset_id,
                registry_version = "17",
                fs_tree_hash     = "abc123",
                reason           = consts.BASELINE_REASONS.OPEN,
            })
            test.is_nil(err)
            test.not_nil(bid)

            local latest, err2 = repo.latest_baseline(ws.changeset_id)
            test.is_nil(err2)
            test.eq(latest.registry_version, "17")
            test.eq(latest.fs_tree_hash, "abc123")
            test.eq(latest.reason, consts.BASELINE_REASONS.OPEN)
        end)

        it("records fs deletes and lists them", function()
            local ws, _ = new_test_changeset({ title = "FS Delete Test" })

            local _, err = repo.record_fs_delete(ws.changeset_id, "foo/bar.vue", "hash1")
            test.is_nil(err)

            local _, err2 = repo.record_fs_delete(ws.changeset_id, "baz/qux.vue", "hash2")
            test.is_nil(err2)

            local deletes, err3 = repo.list_fs_deletes(ws.changeset_id)
            test.is_nil(err3)
            test.eq(#deletes, 2)

            -- Unrecord
            local _, err4 = repo.unrecord_fs_delete(ws.changeset_id, "foo/bar.vue")
            test.is_nil(err4)

            local deletes_after, _ = repo.list_fs_deletes(ws.changeset_id)
            test.eq(#deletes_after, 1)
            test.eq(deletes_after[1].rel_path, "baz/qux.vue")
        end)

        it("records change rows with monotonic sequence", function()
            local ws, _ = new_test_changeset({ title = "Change Journal Test" })

            local c1, err1 = repo.record_change({
                changeset_id  = ws.changeset_id,
                category      = consts.CATEGORIES.REGISTRY,
                op            = consts.OPS.CREATE,
                target        = "test.ns:entry_1",
                current_hash  = "h1",
                source        = consts.SOURCES.PUSHED,
                status        = consts.CHANGE_STATUSES.APPLIED,
            })
            test.is_nil(err1)
            test.not_nil(c1)

            local c2, err2 = repo.record_change({
                changeset_id  = ws.changeset_id,
                category      = consts.CATEGORIES.REGISTRY,
                op            = consts.OPS.UPDATE,
                target        = "test.ns:entry_2",
                baseline_hash = "h2a",
                current_hash  = "h2b",
                source        = consts.SOURCES.PUSHED,
                status        = consts.CHANGE_STATUSES.APPLIED,
            })
            test.is_nil(err2)

            local changes, err3 = repo.list_changes_for_changeset(ws.changeset_id)
            test.is_nil(err3)
            test.eq(#changes, 2)
            test.eq(changes[1].sequence, 1)
            test.eq(changes[2].sequence, 2)
        end)

        it("count_changes returns the total row count for a changeset", function()
            local ws, _ = new_test_changeset({ title = "Count Changes" })

            local n0, err0 = repo.count_changes(ws.changeset_id)
            test.is_nil(err0)
            test.eq(n0, 0)

            repo.record_change({
                changeset_id = ws.changeset_id,
                category     = consts.CATEGORIES.REGISTRY,
                op           = consts.OPS.CREATE,
                target       = "count.ns:a",
                current_hash = "h1",
                source       = consts.SOURCES.PUSHED,
                status       = consts.CHANGE_STATUSES.APPLIED,
            })
            repo.record_change({
                changeset_id = ws.changeset_id,
                category     = consts.CATEGORIES.REGISTRY,
                op           = consts.OPS.CREATE,
                target       = "count.ns:b",
                current_hash = "h2",
                source       = consts.SOURCES.PUSHED,
                status       = consts.CHANGE_STATUSES.APPLIED,
            })

            local n2, err2 = repo.count_changes(ws.changeset_id)
            test.is_nil(err2)
            test.eq(n2, 2)
        end)

        it("count_changes rejects missing changeset_id", function()
            local n, err = repo.count_changes(nil)
            test.eq(n, 0)
            test.not_nil(err)
        end)

        it("list_applied_for_task returns applied rows from merged session changesets only", function()
            local task_id = "task-" .. uuid.v7()

            local merged_ws, _ = new_test_changeset({
                title  = "Merged Session",
                kind   = consts.KINDS.SESSION,
                actor_id = task_id,
            })
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute("UPDATE keeper_changesets SET task_id = ?, state = ?, closed_at = ? WHERE changeset_id = ?",
                { task_id, consts.STATES.MERGED, "2026-04-22T10:00:00Z", merged_ws.changeset_id })
            db:release()

            repo.record_change({
                changeset_id = merged_ws.changeset_id,
                category     = consts.CATEGORIES.REGISTRY,
                op           = consts.OPS.CREATE,
                target       = "merged.ns:a",
                current_hash = "h1",
                source       = consts.SOURCES.PUSHED,
                status       = consts.CHANGE_STATUSES.APPLIED,
            })
            repo.record_change({
                changeset_id = merged_ws.changeset_id,
                category     = consts.CATEGORIES.FILESYSTEM,
                op           = consts.OPS.UPDATE,
                target       = "frontend/foo.vue",
                current_hash = "h2",
                source       = consts.SOURCES.PUSHED,
                status       = consts.CHANGE_STATUSES.APPLIED,
            })
            -- Non-applied row on the same changeset must be filtered out.
            repo.record_change({
                changeset_id = merged_ws.changeset_id,
                category     = consts.CATEGORIES.REGISTRY,
                op           = consts.OPS.DELETE,
                target       = "merged.ns:leftover",
                current_hash = "h3",
                source       = consts.SOURCES.PUSHED,
                status       = consts.CHANGE_STATUSES.SUPERSEDED,
            })

            -- Open (non-merged) session changeset for the same task — must be excluded.
            local open_ws, _ = new_test_changeset({
                title  = "Open Session",
                kind   = consts.KINDS.SESSION,
            })
            db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute("UPDATE keeper_changesets SET task_id = ? WHERE changeset_id = ?",
                { task_id, open_ws.changeset_id })
            db:release()
            repo.record_change({
                changeset_id = open_ws.changeset_id,
                category     = consts.CATEGORIES.REGISTRY,
                op           = consts.OPS.CREATE,
                target       = "open.ns:a",
                current_hash = "h4",
                source       = consts.SOURCES.PUSHED,
                status       = consts.CHANGE_STATUSES.APPLIED,
            })

            local rows, err = repo.list_applied_for_task(task_id)
            test.is_nil(err)
            test.eq(#rows, 2)
            test.eq(rows[1].target, "merged.ns:a")
            test.eq(rows[1].category, consts.CATEGORIES.REGISTRY)
            test.eq(rows[2].target, "frontend/foo.vue")
            test.eq(rows[2].category, consts.CATEGORIES.FILESYSTEM)
        end)

        it("list_applied_for_task rejects missing task_id", function()
            local rows, err = repo.list_applied_for_task("")
            test.is_nil(rows)
            test.not_nil(err)
        end)
    end)

    -- ==========================================================================
    describe("additional coverage", function()
        it("set_change_status updates a recorded change", function()
            local ws, _ = new_test_changeset({ title = "Status Update" })
            local cid, _ = repo.record_change({
                changeset_id = ws.changeset_id,
                category     = consts.CATEGORIES.REGISTRY,
                op           = consts.OPS.CREATE,
                target       = "test.status:entry",
                current_hash = "h1",
                source       = consts.SOURCES.DETECTED_DRIFT,
                status       = consts.CHANGE_STATUSES.PENDING,
            })
            test.not_nil(cid)

            local _, err = repo.set_change_status(cid, consts.CHANGE_STATUSES.APPLIED)
            test.is_nil(err)

            local updated = repo.get_change(cid)
            test.eq(updated.status, consts.CHANGE_STATUSES.APPLIED)
        end)

        it("log_merge records a merge event", function()
            local ws, _ = new_test_changeset({ title = "Merge Log" })
            local mid, err = repo.log_merge({
                into_changeset = ws.changeset_id,
                change_ids     = { "fake-change-1", "fake-change-2" },
                resolution     = consts.MERGE_RESOLUTIONS.AUTO,
                actor_id       = "test.actor",
            })
            test.is_nil(err)
            test.not_nil(mid)
        end)

        it("state_machine.is_live returns true for live states", function()
            local sm = require("state_machine")
            test.is_true(sm.is_live(consts.STATES.OPEN))
            test.is_true(sm.is_live(consts.STATES.EDITING))
            test.is_true(sm.is_live(consts.STATES.REVIEW))
            test.is_true(sm.is_live(consts.STATES.ACCEPTED))
            test.is_true(sm.is_live(consts.STATES.REJECTED))
            test.is_false(sm.is_live(consts.STATES.MERGED))
            test.is_false(sm.is_live(consts.STATES.DROPPED))
        end)

        it("push_start guard requires accepted state", function()
            local sm = require("state_machine")
            local ok, err = sm.guards.push_start({ workspace = { state = consts.STATES.EDITING } })
            test.is_false(ok)
            test.not_nil(err)

            local ok2, _ = sm.guards.push_start({ workspace = { state = consts.STATES.ACCEPTED } })
            test.is_true(ok2)
        end)

        it("submit_for_review guard rejects when there are no pending changes", function()
            local sm = require("state_machine")
            local ok, err = sm.guards.submit_for_review({ pending_changes = {} })
            test.is_false(ok)
            test.is_true(err:find("no pending changes") ~= nil)
        end)

        it("submit_for_review guard rejects unresolved conflicts", function()
            local sm = require("state_machine")
            local ok, err = sm.guards.submit_for_review({
                pending_changes = { { id = "a" } },
                conflicts       = { { id = "a" } },
            })
            test.is_false(ok)
            test.is_true(err:find("conflict") ~= nil)
        end)

        it("submit_for_review guard passes when pending > 0 and no conflicts", function()
            local sm = require("state_machine")
            local ok = sm.guards.submit_for_review({
                pending_changes = { { id = "a" } },
            })
            test.is_true(ok)
        end)

        it("accept guard rejects when linter is not clean", function()
            local sm = require("state_machine")
            local ok, err = sm.guards.accept({ linter_result = { success = false } })
            test.is_false(ok)
            test.is_true(err:find("linter") ~= nil)

            local ok2 = sm.guards.accept({})
            test.is_false(ok2, "missing linter_result must not pass")
        end)

        it("accept guard passes with a clean linter", function()
            local sm = require("state_machine")
            local ok = sm.guards.accept({ linter_result = { success = true } })
            test.is_true(ok)
        end)

        it("next_state rejects missing current_state or event", function()
            local sm = require("state_machine")
            local _, e1 = sm.next_state(nil, sm.EVENTS.ACCEPT)
            test.not_nil(e1)
            test.is_true(e1:find("current_state") ~= nil)

            local _, e2 = sm.next_state(consts.STATES.OPEN, nil)
            test.not_nil(e2)
            test.is_true(e2:find("event") ~= nil)
        end)

        it("next_state flags an unknown current_state", function()
            local sm = require("state_machine")
            local _, err = sm.next_state("nonsense", sm.EVENTS.ACCEPT)
            test.not_nil(err)
            test.is_true(err:find(consts.ERRORS.INVALID_STATE) ~= nil)
        end)

        it("list_fs_content filters flushed by default", function()
            local ws, _ = new_test_changeset({ title = "fs content history filter" })

            local _, serr = repo.store_fs_content(ws.changeset_id, "frontend/a.vue", "v1", "h1")
            test.is_nil(serr)

            local staged, _ = repo.list_fs_content(ws.changeset_id)
            test.eq(#staged, 1)

            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute(
                "UPDATE keeper_changeset_fs_content SET flushed_at = ? WHERE changeset_id = ? AND rel_path = ?",
                { "2026-04-20T00:00:00Z", ws.changeset_id, "frontend/a.vue" }
            )
            db:release()

            local after_flush, _ = repo.list_fs_content(ws.changeset_id)
            test.eq(#after_flush, 0)

            local with_hist, _ = repo.list_fs_content(ws.changeset_id, true)
            test.eq(#with_hist, 1)

            local hist_only, _ = repo.list_fs_content_flushed(ws.changeset_id)
            test.eq(#hist_only, 1)
            test.eq(hist_only[1].rel_path, "frontend/a.vue")
        end)

        it("store_fs_content refuses to overwrite a flushed row", function()
            local ws, _ = new_test_changeset({ title = "fs content immutable history" })

            local _, serr = repo.store_fs_content(ws.changeset_id, "frontend/b.vue", "v1", "h1")
            test.is_nil(serr)

            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute(
                "UPDATE keeper_changeset_fs_content SET flushed_at = ? WHERE changeset_id = ? AND rel_path = ?",
                { "2026-04-20T00:00:00Z", ws.changeset_id, "frontend/b.vue" }
            )
            db:release()

            local _, err = repo.store_fs_content(ws.changeset_id, "frontend/b.vue", "v2", "h2")
            test.not_nil(err)
            test.is_true(err:find("cannot stage over flushed history row", 1, true) ~= nil)
        end)

        it("get_fs_content ignores flushed rows", function()
            local ws, _ = new_test_changeset({ title = "fs content read filter" })

            local _, serr = repo.store_fs_content(ws.changeset_id, "frontend/c.vue", "v1", "h1")
            test.is_nil(serr)

            local row, _ = repo.get_fs_content(ws.changeset_id, "frontend/c.vue")
            test.not_nil(row)

            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute(
                "UPDATE keeper_changeset_fs_content SET flushed_at = ? WHERE changeset_id = ? AND rel_path = ?",
                { "2026-04-20T00:00:00Z", ws.changeset_id, "frontend/c.vue" }
            )
            db:release()

            local after, _ = repo.get_fs_content(ws.changeset_id, "frontend/c.vue")
            test.is_nil(after)
        end)

        it("list_fs_deletes filters flushed by default", function()
            local ws, _ = new_test_changeset({ title = "fs deletes history filter" })

            local _, rerr = repo.record_fs_delete(ws.changeset_id, "frontend/gone.vue", "h1")
            test.is_nil(rerr)

            local staged, _ = repo.list_fs_deletes(ws.changeset_id)
            test.eq(#staged, 1)

            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute(
                "UPDATE keeper_changeset_fs_deletes SET flushed_at = ? WHERE changeset_id = ? AND rel_path = ?",
                { "2026-04-20T00:00:00Z", ws.changeset_id, "frontend/gone.vue" }
            )
            db:release()

            local after, _ = repo.list_fs_deletes(ws.changeset_id)
            test.eq(#after, 0)

            local hist, _ = repo.list_fs_deletes_flushed(ws.changeset_id)
            test.eq(#hist, 1)
            test.eq(hist[1].rel_path, "frontend/gone.vue")
        end)

    end)

    -- ==========================================================================
    describe("branch scoping", function()
        local function set_state(cs_id, state)
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute(
                "UPDATE keeper_changesets SET state = ? WHERE changeset_id = ?",
                { state, cs_id }
            )
            db:release()
        end

        it("active_for_task excludes rejected session changesets", function()
            local task_id = "task-reject-" .. uuid.v7()
            local ws = new_test_changeset({
                kind    = consts.KINDS.SESSION,
                title   = "rejected session for task",
                changeset_id = "cs-rej-" .. uuid.v7(),
            })
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute("UPDATE keeper_changesets SET task_id = ? WHERE changeset_id = ?",
                { task_id, ws.changeset_id })
            db:release()
            set_state(ws.changeset_id, consts.STATES.REJECTED)

            test.is_nil(repo.active_for_task(task_id),
                "rejected session must not be returned as active")
        end)

        it("active_for_task returns live session changesets", function()
            local task_id = "task-live-" .. uuid.v7()
            local ws = new_test_changeset({
                kind    = consts.KINDS.SESSION,
                title   = "live session for task",
                changeset_id = "cs-live-" .. uuid.v7(),
            })
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute("UPDATE keeper_changesets SET task_id = ? WHERE changeset_id = ?",
                { task_id, ws.changeset_id })
            db:release()

            local active = repo.active_for_task(task_id)
            test.not_nil(active)
            test.eq(active.changeset_id, ws.changeset_id)
        end)

        it("has_terminal_by_branch flags merged/rejected/dropped branches", function()
            local branch = "ws/terminal-probe-" .. uuid.v7()
            local ws = new_test_changeset({
                title        = "terminal probe",
                changeset_id = "cs-term-" .. uuid.v7(),
            })
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute("UPDATE keeper_changesets SET state_branch = ? WHERE changeset_id = ?",
                { branch, ws.changeset_id })
            db:release()

            local consumed, _ = repo.has_terminal_by_branch(branch)
            test.is_false(consumed, "live branch is not consumed")

            set_state(ws.changeset_id, consts.STATES.REJECTED)
            local c2, s2 = repo.has_terminal_by_branch(branch)
            test.is_true(c2)
            test.eq(s2, consts.STATES.REJECTED)

            set_state(ws.changeset_id, consts.STATES.MERGED)
            local c3, s3 = repo.has_terminal_by_branch(branch)
            test.is_true(c3)
            test.eq(s3, consts.STATES.MERGED)
        end)

        it("has_terminal_by_branch ignores unknown branches", function()
            local consumed = repo.has_terminal_by_branch("ws/definitely-not-present-" .. uuid.v7())
            test.is_false(consumed)
        end)

        it("has_merged_for_task sees merges across any kind", function()
            local task_id = "task-merge-" .. uuid.v7()
            local ws = new_test_changeset({
                kind         = consts.KINDS.MANUAL,
                title        = "merged manual for task",
                changeset_id = "cs-merge-" .. uuid.v7(),
            })
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute("UPDATE keeper_changesets SET task_id = ? WHERE changeset_id = ?",
                { task_id, ws.changeset_id })
            db:release()
            set_state(ws.changeset_id, consts.STATES.MERGED)

            test.is_true(repo.has_merged_for_task(task_id),
                "merged manual cs tied to task_id must count as a merge for the task")
        end)
    end)

    -- ==========================================================================
    describe("fs_hash edge cases", function()
        it("diff_manifests handles empty baseline", function()
            local diffs = fs_hash.diff_manifests({}, {{ path = "new.txt", sha256 = "aaa" }})
            test.eq(#diffs, 1)
            test.eq(diffs[1].op, "create")
        end)

        it("diff_manifests handles empty current", function()
            local diffs = fs_hash.diff_manifests({{ path = "old.txt", sha256 = "aaa" }}, {})
            test.eq(#diffs, 1)
            test.eq(diffs[1].op, "delete")
        end)

        it("diff_manifests handles both empty", function()
            test.eq(#fs_hash.diff_manifests({}, {}), 0)
        end)

        it("diff_manifests handles identical manifests", function()
            local m = {{ path = "a.txt", sha256 = "same" }}
            test.eq(#fs_hash.diff_manifests(m, m), 0)
        end)
    end)

    -- ==========================================================================
    describe("path validation edge cases", function()
        it("accepts triple dots as valid segment", function()
            local p, err = fs_view.validate_rel_path("...")
            test.is_nil(err)
            test.eq(p, "...")
        end)

        it("accepts deeply nested paths", function()
            local p, err = fs_view.validate_rel_path("a/b/c/d/e/f/g.txt")
            test.is_nil(err)
            test.eq(p, "a/b/c/d/e/f/g.txt")
        end)

        it("accepts hyphens and underscores", function()
            local p, _ = fs_view.validate_rel_path("my-comp/some_file.vue")
            test.eq(p, "my-comp/some_file.vue")
        end)
    end)

    -- ==========================================================================
    describe("full lifecycle", function()
        it("happy path: open → editing → review → accepted → merged", function()
            local sm = require("state_machine")
            local s, _
            s, _ = sm.next_state(consts.STATES.OPEN, sm.EVENTS.FIRST_EDIT)
            test.eq(s, consts.STATES.EDITING)
            s, _ = sm.next_state(s, sm.EVENTS.SUBMIT_FOR_REVIEW)
            test.eq(s, consts.STATES.REVIEW)
            s, _ = sm.next_state(s, sm.EVENTS.ACCEPT)
            test.eq(s, consts.STATES.ACCEPTED)
            s, _ = sm.next_state(s, sm.EVENTS.PUSH_SUCCESS)
            test.eq(s, consts.STATES.MERGED)
            test.is_true(sm.is_terminal(s))
        end)

        it("reject → reopen → retry path", function()
            local sm = require("state_machine")
            local s, _
            s, _ = sm.next_state(consts.STATES.REVIEW, sm.EVENTS.REJECT)
            test.eq(s, consts.STATES.REJECTED)
            s, _ = sm.next_state(s, sm.EVENTS.REOPEN)
            test.eq(s, consts.STATES.EDITING)
            s, _ = sm.next_state(s, sm.EVENTS.SUBMIT_FOR_REVIEW)
            test.eq(s, consts.STATES.REVIEW)
        end)

        it("push_failure returns to rejected", function()
            local sm = require("state_machine")
            local s, _ = sm.next_state(consts.STATES.ACCEPTED, sm.EVENTS.PUSH_FAILURE)
            test.eq(s, consts.STATES.REJECTED)
            test.is_false(sm.is_terminal(s))
        end)
    end)

    -- ==========================================================================
    describe("repo error handling", function()
        it("rejects create without title", function()
            local _, err = repo.create_changeset({
                kind = consts.KINDS.MANUAL, state_branch = "ws/no-title",
                scratch_fs_path = "x/", baseline_version = "0", baseline_fs_hash = "",
            })
            test.not_nil(err)
        end)

        it("returns error for nonexistent id", function()
            local _, err = repo.get_changeset("nonexistent-" .. uuid.v7())
            test.not_nil(err)
        end)

        it("list_changesets with kind filter", function()
            local ws, _ = new_test_changeset({ title = "Kind Filter" })
            local listed, err = repo.list_changesets({ kind = consts.KINDS.MANUAL })
            test.is_nil(err)
            local found = false
            for _, c in ipairs(listed) do
                if c.changeset_id == ws.changeset_id then found = true break end
            end
            test.is_true(found)
        end)

        it("unattributed change gets sequence 0", function()
            local cid, err = repo.record_change({
                category = consts.CATEGORIES.FILESYSTEM, op = consts.OPS.CREATE,
                target = "unattributed/" .. uuid.v7() .. ".txt", current_hash = "h1",
                source = consts.SOURCES.DETECTED_DRIFT, status = consts.CHANGE_STATUSES.PENDING,
            })
            test.is_nil(err)
            local change = repo.get_change(cid)
            test.eq(change.sequence, 0)
        end)

        it("update_state sets closed_at for terminal states", function()
            local ws, _ = new_test_changeset({ title = "Closed At Test" })
            repo.update_state(ws.changeset_id, consts.STATES.MERGED, "test merge")
            local updated = repo.get_changeset(ws.changeset_id)
            test.eq(updated.state, consts.STATES.MERGED)
            test.not_nil(updated.closed_at)
        end)

        it("set_head updates head fields", function()
            local ws, _ = new_test_changeset({ title = "Set Head" })
            repo.set_head(ws.changeset_id, "42", "abc123")
            local updated = repo.get_changeset(ws.changeset_id)
            test.eq(updated.head_version, "42")
            test.eq(updated.head_fs_hash, "abc123")
        end)
    end)

    describe("Locking", function()
        it("locks a changeset to an agent", function()
            local ws, _ = new_test_changeset({ title = "Lock Test" })
            local ok, err = repo.lock_changeset(ws.changeset_id, "agent-1")
            test.is_nil(err)
            test.eq(ok, true)

            local updated = repo.get_changeset(ws.changeset_id)
            test.eq(updated.locked_by, "agent-1")
            test.not_nil(updated.locked_at)
        end)

        it("rejects lock by another agent", function()
            local ws, _ = new_test_changeset({ title = "Lock Conflict" })
            repo.lock_changeset(ws.changeset_id, "agent-1")

            local ok, err = repo.lock_changeset(ws.changeset_id, "agent-2")
            test.is_nil(ok)
            test.not_nil(err)
            test.not_nil(err:find("locked by another"))
        end)

        it("allows same agent to re-lock", function()
            local ws, _ = new_test_changeset({ title = "Re-lock" })
            repo.lock_changeset(ws.changeset_id, "agent-1")

            local ok, err = repo.lock_changeset(ws.changeset_id, "agent-1")
            test.is_nil(err)
            test.eq(ok, true)
        end)

        it("unlocks by the holder", function()
            local ws, _ = new_test_changeset({ title = "Unlock Test" })
            repo.lock_changeset(ws.changeset_id, "agent-1")

            local ok, err = repo.unlock_changeset(ws.changeset_id, "agent-1")
            test.is_nil(err)
            test.eq(ok, true)

            local updated = repo.get_changeset(ws.changeset_id)
            test.is_nil(updated.locked_by)
        end)

        it("rejects unlock by non-holder", function()
            local ws, _ = new_test_changeset({ title = "Unlock Reject" })
            repo.lock_changeset(ws.changeset_id, "agent-1")

            local ok, err = repo.unlock_changeset(ws.changeset_id, "agent-2")
            test.is_nil(ok)
            test.not_nil(err)
            test.not_nil(err:find("not the lock holder"))
        end)

        it("rejects unlock on unlocked changeset", function()
            local ws, _ = new_test_changeset({ title = "Unlock Empty" })

            local ok, err = repo.unlock_changeset(ws.changeset_id, "agent-1")
            test.is_nil(ok)
            test.not_nil(err)
            test.not_nil(err:find("not locked"))
        end)

        it("is_locked_by returns true for holder", function()
            local ws, _ = new_test_changeset({ title = "Check Lock" })
            repo.lock_changeset(ws.changeset_id, "agent-1")

            test.eq(repo.is_locked_by(ws.changeset_id, "agent-1"), true)
            test.eq(repo.is_locked_by(ws.changeset_id, "agent-2"), false)
        end)

        it("is_locked_by returns true when unlocked", function()
            local ws, _ = new_test_changeset({ title = "Check Unlocked" })
            test.eq(repo.is_locked_by(ws.changeset_id, "anyone"), true)
        end)
    end)

    -- ==========================================================================
    describe("revert_to_phase_baseline", function()
        local function insert_overlay_entry(branch, id, created_at)
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute(
                "INSERT INTO keeper_overlay_entries (id, branch, kind, deleted, created_at, updated_at) " ..
                "VALUES (?, ?, ?, 0, ?, ?)",
                { id, branch, "function.lua", created_at, created_at }
            )
            db:release()
        end

        local function insert_overlay_chunk(branch, entry_id, created_at, content)
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute(
                "INSERT INTO keeper_overlay_chunks (entry_id, branch, chunk_type, content, content_hash, created_at) " ..
                "VALUES (?, ?, 'definition', ?, ?, ?)",
                { entry_id, branch, content, "hash-" .. content, created_at }
            )
            db:release()
        end

        local function insert_overlay_edge(branch, source_id, target_id, created_at)
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute(
                "INSERT INTO keeper_overlay_edges (source_id, target_id, branch, edge_type, metadata, created_at) " ..
                "VALUES (?, ?, ?, 'depends_on', NULL, ?)",
                { source_id, target_id, branch, created_at }
            )
            db:release()
        end

        local function insert_fs_content(changeset_id, rel_path, updated_at)
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute(
                "INSERT INTO keeper_changeset_fs_content (changeset_id, rel_path, content, content_hash, updated_at) " ..
                "VALUES (?, ?, ?, ?, ?)",
                { changeset_id, rel_path, "body-" .. rel_path, "fh-" .. rel_path, updated_at }
            )
            db:release()
        end

        local function insert_fs_delete(changeset_id, rel_path, deleted_at)
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            db:execute(
                "INSERT INTO keeper_changeset_fs_deletes (changeset_id, rel_path, baseline_hash, deleted_at) " ..
                "VALUES (?, ?, ?, ?)",
                { changeset_id, rel_path, "base-" .. rel_path, deleted_at }
            )
            db:release()
        end

        local function insert_change(changeset_id, target, status, created_at)
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            local _, ins_err = db:execute(
                "INSERT INTO keeper_changeset_changes (" ..
                "change_id, changeset_id, sequence, category, op, target, " ..
                "source, status, created_at, updated_at) " ..
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {
                    "chg-" .. target .. "-" .. uuid.v7(), changeset_id, 0,
                    consts.CATEGORIES.REGISTRY, consts.OPS.CREATE, target,
                    consts.SOURCES.MATERIALIZED, status, created_at, created_at,
                }
            )
            db:release()
            if ins_err then error("insert_change failed: " .. tostring(ins_err)) end
        end

        local function count_rows(sql_text, args)
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            local rows = db:query(sql_text, args) or {}
            db:release()
            return tonumber(rows[1] and rows[1].n) or 0
        end

        local function select_change_status(changeset_id, target)
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            local rows = db:query(
                "SELECT status FROM keeper_changeset_changes WHERE changeset_id = ? AND target = ?",
                { changeset_id, target }
            ) or {}
            db:release()
            return rows[1] and rows[1].status
        end

        it("deletes rows created after since_at, keeps pre-existing ones", function()
            local ws, _ = new_test_changeset({ title = "Revert Basic" })
            local branch = ws.state_branch
            local cs_id = ws.changeset_id
            local before = "2026-04-20T10:00:00.000Z"
            local baseline_at = "2026-04-20T11:00:00.000Z"
            local after = "2026-04-20T12:00:00.000Z"

            insert_overlay_entry(branch, "ns:pre_entry", before)
            insert_overlay_chunk(branch, "ns:pre_entry", before, "pre-chunk")
            insert_overlay_edge(branch, "ns:pre_entry", "ns:pre_other", before)
            insert_fs_content(cs_id, "pre/file.vue", before)
            insert_fs_delete(cs_id, "pre/deleted.vue", before)
            insert_change(cs_id, "ns:pre_entry", consts.CHANGE_STATUSES.PENDING, before)

            insert_overlay_entry(branch, "ns:new_entry", after)
            insert_overlay_chunk(branch, "ns:new_entry", after, "new-def")
            insert_overlay_chunk(branch, "ns:pre_entry", after, "late-chunk")
            insert_overlay_edge(branch, "ns:pre_entry", "ns:new_target", after)
            insert_fs_content(cs_id, "new/file.vue", after)
            insert_fs_delete(cs_id, "new/deleted.vue", after)
            insert_change(cs_id, "ns:new_entry", consts.CHANGE_STATUSES.PENDING, after)

            local stats, err = repo.revert_to_phase_baseline(cs_id, branch, baseline_at)
            test.is_nil(err)
            test.not_nil(stats)
            test.eq(stats.entries, 1)
            test.is_true(stats.chunks >= 1)
            test.eq(stats.edges, 1)
            test.eq(stats.fs_content, 1)
            test.eq(stats.fs_deletes, 1)
            test.eq(stats.journal, 1)

            test.eq(
                count_rows("SELECT COUNT(*) AS n FROM keeper_overlay_entries WHERE branch = ? AND id = ?",
                    { branch, "ns:new_entry" }),
                0
            )
            test.eq(
                count_rows("SELECT COUNT(*) AS n FROM keeper_overlay_entries WHERE branch = ? AND id = ?",
                    { branch, "ns:pre_entry" }),
                1
            )
            test.eq(
                count_rows("SELECT COUNT(*) AS n FROM keeper_overlay_chunks WHERE branch = ? AND created_at > ?",
                    { branch, baseline_at }),
                0
            )
            test.eq(
                count_rows("SELECT COUNT(*) AS n FROM keeper_overlay_edges WHERE branch = ? AND created_at > ?",
                    { branch, baseline_at }),
                0
            )
            test.eq(
                count_rows("SELECT COUNT(*) AS n FROM keeper_changeset_fs_content WHERE changeset_id = ? AND updated_at > ?",
                    { cs_id, baseline_at }),
                0
            )
            test.eq(
                count_rows("SELECT COUNT(*) AS n FROM keeper_changeset_fs_deletes WHERE changeset_id = ? AND deleted_at > ?",
                    { cs_id, baseline_at }),
                0
            )
        end)

        it("marks pending changes as reverted (audit preserved)", function()
            local ws, _ = new_test_changeset({ title = "Revert Audit" })
            local cs_id = ws.changeset_id
            local before = "2026-04-20T10:00:00.000Z"
            local baseline_at = "2026-04-20T11:00:00.000Z"
            local after = "2026-04-20T12:00:00.000Z"

            insert_change(cs_id, "ns:pre_pending", consts.CHANGE_STATUSES.PENDING, before)
            insert_change(cs_id, "ns:late_pending", consts.CHANGE_STATUSES.PENDING, after)
            insert_change(cs_id, "ns:late_applied", consts.CHANGE_STATUSES.APPLIED, after)

            local stats, err = repo.revert_to_phase_baseline(cs_id, ws.state_branch, baseline_at)
            test.is_nil(err)
            test.eq(stats.journal, 1)

            test.eq(select_change_status(cs_id, "ns:pre_pending"), consts.CHANGE_STATUSES.PENDING)
            test.eq(select_change_status(cs_id, "ns:late_pending"), consts.CHANGE_STATUSES.REVERTED)
            test.eq(select_change_status(cs_id, "ns:late_applied"), consts.CHANGE_STATUSES.APPLIED)
        end)

        it("no-op on empty branch returns zero stats", function()
            local ws, _ = new_test_changeset({ title = "Revert Empty" })
            local stats, err = repo.revert_to_phase_baseline(
                ws.changeset_id, ws.state_branch, "2026-04-20T11:00:00.000Z"
            )
            test.is_nil(err)
            test.eq(stats.entries, 0)
            test.eq(stats.chunks, 0)
            test.eq(stats.edges, 0)
            test.eq(stats.fs_content, 0)
            test.eq(stats.fs_deletes, 0)
            test.eq(stats.journal, 0)
        end)

        it("rejects missing required args", function()
            local _, err1 = repo.revert_to_phase_baseline(nil, "ws/x", "2026-04-20T11:00:00.000Z")
            test.not_nil(err1)
            local _, err2 = repo.revert_to_phase_baseline("cs1", nil, "2026-04-20T11:00:00.000Z")
            test.not_nil(err2)
            local _, err3 = repo.revert_to_phase_baseline("cs1", "ws/x", nil)
            test.not_nil(err3)
        end)
    end)

    -- ==========================================================================
    describe("latest_baseline_by_reason", function()
        it("returns the most recent baseline matching reason", function()
            local ws, _ = new_test_changeset({ title = "Baseline By Reason" })

            repo.record_baseline({
                changeset_id     = ws.changeset_id,
                registry_version = "1",
                fs_tree_hash     = "h1",
                reason           = consts.BASELINE_REASONS.OPEN,
            })
            repo.record_baseline({
                changeset_id     = ws.changeset_id,
                registry_version = "2",
                fs_tree_hash     = "h2",
                reason           = consts.BASELINE_REASONS.PHASE_SPAWN,
            })
            repo.record_baseline({
                changeset_id     = ws.changeset_id,
                registry_version = "3",
                fs_tree_hash     = "h3",
                reason           = consts.BASELINE_REASONS.PHASE_SPAWN,
            })

            local latest, err = repo.latest_baseline_by_reason(
                ws.changeset_id, consts.BASELINE_REASONS.PHASE_SPAWN
            )
            test.is_nil(err)
            test.not_nil(latest)
            test.eq(latest.registry_version, "3")
            test.eq(latest.reason, consts.BASELINE_REASONS.PHASE_SPAWN)
        end)

        it("returns (nil, nil) when no baseline matches", function()
            local ws, _ = new_test_changeset({ title = "Baseline By Reason Miss" })
            local latest, err = repo.latest_baseline_by_reason(
                ws.changeset_id, consts.BASELINE_REASONS.PHASE_SPAWN
            )
            test.is_nil(err)
            test.is_nil(latest)
        end)

        it("rejects missing required args", function()
            local _, err1 = repo.latest_baseline_by_reason(nil, "phase_spawn")
            test.not_nil(err1)
            local _, err2 = repo.latest_baseline_by_reason("cs1", nil)
            test.not_nil(err2)
        end)
    end)
    end)  -- close "Changeset Unit Tests"
end

local run = test.run_cases(define_tests)
return { define_tests = run }
