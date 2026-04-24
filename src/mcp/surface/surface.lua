-- Tool surface composition for MCP sessions.
--
-- Responsibilities:
--   * Declare the meta-tool catalog (schemas clients see in tools/list).
--   * Build the per-session tool list: meta-tools + materialized dynamic
--     tools (tools_only filter OR any/traits compiler pipeline).
--   * Provide snapshot helpers used by meta-tool handlers to diff the
--     surface before/after activation.

local mcp_traits = require("mcp_traits")

local M = {}

-- Meta-tool catalog. `always_visible=true` surfaces the tool in every access
-- mode; otherwise the tool is listed only for any/traits sessions that have a
-- trait layer to navigate.
M.META_TOOLS = {
    {
        name = "session_info",
        description = "Return everything about this MCP session in one call: access_mode, active traits, available catalog, current tool count, and default_active. Use this first after connecting.",
        inputSchema = { type = "object" },
        always_visible = true,
    },
    {
        name = "list_traits",
        description = "List every trait in the catalog this session can activate. Returns id, title, description, tool ids, and which traits are currently active.",
        inputSchema = { type = "object" },
    },
    {
        name = "describe_trait",
        description = "Return the full prompt and resolved tool list for a single trait, including transitively-included sub-traits.",
        inputSchema = {
            type = "object",
            properties = {
                id = { type = "string", description = "Trait registry id (e.g. keeper.agents.traits.state:editor)" },
            },
            required = { "id" },
        },
    },
    {
        name = "use_trait",
        description = "Activate traits AND return the tools that just became available in one call. Preferred over activate_traits when you want to act on the new surface immediately.",
        inputSchema = {
            type = "object",
            properties = {
                ids = { type = "array", items = { type = "string" }, description = "Trait ids to add to active set" },
            },
            required = { "ids" },
        },
        mutates_surface = true,
    },
    {
        name = "drop_trait",
        description = "Deactivate traits AND return the tools that just disappeared in one call. Mirror of use_trait.",
        inputSchema = {
            type = "object",
            properties = {
                ids = { type = "array", items = { type = "string" }, description = "Trait ids to remove from active set" },
            },
            required = { "ids" },
        },
        mutates_surface = true,
    },
    {
        name = "activate_traits",
        description = "Add traits to the active set. Expands tool surface and prompt. Other active traits remain active. Use set_traits for replacement.",
        inputSchema = {
            type = "object",
            properties = {
                ids = { type = "array", items = { type = "string" }, description = "Trait ids to add" },
            },
            required = { "ids" },
        },
        mutates_surface = true,
    },
    {
        name = "deactivate_traits",
        description = "Remove traits from the active set. Other active traits remain active.",
        inputSchema = {
            type = "object",
            properties = {
                ids = { type = "array", items = { type = "string" }, description = "Trait ids to remove" },
            },
            required = { "ids" },
        },
        mutates_surface = true,
    },
    {
        name = "set_traits",
        description = "Replace the entire active set with the given ids. Passing an empty array clears the active set. Use reset_traits to revert to the token's default_active.",
        inputSchema = {
            type = "object",
            properties = {
                ids = { type = "array", items = { type = "string" }, description = "New complete active set" },
            },
            required = { "ids" },
        },
        mutates_surface = true,
    },
    {
        name = "reset_traits",
        description = "Revert the active set to the token's default_active configuration.",
        inputSchema = { type = "object" },
        mutates_surface = true,
    },
    {
        name = "list_tools",
        description = "Enumerate registry tools (meta.type=tool) this session is allowed to call, optionally filtered by namespace or tag. Returns id, name, description, tags, and input_schema so the caller can dispatch via call_tool without waiting for the client's MCP tool cache to refresh.",
        inputSchema = {
            type = "object",
            properties = {
                namespace = { type = "string", description = "Match tool ids in this namespace or any sub-namespace (e.g. 'keeper.state.tools')" },
                tag_any = { type = "array", items = { type = "string" }, description = "Match if any listed tag is present" },
                tag_all = { type = "array", items = { type = "string" }, description = "Match only if every listed tag is present" },
                include_schema = { type = "boolean", description = "Include the full input_schema per tool (default true)" },
                limit = { type = "integer", description = "Cap result count (default 200)" },
            },
        },
        always_visible = true,
    },
    {
        name = "call_tool",
        description = "Invoke any registry tool by id with the given arguments, as the session's synthesized admin. Uses the same dispatch path the MCP client would use if the tool were in its tool list — so it works for tools added after the MCP client snapshot. Session context (overlay_branch, changeset_id) is injected automatically.",
        inputSchema = {
            type = "object",
            properties = {
                id = { type = "string", description = "Registry id of the tool (e.g. 'keeper.debug.tools:data')" },
                arguments = { type = "object", description = "Arguments object passed to the tool (default {})" },
                context = { type = "object", description = "Optional extra context overrides merged with session-derived context" },
            },
            required = { "id" },
        },
        always_visible = true,
    },
}

