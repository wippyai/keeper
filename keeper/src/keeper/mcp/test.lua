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
local security = require("security")
local http_client = require("http_client")
local json = require("json")
local api_test = require("api_test")
local mcp_surface = require("mcp_surface")
local mcp_meta = require("mcp_meta")
local mcp_auth = require("mcp_auth")
local mcp_authorize = require("mcp_authorize")
local mcp_handler_core = require("mcp_handler_core")
local mcp_handler_get_core = require("mcp_handler_get_core")
local mcp_sessions = require("mcp_sessions")
local mcp_broker = require("mcp_broker")
local mcp_stream_targets = require("mcp_stream_targets")
local keeper_config = require("keeper_config")

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

            it("revoke returns not found instead of success for non-stored raw token", function()
                local tok = create_token({
                    label = "revoke-raw-" .. uuid.v4(),
                    scopes = { "registry.read" },
                })

                local ok, rerr = mcp_tokens.revoke(tok.token)
                test.is_false(ok)
                test.eq(rerr, "token not found")

                local session, gerr = mcp_tokens.get(tok.token)
                test.not_nil(session)
                test.is_nil(gerr)
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

            it("strict mode denies non-root external tools without explicit MCP scopes", function()
                local ok, err = mcp_authorize.tool(
                    { scopes = { "state.read" } },
                    "wippy.agent.tools:delay_tool"
                )
                test.is_true(not ok)
                test.not_nil(err)
                test.is_true(err:find("required_scopes") ~= nil)
            end)

            it("root scope can use registered tools missing explicit MCP scopes", function()
                local session = { scopes = { "mcp.root" } }
                local ok, err = mcp_authorize.tool(session, "wippy.agent.tools:delay_tool")
                test.is_true(ok, tostring(err))

                local call_ok, call_err = mcp_authorize.tool_call(session, "wippy.agent.tools:delay_tool", nil, {})
                test.is_true(call_ok, tostring(call_err))
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
                test.is_true(scopes["git.read"])
                test.is_true(scopes["git.write"])
                test.is_true(scopes["git.pr"])
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

            it("composite traits expand through nested trait ids under the same filter", function()
                local preset = mcp_policy.get_preset("wippy_operator")
                local expanded, err = mcp_traits._expand_trait_ids({
                    access_mode = preset.access_mode,
                    scopes = preset.scopes,
                    trait_filter = preset.trait_filter,
                }, preset.default_active)

                test.is_nil(err)
                local found = {}
                for _, id in ipairs(expanded or {}) do found[id] = true end
                test.is_true(found["keeper.agents.traits.wippy:operator"] == true)
                test.is_true(found["keeper.agents.traits.state:explorer"] == true)
                test.is_true(found["keeper.agents.traits.hub:operator"] == true)
                test.is_true(found["keeper.agents.traits.git:reviewer"] == true)
            end)

            it("composite traits cannot smuggle nested traits outside token filters", function()
                local expanded, err = mcp_traits._expand_trait_ids({
                    access_mode = "traits",
                    scopes = { "mcp.introspect" },
                    trait_filter = { namespaces = { "keeper.agents.traits.wippy" } },
                }, { "keeper.agents.traits.wippy:operator" })

                test.is_nil(expanded)
                test.not_nil(err)
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
                test.is_true(names.list_clusters == true)
                test.is_true(names.get_cluster == true)
                test.is_true(names.set_decision == true)
                test.is_true(names.push == true)
                test.is_true(names.pull_request == true)
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
                local db = open_db()
                local _, users_err = db:execute([[CREATE TABLE IF NOT EXISTS app_users (
                    user_id TEXT PRIMARY KEY, status TEXT NOT NULL
                )]])
                test.is_nil(users_err)
                local _, groups_err = db:execute([[CREATE TABLE IF NOT EXISTS app_user_groups (
                    user_id TEXT NOT NULL, group_id TEXT NOT NULL,
                    PRIMARY KEY (user_id, group_id)
                )]])
                test.is_nil(groups_err)
                local _, user_err = db:execute(
                    "INSERT OR IGNORE INTO app_users (user_id, status) VALUES (?, ?)",
                    { ADMIN_USER, "active" })
                test.is_nil(user_err)
                local _, group_err = db:execute(
                    "INSERT OR IGNORE INTO app_user_groups (user_id, group_id) VALUES (?, ?)",
                    { ADMIN_USER, keeper_config.admin_scope() })
                test.is_nil(group_err)
                db:release()
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

            it("endpoint policies let the transport read its enabled switch", function()
                local policies = {}
                for _, id in ipairs({
                    "keeper.mcp.security:endpoint_db_access",
                    "keeper.mcp.security:endpoint_actor_create",
                    "keeper.mcp.security:endpoint_registry_read",
                    "keeper.mcp.security:endpoint_env_read",
                }) do
                    local policy, err = security.policy(id)
                    test.not_nil(policy, "policy " .. id .. " must exist; err=" .. tostring(err))
                    policies[#policies + 1] = policy
                end
                local scope = security.new_scope(policies)
                local actor = security.new_actor("keeper.mcp.transport:handler")
                test.eq(scope:evaluate(actor, "env.get", ENABLED_ENV), "allow",
                    "transport must be able to read " .. ENABLED_ENV)
                test.eq(scope:evaluate(actor, "env.get", PUBLIC_API_URL_ENV), "allow",
                    "transport must be able to read " .. PUBLIC_API_URL_ENV)
            end)

            -- GET / is the Streamable HTTP SSE leg. A client that opens it and gets
            -- anything but an event stream (or a 405) waits instead of falling back
            -- to POST, so the leg must be wired end to end by the module itself.
            local function transport_scope(entry_id)
                local entry, err = registry.get(entry_id)
                test.not_nil(entry, entry_id .. " entry must exist; err=" .. tostring(err))
                local declared = entry.data.security.policies
                local policies = {}
                for _, id in ipairs(declared) do
                    local policy, perr = security.policy(id)
                    test.not_nil(policy, "policy " .. id .. " must exist; err=" .. tostring(perr))
                    policies[#policies + 1] = policy
                end
                return security.new_scope(policies), security.new_actor(entry_id)
            end

            it("GET transport router relays the SSE stream it hands off", function()
                local router, err = registry.get("keeper.mcp:router")
                test.not_nil(router, "keeper.mcp:router must exist; err=" .. tostring(err))
                local relays = false
                for _, name in ipairs(router.data.middleware or {}) do
                    if name == "sse_relay" then relays = true end
                end
                test.is_true(relays,
                    "handler_get hands the connection off via X-SSE-Relay; without sse_relay on the router nothing consumes it")
            end)

            local function get_fixture(session_ids)
                local token_session = { token_hash = "test-token-hash", label = "test", identity = ADMIN_USER }
                local registry_names = {}
                for _, id in ipairs(session_ids) do
                    registry_names[mcp_consts.SSE_BROKER_NAME_PREFIX .. token_session.token_hash .. "." .. id] = "broker-" .. id
                end
                local cancelled = {}
                local sent = {}
                local spawned = 0
                local ready_messages = {}
                local ready_channels = {}
                local runtime
                local fake_channel = {
                    select = function(cases)
                        local ready = ready_messages[cases[1].topic]
                        if ready then return { channel = cases[1], value = ready } end
                        return { channel = cases[2], value = true }
                    end,
                }
                local fake_time = {
                    timer = function()
                        local timeout_channel = { case_receive = function(self) return self end }
                        return {
                            channel = function() return timeout_channel end,
                            stop = function() return true end,
                        }
                    end,
                }
                runtime = {
                    registry = {
                        lookup = function(name) return registry_names[name] end,
                        unregister = function(name)
                            registry_names[name] = nil
                            return true
                        end,
                        register = function(name, pid)
                            if registry_names[name] then return nil, "already exists" end
                            registry_names[name] = pid
                            return true
                        end,
                    },
                    listen = function(topic)
                        if not ready_channels[topic] then
                            ready_channels[topic] = {
                                topic = topic,
                                case_receive = function(self) return self end,
                            }
                        end
                        return ready_channels[topic]
                    end,
                    pid = function() return "handler-pid" end,
                    cancel = function(pid)
                        cancelled[#cancelled + 1] = pid
                        for name, registered_pid in pairs(registry_names) do
                            if registered_pid == pid then registry_names[name] = nil end
                        end
                    end,
                    send = function(pid, topic, payload)
                        if pid == "handler-pid" then
                            ready_messages[topic] = payload
                            return true
                        end
                        sent[#sent + 1] = { pid = pid, topic = topic, payload = payload }
                        return true
                    end,
                    with_context = function()
                        return {
                            with_actor = function(self) return self end,
                            with_scope = function(self) return self end,
                            spawn = function(_, _, _, args)
                                spawned = spawned + 1
                                local pid = "spawned-" .. spawned
                                local slot_name
                                for index = 1, args.slot_count do
                                    local candidate = args.slot_prefix .. tostring(index)
                                    if not registry_names[candidate] then
                                        local registered = runtime.registry.register(candidate, pid)
                                        if registered then slot_name = candidate; break end
                                    end
                                end
                                if slot_name and not registry_names[args.session_name] then
                                    runtime.registry.register(args.session_name, pid)
                                    runtime.send(args.ready_to, args.ready_topic, { success = true })
                                else
                                    if slot_name then runtime.registry.unregister(slot_name) end
                                    runtime.send(args.ready_to, args.ready_topic, {
                                        success = false,
                                        error = slot_name and "broker register failed" or "MCP_SESSION_LIMIT",
                                    })
                                end
                                return pid
                            end,
                        }
                    end,
                }
                runtime.channel_api = fake_channel
                runtime.time_api = fake_time
                local function response_for_get()
                    local response = { headers = {} }
                    function response:set_status(status) self.status = status end
                    function response:set_content_type(content_type) self.content_type = content_type end
                    function response:write_json(body) self.body = body end
                    function response:set_header(name, value) self.headers[name] = value end
                    return response
                end
                local function request_for(id)
                    return { header = function(_, name)
                        if name == "Mcp-Session-Id" then return id end
                    end }
                end
                local function get(id)
                    local response = response_for_get()
                    mcp_handler_get_core._serve_get(request_for(id), response, token_session, runtime)
                    return response
                end
                return get, cancelled, runtime, token_session, response_for_get, request_for, sent
            end

            local session_a = string.rep("a", 64)
            local session_b = string.rep("b", 64)
            local unknown_session = string.rep("c", 64)

            it("GET streams for two sessions with one token keep both brokers alive", function()
                local get, cancelled = get_fixture({ session_a, session_b })
                local first = get(session_a)
                local second = get(session_b)
                test.not_nil(first.headers["X-SSE-Relay"])
                test.not_nil(second.headers["X-SSE-Relay"])
                test.is_true(first.headers["X-SSE-Relay"]:find("broker-" .. session_a, 1, true) ~= nil)
                test.is_true(second.headers["X-SSE-Relay"]:find("broker-" .. session_b, 1, true) ~= nil)
                test.eq(#cancelled, 0, "a second client's GET must not cancel the first broker")
            end)

            it("GET with an unknown session returns HTTP 404", function()
                local get = get_fixture({ session_a })
                local response = get(unknown_session)
                test.eq(response.status, 404)
                test.is_nil(response.headers["X-SSE-Relay"])
            end)

            it("GET reconnect of one session reuses its broker without cancellation", function()
                local get, cancelled = get_fixture({ session_a })
                local first = get(session_a)
                local second = get(session_a)
                test.is_true(first.headers["X-SSE-Relay"]:find("broker-" .. session_a, 1, true) ~= nil)
                test.is_true(second.headers["X-SSE-Relay"]:find("broker-" .. session_a, 1, true) ~= nil)
                test.eq(#cancelled, 0, "reconnect must not cancel the session broker")
            end)

            it("one session routes each notification to one stream and survives leaves", function()
                local streams = mcp_stream_targets.new()
                streams:join("stream-one")
                test.eq(streams:current(), "stream-one")
                streams:join("stream-two")
                test.eq(streams:current(), "stream-two")
                streams:leave("stream-one")
                test.eq(streams:current(), "stream-two")
                streams:join("stream-one")
                test.eq(streams:current(), "stream-one")
                streams:leave("stream-one")
                test.eq(streams:current(), "stream-two")
                streams:leave("stream-two")
                test.is_nil(streams:current())
                streams:join("stream-three")
                test.eq(streams:current(), "stream-three")
            end)

            it("initialize issues distinct session IDs and POST binds to the issued broker", function()
                local get, cancelled, runtime, token_session, new_response, request_for = get_fixture({})
                local first = new_response()
                local second = new_response()
                local identity = function() return "actor", "scope" end
                test.is_true(mcp_handler_core._bind_session(request_for(nil), first, "initialize",
                    token_session, 1, runtime, identity, keeper_config.process_host(),
                    runtime.channel_api, runtime.time_api))
                test.is_true(mcp_handler_core._bind_session(request_for(nil), second, "initialize",
                    token_session, 2, runtime, identity, keeper_config.process_host(),
                    runtime.channel_api, runtime.time_api))
                local first_id = first.headers["Mcp-Session-Id"]
                local second_id = second.headers["Mcp-Session-Id"]
                test.is_true(type(first_id) == "string" and first_id:match("^[0-9a-f]+$") ~= nil)
                test.eq(#first_id, 64)
                test.is_true(first_id ~= second_id)
                test.not_nil(get(first_id).headers["X-SSE-Relay"])
                test.not_nil(get(second_id).headers["X-SSE-Relay"])
                test.is_true(mcp_handler_core._bind_session(request_for(first_id), new_response(), "ping",
                    token_session, 3, runtime))
                test.eq(token_session.mcp_session_id, first_id)
                test.eq(#cancelled, 0)
            end)

            it("POST rejects missing, unknown and foreign session IDs", function()
                local _, _, runtime, token_session, new_response, request_for = get_fixture({ session_a })
                local missing = new_response()
                test.is_false(mcp_handler_core._bind_session(request_for(nil), missing, "ping",
                    token_session, 1, runtime))
                test.eq(missing.status, 400)
                local unknown = new_response()
                test.is_false(mcp_handler_core._bind_session(request_for(unknown_session), unknown, "ping",
                    token_session, 2, runtime))
                test.eq(unknown.status, 404)
                local foreign = new_response()
                test.is_false(mcp_handler_core._bind_session(request_for(session_a), foreign, "ping",
                    { token_hash = "another-token" }, 3, runtime))
                test.eq(foreign.status, 404)
            end)

            it("POST activity touches the resolved session broker", function()
                local _, _, runtime, token_session, new_response, request_for, sent = get_fixture({ session_a })
                test.is_true(mcp_handler_core._bind_session(request_for(session_a), new_response(), "ping",
                    token_session, 9, runtime))
                test.eq(#sent, 1)
                test.eq(sent[1].pid, "broker-" .. session_a)
                test.eq(sent[1].topic, "mcp.activity")
            end)

            it("POST activity keeps an unstreamed broker alive past its idle window, then idle expires", function()
                local function simulate_broker(activity_times, other_events, reset_fire_race)
                    local now = 0
                    local timer_fired_at
                    local timer_count = 0
                    local timer_resets = 0
                    local timer_stops = 0
                    local timer_subscriptions = 0
                    local channels = {}
                    local queue = {}
                    for _, at in ipairs(activity_times) do
                        queue[#queue + 1] = { at = at, topic = "mcp.activity", value = {} }
                    end
                    for _, event in ipairs(other_events or {}) do queue[#queue + 1] = event end
                    local function channel_for(topic)
                        if not channels[topic] then
                            channels[topic] = {
                                topic = topic,
                                case_receive = function(self) return self end,
                            }
                        end
                        return channels[topic]
                    end
                    local registry_names = {}
                    local fake_process = {
                        event = { CANCEL = "cancel", EXIT = "exit" },
                        pid = function() return "broker-pid" end,
                        registry = {
                            register = function(name)
                                if registry_names[name] then return nil, "already exists" end
                                registry_names[name] = "broker-pid"
                                return true
                            end,
                            lookup = function(name) return registry_names[name] end,
                            unregister = function(name) registry_names[name] = nil; return true end,
                        },
                        listen = function(topic) return channel_for(topic) end,
                        events = function() return channel_for("process.events") end,
                        send = function() return true end,
                    }
                    local fake_time = {
                        timer = function()
                            timer_count = timer_count + 1
                            timer_subscriptions = timer_subscriptions + 1
                            local timer = {
                                deadline = now + 100,
                                active = true,
                                closed = false,
                                stopped = false,
                                generation = 0,
                            }
                            timer.case_receive = function(self) return self end
                            timer.channel = function(self) return self end
                            timer.reset = function(self)
                                timer_resets = timer_resets + 1
                                if self.stopped or self.closed then return false end
                                self.generation = self.generation + 1
                                if reset_fire_race and now >= self.deadline then
                                    self.fired = true
                                    self.stale_frame_discarded = true
                                    self.active = false
                                    return false
                                end
                                self.deadline = now + 100
                                self.active = true
                                return true
                            end
                            timer.stop = function(self)
                                timer_stops = timer_stops + 1
                                if not self.stopped then
                                    timer_subscriptions = timer_subscriptions - 1
                                end
                                self.stopped = true
                                self.active = false
                                self.closed = true
                                return true
                            end
                            return timer
                        end,
                    }
                    fake_time.after = function()
                        timer_count = timer_count + 1
                        local timer = { deadline = now + 100 }
                        timer.case_receive = function(self) return self end
                        return timer
                    end
                    local fake_channel = {
                        select = function(cases)
                            for _, candidate in ipairs(cases) do
                                if candidate.closed then
                                    timer_fired_at = now
                                    return { channel = candidate, value = nil }
                                end
                            end
                            local next_event_index
                            for index, event in ipairs(queue) do
                                if not next_event_index or event.at < queue[next_event_index].at then
                                    next_event_index = index
                                end
                            end
                            local timer
                            for _, candidate in ipairs(cases) do
                                if candidate.deadline and candidate.active ~= false then timer = candidate end
                            end
                            if next_event_index and (not timer or queue[next_event_index].at < timer.deadline
                                or (reset_fire_race and queue[next_event_index].at == timer.deadline)) then
                                local event = table.remove(queue, next_event_index)
                                now = event.at
                                return { channel = channel_for(event.topic), value = event.value }
                            end
                            if not timer then error("fake select has no active timer or queued event") end
                            now = timer.deadline
                            timer_fired_at = now
                            timer.active = false
                            timer.closed = true
                            if not timer.stopped then timer_subscriptions = timer_subscriptions - 1 end
                            return { channel = timer, value = nil }
                        end,
                    }
                    local state = mcp_broker._run_with(fake_channel, fake_time, mcp_stream_targets, {
                        SSE_IDLE_TIMEOUT = "test",
                        MCP_ACTIVITY_TOPIC = "mcp.activity",
                        MCP_NOTIFY_TOPIC = "mcp.notify",
                        SSE_MESSAGE_TOPIC = "message",
                    }, fake_process, {
                        session_name = "mcp.session.token.id",
                        slot_prefix = "mcp.session.token.slot.",
                        slot_count = 1,
                        ready_to = "handler-pid",
                        ready_topic = "mcp.ready.id",
                    })
                    test.eq(state.activity_count, #activity_times,
                        "the broker state must account for every POST touch")
                    test.not_nil(state.idle_timer,
                        "the broker state must retain its idle timer")
                    return timer_fired_at, timer_count, timer_resets, timer_stops, state, timer_subscriptions
                end

                local activity_times = {}
                for at = 1, 1000 do activity_times[#activity_times + 1] = at end
                local active_expiry, active_timers, active_resets, _, active_state = simulate_broker(activity_times)
                test.eq(active_expiry, 1100,
                    "the most recent POST must refresh expiry beyond the original idle window")
                test.eq(active_timers, 1,
                    "1,000 POST touches must reuse the broker's one idle timer")
                test.eq(active_resets, 1000)
                test.eq(active_state.idle_timer, active_state.idle_channel,
                    "the broker must keep the same timer channel while resetting its timer")
                local idle_expiry, idle_timers = simulate_broker({})
                test.eq(idle_expiry, 100)
                test.eq(idle_timers, 1)

                local function stream_message(pid)
                    return { from = function() return pid end }
                end
                local stream_expiry, stream_timers, stream_resets, stream_stops, stream_state =
                    simulate_broker({ 20 }, {
                        { at = 10, topic = "sse.join", value = stream_message("stream-pid") },
                        { at = 30, topic = "sse.leave", value = stream_message("stream-pid") },
                    })
                test.eq(stream_expiry, 130,
                    "the idle window must restart when the attached stream leaves")
                test.eq(stream_timers, 2,
                    "the final stream detach must allocate a fresh idle timer")
                test.eq(stream_resets, 0,
                    "activity while a stream is attached must not reset an idle timer")
                test.eq(stream_stops, 1,
                    "attaching an SSE stream must stop the idle timer")
                test.eq(stream_state.activity_count, 1)

                local detached_expiry, detached_timers, detached_resets, detached_stops =
                    simulate_broker({ 40, 70 }, {
                        { at = 10, topic = "sse.join", value = stream_message("stream-pid") },
                        { at = 30, topic = "sse.leave", value = stream_message("stream-pid") },
                    })
                test.eq(detached_expiry, 170,
                    "POST touches after detach must extend the fresh idle timer")
                test.eq(detached_timers, 2,
                    "detached POST touches must reuse the new timer")
                test.eq(detached_resets, 2)
                test.eq(detached_stops, 1)

                local cycle_expiry, cycle_timers, _, cycle_stops = simulate_broker({}, {
                    { at = 10, topic = "sse.join", value = stream_message("first-stream") },
                    { at = 30, topic = "sse.leave", value = stream_message("first-stream") },
                    { at = 80, topic = "sse.join", value = stream_message("second-stream") },
                    { at = 90, topic = "sse.leave", value = stream_message("second-stream") },
                })
                test.eq(cycle_expiry, 190,
                    "each final detach must start a full idle retention window")
                test.eq(cycle_timers, 3,
                    "each attach/detach cycle must replace its stopped timer")
                test.eq(cycle_stops, 2)

                local race_expiry, race_timers, race_resets, race_stops, _, race_subscriptions =
                    simulate_broker({ 100 }, nil, true)
                test.eq(race_expiry, 200,
                    "a POST touch racing timer expiry must start a fresh idle window")
                test.eq(race_timers, 2,
                    "a failed reset after the timer fires must allocate a replacement timer")
                test.eq(race_resets, 1)
                test.eq(race_subscriptions, 0,
                    "the reset/fire race must leave no orphan timer subscriptions")
                test.eq(race_stops, 1,
                    "the broker must stop the timer whose reset loses a race with expiry")
            end)

            it("a broker that exits before readiness cannot reserve a slot", function()
                local cap = keeper_config.mcp_max_sessions_per_token()
                local token_session = { token_hash = "dead-broker-token", label = "dead-broker", identity = ADMIN_USER }
                local names = {}
                local cancelled = {}
                local ready_channel = { case_receive = function(self) return self end }
                local timeout_channel = { case_receive = function(self) return self end }
                local timeout_timer = {
                    channel = function() return timeout_channel end,
                    stop = function() return true end,
                }
                local runtime = {
                    registry = {
                        lookup = function(name) return names[name] end,
                        register = function(name, pid)
                            if names[name] then return nil, "already exists" end
                            names[name] = pid
                            return true
                        end,
                        unregister = function(name) names[name] = nil; return true end,
                    },
                    listen = function() return ready_channel end,
                    pid = function() return "handler-pid" end,
                    cancel = function(pid)
                        cancelled[#cancelled + 1] = pid
                        for name, registered_pid in pairs(names) do
                            if registered_pid == pid then names[name] = nil end
                        end
                    end,
                    with_context = function()
                        return {
                            with_actor = function(self) return self end,
                            with_scope = function(self) return self end,
                            spawn = function() return "dead-broker" end,
                        }
                    end,
                }
                local fake_channel = {
                    select = function(cases)
                        return { channel = cases[2], value = true }
                    end,
                }
                local fake_time = { timer = function() return timeout_timer end }
                local identity = function() return "actor", "scope" end
                local response = {}
                function response:set_status(status) self.status = status end
                function response:write_json(body) self.body = body end
                function response:set_header(name, value)
                    self.headers = self.headers or {}
                    self.headers[name] = value
                end
                local request = { header = function() return nil end }

                test.is_false(mcp_handler_core._bind_session(request, response, "initialize",
                    token_session, 42, runtime, identity, keeper_config.process_host(),
                    fake_channel, fake_time))
                test.eq(response.status, 500)
                test.eq(response.body.error.message, "broker readiness timed out")

                for _ = 1, cap do
                    local id, err = mcp_sessions.create(token_session, runtime, identity,
                        keeper_config.process_host(), fake_channel, fake_time)
                    test.is_nil(id, tostring(err))
                    test.eq(err, "broker readiness timed out")
                end
                test.eq(next(names), nil, "a dead child must never leave session or slot names")
                test.eq(#cancelled, cap + 1, "each timed-out broker must be cancelled")
            end)

            it("lost broker readiness times out, releases both names, and permits replacement initialize", function()
                local token_session = {
                    token_hash = "lost-readiness-token",
                    label = "lost-readiness",
                    identity = ADMIN_USER,
                }
                local names = {}
                local pending_cancels = {}
                local spawn_records = {}
                local readiness_messages = {}
                local channels = {}
                local spawn_count = 0
                local both_names_registered_at_timeout = false

                local function channel_for(topic)
                    if not channels[topic] then
                        channels[topic] = {
                            topic = topic,
                            case_receive = function(self) return self end,
                        }
                    end
                    return channels[topic]
                end

                local runtime
                runtime = {
                    registry = {
                        lookup = function(name) return names[name] end,
                        register = function(name, pid)
                            if names[name] then return nil, "already exists" end
                            names[name] = pid
                            return true
                        end,
                        unregister = function(name) names[name] = nil; return true end,
                    },
                    listen = channel_for,
                    pid = function() return "handler-pid" end,
                    cancel = function(pid) pending_cancels[#pending_cancels + 1] = pid end,
                    send = function(_, topic, payload)
                        if spawn_count > 1 then readiness_messages[topic] = payload end
                        return true
                    end,
                    with_context = function()
                        local context = {}
                        context.with_actor = function(self) return self end
                        context.with_scope = function(self) return self end
                        context.spawn = function(_, _, _, args)
                            spawn_count = spawn_count + 1
                            local pid = "readiness-broker-" .. tostring(spawn_count)
                            local slot_name
                            for index = 1, args.slot_count do
                                local candidate = args.slot_prefix .. tostring(index)
                                if runtime.registry.register(candidate, pid) then
                                    slot_name = candidate
                                    break
                                end
                            end
                            if not slot_name then return nil, "MCP_SESSION_LIMIT" end
                            if not runtime.registry.register(args.session_name, pid) then
                                runtime.registry.unregister(slot_name)
                                return nil, "broker register failed"
                            end
                            spawn_records[spawn_count] = {
                                pid = pid,
                                slot_name = slot_name,
                                session_name = args.session_name,
                                ready_topic = args.ready_topic,
                            }

                            -- The first broker's accepted ready reply is lost before the
                            -- handler can receive it; the replacement reply is delivered.
                            runtime.send(args.ready_to, args.ready_topic, { success = true })
                            return pid
                        end
                        return context
                    end,
                }

                local fake_channel = {
                    select = function(cases)
                        local ready = readiness_messages[cases[1].topic]
                        if ready then
                            readiness_messages[cases[1].topic] = nil
                            return { channel = cases[1], value = ready }
                        end
                        if spawn_count == 1 then
                            local lost = spawn_records[1]
                            both_names_registered_at_timeout = names[lost.slot_name] == lost.pid
                                and names[lost.session_name] == lost.pid
                        end
                        return { channel = cases[2], value = true }
                    end,
                }
                local fake_time = {
                    timer = function()
                        local timeout_channel = { case_receive = function(self) return self end }
                        return {
                            channel = function() return timeout_channel end,
                            stop = function() return true end,
                        }
                    end,
                }
                local function response()
                    local res = {}
                    function res:set_status(status) self.status = status end
                    function res:write_json(body) self.body = body end
                    function res:set_header(name, value)
                        self.headers = self.headers or {}
                        self.headers[name] = value
                    end
                    return res
                end
                local request = { header = function() return nil end }
                local identity = function() return "actor", "scope" end

                local timed_out = response()
                test.is_false(mcp_handler_core._bind_session(request, timed_out, "initialize",
                    token_session, 71, runtime, identity, keeper_config.process_host(),
                    fake_channel, fake_time))
                test.eq(timed_out.status, 500)
                test.eq(timed_out.body.error.message, "broker readiness timed out")
                test.is_true(both_names_registered_at_timeout,
                    "the lost reply must occur after the broker owns its slot and session name")
                test.eq(#pending_cancels, 1)
                test.eq(pending_cancels[1], spawn_records[1].pid)
                test.not_nil(names[spawn_records[1].slot_name],
                    "names remain owned until the broker processes cancellation")
                test.not_nil(names[spawn_records[1].session_name])

                local cancelled_pid = table.remove(pending_cancels, 1)
                local cancelled_record = spawn_records[1]
                test.eq(cancelled_pid, cancelled_record.pid)
                names[cancelled_record.slot_name] = nil
                names[cancelled_record.session_name] = nil
                test.eq(next(names), nil,
                    "processing readiness-timeout cancellation must release both broker names")

                local replacement = response()
                test.is_true(mcp_handler_core._bind_session(request, replacement, "initialize",
                    token_session, 72, runtime, identity, keeper_config.process_host(),
                    fake_channel, fake_time))
                local replacement_id = replacement.headers["Mcp-Session-Id"]
                test.not_nil(replacement_id,
                    "a replacement initialize must receive a session ID")
                test.eq(names[spawn_records[2].slot_name], spawn_records[2].pid)
                test.eq(names[spawn_records[2].session_name], spawn_records[2].pid)
            end)

            it("broker startup releases slot and session names across registration crashes", function()
                local names = {}
                local args = {
                    session_name = "mcp.session.crash-test.id",
                    slot_prefix = "mcp.session.crash-test.slot.",
                    slot_count = 1,
                    ready_to = "handler-pid",
                    ready_topic = "mcp.ready.crash-test",
                }

                local function run_startup(failure_stage)
                    local pid = "crash-test-broker-" .. tostring(failure_stage or "healthy")
                    local ready_payload
                    local listeners_ready_at_ack = false
                    local process_dead = false
                    local channels = {}
                    local function channel_for(topic)
                        if not channels[topic] then
                            channels[topic] = {
                                topic = topic,
                                case_receive = function(self) return self end,
                            }
                        end
                        return channels[topic]
                    end
                    local function cleanup_owner()
                        local owned = {}
                        for name, owner in pairs(names) do
                            if owner == pid then owned[#owned + 1] = name end
                        end
                        for _, name in ipairs(owned) do names[name] = nil end
                    end
                    local fake_process = {
                        event = { CANCEL = "cancel", EXIT = "exit" },
                        registry = {
                            register = function(name)
                                if failure_stage == "before_slot" and name == args.slot_prefix .. "1" then
                                    return nil, "simulated exit before slot registration"
                                end
                                if failure_stage == "after_slot" and name == args.session_name then
                                    process_dead = true
                                    cleanup_owner()
                                    return nil, "simulated exit after slot registration"
                                end
                                if failure_stage == "before_session" and name == args.session_name then
                                    return nil, "simulated exit after slot registration"
                                end
                                if names[name] then return nil, "already exists" end
                                names[name] = pid
                                if failure_stage == "after_session" and name == args.session_name then
                                    process_dead = true
                                    cleanup_owner()
                                    return nil, "simulated exit after session registration"
                                end
                                return true
                            end,
                            lookup = function(name) return names[name] end,
                            unregister = function(name)
                                if names[name] == pid then names[name] = nil end
                                return true
                            end,
                        },
                        listen = function(topic) return channel_for(topic) end,
                        events = function() return channel_for("process.events") end,
                        send = function(to, topic, payload)
                            if process_dead then return false end
                            if failure_stage == "before_ready" and payload.success then
                                process_dead = true
                                cleanup_owner()
                                return false
                            end
                            if payload.success then
                                listeners_ready_at_ack = channels["sse.join"] ~= nil
                                    and channels["sse.leave"] ~= nil
                                    and channels["mcp.notify"] ~= nil
                                    and channels["mcp.activity"] ~= nil
                            end
                            ready_payload = payload
                            return true
                        end,
                    }
                    local fake_time = {
                        timer = function()
                            local timer_channel = { case_receive = function(self) return self end }
                            return {
                                channel = function() return timer_channel end,
                                reset = function() return true end,
                                stop = function() return true end,
                            }
                        end,
                    }
                    local events = channel_for("process.events")
                    local fake_channel = {
                        select = function()
                            return { channel = events, value = { kind = "exit" } }
                        end,
                    }
                    local state = mcp_broker._run_with(fake_channel, fake_time, mcp_stream_targets, {
                        SSE_IDLE_TIMEOUT = "test",
                        MCP_ACTIVITY_TOPIC = "mcp.activity",
                        MCP_NOTIFY_TOPIC = "mcp.notify",
                        SSE_MESSAGE_TOPIC = "message",
                    }, fake_process, args)
                    cleanup_owner()
                    return state, ready_payload, process_dead, listeners_ready_at_ack
                end

                for _, stage in ipairs({
                    "before_slot", "after_slot", "before_session", "after_session", "before_ready",
                }) do
                    local failed = run_startup(stage)
                    test.eq(next(names), nil, "crash at " .. stage .. " must release every owned name")
                    test.not_nil(failed.startup_error,
                        "crash at " .. stage .. " must fail broker startup")
                    local healthy, ready, _, listeners_ready = run_startup(nil)
                    test.is_true(ready and ready.success,
                        "a new broker must claim the freed slot after " .. stage)
                    test.not_nil(healthy.slot_name)
                    test.is_true(listeners_ready,
                        "a broker must have its stream and activity listeners before readiness")
                    test.eq(next(names), nil, "exiting healthy broker must release its slot and session name")
                end

                local exited, ready, _, listeners_ready = run_startup("after_ready")
                test.is_true(ready and ready.success)
                test.is_true(listeners_ready)
                test.eq(exited.exit_kind, "exit")
                test.eq(next(names), nil, "exit after readiness must release both names")
            end)

            it("session creation accepts the per-token cap and rejects the next session without eviction", function()
                local cap = keeper_config.mcp_max_sessions_per_token()
                test.is_true(cap >= 1)
                local token_session = { token_hash = "cap-test-token", label = "cap-test", identity = ADMIN_USER }
                local names = {}
                local spawned = 0
                local cancelled = {}
                local ready_messages = {}
                local ready_channels = {}
                local runtime
                local fake_channel = {
                    select = function(cases)
                        local ready = ready_messages[cases[1].topic]
                        if ready then return { channel = cases[1], value = ready } end
                        return { channel = cases[2], value = true }
                    end,
                }
                local fake_time = {
                    timer = function()
                        local timeout_channel = { case_receive = function(self) return self end }
                        return {
                            channel = function() return timeout_channel end,
                            stop = function() return true end,
                        }
                    end,
                }
                runtime = {
                    registry = {
                        lookup = function(name) return names[name] end,
                        register = function(name, pid)
                            if names[name] then return nil, "already exists" end
                            names[name] = pid
                            return true
                        end,
                        unregister = function(name) names[name] = nil; return true end,
                    },
                    listen = function(topic)
                        if not ready_channels[topic] then
                            ready_channels[topic] = {
                                topic = topic,
                                case_receive = function(self) return self end,
                            }
                        end
                        return ready_channels[topic]
                    end,
                    pid = function() return "handler-pid" end,
                    cancel = function(pid)
                        cancelled[#cancelled + 1] = pid
                        for name, registered_pid in pairs(names) do
                            if registered_pid == pid then names[name] = nil end
                        end
                    end,
                    send = function(pid, topic, payload)
                        if pid == "handler-pid" then ready_messages[topic] = payload end
                        return true
                    end,
                    with_context = function()
                        return {
                            with_actor = function(self) return self end,
                            with_scope = function(self) return self end,
                            spawn = function(_, _, _, args)
                                spawned = spawned + 1
                                local pid = "cap-broker-" .. spawned
                                local slot_name
                                for index = 1, args.slot_count do
                                    local candidate = args.slot_prefix .. tostring(index)
                                    local registered = runtime.registry.register(candidate, pid)
                                    if registered then slot_name = candidate; break end
                                end
                                if slot_name then
                                    local registered = runtime.registry.register(args.session_name, pid)
                                    if registered then
                                        runtime.send(args.ready_to, args.ready_topic, { success = true })
                                    else
                                        runtime.registry.unregister(slot_name)
                                        runtime.send(args.ready_to, args.ready_topic, {
                                            success = false,
                                            error = "broker session registration failed",
                                        })
                                    end
                                else
                                    runtime.send(args.ready_to, args.ready_topic, {
                                        success = false,
                                        error = "MCP_SESSION_LIMIT",
                                    })
                                end
                                return pid
                            end,
                        }
                    end,
                }
                runtime.channel_api = fake_channel
                runtime.time_api = fake_time
                local identity = function() return "actor", "scope" end
                local ids = {}
                for _ = 1, cap do
                    local id, err = mcp_sessions.create(token_session, runtime, identity,
                        keeper_config.process_host(), fake_channel, fake_time)
                    test.not_nil(id, tostring(err))
                    ids[#ids + 1] = id
                end
                local rejected, limit_err = mcp_sessions.create(token_session, runtime, identity,
                    keeper_config.process_host(), fake_channel, fake_time)
                test.is_nil(rejected)
                test.eq(limit_err, "MCP_SESSION_LIMIT")
                local response = {}
                function response:set_status(status) self.status = status end
                function response:write_json(body) self.body = body end
                function response:set_header(name, value) self.headers = self.headers or {}; self.headers[name] = value end
                local request = { header = function() return nil end }
                test.is_false(mcp_handler_core._bind_session(request, response, "initialize",
                    token_session, 18, runtime, identity, keeper_config.process_host(),
                    fake_channel, fake_time))
                test.eq(response.status, 429)
                test.eq(response.body.jsonrpc, "2.0")
                test.eq(response.body.id, 18)
                test.eq(response.body.error.code, -32000)
                test.eq(response.body.error.message, "Maximum active MCP sessions per token reached")
                test.eq(#cancelled, 2, "only rejected new brokers may be cancelled")
                for _, id in ipairs(ids) do
                    test.not_nil(mcp_sessions.lookup(token_session, id, runtime),
                        "reaching the cap must leave every existing session registered")
                end
            end)

            it("DELETE terminates one session and later GET and POST return HTTP 404", function()
                local get, cancelled, runtime, token_session, new_response, request_for =
                    get_fixture({ session_a, session_b })
                local deleted = new_response()
                mcp_handler_core._terminate_session(request_for(session_a), deleted, token_session, runtime)
                test.eq(deleted.status, 204)
                test.eq(#cancelled, 1)
                test.eq(cancelled[1], "broker-" .. session_a)
                test.eq(get(session_a).status, 404)
                test.not_nil(get(session_b).headers["X-SSE-Relay"])
                local post = new_response()
                test.is_false(mcp_handler_core._bind_session(request_for(session_a), post, "ping",
                    token_session, 1, runtime))
                test.eq(post.status, 404)
                local repeated = new_response()
                mcp_handler_core._terminate_session(request_for(session_a), repeated, token_session, runtime)
                test.eq(repeated.status, 404)
            end)

            it("expired broker IDs return HTTP 404 on GET and POST", function()
                local get, _, runtime, token_session, new_response, request_for = get_fixture({ session_a })
                runtime.registry.unregister(mcp_consts.SSE_BROKER_NAME_PREFIX .. token_session.token_hash .. "." .. session_a)
                test.eq(get(session_a).status, 404)
                local post = new_response()
                test.is_false(mcp_handler_core._bind_session(request_for(session_a), post, "ping",
                    token_session, 1, runtime))
                test.eq(post.status, 404)
            end)

            it("POST gets startup, readiness failure, and broker send permissions only", function()
                local scope, actor = transport_scope("keeper.mcp.transport:handler")
                local broker_name = mcp_consts.SSE_BROKER_NAME_PREFIX .. "0123abcd." .. session_a
                local some_pid = "{node@" .. keeper_config.process_host() .. "|0x00042}"
                local required = {
                    { "process.context", "context" },
                    { "process.security", "security" },
                    { "process.spawn", "keeper.mcp.transport:broker" },
                    { "process.host", keeper_config.process_host() },
                    { "process.cancel", some_pid },
                    { "process.send", some_pid },
                }
                for _, pair in ipairs(required) do
                    test.eq(scope:evaluate(actor, pair[1], pair[2]), "allow",
                        "handler needs " .. pair[1] .. " on " .. pair[2])
                end
                local denied = {
                    { "process.registry.register", broker_name },
                    { "process.registry.unregister", broker_name },
                    { "process.registry.foreign", some_pid },
                }
                for _, pair in ipairs(denied) do
                    test.is_true(scope:evaluate(actor, pair[1], pair[2]) ~= "allow",
                        "POST handler must not hold " .. pair[1])
                end
            end)

            it("GET resolves a broker without foreign, send, spawn, or cancel permission", function()
                local scope, actor = transport_scope("keeper.mcp.transport:handler_get")
                local some_pid = "{node@" .. keeper_config.process_host() .. "|0x00042}"
                test.is_true(scope:evaluate(actor, "process.registry.foreign", some_pid) ~= "allow")
                local denied = {
                    { "process.spawn", "keeper.mcp.transport:handler" },
                    { "process.spawn", "keeper.mcp.transport:broker" },
                    { "process.cancel", some_pid },
                    { "process.send", some_pid },
                    { "process.registry.register", "keeper.other.name" },
                    { "process.registry.unregister", "keeper.other.name" },
                }
                for _, pair in ipairs(denied) do
                    test.is_true(scope:evaluate(actor, pair[1], pair[2]) ~= "allow",
                        "handler_get must not hold " .. pair[1] .. " on " .. pair[2])
                end
            end)

            it("DELETE gets only session unregister and broker cancel permissions", function()
                local scope, actor = transport_scope("keeper.mcp.transport:handler_delete")
                local some_pid = "{node@" .. keeper_config.process_host() .. "|0x00042}"
                local session_name = mcp_consts.SSE_BROKER_NAME_PREFIX .. "test-token.session-id"
                test.eq(scope:evaluate(actor, "process.registry.unregister", session_name), "allow")
                test.eq(scope:evaluate(actor, "process.cancel", some_pid), "allow")
                local denied = {
                    { "process.registry.register", session_name },
                    { "process.registry.foreign", some_pid },
                    { "process.send", some_pid },
                    { "process.spawn", "keeper.mcp.transport:broker" },
                    { "process.context", "context" },
                    { "process.security", "security" },
                }
                for _, pair in ipairs(denied) do
                    test.is_true(scope:evaluate(actor, pair[1], pair[2]) ~= "allow",
                        "DELETE handler must not hold " .. pair[1])
                end
            end)

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

            it("admin config failures become explicit service errors, not generic admin denials", function()
                local status, payload = mcp_auth.admin_failure({
                    code = "KEEPER_CONFIG_EMPTY",
                    key = "admin_scope",
                    requirement = "keeper:admin_scope",
                    entry = "keeper.config:admin_scope",
                    message = "Keeper configuration empty: admin_scope",
                })
                test.eq(status, 503)
                test.eq(payload.error, "Keeper configuration incomplete")
                test.eq(payload.code, "KEEPER_CONFIG_EMPTY")
                test.eq(payload.details.requirement, "keeper:admin_scope")
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

            it("HTTP initialize, POST, GET rejection and DELETE follow session lifecycle", function()
                env.set(ENABLED_ENV, "true")
                local tok = create_token({
                    label = "http-session-" .. uuid.v4(),
                    identity = ADMIN_USER,
                    scopes = { "registry.read" },
                    access_mode = "tools_only",
                })
                local endpoint = api_test.endpoint("/keeper-mcp/")
                local function headers(id)
                    local out = {
                        Authorization = "Bearer " .. tok.token,
                        ["Content-Type"] = "application/json",
                        Accept = "application/json, text/event-stream",
                    }
                    if id then out["Mcp-Session-Id"] = id end
                    return out
                end
                local function response_header(response, name)
                    for key, value in pairs(response.headers or {}) do
                        if tostring(key):lower() == name:lower() then
                            if type(value) == "table" then return value[1] end
                            return value
                        end
                    end
                    return nil
                end
                local function initialize(request_id)
                    return http_client.post(endpoint, {
                        headers = headers(),
                        body = json.encode({ jsonrpc = "2.0", id = request_id, method = "initialize",
                            params = { protocolVersion = mcp_consts.PROTOCOL_VERSION,
                                capabilities = {}, clientInfo = { name = "keeper-test", version = "1" } } }),
                    })
                end
                local first, first_err = initialize(1)
                test.is_nil(first_err)
                test.eq(first.status_code, 200, "first initialize")
                local first_id = response_header(first, "Mcp-Session-Id")
                test.not_nil(first_id)
                test.eq(#first_id, 64)

                local second, second_err = initialize(2)
                test.is_nil(second_err)
                test.eq(second.status_code, 200, "second initialize")
                local second_id = response_header(second, "Mcp-Session-Id")
                test.not_nil(second_id)
                test.is_true(first_id ~= second_id)

                local ping, ping_err = http_client.post(endpoint, {
                    headers = headers(first_id),
                    body = json.encode({ jsonrpc = "2.0", id = 3, method = "ping" }),
                })
                test.is_nil(ping_err)
                test.eq(ping.status_code, 200, "first ping after initialize")

                local deleted, delete_err = http_client.delete(endpoint, { headers = headers(first_id) })
                test.is_nil(delete_err)
                test.eq(deleted.status_code, 204,
                    "DELETE response body: " .. json.encode(deleted.body or {}))

                local expired, expired_err = http_client.get(endpoint, {
                    headers = headers(first_id),
                })
                test.is_nil(expired_err)
                test.eq(expired.status_code, 404)
                local expired_post, expired_post_err = http_client.post(endpoint, {
                    headers = headers(first_id),
                    body = json.encode({ jsonrpc = "2.0", id = 5, method = "ping" }),
                })
                test.is_nil(expired_post_err)
                test.eq(expired_post.status_code, 404)

                local second_ping, second_ping_err = http_client.post(endpoint, {
                    headers = headers(second_id),
                    body = json.encode({ jsonrpc = "2.0", id = 4, method = "ping" }),
                })
                test.is_nil(second_ping_err)
                test.eq(second_ping.status_code, 200, "second session ping")
                local second_deleted, second_delete_err = http_client.delete(endpoint, {
                    headers = headers(second_id),
                })
                test.is_nil(second_delete_err)
                test.eq(second_deleted.status_code, 204)
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
                    scopes = { "mcp.introspect", "state.read" },
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

            local function tool_names(session)
                local list, _, err = mcp_surface.build(session)
                test.is_nil(err)
                local names = {}
                for _, t in ipairs(list or {}) do names[t.name] = true end
                return names
            end

            it("list_tools is always visible and call_tool declares native root security", function()
                test.is_true(mcp_surface.ALWAYS_VISIBLE.list_tools == true)
                test.is_true(mcp_surface.ALWAYS_VISIBLE.call_tool == true)
                local req = mcp_surface.META_REQUIRED_SECURITY.call_tool
                test.not_nil(req)
                test.eq(req.action, "keeper.mcp.call_tool")
            end)

            it("native MCP security hides call_tool from non-root sessions", function()
                local scoped = new_session({
                    access_mode = "any",
                    scopes = { "state.read", "mcp.introspect" },
                })
                local root = new_session({
                    access_mode = "any",
                    scopes = { "mcp.root" },
                })

                test.is_nil(tool_names(scoped).call_tool,
                    "scoped sessions must not see arbitrary registry-tool dispatch")
                test.is_true(tool_names(root).call_tool == true,
                    "root sessions should see call_tool")
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
                    scopes = { "mcp.introspect", "state.read" },
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

            it("call_tool is denied for non-root sessions by native security", function()
                local session = new_session({
                    access_mode = "any",
                    scopes = { "state.read", "mcp.introspect" },
                })
                local result, err = mcp_meta.call_tool({ id = "keeper.state.tools:get_entries" }, session)
                test.is_nil(result)
                test.not_nil(err)
                test.is_true(err:find("keeper.mcp.call_tool") ~= nil)
            end)

            it("call_tool rejects arguments that violate declared schema", function()
                local session = new_session({ access_mode = "any", scopes = { "mcp.root" } })
                local result, err = mcp_meta.call_tool({
                    id = "keeper.state.tools:explore",
                    arguments = {},
                }, session)
                test.is_nil(result)
                test.not_nil(err,
                    "missing required 'operation' must be caught by validate")
            end)

            it("call_tool rejects non-object arguments", function()
                local session = new_session({ access_mode = "any", scopes = { "mcp.root" } })
                local result, err = mcp_meta.call_tool({
                    id = "keeper.state.tools:explore",
                    arguments = "not a table",
                }, session)
                test.is_nil(result)
                test.not_nil(err)
            end)

            it("call_tool dispatches a real read tool end-to-end", function()
                local session = new_session({ access_mode = "any", scopes = { "mcp.root" } })
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
