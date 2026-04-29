-- Regression tests for read_context. Pins the Live State preamble behaviour
-- added 2026-04-25: every read_context return must open with the live
-- workspace snapshot (task_id + changeset_id + branch + state), followed
-- by findings. This exists so orchestrators running across multiple phase
-- spawns can't conflate a stale branch name from a save_context finding
-- with the currently-active overlay branch.

local test           = require("test")
local sql            = require("sql")
local read_context   = require("read_context")
local task_writer    = require("task_writer")
local nodes_writer   = require("nodes_writer")
local open           = require("open")

local DB = "keeper.state:db"

local function must_db()
    local db, err = sql.get(DB)
    if err then error("db: " .. tostring(err)) end
    if not db then error("db unavailable") end
    return db
end

local function cleanup_task(task_id)
    if not task_id or task_id == "" then return end
    local db = must_db()
    db:execute("DELETE FROM keeper_task_nodes WHERE task_id=?", { task_id })
    db:execute("DELETE FROM keeper_changesets WHERE task_id=?", { task_id })
    db:execute("DELETE FROM keeper_tasks WHERE task_id=?", { task_id })
    db:release()
end

local function make_task(title)
    local res = task_writer.create_task({
        title    = title or "read_context probe",
        actor_id = "read_context_test",
    }):execute()
    return res and res.task_id or nil
end

local function make_changeset(task_id)
    local ws, err = open.run({
        title    = "probe changeset",
        kind     = "session",
        actor_id = "read_context_test",
        task_id  = task_id,
    })
    if err then return nil, err end
    return ws
end

local function save_finding(task_id, key, content)
    nodes_writer.record({
        task_id       = task_id,
        type          = "finding",
        discriminator = key,
        title         = key,
        content       = content,
        content_type  = "text/markdown",
        status        = "active",
        visibility    = "user",
    })
end

local function define_tests()
    test.describe("keeper.task.tools:read_context — Live State preamble", function()
        test.it("prepends Live State block with task_id + changeset + branch + state",
            function()
                local task_id = make_task()
                test.not_nil(task_id)
                local ws = make_changeset(task_id)
                test.not_nil(ws)

                save_finding(task_id, "old_cycle_note",
                    "Worked on branch ws/STALE-BRANCH-NAME last cycle.")

                local out, err = read_context.read(task_id)
                test.is_nil(err)
                test.not_nil(out)
                test.is_true(out:find("## Live State", 1, true) ~= nil,
                    "Live State heading must be present")
                test.is_true(out:find("- task_id: " .. task_id, 1, true) ~= nil,
                    "Live State must surface task_id")
                test.is_true(out:find("- active_changeset_id: " .. ws.changeset_id, 1, true) ~= nil,
                    "Live State must surface active changeset_id")
                test.is_true(out:find("- overlay_branch: " .. ws.state_branch, 1, true) ~= nil,
                    "Live State must surface current overlay branch, not stale finding contents")
                test.is_true(out:find("SOURCE OF TRUTH", 1, true) ~= nil,
                    "Live State must tell the agent this block overrides stale finding branches")
                test.is_true(out:find("# Saved Findings", 1, true) ~= nil,
                    "Findings section still renders below the preamble")

                -- Preamble must appear before any finding body.
                local live_pos = out:find("## Live State", 1, true)
                local finding_pos = out:find("Saved Findings", 1, true)
                test.is_true(live_pos < finding_pos,
                    "Live State preamble must precede findings body")

                cleanup_task(task_id)
            end)

        test.it("renders preamble even when no findings exist yet", function()
            local task_id = make_task("empty probe")
            local ws = make_changeset(task_id)
            test.not_nil(ws)

            local out = read_context.read(task_id)
            test.not_nil(out)
            test.is_true(out:find("## Live State", 1, true) ~= nil,
                "Live State must render on empty-findings path")
            test.is_true(out:find("No prior findings saved", 1, true) ~= nil,
                "Empty-findings message still present")
            cleanup_task(task_id)
        end)

        test.it("renders preamble with '(none)' when task has no active changeset",
            function()
                local task_id = make_task("no changeset probe")
                local out = read_context.read(task_id)
                test.not_nil(out)
                test.is_true(out:find("active_changeset_id: %(none", 1) ~= nil,
                    "When there is no active changeset, the preamble says so explicitly")
                cleanup_task(task_id)
            end)

        test.it("errors cleanly on missing task_id", function()
            local out, err = read_context.read("")
            test.is_nil(out)
            test.not_nil(err)
        end)

        -- Researchers commonly stamp findings with `<embed id="..."/>` tags
        -- expecting the source to be inlined when the next agent reads them.
        -- Pre-fix, read_context returned the raw tag and subagents stared at
        -- placeholder text. Post-fix, read_context routes findings through
        -- format_context.resolve, so the embedded entry appears as inlined
        -- source. Pin both the success path (real entry inlined) and the
        -- fallback path (missing entry surfaces an explicit error marker
        -- rather than dropping the placeholder silently).
        test.it("resolves <embed/> tags so agents see inlined source not placeholders",
            function()
                local task_id = make_task("embed probe")
                local ws = make_changeset(task_id)
                test.not_nil(ws)

                -- Use a real registry entry that's guaranteed to exist on main —
                -- format_context itself.
                save_finding(task_id, "embedded_research",
                    'Reference impl: <embed id="keeper.develop.context:format_context" mode="full" />')

                local out = read_context.read(task_id)
                test.not_nil(out)
                -- The specific placeholder we wrote must be gone. We check
                -- the exact placeholder string rather than any "<embed"
                -- substring because the resolved entry's own source code
                -- (format_context.lua itself) embeds a regex literal that
                -- contains "<embed" — matching that would falsely fail.
                local placeholder = '<embed id="keeper.develop.context:format_context"'
                test.is_true(out:find(placeholder, 1, true) == nil,
                    "Original <embed/> placeholder must be gone after resolve")
                -- Resolved block carries the entry id banner.
                test.is_true(out:find("=== keeper.develop.context:format_context ===", 1, true) ~= nil,
                    "Resolved entry must carry its === id === banner")
                -- And the inlined source content is present (sanity).
                test.is_true(out:find("local function replace_embeds", 1, true) ~= nil,
                    "Resolved entry must contain the actual source code")

                cleanup_task(task_id)
            end)

        test.it("missing-entry <embed/> falls back to an explicit error marker",
            function()
                local task_id = make_task("embed missing probe")
                local ws = make_changeset(task_id)

                save_finding(task_id, "missing_ref",
                    'Vanished entry: <embed id="ns:does_not_exist_xyz" mode="full" />')

                local out = read_context.read(task_id)
                test.not_nil(out)
                test.is_true(out:find("<embed", 1, true) == nil,
                    "Even an unresolvable embed is replaced (with an error marker), never left raw")
                test.is_true(out:find("Entry not found: ns:does_not_exist_xyz", 1, true) ~= nil,
                    "Missing entry yields a visible error marker rather than silent drop")
                cleanup_task(task_id)
            end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
