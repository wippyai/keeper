-- keeper.debug.tools:sessions
--
-- Action-dispatched session debug tool. Every action is scoped to the current
-- authenticated user (security.actor():id()). Markdown output via _mcp_content.

local json = require("json")
local security = require("security")

local repo = require("repo")
local render = require("render")

local M = {}

local ACTIONS = {}

local function mcp_text(text)
    return { _mcp_content = { { type = "text", text = text } } }
end

local function require_user()
    local actor = security.actor()
    if not actor then return nil, "authentication required" end
    local uid = actor:id()
    if not uid or uid == "" then return nil, "actor has no id" end
    return uid
end

function M.fmt_int(n) return tostring(tonumber(n) or 0) end
local fmt_int = M.fmt_int

function M.since_from_window(since, window_hours, now)
    if since then return since end
    if not window_hours then return nil end
    local h = tonumber(window_hours) or 168
    local base = now or os.time()
    return os.date("!%Y-%m-%dT%H:%M:%SZ", base - h * 3600)
end
local since_from_window = M.since_from_window

function M.parse_types_csv(s)
    if type(s) ~= "string" or s == "" then return nil end
    local out = {}
    for t in s:gmatch("[^,%s]+") do table.insert(out, t) end
    if #out == 0 then return nil end
    return out
end
local parse_types_csv = M.parse_types_csv

-- ---------------------------------------------------------------------------
-- overview
-- ---------------------------------------------------------------------------

