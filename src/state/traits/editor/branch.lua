local json = require("json")
local ctx = require("ctx")

local function handler(params)
    local action = params.action or "set"

    if action == "get" then
        local current_branch, err = ctx.get("overlay_branch")
        if err or not current_branch or current_branch == "" then
            return {
                branch = "main",
                message = "No branch set, using main"
            }
        end

        return {
            branch = current_branch,
            message = "Current branch: " .. current_branch
        }

    elseif action == "clear" then
        local control = {
            context = {
                session = {
                    delete = {"overlay_branch"}
                },
                public_meta = {
                    clear = "branch"
                }
            }
        }

        return {
            branch = "main",
            message = "Branch cleared, using main",
            _control = control
        }

    elseif action == "set" then
        if not params.branch or params.branch == "" then
            return nil, "Branch name required for set action"
        end

        if params.branch == "main" then
            return nil, "Cannot set branch to 'main' (use clear to return to main)"
        end

        local control = {
            context = {
                session = {
                    set = {
                        overlay_branch = params.branch
                    }
                },
                public_meta = {
                    set = {
                        {
                            id = "branch_info",
                            title = params.branch,
                            display_name = "Branch: " .. params.branch,
                            type = "branch",
                            icon = "tabler:git-branch",
                            url = nil,
                            branch = params.branch
                        }
                    }
                }
            }
        }

        return {
            branch = params.branch,
            message = "Branch set to: " .. params.branch,
            _control = control
        }
    else
        return nil, "Invalid action: " .. action .. " (must be set, get, or clear)"
    end
end

return { handler = handler }