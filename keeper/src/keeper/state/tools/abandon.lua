local audit = require("audit")
local cs_client = require("cs_client")
local branch_ctx = require("branch_ctx")

local function do_handler(params)
    local branch = branch_ctx.get_active_branch()
    if not branch or branch == "main" then
        return nil, "no active branch (set_branch first)"
    end

    local changeset_id, cs_err = branch_ctx.resolve_changeset_id(branch)
    if not changeset_id then
        return nil, "no active changeset for branch '" .. branch ..
            "' (" .. tostring(cs_err) .. ")"
    end

    local _, derr = cs_client.drop({
        changeset_id = changeset_id,
        reason       = params.reason or "tool: user-initiated abandon",
    })
    if derr then
        return nil, "abandon failed: " .. tostring(derr)
    end

    return {
        ok           = true,
        branch       = branch,
        changeset_id = changeset_id,
        message      = "changeset " .. changeset_id .. " abandoned",
    }, nil
end

local function handler(params)
    params = params or {}
    return audit.wrap({
        tool          = "abandon",
        discriminator = "abandon",
        target        = params.reason,
        params        = { reason = params.reason },
        summarise = function(result, err)
            if err then return "abandon failed: " .. tostring(err) end
            return (result and result.message) or "abandoned"
        end,
    }, function()
        return do_handler(params)
    end)
end

return { handler = handler }