function ACTIONS.overview(params)
    local user_id, err = require_user()
    if err then return nil, err end

    local rows = repo.overview(user_id, {
        limit = params.limit,
        offset = params.offset,
        status = params.status,
        kind = params.kind,
        since = params.since,
    })

    local out = {}
    table.insert(out, "# Sessions (user=" .. user_id .. ", newest first)")
    table.insert(out, "count=" .. #rows)
    table.insert(out, "")

    if #rows == 0 then
        table.insert(out, "No sessions match filters.")
        return mcp_text(table.concat(out, "\n"))
    end

    table.insert(out, render.table_header({
        "session_id", "status", "kind", "msgs", "user", "asst", "func", "artf", "agent", "model", "last_msg", "title",
    }))
    for _, r in ipairs(rows) do
        local agent = (r.config and r.config.agent_id) or ""
        local model = (r.config and r.config.model) or ""
        table.insert(out, render.table_row({
            r.session_id,
            render.status_marker(r.status),
            r.kind or "",
            fmt_int(r.message_count),
            fmt_int(r.user_msgs),
            fmt_int(r.assistant_msgs),
            fmt_int(r.function_msgs),
            fmt_int(r.artifact_msgs),
            render.clip(tostring(agent), 24),
            render.clip(tostring(model), 24),
            r.last_message_date or "",
            render.clip(r.title or "", 60),
        }))
    end

    table.insert(out, "")
    table.insert(out, "Next: `action=inspect session_id=<id>`, `action=messages session_id=<id>`, or `action=search query=<substr>`.")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- inspect
-- ---------------------------------------------------------------------------

function ACTIONS.inspect(params)
    local user_id, err = require_user()
    if err then return nil, err end
    if type(params.session_id) ~= "string" or params.session_id == "" then
        return nil, "session_id is required"
    end

    local session, serr = repo.get_session(params.session_id, user_id)
    if serr then return nil, serr end

    local counts = repo.message_counts(params.session_id)
    local usage = repo.usage_for_session(params.session_id)

    local out = {}
    table.insert(out, "# Session `" .. session.session_id .. "`")
    table.insert(out, "")
    table.insert(out, render.table_header({ "field", "value" }))
    table.insert(out, render.table_row({ "status", render.status_marker(session.status) }))
    table.insert(out, render.table_row({ "title", render.clip(session.title or "", 80) }))
    table.insert(out, render.table_row({ "kind", session.kind or "" }))
    table.insert(out, render.table_row({ "start_date", session.start_date or "" }))
    table.insert(out, render.table_row({ "last_message_date", session.last_message_date or "" }))
    local cfg = session.config or {}
    table.insert(out, render.table_row({ "config.agent_id", tostring(cfg.agent_id or "") }))
    table.insert(out, render.table_row({ "config.model", tostring(cfg.model or "") }))
    if cfg.token_checkpoint_threshold then
        table.insert(out, render.table_row({ "config.token_checkpoint_threshold", tostring(cfg.token_checkpoint_threshold) }))
    end
    if cfg.max_message_limit then
        table.insert(out, render.table_row({ "config.max_message_limit", tostring(cfg.max_message_limit) }))
    end
    table.insert(out, render.table_row({ "primary_context_id", session.primary_context_id or "" }))

    -- Message counts by type
    table.insert(out, "")
    table.insert(out, "## Messages: " .. counts.total)
    table.insert(out, render.table_header({ "type", "count" }))
    local type_order = { "user", "assistant", "system", "developer", "function", "private_function", "artifact", "delegation" }
    local shown = {}
    for _, t in ipairs(type_order) do
        if counts.by_type[t] then
            table.insert(out, render.table_row({ t, counts.by_type[t] }))
            shown[t] = true
        end
    end
    for t, c in pairs(counts.by_type) do
        if not shown[t] then table.insert(out, render.table_row({ t, c })) end
    end

    -- Usage summary
    table.insert(out, "")
    table.insert(out, "## Token usage (via primary_context_id)")
    table.insert(out, render.table_header({ "metric", "value" }))
    table.insert(out, render.table_row({ "llm_calls", usage.calls }))
    table.insert(out, render.table_row({ "prompt_tokens", usage.prompt }))
    table.insert(out, render.table_row({ "completion_tokens", usage.completion }))
    table.insert(out, render.table_row({ "thinking_tokens", usage.thinking }))
    table.insert(out, render.table_row({ "cache_read_tokens", usage.cache_read }))
    table.insert(out, render.table_row({ "cache_write_tokens", usage.cache_write }))
    if next(usage.by_model) then
        table.insert(out, "")
        table.insert(out, "### By model")
        table.insert(out, render.table_header({ "model", "calls", "prompt", "completion", "thinking" }))
        for _, b in pairs(usage.by_model) do
            table.insert(out, render.table_row({ b.model, b.calls, b.prompt, b.completion, b.thinking }))
        end
    end

    -- Artifacts rollup
    local artifacts = repo.artifacts(params.session_id, { limit = 10 })
    table.insert(out, "")
    table.insert(out, "## Artifacts (" .. #artifacts .. " shown)")
    if #artifacts > 0 then
        table.insert(out, render.table_header({ "artifact_id", "kind", "title", "created_at" }))
        for _, a in ipairs(artifacts) do
            table.insert(out, render.table_row({
                render.shorten(a.artifact_id),
                a.kind or "",
                render.clip(a.title or "", 60),
                a.created_at or "",
            }))
        end
    end

    table.insert(out, "")
    table.insert(out, "Next: `action=messages session_id=" .. session.session_id
        .. "` for transcript, `action=usage session_id=...` for detailed usage, "
        .. "`action=dataflows` for flows launched by this user.")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- messages — transcript render
-- ---------------------------------------------------------------------------

local ROLE_MARKERS = {
    user = "USER",
    assistant = "ASSISTANT",
    system = "SYSTEM",
    developer = "DEV",
    ["function"] = "FUNC",
    private_function = "PFUNC",
    artifact = "ARTIFACT",
    delegation = "DELEG",
}

function M.role_marker(msg_type)
    return ROLE_MARKERS[msg_type] or string.upper(msg_type or "?")
end
local role_marker = M.role_marker

function M.format_message_header(index, msg)
    local marker = role_marker(msg.type)
    local meta = msg.metadata or {}
    local header = string.format("## [%d] %s  (%s)  `%s`", index, marker, msg.date or "", msg.message_id or "")
    if meta.function_name then
        header = header .. "  fn=" .. tostring(meta.function_name)
    end
    if meta.status then
        header = header .. "  status=" .. tostring(meta.status)
    end
    return header
end
local format_message_header = M.format_message_header

local function render_msg_body(msg, opts)
    local text = repo.decode_message_data(msg)
    if opts and opts.preview then
        return render.clip(text, opts.preview_chars or 240)
    end
    return render.clip(text, opts and opts.full_chars or 1200)
end

function ACTIONS.messages(params)
    local user_id, err = require_user()
    if err then return nil, err end
    if type(params.session_id) ~= "string" or params.session_id == "" then
        return nil, "session_id is required"
    end
    -- Ensure ownership.
    local session, serr = repo.get_session(params.session_id, user_id)
    if serr then return nil, serr end

    local page = repo.messages(params.session_id, {
        limit = params.limit,
        cursor = params.cursor,
        direction = params.direction,
    })

    local out = {}
    table.insert(out, "# Messages `" .. session.session_id .. "` ("
        .. #page.messages .. (page.has_more and " of many" or "") .. ")")
    table.insert(out, "title: " .. (session.title or ""))
    table.insert(out, "")

    local preview_chars = tonumber(params.preview_chars) or 300
    for i, m in ipairs(page.messages) do
        table.insert(out, format_message_header(i, m))
        table.insert(out, render_msg_body(m, { preview = true, preview_chars = preview_chars }))
        table.insert(out, "")
    end

    if page.has_more then
        table.insert(out, string.format("... more available. Paginate with `cursor=%s direction=before`.",
            page.next_cursor or ""))
    end
    table.insert(out, "Next: `action=message message_id=<id>` for full body of a specific message.")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- message (single, full content)
-- ---------------------------------------------------------------------------

function ACTIONS.message(params)
    local user_id, err = require_user()
    if err then return nil, err end
    if type(params.message_id) ~= "string" or params.message_id == "" then
        return nil, "message_id is required"
    end
    local m, merr = repo.get_message(params.message_id)
    if merr or not m then return nil, merr or "message not found" end

    -- Ownership check: session must belong to user.
    local s, serr = repo.get_session(m.session_id, user_id)
    if serr or not s then return nil, "message not accessible" end

    local out = {}
    table.insert(out, "# Message `" .. m.message_id .. "`")
    table.insert(out, "session=" .. m.session_id .. "  type=" .. (m.type or "?") .. "  date=" .. (m.date or ""))
    if m.metadata and next(m.metadata) then
        table.insert(out, "")
        table.insert(out, "## Metadata")
        table.insert(out, "```json")
        local ok, enc = pcall(json.encode, m.metadata)
        table.insert(out, ok and enc or tostring(m.metadata))
        table.insert(out, "```")
    end
    table.insert(out, "")
    table.insert(out, "## Body")
    table.insert(out, "```")
    table.insert(out, render.clip(repo.decode_message_data(m), tonumber(params.limit) or 4000))
    table.insert(out, "```")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- artifacts
-- ---------------------------------------------------------------------------

function ACTIONS.artifacts(params)
    local user_id, err = require_user()
    if err then return nil, err end

    if type(params.session_id) == "string" and params.session_id ~= "" then
        local s, serr = repo.get_session(params.session_id, user_id)
        if serr or not s then return nil, "session not accessible" end
        local list = repo.artifacts(params.session_id, {
            limit = params.limit,
            offset = params.offset,
        })
        local out = {}
        table.insert(out, "# Artifacts for session `" .. s.session_id .. "`")
        table.insert(out, "count=" .. #list)
        table.insert(out, "")
        if #list == 0 then
            table.insert(out, "No artifacts.")
            return mcp_text(table.concat(out, "\n"))
        end
        table.insert(out, render.table_header({ "artifact_id", "kind", "title", "created_at" }))
        for _, a in ipairs(list) do
            table.insert(out, render.table_row({
                a.artifact_id,
                a.kind or "",
                render.clip(a.title or "", 60),
                a.created_at or "",
            }))
        end
        return mcp_text(table.concat(out, "\n"))
    end

    -- Fall back: single-artifact view.
    if type(params.artifact_id) ~= "string" or params.artifact_id == "" then
        return nil, "session_id or artifact_id is required"
    end
    local a, aerr = repo.get_artifact(params.artifact_id)
    if aerr or not a then return nil, aerr or "artifact not found" end
    if a.user_id ~= user_id then return nil, "artifact not accessible" end
    local out = {}
    table.insert(out, "# Artifact `" .. a.artifact_id .. "`")
    table.insert(out, render.table_header({ "field", "value" }))
    table.insert(out, render.table_row({ "session_id", a.session_id or "" }))
    table.insert(out, render.table_row({ "kind", a.kind or "" }))
    table.insert(out, render.table_row({ "title", render.clip(a.title or "", 100) }))
    table.insert(out, render.table_row({ "created_at", a.created_at or "" }))
    table.insert(out, render.table_row({ "updated_at", a.updated_at or "" }))
    if a.meta and next(a.meta) then
        table.insert(out, "")
        table.insert(out, "## Meta")
        table.insert(out, "```json")
        local ok, enc = pcall(json.encode, a.meta)
        table.insert(out, ok and enc or "")
        table.insert(out, "```")
    end
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- usage
-- ---------------------------------------------------------------------------

function ACTIONS.usage(params)
    local user_id, err = require_user()
    if err then return nil, err end

    if type(params.session_id) == "string" and params.session_id ~= "" then
        local s, serr = repo.get_session(params.session_id, user_id)
        if serr or not s then return nil, "session not accessible" end
        local u = repo.usage_for_session(params.session_id)
        local out = {}
        table.insert(out, "# Usage for session `" .. s.session_id .. "`")
        table.insert(out, "")
        table.insert(out, render.table_header({ "metric", "value" }))
        table.insert(out, render.table_row({ "llm_calls", u.calls }))
        table.insert(out, render.table_row({ "prompt_tokens", u.prompt }))
        table.insert(out, render.table_row({ "completion_tokens", u.completion }))
        table.insert(out, render.table_row({ "thinking_tokens", u.thinking }))
        table.insert(out, render.table_row({ "cache_read_tokens", u.cache_read }))
        table.insert(out, render.table_row({ "cache_write_tokens", u.cache_write }))
        if next(u.by_model) then
            table.insert(out, "")
            table.insert(out, "## By model")
            table.insert(out, render.table_header({ "model", "calls", "prompt", "completion", "thinking" }))
            for _, b in pairs(u.by_model) do
                table.insert(out, render.table_row({ b.model, b.calls, b.prompt, b.completion, b.thinking }))
            end
        end
        return mcp_text(table.concat(out, "\n"))
    end

    -- User-wide window rollup.
    local since = since_from_window(params.since, params.window_hours)
    local rows = repo.usage_by_model(user_id, { since = since })
    local out = {}
    table.insert(out, "# Usage for user `" .. user_id .. "`"
        .. (since and (" since " .. since) or ""))
    table.insert(out, "")
    table.insert(out, render.table_header({
        "model", "calls", "prompt", "completion", "thinking", "cache_r", "cache_w", "total",
    }))
    for _, r in ipairs(rows) do
        table.insert(out, render.table_row({
            r.model_id or "unknown",
            r.calls, r.prompt_tokens, r.completion_tokens, r.thinking_tokens,
            r.cache_read_tokens, r.cache_write_tokens, r.total_tokens,
        }))
    end
    if #rows == 0 then
        table.insert(out, "No usage records in window.")
    end
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- dataflows (bridge to flow debugger)
-- ---------------------------------------------------------------------------

function ACTIONS.dataflows(params)
    local user_id, err = require_user()
    if err then return nil, err end
    local since = since_from_window(params.since, params.window_hours)
    local rows = repo.user_dataflows(user_id, { since = since, limit = params.limit })

    local out = {}
    table.insert(out, "# Dataflows launched by `" .. user_id .. "`"
        .. (since and (" since " .. since) or ""))
    table.insert(out, "count=" .. #rows)
    table.insert(out, "")
    if #rows == 0 then
        table.insert(out, "No dataflows.")
        return mcp_text(table.concat(out, "\n"))
    end
    table.insert(out, render.table_header({ "flow_id", "status", "type", "nodes", "failed", "created_at", "title" }))
    for _, r in ipairs(rows) do
        local title = (r.metadata and (r.metadata.title or r.metadata.name)) or ""
        table.insert(out, render.table_row({
            r.dataflow_id,
            render.status_marker(r.status),
            r.type or "",
            r.node_count,
            r.failed_nodes,
            r.created_at or "",
            render.clip(tostring(title), 60),
        }))
    end
    table.insert(out, "")
    table.insert(out, "Next: switch to `dataflow` tool with `action=anomalies flow_id=<id>` or `action=tree flow_id=<id>`.")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- search (cross-session message substring, current user only)
-- ---------------------------------------------------------------------------

function ACTIONS.search(params)
    local user_id, err = require_user()
    if err then return nil, err end
    if type(params.query) ~= "string" or params.query == "" then
        return nil, "query is required"
    end
    local rows = repo.search_messages(user_id, params.query, {
        types = parse_types_csv(params.types),
        session_id = params.session_id,
        since = params.since,
        limit = params.limit,
    })
    local out = {}
    table.insert(out, string.format("# Search `%s` — %d hits (user=%s)", params.query, #rows, user_id))
    if params.session_id then
        table.insert(out, "scope: session=" .. params.session_id)
    end
    table.insert(out, "")
    if #rows == 0 then
        table.insert(out, "No matches.")
        return mcp_text(table.concat(out, "\n"))
    end
    table.insert(out, render.table_header({ "message_id", "session_id", "type", "date", "session_title", "snippet" }))
    for _, r in ipairs(rows) do
        table.insert(out, render.table_row({
            render.shorten(r.message_id),
            render.shorten(r.session_id),
            r.type or "",
            r.date or "",
            render.clip(r.session_title or "", 40),
            render.clip(r.snippet or "", 160),
        }))
    end
    table.insert(out, "")
    table.insert(out, "Next: `action=message message_id=<id>` for the full body, `action=messages session_id=<id>` for the transcript.")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- stats (user-wide rollup)
-- ---------------------------------------------------------------------------

function ACTIONS.stats(params)
    local user_id, err = require_user()
    if err then return nil, err end
    local since = since_from_window(params.since, params.window_hours)
    local s = repo.user_stats(user_id, { since = since })

    local out = {}
    table.insert(out, "# User stats `" .. user_id .. "`"
        .. (since and (" since " .. since) or ""))
    table.insert(out, "")

    table.insert(out, "## Sessions")
    table.insert(out, render.table_header({ "metric", "value" }))
    table.insert(out, render.table_row({ "total", s.sessions.total }))
    for k, v in pairs(s.sessions.by_status) do
        table.insert(out, render.table_row({ "status." .. k, v }))
    end

    table.insert(out, "")
    table.insert(out, "## Messages")
    table.insert(out, render.table_header({ "type", "count" }))
    table.insert(out, render.table_row({ "all", s.messages.total }))
    for k, v in pairs(s.messages.by_type) do
        table.insert(out, render.table_row({ k, v }))
    end

    table.insert(out, "")
    table.insert(out, "## Artifacts: " .. s.artifacts_total)

    table.insert(out, "")
    table.insert(out, "## Usage by model")
    table.insert(out, render.table_header({
        "model", "calls", "prompt", "completion", "thinking", "cache_r", "cache_w", "total",
    }))
    for _, r in ipairs(s.usage_by_model) do
        table.insert(out, render.table_row({
            r.model_id or "unknown",
            r.calls, r.prompt_tokens, r.completion_tokens, r.thinking_tokens,
            r.cache_read_tokens, r.cache_write_tokens, r.total_tokens,
        }))
    end
    if #s.usage_by_model == 0 then
        table.insert(out, "(no usage records)")
    end

    table.insert(out, "")
    table.insert(out, "Next: `action=overview` for recent sessions, `action=search query=<substr>` to find messages.")
    return mcp_text(table.concat(out, "\n"))
end

-- ---------------------------------------------------------------------------
-- dispatcher
-- ---------------------------------------------------------------------------

local function handler(params)
    params = params or {}
    local action = params.action
    if type(action) ~= "string" or action == "" then
        return nil, "action is required"
    end
    local fn = ACTIONS[action]
    if not fn then return nil, "unknown action: " .. tostring(action) end

    local result, err = fn(params)
    if err then return nil, err end

    return result
end

M.handler = handler
return M
