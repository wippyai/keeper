local test = require("test")
local reader = require("reader")

local function define_tests()
    describe("reader helpers", function()
        describe("ERR constants", function()
            it("exposes bad_request/not_found/internal", function()
                test.eq(reader.ERR.BAD_REQUEST, "bad_request")
                test.eq(reader.ERR.NOT_FOUND, "not_found")
                test.eq(reader.ERR.INTERNAL, "internal")
            end)
        end)

        describe("clamp_limit", function()
            it("defaults to 100 for nil / non-number", function()
                test.eq(reader.clamp_limit(nil), 100)
                test.eq(reader.clamp_limit("abc"), 100)
            end)

            it("preserves valid small values", function()
                test.eq(reader.clamp_limit(1), 1)
                test.eq(reader.clamp_limit(42), 42)
                test.eq(reader.clamp_limit(500), 500)
            end)

            it("clamps values above 500", function()
                test.eq(reader.clamp_limit(501), 500)
                test.eq(reader.clamp_limit(10000), 500)
            end)

            it("parses numeric strings", function()
                test.eq(reader.clamp_limit("50"), 50)
                test.eq(reader.clamp_limit("9999"), 500)
            end)

            it("exposes DEFAULT_LIST_LIMIT and MAX_LIST_LIMIT", function()
                test.eq(reader.DEFAULT_LIST_LIMIT, 100)
                test.eq(reader.MAX_LIST_LIMIT, 500)
            end)
        end)

        describe("validate_changeset_id", function()
            it("returns nil for a non-empty id", function()
                test.is_nil(reader.validate_changeset_id("cs-1"))
            end)

            it("rejects nil", function()
                local err = reader.validate_changeset_id(nil)
                test.eq(err.code, reader.ERR.BAD_REQUEST)
                test.is_true(err.message:find("workspace id", 1, true) ~= nil)
            end)

            it("rejects empty string", function()
                local err = reader.validate_changeset_id("")
                test.eq(err.code, reader.ERR.BAD_REQUEST)
            end)
        end)

        describe("sanitize", function()
            it("returns nil for nil input", function()
                test.is_nil(reader.sanitize(nil))
            end)

            it("maps parent_workspace to parent_changeset", function()
                local out = reader.sanitize({
                    changeset_id     = "cs-1",
                    parent_workspace = "cs-parent",
                })
                test.eq(out.parent_changeset, "cs-parent")
                test.is_nil(out.parent_workspace)
            end)

            it("projects whitelisted fields and drops unknowns", function()
                local out = reader.sanitize({
                    changeset_id = "cs-1",
                    kind         = "manual",
                    title        = "t",
                    description  = "d",
                    actor_id     = "a",
                    session_id   = "s",
                    task_id      = "tk",
                    state        = "open",
                    state_reason = "r",
                    created_at   = 1,
                    updated_at   = 2,
                    closed_at    = 3,
                    secret_field = "must be dropped",
                    state_branch = "ws/cs-1",
                })
                test.eq(out.changeset_id, "cs-1")
                test.eq(out.kind, "manual")
                test.eq(out.title, "t")
                test.eq(out.description, "d")
                test.eq(out.actor_id, "a")
                test.eq(out.session_id, "s")
                test.eq(out.task_id, "tk")
                test.eq(out.state, "open")
                test.eq(out.state_reason, "r")
                test.eq(out.created_at, 1)
                test.eq(out.updated_at, 2)
                test.eq(out.closed_at, 3)
                test.is_nil(out.secret_field)
                test.is_nil(out.state_branch)
            end)

            it("preserves nil fields as nil", function()
                local out = reader.sanitize({ changeset_id = "cs-1" })
                test.eq(out.changeset_id, "cs-1")
                test.is_nil(out.title)
                test.is_nil(out.description)
                test.is_nil(out.parent_changeset)
            end)
        end)

        describe("project_journal", function()
            it("returns empty buckets for nil / empty journal", function()
                local out = reader.project_journal(nil)
                test.eq(#out.registry, 0)
                test.eq(#out.filesystem, 0)
                out = reader.project_journal({})
                test.eq(#out.registry, 0)
                test.eq(#out.filesystem, 0)
            end)

            it("splits applied rows by category", function()
                local out = reader.project_journal({
                    { status = "applied", category = "registry",   op = "create", target = "ns:a" },
                    { status = "applied", category = "filesystem", op = "update", target = "path/b" },
                    { status = "applied", category = "registry",   op = "delete", target = "ns:c" },
                })
                test.eq(#out.registry, 2)
                test.eq(#out.filesystem, 1)
                test.eq(out.registry[1].target, "ns:a")
                test.eq(out.registry[1].op, "create")
                test.eq(out.filesystem[1].target, "path/b")
            end)

            it("skips superseded and reverted rows", function()
                local out = reader.project_journal({
                    { status = "applied",    category = "registry", op = "create", target = "ns:a" },
                    { status = "superseded", category = "registry", op = "update", target = "ns:b" },
                    { status = "reverted",   category = "registry", op = "delete", target = "ns:c" },
                })
                test.eq(#out.registry, 1)
                test.eq(out.registry[1].target, "ns:a")
            end)

            it("keeps pending and rejected rows for display", function()
                local out = reader.project_journal({
                    { status = "pending",  category = "registry",   op = "create", target = "ns:a" },
                    { status = "rejected", category = "filesystem", op = "delete", target = "path/b" },
                })
                test.eq(#out.registry, 1)
                test.eq(#out.filesystem, 1)
            end)

            it("drops rows with unknown category", function()
                local out = reader.project_journal({
                    { status = "applied", category = "mystery", op = "create", target = "x" },
                })
                test.eq(#out.registry, 0)
                test.eq(#out.filesystem, 0)
            end)

            it("preserves baseline_hash and current_hash", function()
                local out = reader.project_journal({
                    { status = "applied", category = "registry", op = "update", target = "ns:x",
                      baseline_hash = "h1", current_hash = "h2" },
                })
                test.eq(out.registry[1].baseline_hash, "h1")
                test.eq(out.registry[1].current_hash, "h2")
            end)
        end)

        describe("get / list_changes validation", function()
            it("get returns BAD_REQUEST for empty id", function()
                local v, err = reader.get("")
                test.is_nil(v)
                test.eq(err.code, reader.ERR.BAD_REQUEST)
            end)

            it("get returns BAD_REQUEST for nil id", function()
                local v, err = reader.get(nil)
                test.is_nil(v)
                test.eq(err.code, reader.ERR.BAD_REQUEST)
            end)

            it("list_changes returns BAD_REQUEST for empty id", function()
                local v, err = reader.list_changes("")
                test.is_nil(v)
                test.eq(err.code, reader.ERR.BAD_REQUEST)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
