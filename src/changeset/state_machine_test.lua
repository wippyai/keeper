local test = require("test")
local sm = require("state_machine")
local consts = require("consts")

local S = consts.STATES
local E = sm.EVENTS

local function define_tests()
    test.describe("changeset.state_machine", function()
        test.describe("next_state", function()
            test.it("open -> first_edit -> editing", function()
                local s, err = sm.next_state(S.OPEN, E.FIRST_EDIT)
                test.eq(err, nil)
                test.eq(s, S.EDITING)
            end)

            test.it("open -> drop -> dropped", function()
                local s = sm.next_state(S.OPEN, E.DROP)
                test.eq(s, S.DROPPED)
            end)

            test.it("editing -> submit_for_review -> review", function()
                local s = sm.next_state(S.EDITING, E.SUBMIT_FOR_REVIEW)
                test.eq(s, S.REVIEW)
            end)

            test.it("review -> accept -> accepted", function()
                local s = sm.next_state(S.REVIEW, E.ACCEPT)
                test.eq(s, S.ACCEPTED)
            end)

            test.it("review -> reject -> rejected", function()
                local s = sm.next_state(S.REVIEW, E.REJECT)
                test.eq(s, S.REJECTED)
            end)

            test.it("accepted -> push_start stays accepted", function()
                local s = sm.next_state(S.ACCEPTED, E.PUSH_START)
                test.eq(s, S.ACCEPTED)
            end)

            test.it("accepted -> push_success -> merged (fs-only path regression)", function()
                local s, err = sm.next_state(S.ACCEPTED, E.PUSH_SUCCESS)
                test.eq(err, nil)
                test.eq(s, S.MERGED,
                    "fs-only push must drive changeset to merged; if this fails the serial-queue guard will block every subsequent task")
            end)

            test.it("accepted -> push_failure -> rejected", function()
                local s = sm.next_state(S.ACCEPTED, E.PUSH_FAILURE)
                test.eq(s, S.REJECTED)
            end)

            test.it("rejected -> reopen -> editing", function()
                local s = sm.next_state(S.REJECTED, E.REOPEN)
                test.eq(s, S.EDITING)
            end)

            test.it("merged is terminal — push_success from merged rejected", function()
                local s, err = sm.next_state(S.MERGED, E.PUSH_SUCCESS)
                test.eq(s, nil)
                test.is_true(err ~= nil)
            end)

            test.it("dropped is terminal", function()
                local s, err = sm.next_state(S.DROPPED, E.REOPEN)
                test.eq(s, nil)
                test.is_true(err ~= nil)
            end)

            test.it("editing -> push_success is invalid (must go through review+accept first)", function()
                local s, err = sm.next_state(S.EDITING, E.PUSH_SUCCESS)
                test.eq(s, nil)
                test.is_true(err ~= nil,
                    "only ACCEPTED state can emit push_success; otherwise push bypasses review gate")
            end)

            test.it("missing current_state returns error", function()
                local s, err = sm.next_state(nil, E.FIRST_EDIT)
                test.eq(s, nil)
                test.is_true(err ~= nil)
            end)

            test.it("missing event returns error", function()
                local s, err = sm.next_state(S.EDITING, nil)
                test.eq(s, nil)
                test.is_true(err ~= nil)
            end)
        end)

        test.describe("full fs-only push sequence (open -> merged)", function()
            test.it("drives through every step without skipping", function()
                -- This is the state sequence push.lua's fs-only branch now invokes
                -- after the bug fix: drive_to_accepted issues FIRST_EDIT + SUBMIT_FOR_REVIEW +
                -- ACCEPT, then push_start, then push_success.
                local s
                s = assert(sm.next_state(S.OPEN, E.FIRST_EDIT))
                test.eq(s, S.EDITING)
                s = assert(sm.next_state(s, E.SUBMIT_FOR_REVIEW))
                test.eq(s, S.REVIEW)
                s = assert(sm.next_state(s, E.ACCEPT))
                test.eq(s, S.ACCEPTED)
                s = assert(sm.next_state(s, E.PUSH_START))
                test.eq(s, S.ACCEPTED)
                s = assert(sm.next_state(s, E.PUSH_SUCCESS))
                test.eq(s, S.MERGED,
                    "fs-only push sequence must terminate in MERGED")
            end)

            test.it("fs flush failure path terminates in rejected", function()
                local s = S.ACCEPTED
                s = assert(sm.next_state(s, E.PUSH_START))
                s = assert(sm.next_state(s, E.PUSH_FAILURE))
                test.eq(s, S.REJECTED)
            end)
        end)

        test.describe("is_terminal", function()
            test.it("merged and dropped are terminal", function()
                test.is_true(sm.is_terminal(S.MERGED))
                test.is_true(sm.is_terminal(S.DROPPED))
            end)

            test.it("live states are not terminal", function()
                test.is_false(sm.is_terminal(S.OPEN))
                test.is_false(sm.is_terminal(S.EDITING))
                test.is_false(sm.is_terminal(S.REVIEW))
                test.is_false(sm.is_terminal(S.ACCEPTED))
                test.is_false(sm.is_terminal(S.REJECTED))
            end)
        end)

        test.describe("guards", function()
            test.it("submit_for_review rejects empty pending_changes", function()
                local ok, reason = sm.guards.submit_for_review({ pending_changes = {} })
                test.is_false(ok)
                test.is_true(reason:find("no pending changes") ~= nil)
            end)

            test.it("submit_for_review rejects when conflicts present", function()
                local ok, reason = sm.guards.submit_for_review({
                    pending_changes = { { id = "a" } },
                    conflicts = { { change_id = "x" } },
                })
                test.is_false(ok)
                test.is_true(reason:find("conflicts") ~= nil)
            end)

            test.it("submit_for_review passes with clean pending_changes", function()
                local ok = sm.guards.submit_for_review({
                    pending_changes = { { id = "a" } },
                    conflicts = {},
                })
                test.is_true(ok)
            end)

            test.it("accept rejects when linter unclean", function()
                local ok, reason = sm.guards.accept({
                    linter_result = { success = false },
                })
                test.is_false(ok)
                test.is_true(reason:find("linter") ~= nil)
            end)

            test.it("accept passes when linter clean", function()
                local ok = sm.guards.accept({
                    linter_result = { success = true },
                })
                test.is_true(ok)
            end)

            test.it("push_start rejects if workspace not accepted", function()
                local ok, reason = sm.guards.push_start({
                    workspace = { state = S.EDITING },
                })
                test.is_false(ok)
                test.is_true(reason:find("accepted") ~= nil)
            end)

            test.it("push_start passes when workspace accepted", function()
                local ok = sm.guards.push_start({
                    workspace = { state = S.ACCEPTED },
                })
                test.is_true(ok)
            end)
        end)
    end)
end

return { define_tests = define_tests }
