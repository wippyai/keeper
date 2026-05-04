local pr_flow = require("pr_flow")
local consts = require("git_consts")

local M = {}

function M.handle(payload, deps)
    local args = payload.args or {}
    local result, err = pr_flow.handle(args)
    if result and result.pr_url then
        deps.relay(consts.EVENTS.PR_CREATED, {
            url = result.pr_url,
            head = result.head_branch,
            base = result.base_branch,
        })
    end
    deps.reply(payload, result, err)
end

return M
