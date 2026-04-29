-- keeper.task:audit
--
-- Structural tool-call auditor. Every registry tool handler wraps its body in
-- `audit.wrap({tool=..., discriminator=..., target=...}, function() ... end)`.
-- Reads task_id + task_node_parent_id + agent_id + dataflow_id + changeset_id +
-- phase from ctx, writes a `tool_call` row with status=running before fn(),
-- updates it with status=passed|failed, execution_ms, full JSON-encoded
-- result_summary, full error_message after fn() returns.
--
-- When ctx.task_id is absent (CLI, admin, standalone tests) wrap() is a
-- transparent pass-through — no audit row is written and the caller's return
-- value is unchanged. Tools stay usable outside a task.
--
-- Canonical invariant: every dataflow keeper spawns must declare
-- task_id via :with_input. The dataflow runtime then propagates that
-- through the agent's arena.context into the tool handler's ctx. If
-- ctx.task_id is missing inside a task-spawned tool handler, that is a
-- runtime/lifecycle bug — fix the spawn site, not the auditor.

local ctx    = require("ctx")
local json   = require("json")
local time   = require("time")
local logger = require("logger")
local writer = require("nodes_writer")

local log = logger:named("keeper.task.audit")

local M = {}

local function now_ms()
    return math.floor(time.now():unix_nano() / 1e6)
end

local function stringify(v)
    if v == nil then return nil end
    if type(v) == "string" then return v end
    local s, err = json.encode(v)
    if err then return "<encode error>" end
    return s
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
        return stringify(cfg.params), "application/json"
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
        parent_node_id = ctx.get("task_node_parent_id"),
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

    if not audit_ctx.task_id then
        return fn()
    end

    local title = resolve_title(cfg)
    local content, content_type = resolve_content(cfg)

    local spec = {
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
    }

    local pre, rec_err = writer.record(spec)
    if not pre and audit_ctx.parent_node_id
       and tostring(rec_err or ""):find("parent node not found:", 1, true) then
        log:warn("stale audit parent_node_id rejected; inserting at root", {
            task_id        = audit_ctx.task_id,
            parent_node_id = audit_ctx.parent_node_id,
            tool           = cfg.tool,
            error          = rec_err,
        })
        spec.parent_node_id = nil
        pre, rec_err = writer.record(spec)
    end

    local started = now_ms()
    local result, err = fn()
    local duration = now_ms() - started

    if pre and pre.node_id then
        local fields = { execution_ms = duration }
        if err then
            fields.status        = "failed"
            fields.error_message = type(err) == "string" and err or stringify(err)
        else
            fields.status = "passed"
        end
        if result ~= nil then
            fields.result_summary = stringify(result)
        end

        writer.update(pre.node_id, fields)
    end

    return result, err
end

return M
