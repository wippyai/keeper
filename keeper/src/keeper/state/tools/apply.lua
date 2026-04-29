local funcs = require("funcs")
local audit = require("audit")
local cs_client = require("cs_client")
local engine = require("engine")
local branch_ctx = require("branch_ctx")

local PUSH_FN = "keeper.state.tools:push"
local MAX_PATCHES = 200
local CS_TIMEOUT = "10s"

local function err(code, message, fix_hint)
    return { code = code, message = message, fix_hint = fix_hint }
end

local function open_or_use_changeset(args)
    local explicit_branch = args.branch
    if explicit_branch and explicit_branch ~= "" then
        local cs, cerr = cs_client.open_or_resume({
            state_branch = explicit_branch,
            title        = args.title or "system apply",
            kind         = args.kind or "system",
            description  = args.description,
            actor_id     = args.actor_id,
            session_id   = args.session_id,
        }, CS_TIMEOUT)
        if not cs then
            return nil, nil, err("OPEN_FAILED", "open_or_resume failed: " .. tostring(cerr))
        end
        return cs.changeset_id, cs.state_branch, nil
    end

    local branch = branch_ctx.get_active_branch()
    if not branch or branch == "main" then
        return nil, nil, err("NO_BRANCH",
            "no active branch and no explicit args.branch provided",
            "set_branch first, or pass args.branch for ephemeral changeset")
    end
    local cs_id, cs_err = branch_ctx.resolve_changeset_id(branch)
    if not cs_id then
        return nil, nil, err("NO_CHANGESET",
            "no active changeset for branch '" .. branch .. "' (" .. tostring(cs_err) .. ")",
            "call set_branch to open a workspace before apply")
    end
    return cs_id, branch, nil
end

local function publish(branch, message)
    local executor, fn_err = funcs.new()
    if fn_err then
        return nil, err("PUSH_FAILED", "funcs.new failed: " .. tostring(fn_err))
    end
    local result, call_err = executor:call(PUSH_FN, {
        branch  = branch,
        message = message,
    })
    if call_err or not result or result.ok == false then
        return nil, err("PUSH_FAILED", tostring(call_err or (result and result.error) or "push failed"))
    end
    return result, nil
end

local function do_apply(args)
    if type(args) ~= "table" then
        return { ok = false, stage = "validate",
            errors = { err("INVALID_ARGS", "args must be a table") } }, nil
    end

    local patches = args.patches
    if type(patches) ~= "table" or #patches == 0 then
        return { ok = false, stage = "validate",
            errors = { err("NO_PATCHES", "patches[] is required and non-empty") } }, nil
    end
    if #patches > MAX_PATCHES then
        return { ok = false, stage = "validate",
            errors = { err("TOO_MANY_PATCHES",
                "patches[] exceeds " .. MAX_PATCHES .. " (got " .. #patches .. ")") } }, nil
    end

    local changeset_id, state_branch, open_err = open_or_use_changeset(args)
    if open_err then
        return { ok = false, stage = "open", errors = { open_err } }, nil
    end

    local applied = {}
    for i, patch in ipairs(patches) do
        local result, perr = engine.apply_one(patch, {
            branch = state_branch,
            changeset_id = changeset_id,
        })
        if not result then
            return {
                ok            = false,
                stage         = "apply",
                changeset_id  = changeset_id,
                state_branch  = state_branch,
                applied       = applied,
                errors        = { err(perr.code or "APPLY_FAILED",
                    "patches[" .. i .. "]: " .. tostring(perr.message),
                    perr.fix_hint) },
            }, nil
        end
        table.insert(applied, result)
    end

    local response = {
        ok           = true,
        stage        = "apply",
        changeset_id = changeset_id,
        state_branch = state_branch,
        applied      = applied,
        errors       = {},
    }

    if args.publish == true then
        local push_result, push_err = publish(state_branch, args.message)
        if push_err then
            response.ok     = false
            response.stage  = "push"
            response.errors = { push_err }
            return response, nil
        end
        response.stage = "push"
        response.push  = push_result
    end

    return response, nil
end

local function summarise(args, result, e)
    if e then return "apply failed: " .. tostring(e) end
    local n = (result and result.applied and #result.applied) or 0
    local stage = (result and result.stage) or "?"
    local published = result and result.push and " + push" or ""
    return "apply " .. n .. " patch(es) @" .. stage .. published
end

local function handler(args)
    args = args or {}
    return audit.wrap({
        tool          = "apply",
        discriminator = "apply." .. ((args.publish == true) and "publish" or "stage"),
        target        = args.message or args.title or "patches",
        params        = {
            patch_count = (args.patches and #args.patches) or 0,
            branch      = args.branch,
            publish     = args.publish == true,
            source      = args.source,
        },
        summarise = function(result, e) return summarise(args, result, e) end,
    }, function()
        return do_apply(args), nil
    end)
end

return { handler = handler }
