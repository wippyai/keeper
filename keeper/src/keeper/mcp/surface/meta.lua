-- Meta-tool handlers for MCP sessions.
--
-- Meta-tools are the navigation/ergonomics layer an MCP client sees before
-- the dynamic tool catalog. They let the client inspect session state,
-- browse the trait catalog, and activate traits with diff feedback.
--
-- Each handler returns (result, err). `err ~= nil` surfaces as a JSON-RPC
-- tool error; successful results are JSON-encoded into the content text of
-- the tools/call response by the HTTP handler.

local registry = require("registry")

local mcp_traits = require("mcp_traits")
local mcp_authorize = require("mcp_authorize")
local surface = require("mcp_surface")
local dispatch = require("mcp_dispatch")
local tools_disc = require("tools_disc")
local validate = require("mcp_validate")

local M = {}

local function count_keys(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

local function format_trait_summary(catalog, active_set)
    local out = {}
    for _, t in ipairs(catalog) do
        table.insert(out, {
            id = t.id,
            name = t.name,
            description = t.description,
            tools = t.tools,
            sub_traits = t.sub_traits,
            has_prompt = t.has_prompt,
            active = active_set[t.id] == true,
        })
    end
    return out
end

function M.session_info(_, session)
    local info = {
        access_mode = session.access_mode,
        label = session.label,
        identity = session.identity,
        default_active = session.default_active or {},
    }

    -- Build the surface first so mcp_traits.resolve gets a chance to prune
    -- and rewrite any stale persisted trait ids. Subsequent get_active then
    -- returns the healed set, keeping session_info's fields consistent with
    -- the tool list the caller just received.
    local tool_list, _, resolve_err = surface.build(session)
    if resolve_err then
        info.tool_count = 0
        info.resolve_error = tostring(resolve_err)
    else
        info.tool_count = #tool_list
        local names = {}
        for _, t in ipairs(tool_list) do table.insert(names, t.name) end
        info.tool_names = names
    end

    if surface.supports_traits(session) then
        local catalog = mcp_traits.list_catalog(session)
        local active = mcp_traits.get_active(session) or {}
        local set = {}
        for _, id in ipairs(active) do set[id] = true end
        info.active_traits = active
        info.traits = format_trait_summary(catalog, set)
    else
        info.active_traits = {}
        info.traits = {}
    end

    return info
end

function M.list_traits(_, session)
    local catalog = mcp_traits.list_catalog(session)
    local active = mcp_traits.get_active(session) or {}
    local set = {}
    for _, id in ipairs(active) do set[id] = true end
    return {
        access_mode = session.access_mode,
        active_traits = active,
        default_active = session.default_active or {},
        traits = format_trait_summary(catalog, set),
    }
end

function M.describe_trait(args, session)
    if type(args) ~= "table" or type(args.id) ~= "string" or args.id == "" then
        return nil, "id required"
    end

    local trait_id = args.id
    local def, err = mcp_traits.describe(trait_id, session)
    if err then return nil, err end
    -- Vendor discovery reads only meta.name; our trait entries use
    -- meta.title. Fall back to the registry entry so the MCP response
    -- matches list_traits (which already prefers title).
    local name = def.name
    local description = def.description
    local entry = registry.get(trait_id)
    local sub_traits = (entry and entry.data and entry.data.traits) or {}
    if not name or name == "" or not description or description == "" then
        if entry and entry.meta then
            if not name or name == "" then
                name = entry.meta.title or entry.meta.name or ""
            end
            if not description or description == "" then
                description = entry.meta.comment or ""
            end
        end
    end
    return {
        id = def.id,
        name = name,
        description = description,
        prompt = def.prompt,
        tools = def.tools,
        sub_traits = sub_traits,
        build_func_id = def.build_func_id,
        prompt_func_id = def.prompt_func_id,
        step_func_id = def.step_func_id,
    }
end

function M.use_trait(args, session)
    if not surface.supports_traits(session) then
        return nil, "access_mode=" .. tostring(session.access_mode) .. " does not support trait selection"
    end
    local before, snap_err = surface.snapshot_names(session)
    if snap_err then return nil, snap_err end

    local result, err = mcp_traits.activate(session, args and args.ids or {})
    if err then return nil, err end

    local after, after_err = surface.snapshot_names(session)
    if after_err then return nil, after_err end

    return {
        active_traits = result.active,
        added_tools = surface.diff_added(before, after),
        tool_count = count_keys(after),
    }
end

function M.drop_trait(args, session)
    if not surface.supports_traits(session) then
        return nil, "access_mode=" .. tostring(session.access_mode) .. " does not support trait selection"
    end
    local before, snap_err = surface.snapshot_names(session)
    if snap_err then return nil, snap_err end

    local result, err = mcp_traits.deactivate(session, args and args.ids or {})
    if err then return nil, err end

    local after, after_err = surface.snapshot_names(session)
    if after_err then return nil, after_err end

    return {
        active_traits = result.active,
        removed_tools = surface.diff_removed(before, after),
        tool_count = count_keys(after),
    }
end

function M.activate_traits(args, session)
    local result, err = mcp_traits.activate(session, args and args.ids or {})
    if err then return nil, err end
    return result
end

function M.deactivate_traits(args, session)
    local result, err = mcp_traits.deactivate(session, args and args.ids or {})
    if err then return nil, err end
    return result
end

function M.set_traits(args, session)
    local result, err = mcp_traits.set_active(session, args and args.ids or {})
    if err then return nil, err end
    return result
end

function M.reset_traits(_, session)
    local result, err = mcp_traits.reset(session)
    if err then return nil, err end
    return result
end

local TOOL_META_TYPE = "tool"
local DEFAULT_LIST_LIMIT = 200

local list_contains = mcp_traits.list_contains

local function namespace_match(entry_ns, filter_ns)
    if not filter_ns or filter_ns == "" then return true end
    if entry_ns == filter_ns then return true end
    return entry_ns:sub(1, #filter_ns + 1) == filter_ns .. "."
end

function M.list_tools(args, session)
    args = args or {}
    local include_schema = args.include_schema
    if include_schema == nil then include_schema = true end
    local limit = tonumber(args.limit) or DEFAULT_LIST_LIMIT
    if limit < 1 then limit = 1 end

    local entries = registry.find({ ["meta.type"] = TOOL_META_TYPE }) or {}

    local out = {}
    for _, e in ipairs(entries) do
        if #out >= limit then break end
        local tags = (e.meta and e.meta.tags) or {}
        local ns = mcp_traits.namespace_of(e.id)
        local pass = namespace_match(ns, args.namespace)

        if pass and args.tag_all and #args.tag_all > 0 then
            for _, required in ipairs(args.tag_all) do
                if not list_contains(tags, required) then pass = false; break end
            end
        end
        if pass and args.tag_any and #args.tag_any > 0 then
            local any = false
            for _, t in ipairs(args.tag_any) do
                if list_contains(tags, t) then any = true; break end
            end
            pass = any
        end
        if pass then
            local allowed = mcp_traits.tool_allowed(session, e.id)
            if allowed then
                local entry_out = { id = e.id, tags = tags }
                if include_schema then
                    local schema = tools_disc.get_tool_schema(e.id)
                    if schema then
                        entry_out.name = schema.name
                        entry_out.title = schema.title
                        entry_out.description = schema.description
                        entry_out.input_schema = schema.schema
                    else
                        entry_out.name = (e.meta and e.meta.llm_alias) or e.id
                        entry_out.description = (e.meta and (e.meta.llm_description or e.meta.comment)) or ""
                    end
                else
                    entry_out.name = (e.meta and e.meta.llm_alias) or e.id
                    entry_out.description = (e.meta and (e.meta.llm_description or e.meta.comment)) or ""
                end
                table.insert(out, entry_out)
            end
        end
    end

    table.sort(out, function(a, b) return a.id < b.id end)
    return { count = #out, tools = out }
end

function M.call_tool(args, session)
    args = args or {}
    local id = args.id
    if type(id) ~= "string" or id == "" then
        return nil, "id is required"
    end

    local entry, rerr = registry.get(id)
    if not entry then
        return nil, rerr or ("tool not found: " .. id)
    end
    if not entry.meta or entry.meta.type ~= TOOL_META_TYPE then
        return nil, "entry is not a tool: " .. id
    end

    local allowed, allow_err = mcp_traits.tool_allowed(session, id)
    if not allowed then
        return nil, allow_err or ("tool not allowed by session filter: " .. id)
    end

    local arguments = args.arguments
    if arguments == nil then arguments = {} end
    if type(arguments) ~= "table" then
        return nil, "arguments must be an object"
    end

    local schema = tools_disc.get_tool_schema(id)
    if schema and schema.schema then
        local schema_err = validate.check(arguments, schema.schema)
        if schema_err then return nil, schema_err end
    end

    local call_allowed, call_err = mcp_authorize.tool_call(session, id, entry, arguments)
    if not call_allowed then
        return nil, call_err or ("tool not allowed by MCP scopes: " .. id)
    end

    local base_context = args.context
    if base_context ~= nil and type(base_context) ~= "table" then
        return nil, "context must be an object"
    end

    return dispatch.call(session, id, arguments, base_context, "mcp.call_tool")
end

M.HANDLERS = {
    session_info = M.session_info,
    list_traits = M.list_traits,
    describe_trait = M.describe_trait,
    use_trait = M.use_trait,
    drop_trait = M.drop_trait,
    activate_traits = M.activate_traits,
    deactivate_traits = M.deactivate_traits,
    set_traits = M.set_traits,
    reset_traits = M.reset_traits,
    list_tools = M.list_tools,
    call_tool = M.call_tool,
}

return M
