local submit = require("submit_lib")
local audit = require("audit")

local function handler(params)
    params = params or {}
    local action = params.action or "stage"
    return audit.wrap({
        tool          = "submit",
        discriminator = "submit." .. action,
        target        = params.message,
        params        = { action = action, message = params.message,
                          patch_count = params.patches and #params.patches or 0,
                          dry_run = params.dry_run },
        summarise = function(result, _err)
            if type(result) == "table" then
                local stage = result.stage or "?"
                local ok = result.ok
                if ok then return "submit " .. action .. " ok @" .. stage end
                return "submit " .. action .. " failed @" .. stage
            end
            return "submit " .. action
        end,
    }, function()
        return submit.run(params), nil
    end)
end

return { handler = handler }
