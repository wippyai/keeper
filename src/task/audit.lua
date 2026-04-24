-- keeper.task:audit
--
-- Structural tool-call auditor. Every registry tool handler wraps its body in
-- `audit.wrap({tool=..., discriminator=..., target=...}, function() ... end)`.
-- The helper reads task_id + parent_node_id + agent_id + dataflow_id +
-- changeset_id + phase from ctx, writes a `tool_call` row with status=running
-- before the body, then updates it with status=passed|failed, execution_ms,
-- result_summary and error_message after the body returns.
--
-- When ctx.task_id is absent (CLI, admin, standalone tests) wrap() is a
-- transparent pass-through — no audit row is written and the caller's return
-- value is unchanged. Tools stay usable outside a task.

local ctx  = require("ctx")
local json = require("json")
local time = require("time")
local writer = require("nodes_writer")

local M = {}

local MAX_CONTENT = 2048
local MAX_SUMMARY = 512

local function now_ms()
    return math.floor(time.now():unix_nano() / 1e6)
end

local function truncate(s, limit)
    if type(s) ~= "string" then return s end
    if #s <= limit then return s end
    return s:sub(1, limit) .. "…"
end

local function stringify(v)
    if v == nil then return nil end
    if type(v) == "string" then return v end
    local s, err = json.encode(v)
    if err then return "<encode error>" end
    return s
end

local function default_summary(result, err)
    if err then
        if type(err) == "string" then return truncate(err, MAX_SUMMARY) end
        return truncate(stringify(err), MAX_SUMMARY)
    end
    if result == nil then return nil end
    return truncate(stringify(result), MAX_SUMMARY)
end

local function resolve_title(cfg)
    if cfg.title and cfg.title ~= "" then return cfg.title end
    if cfg.target and cfg.target ~= "" then
        return cfg.tool .. ": " .. tostring(cfg.target)
    end
    return cfg.tool
end

local function resolve_content(cfg)
    if cfg.content ~= nil then
        return cfg.content, cfg.content_type or "text/plain"
    end
    if cfg.params ~= nil then
        return truncate(stringify(cfg.params), MAX_CONTENT), "application/json"
    end
    return nil, "text/plain"
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- wrap(cfg, fn) — run fn() under an audit row.
--
-- cfg fields:
--   tool           string (required) — tool id / display name
--   discriminator  string (optional) — secondary key (command name, subop)
--   target         string (optional) — target label (entry path, file)
--   title          string (optional) — overrides derived title
--   content        string (optional) — pre-formatted content; otherwise params is used
--   content_type   string (optional) — mime for content
--   params         any    (optional) — auto-stringified into content
--   visibility     string (optional) — "user" | "debug" | "internal"; default "user"
--   summarise      fn(result, err) -> string (optional)
--
-- Returns whatever fn returns. Re-raises if fn raises; audit row captures the error.
function M.wrap(cfg, fn)
    return M._wrap_with_ctx(cfg, fn, M._read_ctx())
end

-- Exposed for testing with controlled context.
function M._read_ctx()
    local task_id = ctx.get("task_id")
    if task_id == "" then task_id = nil end
    return {
        task_id        = task_id,
        parent_node_id = ctx.get("parent_node_id"),
        agent_id       = ctx.get("agent_id"),
        dataflow_id    = ctx.get("dataflow_id"),
        changeset_id   = ctx.get("changeset_id") or ctx.get("overlay_branch_cs"),
        phase          = ctx.get("phase"),
    }
end

function M._wrap_with_ctx(cfg, fn, audit_ctx)
    if type(cfg) ~= "table" then
        error("audit.wrap: cfg table required")
    end
    if type(fn) ~= "function" then
        error("audit.wrap: fn required")
    end
    if not cfg.tool or cfg.tool == "" then
        error("audit.wrap: cfg.tool required")
    end

    -- No task context → pass-through, no row written.
    if not audit_ctx.task_id then
        return fn()
    end

    local title = resolve_title(cfg)
    local content, content_type = resolve_content(cfg)

    local pre, _ = writer.record({
        task_id         = audit_ctx.task_id,
        parent_node_id  = audit_ctx.parent_node_id,
        type            = "tool_call",
        discriminator   = cfg.discriminator or cfg.tool,
        title           = title,
        content         = content,
        content_type    = content_type,
        status          = "running",
        visibility      = cfg.visibility or "user",
        agent_id        = audit_ctx.agent_id,
        dataflow_id     = audit_ctx.dataflow_id,
        changeset_id    = audit_ctx.changeset_id,
        metadata        = {
            phase  = audit_ctx.phase,
            tool   = cfg.tool,
            target = cfg.target,
        },
    })

    local started = now_ms()
    local result, err = fn()
    local duration = now_ms() - started

    if pre and pre.node_id then
        local fields = { execution_ms = duration }
        if err then
            fields.status = "failed"
            fields.error_message = type(err) == "string" and err or stringify(err)
        else
            fields.status = "passed"
        end

        local summary
        if type(cfg.summarise) == "function" then
            summary = cfg.summarise(result, err)
        end
        if summary == nil then
            summary = default_summary(result, err)
        end
        if summary ~= nil then
            fields.result_summary = truncate(tostring(summary), MAX_SUMMARY)
        end

        writer.update(pre.node_id, fields)
    end

    return result, err
end

return M
