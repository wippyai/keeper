-- keeper.components.ui:client
--
-- Client library for keeper.components.ui:supervisor. Function.lua
-- handlers and other code import this to drive the UI session. Each
-- call is one message to the supervisor mailbox; the supervisor
-- serializes operations and owns the single long-lived browser.

local process = require("process")
local channel = require("channel")
local time = require("time")
local uuid = require("uuid")
local json = require("json")

local SERVICE = "keeper.components.ui.supervisor"
local COMMAND_TOPIC = "ui.command"

-- Client-side (listen channel) timeouts. These pair with the supervisor's
-- per-op timeouts: supervisor DEFAULT_CALL_TIMEOUT_S=30 → client waits 35s;
-- supervisor GOTO_TIMEOUT_S=45 → client waits 50s; supervisor OPEN 50 → 60s.
-- Always client > supervisor so the supervisor's own timeout surfaces first
-- with a useful error instead of the client's generic "client timed out".
local DEFAULT_TIMEOUT = "35s"
local GOTO_TIMEOUT    = "50s"
local OPEN_TIMEOUT    = "60s"

local M = {}

local function new_id()
    local id, err = uuid.v4()
    if err then return tostring(time.now():unix_nano()) end
    return id
end

local function new_reply_topic()
    return "ui.response." .. new_id()
end

local function close_ch(ch)
    if ch then pcall(function() if ch.close then ch:close() end end) end
end

local function send_and_wait(op, args, opts)
    opts = opts or {}
    local reply_topic = new_reply_topic()
    local req_id = new_id()

    local listen_ch = process.listen(reply_topic)

    local ok = process.send(SERVICE, COMMAND_TOPIC, {
        id = req_id,
        op = op,
        args = args or {},
        respond_to = reply_topic,
        timeout_s = opts.timeout_s,
    })
    if not ok then
        close_ch(listen_ch)
        return { success = false, error = "failed to reach ui supervisor" }
    end

    local timeout_ch = time.after(opts.wait or DEFAULT_TIMEOUT)
    local result = channel.select({
        listen_ch:case_receive(),
        timeout_ch:case_receive(),
    })

    if result.channel == timeout_ch then
        close_ch(listen_ch)
        return { success = false, error = "client timed out waiting for ui supervisor" }
    end
    if not result.ok then
        close_ch(listen_ch)
        return { success = false, error = "ui response channel closed" }
    end

    close_ch(listen_ch)
    local response = result.value
    if type(response) ~= "table" then
        return { success = false, error = "unexpected response type from ui supervisor" }
    end
    return response
end

function M.open(opts)
    return send_and_wait("open", opts or {}, { wait = OPEN_TIMEOUT, timeout_s = 50 })
end

function M.snapshot()
    return send_and_wait("snapshot", {})
end

function M.goto_url(url, wait_until)
    return send_and_wait("goto", { url = url, wait_until = wait_until }, { wait = GOTO_TIMEOUT, timeout_s = 45 })
end

function M.click(selector, opts)
    opts = opts or {}
    return send_and_wait("click", { selector = selector, timeout = opts.timeout })
end

function M.fill(selector, value, opts)
    opts = opts or {}
    return send_and_wait("fill", { selector = selector, value = value, timeout = opts.timeout })
end

function M.type_text(selector, value, opts)
    opts = opts or {}
    return send_and_wait("type", { selector = selector, value = value, delay = opts.delay, timeout = opts.timeout })
end

function M.press(key, selector)
    return send_and_wait("press", { key = key, selector = selector })
end

function M.hover(selector)
    return send_and_wait("hover", { selector = selector })
end

function M.select_option(selector, value)
    return send_and_wait("select", { selector = selector, value = value })
end

function M.wait_for(selector, opts)
    opts = opts or {}
    return send_and_wait("wait_for", { selector = selector, state = opts.state, timeout = opts.timeout })
end

function M.wait(ms)
    return send_and_wait("wait", { ms = ms })
end

function M.eval(js)
    return send_and_wait("eval", { js = js })
end

function M.screenshot(opts)
    opts = opts or {}
    return send_and_wait("screenshot", {
        name = opts.name,
        selector = opts.selector,
        full = opts.full,
        request_id = opts.request_id or "current",
        raw_root = opts.raw_root,
    })
end

function M.assert_visible(selector)
    return send_and_wait("assert_visible", { selector = selector })
end

function M.assert_text(selector, text)
    return send_and_wait("assert_text", { selector = selector, text = text })
end

function M.expect_url(opts)
    return send_and_wait("expect_url", opts or {})
end

function M.close()
    return send_and_wait("close", {})
end

function M.ping()
    return send_and_wait("ping", {}, { wait = "5s", timeout_s = 3 })
end

return M
