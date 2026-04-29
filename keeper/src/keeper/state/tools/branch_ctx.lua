local ctx = require("ctx")
local funcs = require("funcs")

local LOOKUP_BY_BRANCH_FN = "keeper.changeset.service:lookup_by_branch"

local M = {}

M.LOOKUP_BY_BRANCH_FN = LOOKUP_BY_BRANCH_FN

-- call_service_fn invokes a service function via funcs.new + pcall, normalizing
-- three failure modes into a single (result, err) contract: executor creation
-- failure, thrown panic, and explicit {ok=false, error=...} responses.
function M.call_service_fn(fn_id, args)
    local executor, exec_err = funcs.new()
    if exec_err then
        return nil, "funcs.new failed: " .. tostring(exec_err)
    end
    local ok, result = pcall(executor.call, executor, fn_id, args or {})
    if not ok then
        return nil, fn_id .. " call failed: " .. tostring(result)
    end
    if result and result.ok == false then
        return nil, tostring(result.error or (fn_id .. " returned error"))
    end
    return result, nil
end

function M.get_active_branch()
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return overlay_branch
    end
    return "main"
end

function M.require_active_branch(param_branch)
    if param_branch and param_branch ~= "" then
        return param_branch, nil
    end
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return overlay_branch, nil
    end
    return nil, "No branch specified and no active branch in context"
end

function M.get_active_branch_chain(override)
    if override then
        if override == "main" then
            return { "main" }
        end
        return { override, "main" }
    end
    local overlay_branch, err = ctx.get("overlay_branch")
    if not err and overlay_branch and overlay_branch ~= "" then
        return { overlay_branch, "main" }
    end
    return { "main" }
end

function M.resolve_changeset_id(branch)
    local ctx_cs_id     = ctx.get("changeset_id")
    local ctx_branch, _ = ctx.get("overlay_branch")

    if (not branch or branch == "") and ctx_branch and ctx_branch ~= "" then
        branch = ctx_branch
    end
    if not branch or branch == "" or branch == "main" then
        return nil, "branch not set"
    end

    local result, err = M.call_service_fn(LOOKUP_BY_BRANCH_FN, { branch = branch })
    if err then return nil, err end
    if not result.found then
        if ctx_cs_id and ctx_cs_id ~= "" and (not ctx_branch or branch == ctx_branch) then
            return nil, "changeset for branch '" .. branch ..
                "' is no longer live (merged or dropped); call set_branch with a new branch to open a fresh changeset"
        end
        return nil, "no live changeset for branch '" .. branch .. "'"
    end

    if ctx_cs_id and ctx_cs_id ~= "" and ctx_branch == branch and ctx_cs_id ~= result.changeset_id then
        return result.changeset_id, nil
    end
    return result.changeset_id, nil
end

return M
