local test = require("test")
local dispatch = require("mcp_dispatch")
local tokens = require("mcp_tokens")
local auth = require("mcp_auth")
local uuid = require("uuid")
local sql = require("sql")
local consts = require("mcp_consts")
local hash = require("hash")

local function define_tests()
    describe("MCP session context", function()
        local credentials = {}
        local function session(token, id)
            token = token or uuid.v4()
            credentials[token] = true
            return { token = token, mcp_session_id = id or string.rep("a", 64) }
        end
        local function select_branch(s, branch, changeset)
            dispatch.apply_control(s, { _control = { context = { session = {
                set = { overlay_branch = branch, changeset_id = changeset },
            } } } })
        end
        local function binding(s, branch, changeset)
            local ctx, err = dispatch.build_context(s, { overlay_branch = "untrusted", changeset_id = "untrusted", marker = "kept" })
            test.is_nil(err)
            test.eq(ctx.overlay_branch, branch)
            test.eq(ctx.changeset_id, changeset)
            test.eq(ctx.marker, "kept")
        end
        after_all(function()
            local db, err = sql.get(consts.db_id())
            test.is_nil(err)
            for token in pairs(credentials) do
                local digest, digest_err = hash.sha256(token)
                test.is_nil(digest_err)
                local _, delete_err = sql.builder.delete("keeper_mcp_session_state")
                    :where("token = ?", digest):run_with(db):exec()
                test.is_nil(delete_err)
            end
            db:release()
        end)
        it("isolates interleaved sessions sharing a bearer credential", function()
            local a = session()
            local b = session(a.token, string.rep("b", 64))
            select_branch(a, "feature-a", "changeset-a")
            select_branch(b, "feature-b", "changeset-b")
            binding(a, "feature-a", "changeset-a")
            binding(b, "feature-b", "changeset-b")
            select_branch(a, "feature-c", "changeset-c")
            binding(b, "feature-b", "changeset-b")
        end)
        it("clears one session without clearing another sharing its credential", function()
            local a = session()
            local b = session(a.token, string.rep("b", 64))
            select_branch(a, "feature-a", "changeset-a")
            select_branch(b, "feature-b", "changeset-b")
            dispatch.apply_control(a, { _control = { context = { session = {
                delete = { "overlay_branch", "changeset_id" },
            } } } })
            binding(a, nil, nil)
            binding(b, "feature-b", "changeset-b")
        end)
        it("isolates distinct credentials even with the same session id", function()
            local a, b = session(), session()
            select_branch(a, "feature-a", "changeset-a")
            select_branch(b, "feature-b", "changeset-b")
            binding(a, "feature-a", "changeset-a")
            binding(b, "feature-b", "changeset-b")
        end)
        it("does not inherit a credential's legacy branch binding", function()
            local s = session()
            test.is_true(tokens.set_overlay_branch(s.token, "legacy"))
            test.is_true(tokens.set_changeset_id(s.token, "legacy-changeset"))
            binding(s, nil, nil)
            select_branch(s, "current", "current-changeset")
            test.eq(tokens.get_overlay_branch(s.token), "legacy")
            test.eq(tokens.get_changeset_id(s.token), "legacy-changeset")
        end)
        it("preserves credential-level traits when sessions select branches", function()
            local s = session()
            local updated, err = tokens.set_active_traits(s.token, { "trait-a" })
            test.is_nil(err)
            test.is_true(updated)
            select_branch(s, "feature", "changeset")
            test.eq(tokens.get_active_traits(s.token)[1], "trait-a")
            updated, err = tokens.set_active_traits(s.token, { "trait-b" })
            test.is_nil(err)
            test.is_true(updated)
            binding(s, "feature", "changeset")
        end)
        it("rejects missing transport identity before invoking a tool", function()
            local saved = auth.admin_call
            local called = false
            auth.admin_call = function() called = true; return {} end
            local ok, err = pcall(function()
                local result, call_err = dispatch.call({ token = uuid.v4() }, "tool", {})
                test.is_nil(result)
                test.not_nil(call_err)
                test.is_false(called)
            end)
            auth.admin_call = saved
            if not ok then error(err) end
        end)
        it("does not invoke tools when reading the authoritative binding fails", function()
            local saved_read, saved_call = tokens.get_session_context, auth.admin_call
            local called = false
            tokens.get_session_context = function() return nil, "binding read failed" end
            auth.admin_call = function() called = true; return {} end
            local ok, err = pcall(function()
                local result, call_err = dispatch.call(session(), "tool", {})
                test.is_nil(result)
                test.eq(call_err, "binding read failed")
                test.is_false(called)
            end)
            tokens.get_session_context, auth.admin_call = saved_read, saved_call
            if not ok then error(err) end
        end)
        it("reports a binding write failure to the caller", function()
            local saved_update, saved_call = tokens.update_session_context, auth.admin_call
            tokens.update_session_context = function() return false, "binding write failed" end
            auth.admin_call = function()
                return { _control = { context = { session = { set = { overlay_branch = "feature" } } } } }
            end
            local ok, err = pcall(function()
                local result, call_err = dispatch.call(session(), "tool", {})
                test.is_nil(result)
                test.eq(call_err, "binding write failed")
            end)
            tokens.update_session_context, auth.admin_call = saved_update, saved_call
            if not ok then error(err) end
        end)
        it("updates partial controls without losing the other binding field", function()
            local s = session()
            select_branch(s, "feature", "changeset")
            local updated, err = dispatch.apply_control(s, { _control = { context = { session = {
                set = { changeset_id = "next-changeset" },
            } } } })
            test.is_nil(err)
            test.is_true(updated)
            binding(s, "feature", "next-changeset")
            updated, err = dispatch.apply_control(s, { _control = { context = { session = {
                set = { overlay_branch = "ignored" }, delete = { "overlay_branch" },
            } } } })
            test.is_nil(err)
            test.is_true(updated)
            binding(s, nil, "next-changeset")
        end)
        it("passes each session binding to tool calls and persists their controls", function()
            local a = session()
            local b = session(a.token, string.rep("b", 64))
            select_branch(a, "feature-a", "changeset-a")
            select_branch(b, "feature-b", "changeset-b")
            local saved = auth.admin_call
            local seen = {}
            auth.admin_call = function(s, via, id, args, ctx)
                seen[s.mcp_session_id] = ctx
                return { _control = { context = { session = { set = {
                    overlay_branch = args.branch, changeset_id = args.changeset,
                } } } } }
            end
            local ok, err = pcall(function()
                local _, a_err = dispatch.call(a, "tool", { branch = "updated-a", changeset = "updated-changeset-a" })
                local _, b_err = dispatch.call(b, "tool", { branch = "updated-b", changeset = "updated-changeset-b" })
                test.is_nil(a_err)
                test.is_nil(b_err)
                test.eq(seen[a.mcp_session_id].overlay_branch, "feature-a")
                test.eq(seen[a.mcp_session_id].changeset_id, "changeset-a")
                test.eq(seen[b.mcp_session_id].overlay_branch, "feature-b")
                test.eq(seen[b.mcp_session_id].changeset_id, "changeset-b")
                binding(a, "updated-a", "updated-changeset-a")
                binding(b, "updated-b", "updated-changeset-b")
            end)
            auth.admin_call = saved
            if not ok then error(err) end
        end)
    end)
end
return { run = test.run_cases(define_tests) }
