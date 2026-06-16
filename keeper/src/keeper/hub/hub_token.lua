local contract = require("contract")

local M = {}

local TOKEN_PROVIDER = "keeper.hub:token_provider"

-- resolve returns (token, connected). It asks the optional token_provider seam
-- for the current actor's Hub registry token. When no implementation is bound,
-- or the actor has not connected a Hub identity, it returns (nil, false) so the
-- caller serves public, anonymous Hub access.
function M.resolve()
    local def, def_err = contract.get(TOKEN_PROVIDER)
    if def_err or not def then
        return nil, false
    end

    local inst, open_err = def:open()
    if open_err or not inst then
        return nil, false
    end

    local ok, result = pcall(function() return inst:get_token() end)
    if not ok or type(result) ~= "table" or not result.success then
        return nil, false
    end

    local token = result.token
    if type(token) ~= "string" or token == "" then
        return nil, false
    end

    return token, true
end

return M
