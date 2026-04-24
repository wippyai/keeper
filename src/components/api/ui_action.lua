-- keeper.components.api:ui_action
--
-- Single HTTP dispatcher: POST /keeper/components/ui with body
--   { op: string, args: table }
-- Both fields are required. No inline-args fallback.
-- Returns the raw supervisor response. Agents will usually use the
-- MCP tools; this endpoint is for curl and the keeper frontend.

local http = require("http")

local ui = require("ui")
local security = require("security")
local DISPATCH = {
    open            = function(a) return ui.open(a) end,
    snapshot        = function(_) return ui.snapshot() end,
    goto_url        = function(a) return ui.goto_url(a.url, a.wait_until) end,
    click           = function(a) return ui.click(a.selector, a) end,
    fill            = function(a) return ui.fill(a.selector, a.value, a) end,
    type            = function(a) return ui.type_text(a.selector, a.value, a) end,
    press           = function(a) return ui.press(a.key, a.selector) end,
    hover           = function(a) return ui.hover(a.selector) end,
    select          = function(a) return ui.select_option(a.selector, a.value) end,
    wait_for        = function(a) return ui.wait_for(a.selector, a) end,
    wait            = function(a) return ui.wait(a.ms) end,
    eval            = function(a) return ui.eval(a.js) end,
    screenshot      = function(a) return ui.screenshot(a) end,
    assert_visible  = function(a) return ui.assert_visible(a.selector) end,
    assert_text     = function(a) return ui.assert_text(a.selector, a.text) end,
    expect_url      = function(a) return ui.expect_url(a) end,
    close           = function(_) return ui.close() end,
    ping            = function(_) return ui.ping() end,
}

local function handler()
    local res = http.response()
    local req = http.request()
    if not res or not req then return nil, "Failed to get HTTP context" end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    local body = req:body_json() or {}
    local op = body.op
    if type(op) ~= "string" or op == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "op (string) required" })
        return
    end

    local args = body.args
    if args == nil then args = {} end
    if type(args) ~= "table" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "args must be an object" })
        return
    end

    local fn = (DISPATCH :: any)[op]
    if not fn then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({ success = false, error = "unknown op: " .. op })
        return
    end

    -- For open, let the caller's bearer token drive auth so the browser
    -- session matches the user who triggered the call.
    if op == "open" and not args.auth_token then
        args.auth_token = (function()
        local _auth = req:header("Authorization")
        if not _auth then return nil end
        local _tok = _auth:match("[Bb]earer%s+(.+)")
        if _tok and _tok ~= "" then return _tok end
        return nil
    end)()
    end

    local result = fn(args)
    res:set_status(http.STATUS.OK)
    res:set_content_type(http.CONTENT.JSON)
    res:write_json(result)
end

return { handler = handler }
