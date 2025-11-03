-- test_endpoint.lua
local security = require("security")
local http_client = require("http_client")
local json = require("json")
local env = require("env")
local consts = require("consts")

local CONFIG = {
    ENV_VAR_BASE_URL = "APP_BASE_URL",
    DEFAULT_TOKEN_EXPIRATION = "5m",
    DEFAULT_TIMEOUT = 30,
    TOKEN_META_SOURCE = "endpoint_test"
}

local function handler(input)
    if not input.method or not input.path then
        return {
            success = false,
            error = "method and path required"
        }
    end
    
    local actor = security.actor()
    local scope = security.scope()
    
    if not actor or not scope then
        return {
            success = false,
            error = "No security context available"
        }
    end
    
    local config = consts.get_config()
    local token_store, err = security.token_store(config.token_store)
    if err then
        return {
            success = false,
            error = "Token store failed: " .. err
        }
    end
    
    local actor_meta = actor:meta() or {}
    local token_meta = {source = CONFIG.TOKEN_META_SOURCE}
    
    for key, value in pairs(actor_meta) do
        token_meta[key] = value
    end
    
    local token, err = token_store:create(actor, scope, {
        expiration = CONFIG.DEFAULT_TOKEN_EXPIRATION,
        meta = token_meta
    })
    token_store:close()
    
    if err then
        return {
            success = false,
            error = "Token creation failed: " .. err
        }
    end
    
    local base_url, _ = env.get(CONFIG.ENV_VAR_BASE_URL)
    if not base_url or base_url == "" then
        return {
            success = false,
            error = CONFIG.ENV_VAR_BASE_URL .. " not configured"
        }
    end
    
    local url = base_url .. input.path
    
    local headers = input.headers or {}
    headers["Authorization"] = "Bearer " .. token
    headers["Content-Type"] = "application/json"
    
    local opts = {
        headers = headers,
        timeout = input.timeout or CONFIG.DEFAULT_TIMEOUT
    }
    
    if input.body then
        opts.body = json.encode(input.body)
    end
    
    local response, err = http_client.request(input.method, url, opts)
    
    if err then
        return {
            success = false,
            error = err
        }
    end
    
    return {
        success = true,
        status = response.status_code,
        body = response.body,
        headers = response.headers
    }
end

return {handler = handler}