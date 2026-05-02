local test = require("test")
local sql = require("sql")
local uuid = require("uuid")
local env = require("env")
local hash = require("hash")
local registry = require("registry")
local mcp_tokens = require("mcp_tokens")
local mcp_traits = require("mcp_traits")
local mcp_consts = require("mcp_consts")
local mcp_policy = require("mcp_policy")
local mcp_surface = require("mcp_surface")
local mcp_meta = require("mcp_meta")
local mcp_auth = require("mcp_auth")
local mcp_authorize = require("mcp_authorize")
local mcp_handler_core = require("mcp_handler_core")

local function define_tests()
    describe("MCP", function()
        local created_tokens = {}

        after_all(function()
            local db, err = sql.get(mcp_consts.db_id())
            if err then return end
            for _, raw_value in ipairs(created_tokens) do
                local raw = tostring(raw_value)
                local digest = hash.sha256(raw)
                sql.builder.delete("keeper_mcp_tokens")
                    :where("token = ?", digest)
                    :run_with(db)
                    :exec()
                sql.builder.delete("keeper_mcp_session_state")
                    :where("token = ?", digest)
                    :run_with(db)
                    :exec()
            end
            db:release()
        end)

        local function track(tok, err)
            test.is_nil(err)
            if not tok then error("token create failed: " .. tostring(err)) end
            if type(tok.token) ~= "string" then error("token create returned no raw token") end
            table.insert(created_tokens, tok.token)
            return tok
        end

        local function create_token(params)
            return track(mcp_tokens.create(params))
        end

        local function open_db()
            local db, err = sql.get(mcp_consts.db_id())
            if err or not db then error("db unavailable: " .. tostring(err)) end
            return db
        end

        local function add_column_if_missing(db, ddl, label)
            local ok, db_type = pcall(function() return db:type() end)
            if ok and db_type == sql.type.POSTGRES then
                ddl = ddl:gsub("ADD COLUMN ", "ADD COLUMN IF NOT EXISTS ")
            end
            local _, err = db:execute(ddl)
            local msg = tostring(err)
            if err and not msg:find("duplicate column", 1, true) and not msg:find("already exists", 1, true) then
                error(label .. ": " .. tostring(err))
            end
        end

        before_all(function()
            local db = open_db()
            add_column_if_missing(db,
                "ALTER TABLE keeper_mcp_tokens ADD COLUMN issued_by TEXT",
                "add issued_by")
            add_column_if_missing(db,
                "ALTER TABLE keeper_mcp_tokens ADD COLUMN revoked_at INTEGER",
                "add revoked_at")
            add_column_if_missing(db,
                "ALTER TABLE keeper_mcp_tokens ADD COLUMN revoked_by TEXT",
                "add revoked_by")
            db:release()
        end)

        describe("tokens", function()
            it("generates high-entropy prefixed bearer tokens instead of UUID-shaped secrets", function()
                local tok = create_token({
                    label = "entropy-" .. uuid.v4(),
                    scopes = { "registry.read" },
                })
                local tok2 = create_token({
                    label = "entropy2-" .. uuid.v4(),
                    scopes = { "registry.read" },
                })

                test.is_true(tok.token:match("^wkmcp_[0-9a-f]+$") ~= nil)
                test.eq(#tok.token, 70, "wkmcp_ + 32 random bytes as 64 hex chars")
                test.is_true(tok.token ~= tok2.token, "tokens must be unique")
                test.is_nil(tok.token:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"))
            end)

            it("creates token with default access_mode=tools_only", function()
                local tok = create_token({
                    label = "tools-only-" .. uuid.v4(),
                    scopes = { "registry.read" },
                })
                test.eq(tok.access_mode, "tools_only")
            end)

            it("rejects invalid access_mode", function()
                local tok, err = mcp_tokens.create({
                    label = "bad-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "bogus",
                })
                test.is_nil(tok)
                test.not_nil(err)
            end)

            it("persists trait_filter and tool_filter as JSON", function()
                local trait_filter = { tags_any = { "state", "knowledge" }, namespaces = { "keeper.agents.traits" } }
                local tool_filter = { include_ids = { "keeper.state.tools:explore" } }
                local tok = create_token({
                    label = "filters-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "traits",
                    trait_filter = trait_filter,
                    tool_filter = tool_filter,
                    default_active = { "keeper.agents.traits.state:explorer" },
                })

                local fetched, ferr = mcp_tokens.get(tok.token)
                test.is_nil(ferr)
                test.not_nil(fetched.trait_filter)
                test.eq(fetched.trait_filter.tags_any[1], "state")
                test.eq(fetched.trait_filter.namespaces[1], "keeper.agents.traits")
                test.not_nil(fetched.tool_filter)
                test.eq(fetched.tool_filter.include_ids[1], "keeper.state.tools:explore")
                test.eq(fetched.default_active[1], "keeper.agents.traits.state:explorer")
            end)

            it("stores trait_filter=nil as null (any)", function()
                local tok = create_token({
                    label = "any-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                    trait_filter = nil,
                })

                local fetched = mcp_tokens.get(tok.token)
                test.is_nil(fetched.trait_filter)
            end)

            it("raw bearer is never stored at rest (sha256 hash only)", function()
                local tok = create_token({
                    label = "hash-at-rest-" .. uuid.v4(),
                    scopes = { "registry.read" },
                })

                local db = open_db()
                local rows = sql.builder.select("COUNT(*) AS n")
                    :from("keeper_mcp_tokens")
                    :where("token = ?", tok.token)
                    :run_with(db)
                    :query()
                test.eq(rows[1].n, 0, "raw token must not appear in DB")

                local digest = hash.sha256(tok.token)
                local hrows = sql.builder.select("COUNT(*) AS n")
                    :from("keeper_mcp_tokens")
                    :where("token = ?", digest)
                    :run_with(db)
                    :query()
                db:release()
                test.eq(hrows[1].n, 1, "hash of raw token must be the stored key")
            end)

            it("get(raw) resolves session and re-injects raw for caller keying", function()
                local tok = create_token({
                    label = "get-raw-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                })
                local session = mcp_tokens.get(tok.token)
                test.eq(session.token, tok.token, "session.token must equal the caller-supplied raw")
                test.not_nil(session.token_hash)
                test.is_true(session.token_hash ~= tok.token, "hash column must differ from raw")
            end)

            it("list returns token_hash, never the raw token", function()
                local tok = create_token({
                    label = "list-nohash-" .. uuid.v4(),
                    scopes = { "registry.read" },
                })
                local all = mcp_tokens.list()
                local found
                local digest = hash.sha256(tok.token)
                for _, row in ipairs(all) do
                    if row.token_hash == digest then found = row; break end
                end
                test.not_nil(found, "created token must appear in list by hash")
                test.is_nil(found.token, "list must not surface raw token value")
            end)

            it("records token issuer for audit", function()
                local issuer = "admin@wippy.local"
                local tok = create_token({
                    label = "issuer-" .. uuid.v4(),
                    identity = issuer,
                    issued_by = issuer,
                    scopes = { "registry.read" },
                })

                local fetched = mcp_tokens.get(tok.token)
                test.eq(fetched.issued_by, issuer)

                local digest = hash.sha256(tok.token)
                local all = mcp_tokens.list()
                local found
                for _, row in ipairs(all) do
                    if row.token_hash == digest then found = row; break end
                end
                test.not_nil(found)
                test.eq(found.issued_by, issuer)
            end)

            it("revoke by hash prevents subsequent get(raw)", function()
                local tok = create_token({
                    label = "revoke-" .. uuid.v4(),
                    scopes = { "registry.read" },
                })
                local digest = hash.sha256(tok.token)
                local ok, rerr = mcp_tokens.revoke(digest)
                test.is_true(ok)
                test.is_nil(rerr)
                local session, gerr = mcp_tokens.get(tok.token)
                test.is_nil(session)
                test.not_nil(gerr)
            end)

            it("revoke stores revocation actor and timestamp", function()
                local revoker = "admin@wippy.local"
                local tok = create_token({
                    label = "revoke-audit-" .. uuid.v4(),
                    identity = revoker,
                    issued_by = revoker,
                    scopes = { "registry.read" },
                })
                local digest = hash.sha256(tok.token)
                local ok, rerr = mcp_tokens.revoke(digest, revoker)
                test.is_true(ok)
                test.is_nil(rerr)

                local all = mcp_tokens.list()
                local found
                for _, row in ipairs(all) do
                    if row.token_hash == digest then found = row; break end
                end
                test.not_nil(found)
                test.is_true(found.revoked == true)
                test.eq(found.revoked_by, revoker)
                test.is_true(type(found.revoked_at) == "number")
                test.is_true(found.revoked_at > 0)
            end)
        end)

        describe("session_state", function()
            it("returns nil for fresh token (never written)", function()
                local tok = create_token({
                    label = "fresh-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                })
                local active, err = mcp_tokens.get_active_traits(tok.token)
                test.is_nil(err)
                test.is_nil(active)
            end)

            it("empty token string returns error (not silent fallback)", function()
                local active, err = mcp_tokens.get_active_traits("")
                test.is_nil(active)
                test.not_nil(err)
            end)

            it("distinguishes explicit empty set from never-written", function()
                local tok = create_token({
                    label = "empty-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                    default_active = { "keeper.agents.traits.state:explorer" },
                })
                mcp_tokens.set_active_traits(tok.token, {})
                local active = mcp_tokens.get_active_traits(tok.token)
                test.not_nil(active)
                test.eq(#active, 0)

                -- get_active should NOT fall back to default_active after explicit clear
                local session = mcp_tokens.get(tok.token)
                local resolved = mcp_traits.get_active(session)
                test.eq(#resolved, 0)
            end)

            it("roundtrips set/get active_traits", function()
                local tok = create_token({
                    label = "rt-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                })
                local ok = mcp_tokens.set_active_traits(tok.token, { "a", "b", "c" })
                test.is_true(ok)

                local active = mcp_tokens.get_active_traits(tok.token)
                test.eq(#active, 3)
                test.eq(active[1], "a")
                test.eq(active[3], "c")
            end)

            it("clear_active_traits empties the set", function()
                local tok = create_token({
                    label = "clr-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                })
                mcp_tokens.set_active_traits(tok.token, { "x" })
                mcp_tokens.clear_active_traits(tok.token)
                local active = mcp_tokens.get_active_traits(tok.token)
                test.eq(#active, 0)
            end)
        end)

        describe("filter_matches", function()
            local fm = mcp_traits._filter_matches

            it("nil filter passes everything", function()
                test.is_true(fm(nil, "any.ns:entry", {}))
                test.is_true(fm(nil, "any.ns:entry", { "anytag" }))
            end)

            it("non-table filter fails closed", function()
                test.is_true(not fm("not-a-table", "any.ns:entry", {}))
            end)

            it("empty filter passes everything", function()
                test.is_true(fm({}, "ns:x", {}))
            end)

            it("exclude_ids takes precedence over include_ids", function()
                local f = { include_ids = { "ns:keep" }, exclude_ids = { "ns:keep" } }
                test.is_true(not fm(f, "ns:keep", {}))
            end)

            it("exclude_ids blocks when not in include_ids", function()
                local f = { exclude_ids = { "ns:bad" } }
                test.is_true(not fm(f, "ns:bad", {}))
                test.is_true(fm(f, "ns:ok", {}))
            end)

            it("namespaces restricts by id prefix before colon", function()
                local f = { namespaces = { "keeper.agents.traits", "userspace.agents.traits" } }
                test.is_true(fm(f, "keeper.agents.traits.state:editor", {}))
                test.is_true(fm(f, "userspace.agents.traits:foo", {}))
                test.is_true(not fm(f, "plugin.traits:foo", {}))
                test.is_true(not fm(f, "keeper.state.tools:edit", {}))
            end)

            it("tags_any passes if any tag matches", function()
                local f = { tags_any = { "state", "knowledge" } }
                test.is_true(fm(f, "ns:x", { "state", "readonly" }))
                test.is_true(fm(f, "ns:x", { "knowledge" }))
                test.is_true(not fm(f, "ns:x", { "ui", "docs" }))
            end)

            it("tags_all requires every listed tag", function()
                local f = { tags_all = { "state", "editor" } }
                test.is_true(fm(f, "ns:x", { "state", "editor", "other" }))
                test.is_true(not fm(f, "ns:x", { "state" }))
                test.is_true(not fm(f, "ns:x", { "editor" }))
            end)

            it("combines namespaces AND tags_any (intersection)", function()
                local f = { namespaces = { "keeper" }, tags_any = { "state" } }
                test.is_true(fm(f, "keeper.agents.traits.state:editor", { "state" }))
                test.is_true(not fm(f, "keeper.agents.traits.state:unrelated", { "misc" }))
                test.is_true(not fm(f, "plugin.traits:other", { "state" }))
            end)

            it("namespace filter matches child namespace prefixes", function()
                local f = { namespaces = { "keeper.state" } }
                test.is_true(fm(f, "keeper.state.tools:edit", {}))
                test.is_true(fm(f, "keeper.state.persist:reader", {}))
                test.is_true(not fm(f, "keeper.agents.traits.state:editor", {}))
                test.is_true(not fm(f, "keeper.agents.traits:flow_debugger", {}))
            end)

            it("include_ids bypasses namespace/tag filtering", function()
                local f = { namespaces = { "keeper.state" }, include_ids = { "plugin.traits:special" } }
                test.is_true(fm(f, "plugin.traits:special", {}))
            end)
        end)

        describe("namespace_of", function()
            local nsof = mcp_traits.namespace_of

            it("extracts namespace before colon", function()
                test.eq(nsof("keeper.agents.traits.state:editor"), "keeper.agents.traits.state")
                test.eq(nsof("a:b"), "a")
            end)

            it("returns empty string when no colon", function()
                test.eq(nsof("nocolon"), "")
            end)

            it("handles nil and non-string", function()
                test.eq(nsof(nil), "")
                test.eq(nsof(123), "")
            end)
        end)

        describe("traits catalog", function()
            it("list_catalog returns every trait when filter is nil", function()
                local session = { access_mode = "any", trait_filter = nil }
                local cat = mcp_traits.list_catalog(session)
                test.is_true(#cat >= 1)
            end)

            it("list_catalog honors tags_any", function()
                local session = {
                    access_mode = "traits",
                    trait_filter = { tags_any = { "knowledge" } },
                }
                local cat = mcp_traits.list_catalog(session)
                for _, t in ipairs(cat) do
                    local has_kn = false
                    for _, tag in ipairs(t.tags or {}) do
                        if tag == "knowledge" then has_kn = true; break end
                    end
                    test.is_true(has_kn, "trait " .. t.id .. " passed filter without matching tag")
                end
            end)

            it("list_catalog honors namespaces", function()
                local session = {
                    access_mode = "traits",
                    trait_filter = { namespaces = { "keeper" } },
                }
                local cat = mcp_traits.list_catalog(session)
                for _, t in ipairs(cat) do
                    test.is_true(t.id:sub(1, #"keeper.") == "keeper.", "leaked trait: " .. t.id)
                end
            end)

            it("describe returns prompt and tools for allowed trait", function()
                local session = { access_mode = "any", trait_filter = nil }
                local def, err = mcp_traits.describe("keeper.agents.traits.state:explorer", session)
                test.is_nil(err)
                test.not_nil(def)
                test.eq(def.id, "keeper.agents.traits.state:explorer")
            end)

            it("hub operator trait exposes dependency and migration tools", function()
                local session = { access_mode = "any", trait_filter = nil }
                local def, err = mcp_traits.describe("keeper.agents.traits.hub:operator", session)
                test.is_nil(err)
                test.not_nil(def)
                test.eq(def.id, "keeper.agents.traits.hub:operator")

                local tools = {}
                for _, ref in ipairs(def.tools or {}) do
                    local tool_id = type(ref) == "table" and ref.id or ref
                    tools[tool_id] = true
                end
                test.is_true(tools["keeper.hub.tools:dependencies"])
                test.is_true(tools["keeper.hub.tools:migrations"])
            end)

            it("describe blocks trait not passing filter", function()
                local session = {
                    access_mode = "traits",
                    trait_filter = { namespaces = { "plugin.traits" } },
                }
                local def, err = mcp_traits.describe("keeper.agents.traits.state:explorer", session)
                test.is_nil(def)
                test.not_nil(err)
            end)

            it("trait_allowed returns true when filter is nil", function()
                local allowed = mcp_traits.trait_allowed({ trait_filter = nil }, "keeper.agents.traits.state:explorer")
                test.is_true(allowed)
            end)

            it("trait_allowed rejects unknown id", function()
                local allowed, err = mcp_traits.trait_allowed(
                    { trait_filter = { namespaces = { "keeper.agents.traits" } } },
                    "keeper.agents.traits.state:does_not_exist_xyz"
                )
                test.is_true(not allowed)
                test.not_nil(err)
            end)
        end)

        describe("traits active-set lifecycle", function()
            it("get_active falls back to default_active when no state written", function()
                local tok = create_token({
                    label = "dflt-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                    default_active = { "keeper.agents.traits.state:explorer" },
                })
                local session = mcp_tokens.get(tok.token)
                local active = mcp_traits.get_active(session)
                test.eq(#active, 1)
                test.eq(active[1], "keeper.agents.traits.state:explorer")
            end)

            it("set_active replaces the set and validates ids", function()
                local tok = create_token({
                    label = "set-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                })
                local session = mcp_tokens.get(tok.token)

                local res, err = mcp_traits.set_active(session, { "keeper.agents.traits.state:explorer" })
                test.is_nil(err)
                test.eq(res.active[1], "keeper.agents.traits.state:explorer")

                local bad, berr = mcp_traits.set_active(session, { "keeper.agents.traits.state:nope_nope" })
                test.is_nil(bad)
                test.not_nil(berr)
            end)

            it("activate merges, deactivate removes", function()
                local tok = create_token({
                    label = "mrg-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                })
                local session = mcp_tokens.get(tok.token)

                mcp_traits.set_active(session, { "keeper.agents.traits.state:explorer" })
                mcp_traits.activate(session, { "keeper.agents.traits.state:comparer" })
                local active = mcp_traits.get_active(session)
                test.eq(#active, 2)

                mcp_traits.deactivate(session, { "keeper.agents.traits.state:explorer" })
                active = mcp_traits.get_active(session)
                test.eq(#active, 1)
                test.eq(active[1], "keeper.agents.traits.state:comparer")
            end)

            it("reset restores default_active", function()
                local tok = create_token({
                    label = "rst-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                    default_active = { "keeper.agents.traits.state:explorer" },
                })
                local session = mcp_tokens.get(tok.token)

                mcp_traits.set_active(session, { "keeper.agents.traits.state:comparer" })
                mcp_traits.reset(session)
                local active = mcp_traits.get_active(session)
                test.eq(#active, 1)
                test.eq(active[1], "keeper.agents.traits.state:explorer")
            end)

            it("activate enforces trait_filter (rejects trait outside filter)", function()
                local tok = create_token({
                    label = "enf-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "traits",
                    trait_filter = { namespaces = { "plugin.traits" } },
                })
                local session = mcp_tokens.get(tok.token)
                local res, err = mcp_traits.activate(session, { "keeper.agents.traits.state:explorer" })
                test.is_nil(res)
                test.not_nil(err)
            end)
        end)

        describe("access_mode guards", function()
            it("tools_only session rejects set_active", function()
                local tok = create_token({
                    label = "to-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "tools_only",
                    tool_filter = { include_ids = { "keeper.state.tools:explore" } },
                })
                local session = mcp_tokens.get(tok.token)
                local res, err = mcp_traits.set_active(session, { "keeper.agents.traits.state:explorer" })
                test.is_nil(res)
                test.not_nil(err)
            end)

            it("tools_only session get_active returns empty", function()
                local tok = create_token({
                    label = "to2-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "tools_only",
                    tool_filter = {},
                    default_active = { "should", "be", "ignored" },
                })
                local session = mcp_tokens.get(tok.token)
                local active = mcp_traits.get_active(session)
                test.eq(#active, 0)
            end)
        end)

        describe("resolve_tools_only", function()
            it("materializes tools matching tool_filter", function()
                local session = {
                    label = "test",
                    identity = "test",
                    scopes = { "mcp.root" },
                    access_mode = "tools_only",
                    tool_filter = { tags_any = { "exploration" } },
                }
                local resolved = mcp_traits.resolve_tools_only(session)
                test.not_nil(resolved.tools)
                local count = 0
                for _, _ in pairs(resolved.tools) do count = count + 1 end
                test.is_true(count >= 1, "expected at least one tool with 'exploration' tag")
            end)

            it("returns empty when no tool matches", function()
                local session = {
                    label = "test",
                    identity = "test",
                    scopes = { "mcp.root" },
                    access_mode = "tools_only",
                    tool_filter = { tags_any = { "nonexistent_tag_xyz" } },
                }
                local resolved = mcp_traits.resolve_tools_only(session)
                local count = 0
                for _, _ in pairs(resolved.tools or {}) do count = count + 1 end
                test.eq(count, 0)
            end)

            it("nil tool_filter returns every permitted registered tool", function()
                local session = {
                    label = "test",
                    identity = "test",
                    scopes = { "mcp.root" },
                    access_mode = "tools_only",
                    tool_filter = nil,
                }
                local resolved = mcp_traits.resolve_tools_only(session)
                local count = 0
                for _, _ in pairs(resolved.tools or {}) do count = count + 1 end
                test.is_true(count >= 1)
            end)
        end)

        describe("prune_missing_traits", function()
            local prune = mcp_traits._prune_missing_traits

            it("keeps real traits, drops unknowns", function()
                local kept, dropped = prune({
                    [1] = "keeper.agents.traits.state:explorer",
                    [2] = "keeper.agents.traits.state:does_not_exist_abc",
                    [3] = "does.not.exist:at_all",
                })
                test.eq(#kept, 1)
                test.eq(kept[1], "keeper.agents.traits.state:explorer")
                test.eq(#dropped, 2)
            end)

            it("handles nil and empty input", function()
                local opaque = {}
                local kept, dropped = prune(opaque.missing)
                test.eq(#kept, 0)
                test.eq(#dropped, 0)

                kept, dropped = prune({})
                test.eq(#kept, 0)
                test.eq(#dropped, 0)
            end)

            it("rejects non-trait registry entries", function()
                -- keeper.state.tools:explore exists as a tool, not a trait
                local kept, dropped = prune({ [1] = "keeper.state.tools:explore" })
                test.eq(#kept, 0)
                test.eq(#dropped, 1)
            end)
        end)

        describe("resolve self-heal", function()
            it("strips stale trait ids from persisted active set", function()
                local tok = create_token({
                    label = "stale-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                })
                local session = mcp_tokens.get(tok.token)

                -- Plant a stale id directly (bypass validate_trait_ids so the
                -- persistence layer records it as if the trait was once valid).
                mcp_tokens.set_active_traits(session.token, {
                    "keeper.agents.traits.state:explorer",
                    "keeper.agents.traits.state:removed_offline_xyz",
                })

                local resolved, err = mcp_traits.resolve(session)
                test.is_nil(err)
                test.not_nil(resolved)

                -- Persisted state should have been rewritten without the stale id.
                local active = mcp_tokens.get_active_traits(session.token)
                test.eq(#active, 1)
                test.eq(active[1], "keeper.agents.traits.state:explorer")
            end)

            it("returns no trait-derived tools when every active id is stale", function()
                local tok = create_token({
                    label = "allstale-" .. uuid.v4(),
                    scopes = { "registry.read" },
                    access_mode = "any",
                })
                local session = mcp_tokens.get(tok.token)
                mcp_tokens.set_active_traits(session.token, {
                    "keeper.agents.traits.state:gone_1",
                    "keeper.agents.traits.state:gone_2",
                })

                local resolved, err = mcp_traits.resolve(session)
                test.is_nil(err)
                test.not_nil(resolved)
                test.eq(next(resolved.tools or {}), nil, "no tools expected when every active trait is stale")
            end)
        end)

        describe("tool_allowed guard", function()
            it("rejects non-tool registry entry", function()
                local allowed, err = mcp_traits.tool_allowed(
                    { tool_filter = nil },
                    "keeper.agents.traits.state:explorer"
                )
                test.is_true(not allowed)
                test.not_nil(err)
            end)

            it("rejects unknown tool id", function()
                local allowed, err = mcp_traits.tool_allowed(
                    { tool_filter = nil },
                    "keeper.state.tools:does_not_exist_xyz"
                )
                test.is_true(not allowed)
                test.not_nil(err)
            end)

            it("allows real tool when filter is nil", function()
                local allowed = mcp_traits.tool_allowed(
                    { tool_filter = nil, scopes = { "state.read" } },
                    "keeper.state.tools:explore"
                )
                test.is_true(allowed)
            end)

            it("rejects real tool when scope is missing", function()
                local allowed, err = mcp_traits.tool_allowed(
                    { tool_filter = nil, scopes = { "registry.read" } },
                    "keeper.state.tools:explore"
                )
                test.is_true(not allowed)
                test.not_nil(err)
                test.is_true(err:find("state.read") ~= nil)
            end)
        end)

        describe("tool scope authorization", function()
            it("every Keeper MCP tool declares or maps to at least one scope", function()
                local entries = registry.find({ ["meta.type"] = "tool" }) or {}
                test.is_true(#entries > 0, "expected at least one tool entry")
                for _, entry in ipairs(entries) do
                    local id = entry.id or ""
                    if id:sub(1, #"keeper.") == "keeper." or id == "app.agents:navigate_to" then
                        local scopes = mcp_authorize.required_scopes(id, entry)
                        test.is_true(#scopes > 0, "tool missing MCP required scope: " .. id)
                    end
                end
            end)

            it("strict mode denies external tools without explicit MCP scopes", function()
                local ok, err = mcp_authorize.tool(
                    { scopes = { "mcp.root" } },
                    "wippy.agent.tools:delay_tool"
                )
                test.is_true(not ok)
                test.not_nil(err)
                test.is_true(err:find("required_scopes") ~= nil)
            end)

            it("root scope bypasses normal tool scopes", function()
                local ok, err = mcp_authorize.tool(
                    { scopes = { "mcp.root" } },
                    "keeper.state.tools:push"
                )
                test.is_true(ok, tostring(err))
            end)

            it("read scope cannot call write tool", function()
                local ok, err = mcp_authorize.tool(
                    { scopes = { "state.read" } },
                    "keeper.state.tools:push"
                )
                test.is_true(not ok)
                test.not_nil(err)
                test.is_true(err:find("registry.write") ~= nil)
            end)

            it("agent manager requires agents.read", function()
                local ok, err = mcp_authorize.tool(
                    { scopes = { "registry.read" } },
                    "keeper.agents.tools:manager"
                )
                test.is_true(not ok)
                test.not_nil(err)
                test.is_true(err:find("agents.read") ~= nil)

                local scoped_ok, scoped_err = mcp_authorize.tool(
                    { scopes = { "agents.read" } },
                    "keeper.agents.tools:manager"
                )
                test.is_true(scoped_ok, tostring(scoped_err))
            end)

            it("agent delegate requires agents.read and agents.run", function()
                local ok, err = mcp_authorize.tool(
                    { scopes = { "agents.read" } },
                    "keeper.agents.tools:delegate"
                )
                test.is_true(not ok)
                test.not_nil(err)
                test.is_true(err:find("agents.run") ~= nil)

                local scoped_ok, scoped_err = mcp_authorize.tool(
                    { scopes = { "agents.read", "agents.run" } },
                    "keeper.agents.tools:delegate"
                )
                test.is_true(scoped_ok, tostring(scoped_err))
            end)

            it("action scopes tighten mixed read/write tools", function()
                local function checked_tool_call(session, tool_id, entry, arguments)
                    local pcall_ok, ok, err = pcall(mcp_authorize.tool_call,
                        session, tool_id, entry, arguments)
                    if not pcall_ok then return false, tostring(ok) end
                    return ok, err
                end

                local direct_ok, direct_err = mcp_authorize.require_scopes(
                    { scopes = { "components.read" } },
                    { "components.write" }
                )
                test.is_true(not direct_ok)
                test.not_nil(direct_err)

                local entry = {
                    id = "keeper.test:scoped_tool",
                    meta = {
                        type = "tool",
                        mcp = {
                            required_scopes = { "components.read" },
                            action_scopes = {
                                rewrite = "components.write",
                            },
                        },
                    },
                }

                local view_ok, view_err = checked_tool_call(
                    { scopes = { "components.read" } },
                    entry.id,
                    entry,
                    { command = "view" }
                )
                if not view_ok then error("view action authorization failed: " .. tostring(view_err)) end

                local rewrite_ok, rewrite_err = checked_tool_call(
                    { scopes = { "components.read" } },
                    entry.id,
                    entry,
                    { command = "rewrite" }
                )
                test.is_true(not rewrite_ok)
                if not rewrite_err then error("rewrite action denied without error") end
                if not rewrite_err:find("components.write") then
                    error("rewrite action denied for wrong reason: " .. tostring(rewrite_err))
                end

                local write_ok, write_err = checked_tool_call(
                    { scopes = { "components.read", "components.write" } },
                    entry.id,
                    entry,
                    { command = "rewrite" }
                )
                if not write_ok then error("write-scoped action authorization failed: " .. tostring(write_err)) end

                local invalid_entry = {
                    id = "keeper.test:invalid_scoped_tool",
                    meta = {
                        type = "tool",
                        mcp = {
                            required_scopes = { "components.read" },
                            action_scopes = {
                                rewrite = { "components.write" },
                            },
                        },
                    },
                }
                local invalid_ok, invalid_err = checked_tool_call(
                    { scopes = { "components.read" } },
                    invalid_entry.id,
                    invalid_entry,
                    { command = "rewrite" }
                )
                test.is_true(not invalid_ok)
                test.not_nil(invalid_err)
                test.is_true(invalid_err:find("invalid MCP action scope") ~= nil)
            end)
        end)

        describe("policy library", function()
            it("list_presets returns registry-backed presets", function()
                local presets = mcp_policy.list_presets()
                test.is_true(#presets >= 1, "expected at least one preset entry")
                for _, p in ipairs(presets) do
                    test.not_nil(p.id, "preset missing id")
                    test.not_nil(p.access_mode, "preset missing access_mode")
                    test.not_nil(p.registry_id, "preset missing registry_id")
                end
            end)

            it("get_preset accepts short name", function()
                local p, err = mcp_policy.get_preset("root")
                test.is_nil(err)
                test.not_nil(p)
                test.eq(p.id, "root")
                test.eq(p.registry_id, "keeper.mcp.presets:root")
            end)

            it("get_preset accepts full registry id", function()
                local p, err = mcp_policy.get_preset("keeper.mcp.presets:root")
                test.is_nil(err)
                test.eq(p.id, "root")
            end)

            it("get_preset rejects unknown short name", function()
                local p, err = mcp_policy.get_preset("nope_nope_xyz")
                test.is_nil(p)
                test.not_nil(err)
            end)

            it("get_preset rejects non-preset registry entry", function()
                local p, err = mcp_policy.get_preset("keeper.agents.traits.state:explorer")
                test.is_nil(p)
                test.not_nil(err)
            end)

            it("list_scopes returns registry-backed scopes", function()
                local scopes = mcp_policy.list_scopes()
                test.is_true(#scopes >= 1, "expected at least one scope entry")
                local set = {}
                for _, s in ipairs(scopes) do set[s.id] = true end
                test.is_true(set["registry.read"], "registry.read scope missing from registry")
                test.is_true(set["agents.read"], "agents.read scope missing from registry")
                test.is_true(set["agents.run"], "agents.run scope missing from registry")
            end)
        end)

        describe("presets", function()
            it("every preset carries a valid access_mode", function()
                for _, p in ipairs(mcp_policy.list_presets()) do
                    local valid = p.access_mode == "any"
                        or p.access_mode == "traits"
                        or p.access_mode == "tools_only"
                    test.is_true(valid, "preset " .. p.id .. " invalid access_mode " .. tostring(p.access_mode))
                end
            end)

            it("traits presets resolve non-empty trait catalogs", function()
                for _, p in ipairs(mcp_policy.list_presets()) do
                    if p.access_mode == "traits" then
                        local session = { access_mode = p.access_mode, trait_filter = p.trait_filter }
                        local cat = mcp_traits.list_catalog(session)
                        test.is_true(#cat > 0, "preset " .. p.id .. " resolves empty catalog")
                    end
                end
            end)

            it("default_active entries pass the preset's own filter", function()
                for _, p in ipairs(mcp_policy.list_presets()) do
                    local session = {
                        access_mode = p.access_mode,
                        trait_filter = p.trait_filter,
                    }
                    for _, tid in ipairs(p.default_active or {}) do
                        local allowed, err = mcp_traits.trait_allowed(session, tid)
                        test.is_true(allowed,
                            "preset " .. p.id .. " default_active " .. tid
                            .. " blocked by its own filter: " .. tostring(err))
                    end
                end
            end)

            it("every preset scope is a known scope id", function()
                local known = mcp_policy.known_scope_set()
                for _, p in ipairs(mcp_policy.list_presets()) do
                    for _, sid in ipairs(p.scopes or {}) do
                        test.is_true(known[sid],
                            "preset " .. p.id .. " references unknown scope " .. sid)
                    end
                end
            end)

            it("wippy_operator preset is a scoped remote-work surface, not root", function()
                local p, err = mcp_policy.get_preset("wippy_operator")
                test.is_nil(err)
                test.not_nil(p)
                test.eq(p.access_mode, "traits")
                test.eq(p.default_active[1], "keeper.agents.traits.wippy:operator")

                local scopes = {}
                for _, sid in ipairs(p.scopes or {}) do scopes[sid] = true end
                test.is_true(scopes["registry.write"])
                test.is_true(scopes["agents.read"])
                test.is_true(scopes["agents.run"])
                test.is_true(scopes["registry.sync"])
                test.is_true(scopes["tasks.run"])
                test.is_true(scopes["components.write"])
                test.is_nil(scopes["mcp.root"], "operator preset must stay scoped; root is a separate preset")
            end)

            it("wippy_operator preset resolves Hub tools through its default trait stack", function()
                local preset = mcp_policy.get_preset("wippy_operator")
                local tok = create_token({
                    label = "smoke-wippy-hub-" .. uuid.v4(),
                    identity = "root",
                    scopes = preset.scopes,
                    access_mode = preset.access_mode,
                    trait_filter = preset.trait_filter,
                    default_active = preset.default_active,
                })
                local session = mcp_tokens.get(tok.token)
                local resolved, err = mcp_traits.resolve(session)
                test.is_nil(err)
                test.not_nil(resolved.tools.hub_dependencies)
                test.not_nil(resolved.tools.hub_migrations)
                test.eq(resolved.tools.hub_dependencies.registry_id, "keeper.hub.tools:dependencies")
                test.eq(resolved.tools.hub_migrations.registry_id, "keeper.hub.tools:migrations")
            end)
        end)

        describe("create_token + preset smoke", function()
            it("token created from preset inherits access_mode, scopes, filters", function()
                local preset = mcp_policy.get_preset("developer")
                test.not_nil(preset)

                local tok = create_token({
                    label = "smoke-dev-" .. uuid.v4(),
                    identity = "root",
                    scopes = preset.scopes,
                    access_mode = preset.access_mode,
                    trait_filter = preset.trait_filter,
                    tool_filter = preset.tool_filter,
                    default_active = preset.default_active,
                })

                local session = mcp_tokens.get(tok.token)
                test.eq(session.access_mode, "traits")
                test.not_nil(session.trait_filter)
                test.eq(session.trait_filter.tags_any[1], "state")
                test.eq(session.default_active[1], "keeper.agents.traits.state:explorer")
            end)

            it("developer preset resolves a tool surface", function()
                local preset = mcp_policy.get_preset("developer")
                local tok = create_token({
                    label = "smoke-dev-res-" .. uuid.v4(),
                    identity = "root",
                    scopes = preset.scopes,
                    access_mode = preset.access_mode,
                    trait_filter = preset.trait_filter,
                    default_active = preset.default_active,
                })
                local session = mcp_tokens.get(tok.token)
                local resolved, err = mcp_traits.resolve(session)
                test.is_nil(err)
                local count = 0
                for _, _ in pairs(resolved.tools or {}) do count = count + 1 end
                test.is_true(count >= 1,
                    "developer preset + default_active should resolve tools; got " .. count)
            end)

            it("explorer_tools_only preset materializes tool catalog", function()
                local preset = mcp_policy.get_preset("explorer_tools_only")
                local tok = create_token({
                    label = "smoke-to-" .. uuid.v4(),
                    identity = "root",
                    scopes = preset.scopes,
                    access_mode = preset.access_mode,
                    tool_filter = preset.tool_filter,
                })
                local session = mcp_tokens.get(tok.token)
                local resolved = mcp_traits.resolve_tools_only(session)
                local count = 0
                for _, _ in pairs(resolved.tools or {}) do count = count + 1 end
                test.is_true(count >= 1,
                    "tools_only preset should surface at least one tool")
            end)

            it("observer preset blocks write traits via filter", function()
                local preset = mcp_policy.get_preset("observer")
                local tok = create_token({
                    label = "smoke-obs-" .. uuid.v4(),
                    identity = "root",
                    scopes = preset.scopes,
                    access_mode = preset.access_mode,
                    trait_filter = preset.trait_filter,
                })
                local session = mcp_tokens.get(tok.token)
                local res, err = mcp_traits.set_active(session,
                    { "keeper.agents.traits.state:editor" })
                test.is_nil(res)
                test.not_nil(err,
                    "observer preset should reject write-capable trait")
            end)

            it("wippy_operator preset resolves the practical Wippy work tools", function()
                local preset = mcp_policy.get_preset("wippy_operator")
                local tok = create_token({
                    label = "smoke-wippy-op-" .. uuid.v4(),
                    identity = "root",
                    scopes = preset.scopes,
                    access_mode = preset.access_mode,
                    trait_filter = preset.trait_filter,
                    default_active = preset.default_active,
                })
                local session = mcp_tokens.get(tok.token)
                local list, _, resolve_err = mcp_surface.build(session)
                test.is_nil(resolve_err)

                local names = {}
                for _, tool in ipairs(list or {}) do names[tool.name] = true end
                test.is_true(names.session_info == true)
                test.is_true(names.explore_state == true)
                test.is_true(names.str_replace_based_edit_tool == true)
                test.is_true(names.task_debug == true)
                test.is_true(names.system == true)
                test.is_true(names.run_test == true)
                test.is_true(names.fs == true)
                test.is_true(names.ui == true)
                test.is_true(names.sync_to_fs == true)
            end)
        end)

        describe("admin auth and transport config", function()
            local ADMIN_USER = "admin@wippy.local"
            local ENABLED_ENV = "keeper.mcp:enabled"
            local PUBLIC_API_URL_ENV = "PUBLIC_API_URL"
            local saved_enabled
            local saved_public_api_url

            before_all(function()
                saved_enabled = env.get(ENABLED_ENV)
                saved_public_api_url = env.get(PUBLIC_API_URL_ENV)
            end)

            after_all(function()
                env.set(ENABLED_ENV, saved_enabled or "")
                env.set(PUBLIC_API_URL_ENV, saved_public_api_url or "")
            end)

            local function bearer_req(token)
                return {
                    header = function(_, name)
                        if name == "Authorization" then
                            return "Bearer " .. tostring(token)
                        end
                        return nil
                    end,
                }
            end

            it("verify_admin_user accepts seeded admin", function()
                local ok, err = mcp_auth.verify_admin_user(ADMIN_USER)
                test.is_true(ok, "admin@wippy.local must resolve as admin; err=" .. tostring(err))
                test.is_nil(err)
            end)

            it("verify_admin_user rejects empty id", function()
                local ok, err = mcp_auth.verify_admin_user("")
                test.is_false(ok)
                test.not_nil(err)
            end)

            it("verify_admin_user rejects unknown user", function()
                local ok, err = mcp_auth.verify_admin_user("ghost-" .. uuid.v4() .. "@nope")
                test.is_false(ok)
                test.not_nil(err)
            end)

            it("admin_actor refuses empty session identity", function()
                local ok = pcall(mcp_auth.admin_actor, { identity = "" }, "test")
                test.is_false(ok, "admin_actor must error on empty identity")
            end)

            it("MCP transport is enabled by default", function()
                env.set(ENABLED_ENV, "")
                test.is_true(mcp_auth.enabled())
            end)

            it("MCP enabled flag parses common values and fails closed on invalid input", function()
                env.set(ENABLED_ENV, "false")
                test.is_false(mcp_auth.enabled())

                env.set(ENABLED_ENV, "yes")
                test.is_true(mcp_auth.enabled())

                env.set(ENABLED_ENV, "definitely")
                test.is_false(mcp_auth.enabled())
            end)

            it("MCP URL derives from facade PUBLIC_API_URL and configured route", function()
                env.set(PUBLIC_API_URL_ENV, "https://ops.example.com")
                test.eq(mcp_auth.path(), "/keeper-mcp/")
                test.eq(mcp_auth.public_url(), "https://ops.example.com/keeper-mcp/")
            end)

            it("app POST transport authenticates initialize and ping", function()
                test.is_true(mcp_handler_core._requires_session("initialize"))
                test.is_true(mcp_handler_core._requires_session("ping"))
                test.is_true(mcp_handler_core._requires_session("tools/list"))
            end)

            it("session_from_request extracts bearer and validates token-store subject", function()
                local tok = create_token({
                    label = "auth-session-" .. uuid.v4(),
                    identity = ADMIN_USER,
                    scopes = { "registry.read" },
                    access_mode = "tools_only",
                })

                local session, err = mcp_auth.session_from_request(bearer_req(tok.token))
                test.is_nil(err)
                test.not_nil(session)
                test.eq(session.identity, ADMIN_USER)
                test.eq(session.access_mode, "tools_only")
                test.is_true(session.internal_root ~= true)
            end)

            it("session_from_request allows token-store sessions on the app MCP mount", function()
                local tok = create_token({
                    label = "public-auth-session-" .. uuid.v4(),
                    identity = ADMIN_USER,
                    scopes = { "registry.read" },
                    access_mode = "tools_only",
                })

                local session, err = mcp_auth.session_from_request(bearer_req(tok.token))
                test.is_nil(err)
                test.not_nil(session)
                test.eq(session.identity, ADMIN_USER)
                test.is_true(session.internal_root ~= true)
            end)

            it("session_from_token rejects token-store sessions for missing users", function()
                local tok = create_token({
                    label = "missing-user-" .. uuid.v4(),
                    identity = "ghost-" .. uuid.v4() .. "@nope",
                    scopes = { "registry.read" },
                    access_mode = "tools_only",
                })

                local session, err = mcp_auth.session_from_token(tok.token)
                test.is_nil(session)
                test.not_nil(err)
            end)
        end)

        describe("meta-tool ergonomics", function()
            local function new_session(opts)
                opts = opts or {}
                local tok = create_token({
                    label = (opts.label or "meta") .. "-" .. uuid.v4(),
                    identity = "root",
                    scopes = opts.scopes or { "mcp.root" },
                    access_mode = opts.access_mode or "any",
                    trait_filter = opts.trait_filter,
                    tool_filter = opts.tool_filter,
                    default_active = opts.default_active,
                })
                return mcp_tokens.get(tok.token)
            end

            it("session_info marked always_visible in META_TOOLS", function()
                test.is_true(mcp_surface.ALWAYS_VISIBLE.session_info == true)
            end)

            it("surface.build exposes session_info in tools_only mode", function()
                local session = new_session({
                    access_mode = "tools_only",
                    tool_filter = { tags_any = { "exploration" } },
                })
                local list = mcp_surface.build(session)
                local names = {}
                for _, t in ipairs(list) do names[t.name] = true end
                test.is_true(names.session_info == true,
                    "session_info must appear in tools_only surface")
                test.is_nil(names.list_traits,
                    "trait-only meta tools must be hidden in tools_only mode")
                test.is_nil(names.use_trait,
                    "use_trait must be hidden in tools_only mode")
            end)

            it("surface.build exposes full meta surface in any mode", function()
                local session = new_session({ access_mode = "any" })
                local list = mcp_surface.build(session)
                local names = {}
                for _, t in ipairs(list) do names[t.name] = true end
                test.is_true(names.session_info == true)
                test.is_true(names.list_traits == true)
                test.is_true(names.use_trait == true)
                test.is_true(names.drop_trait == true)
                test.is_true(names.activate_traits == true)
            end)

            it("session_info returns access_mode, traits, tool_count", function()
                local session = new_session({
                    access_mode = "any",
                    default_active = { "keeper.agents.traits.state:explorer" },
                })
                local info, err = mcp_meta.session_info({}, session)
                test.is_nil(err)
                test.eq(info.access_mode, "any")
                test.eq(info.active_traits[1], "keeper.agents.traits.state:explorer")
                test.is_true(type(info.traits) == "table")
                test.is_true(#info.traits > 0, "catalog should not be empty")
                test.is_true(type(info.tool_count) == "number")
                test.is_true(info.tool_count > 0,
                    "explorer trait should materialize at least one tool")
            end)

            it("session_info works in tools_only mode (no traits)", function()
                local session = new_session({
                    access_mode = "tools_only",
                    tool_filter = { tags_any = { "exploration" } },
                })
                local info = mcp_meta.session_info({}, session)
                test.eq(info.access_mode, "tools_only")
                test.eq(#info.active_traits, 0)
                test.eq(#info.traits, 0)
                test.is_true(info.tool_count >= 1,
                    "tools_only session with exploration tag must expose tools")
            end)

            it("use_trait activates and returns added_tools", function()
                local session = new_session({ access_mode = "any" })
                local result, err = mcp_meta.use_trait(
                    { ids = { "keeper.agents.traits.state:explorer" } }, session)
                test.is_nil(err)
                test.eq(#result.active_traits, 1)
                test.eq(result.active_traits[1], "keeper.agents.traits.state:explorer")
                test.is_true(type(result.added_tools) == "table")
                test.is_true(#result.added_tools > 0,
                    "activating explorer must expose at least one new tool")
                test.is_true(type(result.tool_count) == "number")
            end)

            it("use_trait added_tools matches before/after diff", function()
                local session = new_session({ access_mode = "any" })
                local before = mcp_surface.build(session)
                local before_set = {}
                for _, t in ipairs(before) do before_set[t.name] = true end

                local result = mcp_meta.use_trait(
                    { ids = { "keeper.agents.traits.state:explorer" } }, session)

                for _, name in ipairs(result.added_tools) do
                    test.is_nil(before_set[name],
                        "added_tools must not include pre-existing tool: " .. name)
                end
            end)

            it("drop_trait deactivates and returns removed_tools", function()
                local session = new_session({
                    access_mode = "any",
                    default_active = { "keeper.agents.traits.state:explorer" },
                })
                local result, err = mcp_meta.drop_trait(
                    { ids = { "keeper.agents.traits.state:explorer" } }, session)
                test.is_nil(err)
                test.eq(#result.active_traits, 0)
                test.is_true(type(result.removed_tools) == "table")
                test.is_true(#result.removed_tools > 0,
                    "dropping last trait must remove at least one tool")
            end)

            it("use_trait rejects in tools_only mode", function()
                local session = new_session({
                    access_mode = "tools_only",
                    tool_filter = {},
                })
                local result, err = mcp_meta.use_trait(
                    { ids = { "keeper.agents.traits.state:explorer" } }, session)
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("drop_trait rejects in tools_only mode", function()
                local session = new_session({
                    access_mode = "tools_only",
                    tool_filter = {},
                })
                local result, err = mcp_meta.drop_trait(
                    { ids = { "keeper.agents.traits.state:explorer" } }, session)
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("use_trait validates trait_filter", function()
                local session = new_session({
                    access_mode = "traits",
                    trait_filter = { namespaces = { "plugin.traits" } },
                })
                local result, err = mcp_meta.use_trait(
                    { ids = { "keeper.agents.traits.state:explorer" } }, session)
                test.is_nil(result)
                test.not_nil(err,
                    "use_trait must reject trait outside filter")
            end)

            it("session_info self-heals stale persisted trait ids", function()
                local session = new_session({ access_mode = "any" })
                mcp_tokens.set_active_traits(session.token,
                    { "keeper.agents.traits.state:does_not_exist_xyz" })
                local info = mcp_meta.session_info({}, session)
                test.is_nil(info.resolve_error,
                    "prune_missing_traits should self-heal stale ids")
                test.eq(#info.active_traits, 0,
                    "active_traits reflects pruned state after self-heal")
            end)

            it("surface.diff_added/removed behave on disjoint sets", function()
                local before = { a = true, b = true }
                local after = { b = true, c = true }
                local added = mcp_surface.diff_added(before, after)
                local removed = mcp_surface.diff_removed(before, after)
                test.eq(#added, 1)
                test.eq(added[1], "c")
                test.eq(#removed, 1)
                test.eq(removed[1], "a")
            end)
        end)

        describe("list_tools + call_tool dispatcher", function()
            local function new_session(opts)
                opts = opts or {}
                local tok = mcp_tokens.create({
                    label = (opts.label or "dispatch") .. "-" .. uuid.v4(),
                    identity = "root",
                    scopes = opts.scopes or { "mcp.root" },
                    access_mode = opts.access_mode or "any",
                    trait_filter = opts.trait_filter,
                    tool_filter = opts.tool_filter,
                    default_active = opts.default_active,
                })
                if tok and tok.token then
                    table.insert(created_tokens, tok.token)
                end
                return mcp_tokens.get(tok.token)
            end

            it("list_tools and call_tool are always_visible", function()
                test.is_true(mcp_surface.ALWAYS_VISIBLE.list_tools == true)
                test.is_true(mcp_surface.ALWAYS_VISIBLE.call_tool == true)
            end)

            it("list_tools surfaces known registry tools", function()
                local session = new_session({ access_mode = "any" })
                local result, err = mcp_meta.list_tools({}, session)
                test.is_nil(err)
                test.is_true(result.count > 0)
                local found
                for _, t in ipairs(result.tools) do
                    if t.id == "keeper.state.tools:explore" then found = t; break end
                end
                test.not_nil(found, "explore tool must be listed")
                test.eq(found.name, "explore_state")
                test.not_nil(found.input_schema)
            end)

            it("list_tools filters by namespace", function()
                local session = new_session({ access_mode = "any" })
                local result = mcp_meta.list_tools({ namespace = "keeper.state.tools" }, session)
                test.is_true(result.count > 0)
                for _, t in ipairs(result.tools) do
                    test.is_true(t.id:sub(1, #"keeper.state.tools:") == "keeper.state.tools:",
                        "unexpected id in namespace filter: " .. t.id)
                end
            end)

            it("list_tools omits schema when include_schema=false", function()
                local session = new_session({ access_mode = "any" })
                local result = mcp_meta.list_tools({ include_schema = false, limit = 3 }, session)
                test.is_true(#result.tools > 0)
                test.is_nil(result.tools[1].input_schema)
                test.not_nil(result.tools[1].name)
            end)

            it("list_tools respects tool_filter (namespaces)", function()
                local session = new_session({
                    access_mode = "tools_only",
                    tool_filter = { namespaces = { "keeper.state.tools" } },
                })
                local result = mcp_meta.list_tools({}, session)
                test.is_true(result.count > 0)
                for _, t in ipairs(result.tools) do
                    local prefix = t.id:sub(1, #"keeper.state.tools:")
                    test.eq(prefix, "keeper.state.tools:",
                        "unexpected id outside namespace filter: " .. t.id)
                end
            end)

            it("call_tool rejects missing id", function()
                local session = new_session({ access_mode = "any" })
                local result, err = mcp_meta.call_tool({}, session)
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("call_tool rejects non-existent id", function()
                local session = new_session({ access_mode = "any" })
                local result, err = mcp_meta.call_tool({ id = "keeper.does_not_exist:xyz" }, session)
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("call_tool rejects entry that is not a tool", function()
                local session = new_session({ access_mode = "any" })
                local result, err = mcp_meta.call_tool({ id = "keeper.agents.traits.state:explorer" }, session)
                test.is_nil(result)
                test.not_nil(err)
                test.is_true(err:find("not a tool") ~= nil)
            end)

            it("call_tool denies tools outside session filter", function()
                local session = new_session({
                    access_mode = "tools_only",
                    scopes = { "state.read" },
                    tool_filter = { exclude_ids = { "keeper.state.tools:get_entries" } },
                })
                local result, err = mcp_meta.call_tool({ id = "keeper.state.tools:get_entries" }, session)
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("call_tool rejects arguments that violate declared schema", function()
                local session = new_session({ access_mode = "any", scopes = { "state.read" } })
                local result, err = mcp_meta.call_tool({
                    id = "keeper.state.tools:explore",
                    arguments = {},
                }, session)
                test.is_nil(result)
                test.not_nil(err,
                    "missing required 'operation' must be caught by validate")
            end)

            it("call_tool rejects non-object arguments", function()
                local session = new_session({ access_mode = "any", scopes = { "state.read" } })
                local result, err = mcp_meta.call_tool({
                    id = "keeper.state.tools:explore",
                    arguments = "not a table",
                }, session)
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("call_tool dispatches a real read tool end-to-end", function()
                local session = new_session({ access_mode = "any", scopes = { "state.read" } })
                local result, err = mcp_meta.call_tool({
                    id = "keeper.state.tools:explore",
                    arguments = { operation = "tree", root = "keeper.mcp", depth = 1 },
                }, session)
                test.is_nil(err)
                test.not_nil(result)
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
