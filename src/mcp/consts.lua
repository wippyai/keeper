local M = {}

M.DB_ID = "app:db"
M.ACCESS_TOKEN_ENV = "MCP_ACCESS_TOKEN"

M.PROTOCOL_VERSION = "2025-03-26"

M.SERVER_INFO = {
    name = "keeper",
    version = "1.0.0",
}

M.CAPABILITIES = {
    tools = { listChanged = true },
}

-- Streamable HTTP transport. GET / upgrades to SSE via sse_relay; a per-session
-- broker process forwards JSON-RPC notifications from POST handlers to the
-- client. Name prefix keys the broker by session token so reconnects can
-- hot-swap the prior stream.
M.SSE_BROKER_NAME_PREFIX = "mcp.session."
M.SSE_MESSAGE_TOPIC = "message"

-- Topic POST handlers publish on to reach the per-session broker; the
-- broker re-emits the payload to the SSE stream PID on SSE_MESSAGE_TOPIC.
M.MCP_NOTIFY_TOPIC = "mcp.notify"

-- JSON-RPC notification method names pushed to spec-compliant clients when
-- the session mutates its tool surface. Kept here so the producer (handler)
-- and any future consumers speak the same wire protocol.
M.NOTIFICATIONS = {
    TOOLS_LIST_CHANGED = "notifications/tools/list_changed",
}

-- Included in the initialize response so MCP clients surface cross-cutting
-- guidance to the LLM before tool schemas are read. Intentionally terse:
-- this is loaded on every turn, so it must describe relationships and
-- constraints that tool descriptions cannot carry on their own. Per-trait
-- details live in describe_trait; per-tool details in tool.description.
M.INSTRUCTIONS = [[
Keeper MCP — control plane for this Wippy instance. One surface reaches the
live registry, governance pipeline, branch+push workflow, dataflow/session/
system telemetry, SQLite inspection, knowledge base, and UI driver.

## Orient first

1. `session_info` — access_mode, trait catalog, active traits, tool count.
   Authoritative; do not infer traits from tool names.
2. `list_traits` / `describe_trait id=...` when you need catalog details
   before activating.

## Activate the traits you need

Use `list_traits` to see the full catalog and `describe_trait` to inspect what
each one unlocks. Typical bundles:

- Investigate (flows, sessions, logs, SQL, state) → activate the `debug.*`
  traits plus `state.traits:explorer` / `:comparer`.
- Author entries / backend code → `state.traits:{editor, manager, explorer,
  comparer}` + `gov.traits:syncer` + `verify.traits:runner`.
- Frontend files, builds, UI automation → `state.traits:{explorer, manager}`
  + `components.traits:{builder, ui}` + `verify.traits:runner`.
- KB + Wippy docs only → `knowledge.traits:researcher`.

## Workflow rules

- `main` is read-only. Author on a branch: `edit` staged patches on the
  active changeset. Publishing is owned by the task pipeline's integrate
  function runner; agents never invoke push or submit(commit) directly.
- `sync_from_fs` / `sync_to_fs` reconcile `src/**` with the registry
  through the governance pipeline (up to 90s).
- Learning loop: `dataflow action=learn window_hours=168` for systemic
  failure patterns; `sessions action=stats` for user-scoped rollups;
  `system action=log_composition` before guessing log filters. Persist
  durable findings with `write_knowledge` so future sessions inherit them.
- `use_trait`/`drop_trait` emit `notifications/tools/list_changed`
  (`tools.listChanged=true`), so clients with Streamable HTTP (GET / SSE)
  pick up the new surface live. Static clients reconnect to refresh.
]]

return M
