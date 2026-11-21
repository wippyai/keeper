-- keeper.components.tools:ui
--
-- Action-dispatched UI driving tool for MCP / agents. Thin wrapper over
-- keeper.components.ui:client which talks to the long-lived Playwright supervisor.
-- One persistent browser page survives across calls, so a session typically
-- begins with `open` (for a keeper component) or `goto` (for any URL) and
-- ends with `close` when done.

local fs = require("fs")
local base64 = require("base64")
local security = require("security")
local audit = require("audit")
local ui_default = require("ui")
local keeper_config = require("keeper_config")
local filenames = require("filenames")

local PREVIEWS_FS_ID = "keeper.components:previews_fs"
local PREVIEWS_URL_PREFIX = "/app/public/previews/"

local function mint_caller_token()
    local actor = security.actor()
    local scope = security.scope()
    if not actor or not scope then
        return nil, "No security context available"
    end
    local token_store_id = keeper_config.auth_token_store()
    local store, err = security.token_store(token_store_id)
    if not store then return nil, "Token store failed: " .. tostring(err) end
    local token, terr = store:create(actor, scope, {
        expiration = "5m",
        meta = { source = "keeper.components.tools:ui" },
    })
    store:close()
    if not token then return nil, "Token creation failed: " .. tostring(terr) end
    return token
end

local function wrap(res, label)
    if type(res) ~= "table" then
        return nil, (label or "ui") .. ": unexpected response type"
    end
    if res.success == false then
        return nil, (label or "ui") .. ": " .. tostring(res.error or "unknown")
    end
    return res
end

-- Each action receives the dependencies of this call: ui (the supervisor
-- client) and mint_token (caller auth for navigation).
local ACTIONS = {}

function ACTIONS.open(params, deps)
    if type(params.component_id) ~= "string" or params.component_id == "" then
        return nil, "component_id is required for open"
    end
    local token, terr = deps.mint_token()
    if terr then return nil, terr end
    return wrap(deps.ui.open({
        component_id = params.component_id,
        route = params.route,
        auth_token = token,
    }), "open")
end

function ACTIONS.goto_url(params, deps)
    if type(params.url) ~= "string" or params.url == "" then
        return nil, "url is required for goto"
    end
    local token, terr = deps.mint_token()
    if terr then return nil, terr end
    return wrap(deps.ui.goto_url(params.url, params.wait_until, { auth_token = token }), "goto")
end

function ACTIONS.snapshot(_, deps)
    return wrap(deps.ui.snapshot(), "snapshot")
end

function ACTIONS.click(params, deps)
    if type(params.selector) ~= "string" or params.selector == "" then
        return nil, "selector is required for click"
    end
    return wrap(deps.ui.click(params.selector, { timeout = params.timeout_ms }), "click")
end

function ACTIONS.fill(params, deps)
    if type(params.selector) ~= "string" or params.selector == "" then
        return nil, "selector is required for fill"
    end
    return wrap(deps.ui.fill(params.selector, tostring(params.value or ""), { timeout = params.timeout_ms }), "fill")
end

function ACTIONS.type_text(params, deps)
    if type(params.selector) ~= "string" or params.selector == "" then
        return nil, "selector is required for type"
    end
    return wrap(deps.ui.type_text(params.selector, tostring(params.value or ""), {
        delay = params.delay_ms,
        timeout = params.timeout_ms,
    }), "type")
end

function ACTIONS.press(params, deps)
    if type(params.key) ~= "string" or params.key == "" then
        return nil, "key is required for press"
    end
    return wrap(deps.ui.press(params.key, params.selector), "press")
end

function ACTIONS.hover(params, deps)
    if type(params.selector) ~= "string" or params.selector == "" then
        return nil, "selector is required for hover"
    end
    return wrap(deps.ui.hover(params.selector), "hover")
end

function ACTIONS.select_option(params, deps)
    if type(params.selector) ~= "string" or params.selector == "" then
        return nil, "selector is required for select"
    end
    return wrap(deps.ui.select_option(params.selector, params.value), "select")
end

