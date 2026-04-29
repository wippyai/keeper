local test = require("test")
local fs = require("fs")
local sql = require("sql")
local uuid = require("uuid")
local consts = require("consts")
local fs_flush = require("fs_flush")
local fs_view = require("fs_view")
local repo = require("repo")

local FE_PREFIX = "frontend/"
local TEST_ROOT = "__test_fs_flush/"

local function define_tests()
    describe("changeset fs_flush", function()
        local created_changeset_ids = {}
        local cleanup_paths = {}

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

        local function fe_volume()
            local vol, err = fs.get(consts.FS.FE_VOLUME)
            test.is_nil(err)
            test.not_nil(vol)
            pcall(vol.mkdir, vol, TEST_ROOT:sub(1, -2))
            return vol
        end

        local function new_changeset(title)
            local id = "test-fs-flush-" .. uuid.v7()
            local ws, err = repo.create_changeset({
                changeset_id     = id,
                title            = title or "fs_flush test",
                kind             = consts.KINDS.MANUAL,
                actor_id         = "test.fs-flush.actor",
                state_branch     = consts.branch_for(id),
                scratch_fs_path  = id .. "/",
                baseline_version = 0,
                baseline_fs_hash = "",
            })
            test.is_nil(err)
            test.not_nil(ws)
            table.insert(created_changeset_ids, workspace_id(ws))
            return ws
        end

        local function unique_rel(label)
            local inside = TEST_ROOT .. label .. "-" .. uuid.v7() .. ".txt"
            table.insert(cleanup_paths, inside)
            return FE_PREFIX .. inside, inside
        end

        local function read_file(vol, inside)
            local content, err = vol:readfile(inside)
            test.is_nil(err)
            return content
        end

        after_all(function()
            local vol = fs.get(consts.FS.FE_VOLUME)
            if vol then
                for _, inside in ipairs(cleanup_paths) do
                    pcall(vol.remove, vol, inside)
                end
            end
            local db = sql.get(consts.DATABASE.RESOURCE_ID)
            if db then
                for _, id in ipairs(created_changeset_ids) do
                    db:execute("DELETE FROM keeper_changesets WHERE changeset_id = ?", { id })
                end
                db:release()
            end
        end)

        it("reverts a flushed new file and makes the staged overlay visible again", function()
            local ws = new_changeset("fs flush new")
            local rel, inside = unique_rel("new")
            local vol = fe_volume()

            local view = must_view(workspace_id(ws))
            local _, werr = view:write(rel, "new-content")
            test.is_nil(werr)

            local written, deleted, ferr = fs_flush.flush(ws.changeset_id)
            test.is_nil(ferr)
            test.eq(written, 1)
            test.eq(deleted, 0)
            test.is_true(vol:exists(inside))
            test.eq(read_file(vol, inside), "new-content")

            local hidden = repo.get_fs_content(ws.changeset_id, rel)
            test.is_nil(hidden, "flushed rows are hidden from overlay before rollback")

            local reverted, rerr = fs_flush.revert_flushed(ws.changeset_id)
            test.is_nil(rerr)
            test.eq(reverted.restaged, 1)
            test.is_false(vol:exists(inside), "new file removed from main fs")

            local overlay = repo.get_fs_content(ws.changeset_id, rel)
            test.not_nil(overlay)
            test.eq(overlay.content, "new-content")

            local read_back, read_err = view:read(rel)
            test.is_nil(read_err)
            test.eq(read_back, "new-content")
        end)

        it("reverts a flushed update to prior main bytes while keeping new overlay bytes", function()
            local ws = new_changeset("fs flush update")
            local rel, inside = unique_rel("update")
            local vol = fe_volume()
            vol:writefile(inside, "main-before")

            local view = must_view(workspace_id(ws))
            local _, werr = view:write(rel, "overlay-after")
            test.is_nil(werr)

            local written, _, ferr = fs_flush.flush(ws.changeset_id)
            test.is_nil(ferr)
            test.eq(written, 1)
            test.eq(read_file(vol, inside), "overlay-after")

            local reverted, rerr = fs_flush.revert_flushed(ws.changeset_id)
            test.is_nil(rerr)
            test.eq(reverted.restaged, 1)
            test.eq(read_file(vol, inside), "main-before")

            local read_back, read_err = view:read(rel)
            test.is_nil(read_err)
            test.eq(read_back, "overlay-after")
        end)

        it("reverts a flushed delete to prior main bytes while keeping the delete staged", function()
            local ws = new_changeset("fs flush delete")
            local rel, inside = unique_rel("delete")
            local vol = fe_volume()
            vol:writefile(inside, "main-before-delete")

            local view = must_view(workspace_id(ws))
            local _, derr = view:delete(rel)
            test.is_nil(derr)

            local _, deleted, ferr = fs_flush.flush(ws.changeset_id)
            test.is_nil(ferr)
            test.eq(deleted, 1)
            test.is_false(vol:exists(inside))

            local reverted, rerr = fs_flush.revert_flushed(ws.changeset_id)
            test.is_nil(rerr)
            test.eq(reverted.restaged, 1)
            test.eq(read_file(vol, inside), "main-before-delete")

            local read_back, read_err = view:read(rel)
            test.is_nil(read_back)
            test.eq(read_err, "deleted")
        end)

        it("allows edit and flush of the same path after a rollback restage", function()
            local ws = new_changeset("fs flush retry")
            local rel, inside = unique_rel("retry")
            local vol = fe_volume()

            local view = must_view(workspace_id(ws))
            local _, werr = view:write(rel, "buggy")
            test.is_nil(werr)

            local written, _, ferr = fs_flush.flush(ws.changeset_id)
            test.is_nil(ferr)
            test.eq(written, 1)
            test.eq(read_file(vol, inside), "buggy")

            local _, rerr = fs_flush.revert_flushed(ws.changeset_id)
            test.is_nil(rerr)
            test.is_false(vol:exists(inside))

            local _, fix_err = view:write(rel, "fixed")
            test.is_nil(fix_err)

            local written_again, _, retry_err = fs_flush.flush(ws.changeset_id)
            test.is_nil(retry_err)
            test.eq(written_again, 1)
            test.eq(read_file(vol, inside), "fixed")
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
