local ctx = require("ctx")
local branch_ctx = require("branch_ctx")
local audit = require("audit")

local OPEN_OR_RESUME_FN = "keeper.changeset.service:open_or_resume"

local M = {}

function M.get(current_branch, changeset_id)
    if not current_branch or current_branch == "" then
        return {
            branch  = "main",
            message = "No branch set, using main",
        }
    end
    return {
        branch       = current_branch,
        changeset_id = changeset_id,
        message      = "Current branch: " .. current_branch,
    }
end

function M.clear()
    return {
        branch   = "main",
        message  = "Branch cleared, using main",
        _control = {
            context = {
                session = {
                    delete = { "overlay_branch", "changeset_id" },
                },
                public_meta = {
                    clear = "branch",
                },
            },
        },
    }
end

function M.set(params)
    if not params.branch or params.branch == "" then
        return nil, "Branch name required for set action"
    end

    if params.branch == "main" then
        return nil, "Cannot set branch to 'main' (use clear to return to main)"
    end

    -- Inside a task, the branch is a task-level fact supplied by the task
    -- lifecycle. Agents must not change it — they work the workspace the
    -- task opened. Exit the phase if the workspace is wrong (spec_wrong /
    -- ask_user); do not paper over it by opening another changeset.
    local task_id = ctx.get("task_id")
    if task_id and task_id ~= "" then
        return nil, "branch is task-managed; agents cannot set it. " ..
            "The active workspace is provided by the task. " ..
            "If your workspace is gone, exit the phase with an appropriate signal."
    end

    local workspace, err = branch_ctx.call_service_fn(OPEN_OR_RESUME_FN, { branch = params.branch })
    if err then
        return nil, "Failed to open changeset for branch '" .. params.branch .. "': " .. err
    end

    local verb    = workspace.resumed and "Resumed" or "Opened"
    local message = verb .. " changeset " .. workspace.changeset_id ..
        " on branch " .. params.branch

    return {
        branch       = params.branch,
        changeset_id = workspace.changeset_id,
        resumed      = workspace.resumed,
        message      = message,
        _control     = {
            context = {
                session = {
                    set = {
                        overlay_branch = params.branch,
                        changeset_id   = workspace.changeset_id,
                    },
                },
                public_meta = {
                    set = {
                        {
                            id           = "branch_info",
                            title        = params.branch,
                            display_name = "Branch: " .. params.branch,
                            type         = "branch",
                            icon         = "tabler:git-branch",
                            url          = nil,
                            branch       = params.branch,
                            changeset_id = workspace.changeset_id,
                        },
                    },
                },
            },
        },
    }
end

local function do_handler(params)
    local action = params.action or "set"
    if action == "get" then
        return M.get(ctx.get("overlay_branch"), ctx.get("changeset_id"))
    elseif action == "clear" then
        return M.clear()
    elseif action == "set" then
        return M.set(params)
    end
    return nil, "Invalid action: " .. action .. " (must be set, get, or clear)"
end

function M.handler(params)
    params = params or {}
    local action = params.action or "set"
    return audit.wrap({
        tool          = "branch",
        discriminator = "branch." .. action,
        target        = params.branch,
        params        = { action = action, branch = params.branch },
        summarise = function(result, err)
            if err then return "branch " .. action .. " failed: " .. tostring(err) end
            if type(result) == "table" and result.message then return result.message end
            return "branch " .. action
        end,
    }, function()
        return do_handler(params)
    end)
end

return M
