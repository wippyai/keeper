local security = require("security")

local TOKEN_STORE_ID = "userspace.user.security:tokens"
local TOKEN_EXPIRATION = "5m"

local M = {}

function M.mint_token(source)
    local actor = security.actor()
    local scope = security.scope()
    if not actor or not scope then return nil, "no security context" end

    local store, err = security.token_store(TOKEN_STORE_ID)
    if err then return nil, "token store: " .. tostring(err) end

    local token, terr = store:create(actor, scope, {
        expiration = TOKEN_EXPIRATION,
        meta = { source = source or "keeper.components.tools" },
    })
    store:close()
    if terr then return nil, "token create: " .. tostring(terr) end
    return token
end

return M