function ACTIONS.wait_for(params, deps)
    if type(params.selector) ~= "string" or params.selector == "" then
        return nil, "selector is required for wait_for"
    end
    return wrap(deps.ui.wait_for(params.selector, {
        state = params.state,
        timeout = params.timeout_ms,
    }), "wait_for")
end

function ACTIONS.wait(params, deps)
    local ms = tonumber(params.ms) or 0
    if ms <= 0 then return nil, "ms must be a positive integer for wait" end
    return wrap(deps.ui.wait(ms), "wait")
end

function ACTIONS.eval(params, deps)
    if type(params.js) ~= "string" or params.js == "" then
        return nil, "js is required for eval"
    end
    return wrap(deps.ui.eval(params.js), "eval")
end

local function read_preview_png(url)
    if type(url) ~= "string" or url == "" then return nil end
    if url:sub(1, #PREVIEWS_URL_PREFIX) ~= PREVIEWS_URL_PREFIX then return nil end
    local rel: string = url:sub(#PREVIEWS_URL_PREFIX + 1)
    local storage = fs.get(PREVIEWS_FS_ID)
    if not storage then return nil end
    if not storage:exists(rel) then return nil end
    return storage:readfile(rel)
end

function ACTIONS.screenshot(params, deps)
    local name
    if params.name ~= nil and params.name ~= "" then
        name = filenames.with_random_seed(params.name)
    end
    local shot, err = wrap(deps.ui.screenshot({
        name = name,
        selector = params.selector,
        full = params.full == true,
        request_id = "screenshots",
    }), "screenshot")
    if err then return nil, err end

    local content = {
        { type = "text", text = "screenshot: " .. tostring(shot.url or "") },
    }
    local png = read_preview_png(shot.url)
    if png then
        local encoded = base64.encode(png)
        if encoded then
            table.insert(content, { type = "image", data = encoded, mimeType = "image/png" })
        end
    end

    return {
        url = shot.url,
        _mcp_content = content,
    }
end

function ACTIONS.assert_visible(params, deps)
    if type(params.selector) ~= "string" or params.selector == "" then
        return nil, "selector is required for assert_visible"
    end
    return wrap(deps.ui.assert_visible(params.selector), "assert_visible")
end

function ACTIONS.assert_text(params, deps)
    if type(params.selector) ~= "string" or params.selector == "" then
        return nil, "selector is required for assert_text"
    end
    if type(params.text) ~= "string" then
        return nil, "text is required for assert_text"
    end
    return wrap(deps.ui.assert_text(params.selector, params.text), "assert_text")
end

function ACTIONS.expect_url(params, deps)
    return wrap(deps.ui.expect_url({
        url = params.url,
        contains = params.contains,
        regex = params.regex,
    }), "expect_url")
end

function ACTIONS.close(_, deps)
    return wrap(deps.ui.close(), "close")
end

function ACTIONS.ping(_, deps)
    return wrap(deps.ui.ping(), "ping")
end

local ALIASES: {[string]: string} = {
    ["goto"] = "goto_url",
    ["type"] = "type_text",
    ["select"] = "select_option",
}

local M = {}

-- Pure dispatch. Takes its dependencies explicitly so unit tests substitute
-- fakes for the supervisor client and token minting.
function M.run(deps, params)
    deps = deps or {}
    local resolved_deps = {
        ui = deps.ui or ui_default,
        mint_token = deps.mint_token or mint_caller_token,
    }
    params = params or {}
    local action = params.action
    if type(action) ~= "string" or action == "" then
        return nil, "action is required"
    end
    local resolved = ALIASES[action] or action
    local fn = ACTIONS[resolved]
    if not fn then return nil, "unknown action: " .. tostring(action) end

    return fn(params, resolved_deps)
end

local function handler(params)
    params = params or {}
    local action = params.action or "?"
    return audit.wrap({
        tool          = "ui",
        discriminator = "ui." .. action,
        target        = params.url or params.selector,
        params        = params,
        summarise = function(result, err)
            if err then return "ui " .. action .. " failed: " .. tostring(err) end
            return "ui." .. action
        end,
    }, function()
        return M.run(nil, params)
    end)
end

M.handler = handler
return M