M.ALWAYS_VISIBLE = {}
M.MUTATES_SURFACE = {}
for _, m in ipairs(M.META_TOOLS) do
    if m.always_visible then M.ALWAYS_VISIBLE[m.name] = true end
    if m.mutates_surface then M.MUTATES_SURFACE[m.name] = true end
end

function M.supports_traits(session)
    local mode = session and session.access_mode or "tools_only"
    return mode == "any" or mode == "traits"
end

-- Resolve a tool name against the already-seen set. Meta-tool names win:
-- a dynamic tool colliding with a meta-tool gets the `tool_` prefix.
function M.resolve_tool_name(name, seen)
    if seen and seen[name] then return "tool_" .. name end
    return name
end

-- Build a name set from a list of tool specs (each having a `name` field).
function M.names_from_tool_list(list)
    local names = {}
    if type(list) ~= "table" then return names end
    for _, t in ipairs(list) do
        if t and t.name then names[t.name] = true end
    end
    return names
end

-- Compute the tool list visible to this session:
--   * always_visible meta-tools always appear.
--   * Full meta-tool surface only in any/traits modes.
--   * tools_only mode: resolve tool_filter against registry tool catalog.
--   * any/traits mode: materialize active trait set via agent compiler.
-- Name collisions between meta-tools and resolved tools are resolved in
-- favor of the meta-tool (dynamic tool gets `tool_` prefix to disambiguate).
function M.build(session)
    local tool_list = {}
    local seen = {}
    local supports = M.supports_traits(session)

    for _, m in ipairs(M.META_TOOLS) do
        if supports or m.always_visible then
            table.insert(tool_list, {
                name = m.name,
                description = m.description,
                inputSchema = m.inputSchema,
            })
            seen[m.name] = true
        end
    end

    local resolved, resolve_err
    if session.access_mode == "tools_only" then
        resolved = mcp_traits.resolve_tools_only(session)
    else
        resolved, resolve_err = mcp_traits.resolve(session)
        if resolve_err then
            return tool_list, { registry = {}, context = {} }, resolve_err
        end
    end

    local name_to_registry = {}
    local name_to_context = {}
    local name_to_schema = {}
    for name, tool in pairs(resolved.tools or {}) do
        name = M.resolve_tool_name(name, seen)
        seen[name] = true

        local schema = tool.schema or { type = "object" }
        table.insert(tool_list, {
            name = name,
            description = tool.description or name,
            inputSchema = schema,
        })
        name_to_registry[name] = tool.registry_id
        name_to_context[name] = tool.context or {}
        name_to_schema[name] = schema
    end

    return tool_list, { registry = name_to_registry, context = name_to_context, schema = name_to_schema }
end

-- Snapshot the set of tool names visible to a session, used by use_trait /
-- drop_trait to diff the surface around an activation.
function M.snapshot_names(session)
    local list, _, resolve_err = M.build(session)
    if resolve_err then return nil, resolve_err end
    return M.names_from_tool_list(list)
end

function M.diff_added(before, after)
    local added = {}
    for name, _ in pairs(after or {}) do
        if not (before and before[name]) then table.insert(added, name) end
    end
    table.sort(added)
    return added
end

function M.diff_removed(before, after)
    local removed = {}
    for name, _ in pairs(before or {}) do
        if not (after and after[name]) then table.insert(removed, name) end
    end
    table.sort(removed)
    return removed
end

return M
