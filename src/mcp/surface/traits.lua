local registry = require("registry")
local json = require("json")

local traits_disc = require("traits_disc")
local tools_disc = require("tools_disc")
local compiler = require("compiler")
local mcp_tokens = require("mcp_tokens")

local M = {}

local TRAIT_META_TYPE = "agent.trait"
local TOOL_META_TYPE = "tool"

-- Helpers

local function to_set(list)
    local set = {}
    if type(list) ~= "table" then return set end
    for _, v in ipairs(list) do set[v] = true end
    return set
end

local function set_to_list(set)
    local list = {}
    for k, _ in pairs(set) do table.insert(list, k) end
    table.sort(list)
    return list
end

function M.list_contains(list, value)
    for _, v in ipairs(list or {}) do
        if v == value then return true end
    end
    return false
end
local list_contains = M.list_contains

function M.namespace_of(entry_id)
    if type(entry_id) ~= "string" then return "" end
    return entry_id:match("^([^:]+):") or ""
end
local namespace_of = M.namespace_of

-- Filter evaluation
--
-- filter shape: nil | { namespaces, tags_any, tags_all, include_ids, exclude_ids }
-- All criteria are ANDed except within each list (tags_any is OR, tags_all is AND).
-- include_ids unconditionally passes; exclude_ids unconditionally blocks.
local function filter_matches(filter, entry_id, tags)
    if filter == nil then return true end
    if type(filter) ~= "table" then return true end

    if filter.include_ids and #filter.include_ids > 0 and list_contains(filter.include_ids, entry_id) then
        return true
    end
    if filter.exclude_ids and #filter.exclude_ids > 0 and list_contains(filter.exclude_ids, entry_id) then
        return false
    end

    if filter.namespaces and #filter.namespaces > 0 then
        local ns = namespace_of(entry_id)
        local matched = false
        for _, allowed in ipairs(filter.namespaces) do
            if ns == allowed or ns:sub(1, #allowed + 1) == allowed .. "." then
                matched = true
                break
            end
        end
        if not matched then return false end
    end

    tags = tags or {}

    if filter.tags_all and #filter.tags_all > 0 then
        for _, required in ipairs(filter.tags_all) do
            if not list_contains(tags, required) then return false end
        end
    end

    if filter.tags_any and #filter.tags_any > 0 then
        local any = false
        for _, t in ipairs(filter.tags_any) do
            if list_contains(tags, t) then any = true; break end
        end
        if not any then return false end
    end

    return true
end

-- Exposed for tests.
M._filter_matches = filter_matches

-- Fetch raw registry entries for agent.trait so we can read meta.tags. The
-- discovery layer strips meta before returning TraitSpecs, which is why we
-- query the registry directly for filter evaluation.
local function fetch_trait_entries_with_meta()
    local entries = registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = TRAIT_META_TYPE,
    }) or {}
    return entries
end

-- Tools are kind=function.lua (not registry.entry), so .kind is not constrained.
local function fetch_tool_entries_with_meta()
    local entries = registry.find({
        ["meta.type"] = TOOL_META_TYPE,
    }) or {}
    return entries
end

-- Public filter helpers used by both catalog listing and validation.

function M.trait_allowed(session, trait_id)
    local entry, err = registry.get(trait_id)
    if not entry then return false, err or "trait not found: " .. tostring(trait_id) end
    if not entry.meta or entry.meta.type ~= TRAIT_META_TYPE then
        return false, "entry is not a trait: " .. tostring(trait_id)
    end
    local filter = session and session.trait_filter
    if not filter then return true end
    local tags = entry.meta.tags or {}
    return filter_matches(filter, trait_id, tags)
end

function M.tool_allowed(session, tool_id)
    local entry, err = registry.get(tool_id)
    if not entry then return false, err or "tool not found: " .. tostring(tool_id) end
    if not entry.meta or entry.meta.type ~= TOOL_META_TYPE then
        return false, "entry is not a tool: " .. tostring(tool_id)
    end
    local filter = session and session.tool_filter
    if not filter then return true end
    local tags = entry.meta.tags or {}
    return filter_matches(filter, tool_id, tags)
end

-- Catalog

-- Return traits visible to this session (filter resolved against registry).
function M.list_catalog(session)
    local filter = session and session.trait_filter
    local entries = fetch_trait_entries_with_meta()

    local result = {}
    for _, e in ipairs(entries) do
        local tags = (e.meta and e.meta.tags) or {}
        if filter_matches(filter, e.id, tags) then
            local data = e.data or {}
            local prompt = data.prompt or ""
            table.insert(result, {
                id = e.id,
                name = (e.meta and (e.meta.title or e.meta.name)) or "",
                description = (e.meta and e.meta.comment) or "",
                tags = tags,
                tools = data.tools or {},
                sub_traits = data.traits or {},
                has_prompt = prompt ~= "",
                prompt_preview = string.sub(prompt, 1, 200),
            })
        end
    end
    return result
end

-- Full trait detail; enforces filter membership.
function M.describe(trait_id, session)
    local ok, err = M.trait_allowed(session, trait_id)
    if not ok then
        return nil, err or ("trait not allowed by filter: " .. tostring(trait_id))
    end
    local def, derr = traits_disc.get_by_id(trait_id)
    if not def then return nil, derr end
    return def
end

-- Mode helpers

local function access_mode(session)
    return (session and session.access_mode) or "tools_only"
end

local function supports_traits(session)
    local mode = access_mode(session)
    return mode == "any" or mode == "traits"
end

-- Active set (persisted per token). Falls back to default_active when the
-- session has never written state.
function M.get_active(session)
    if not session or not supports_traits(session) then return {} end

    local current, err = mcp_tokens.get_active_traits(session.token)
    if err then return {}, err end
    if current == nil then
        return session.default_active or {}
    end
    return current
end

-- Validate that every id in `trait_ids` passes the session filter. Prevents
-- the LLM from activating a trait it was not authorized for.
function M.validate_trait_ids(session, trait_ids)
    if type(trait_ids) ~= "table" then return false, "trait_ids must be array" end

    local seen = {}
    for _, id in ipairs(trait_ids) do
        if type(id) ~= "string" or id == "" then return false, "invalid trait id" end
        if seen[id] then return false, "duplicate trait id: " .. id end
        seen[id] = true

        local allowed, err = M.trait_allowed(session, id)
        if not allowed then
            return false, err or ("trait not allowed: " .. id)
        end
    end
    return true
end

-- Mutation API

function M.set_active(session, trait_ids)
    if not supports_traits(session) then
        return nil, "access_mode=" .. access_mode(session) .. " does not support trait selection"
    end
    local ok, err = M.validate_trait_ids(session, trait_ids)
    if not ok then return nil, err end
    local _, serr = mcp_tokens.set_active_traits(session.token, trait_ids)
    if serr then return nil, serr end
    return { active = trait_ids }
end

function M.activate(session, trait_ids)
    if not supports_traits(session) then
        return nil, "access_mode=" .. access_mode(session) .. " does not support trait selection"
    end
    local ok, err = M.validate_trait_ids(session, trait_ids or {})
    if not ok then return nil, err end
    local current = M.get_active(session) or {}
    local set = to_set(current)
    for _, id in ipairs(trait_ids or {}) do set[id] = true end
    local merged = set_to_list(set)
    local _, serr = mcp_tokens.set_active_traits(session.token, merged)
    if serr then return nil, serr end
    return { active = merged }
end

function M.deactivate(session, trait_ids)
    if not supports_traits(session) then
        return nil, "access_mode=" .. access_mode(session) .. " does not support trait selection"
    end
    local current = M.get_active(session) or {}
    local remove = to_set(trait_ids or {})
    local kept = {}
    for _, id in ipairs(current) do
        if not remove[id] then table.insert(kept, id) end
    end
    local _, serr = mcp_tokens.set_active_traits(session.token, kept)
    if serr then return nil, serr end
    return { active = kept }
end

function M.reset(session)
    if not supports_traits(session) then
        return nil, "access_mode=" .. access_mode(session) .. " does not support trait selection"
    end
    local default = session.default_active or {}
    local _, serr = mcp_tokens.set_active_traits(session.token, default)
    if serr then return nil, serr end
    return { active = default }
end

-- Strip ids that no longer resolve to a registered trait. Persisted active-sets
-- may reference traits that were deleted between requests; passing those to
-- compile() would kill the entire tool surface. We filter silently — the user
-- can observe the current active_traits via list_traits.
local function prune_missing_traits(active)
    local kept = {}
    local dropped = {}
    for _, id in ipairs(active or {}) do
        local entry = registry.get(id)
        if entry and entry.meta and entry.meta.type == TRAIT_META_TYPE then
            table.insert(kept, id)
        else
            table.insert(dropped, id)
        end
    end
    return kept, dropped
end

M._prune_missing_traits = prune_missing_traits

-- Materialization (any/traits modes): feed active trait set through the agent
-- compiler so MCP tooling shares the exact resolution pipeline agents use.
function M.resolve(session)
    local active = M.get_active(session) or {}
    local pruned, dropped = prune_missing_traits(active)

    -- If the persisted active set contained stale ids, rewrite the persisted
    -- state so subsequent reads converge. Skipped when session storage is not
    -- writable (e.g., access_mode that does not persist active sets).
    if #dropped > 0 and supports_traits(session) and session and session.token then
        mcp_tokens.set_active_traits(session.token, pruned)
    end

    if #pruned == 0 then
        return { tools = {}, prompt = "", prompt_funcs = {}, step_funcs = {} }
    end

    local synthetic = {
        id = "keeper.mcp.session:" .. (session.label or "unknown"),
        traits = pruned,
        tools = {},
        context = {
            _mcp_session = true,
            mcp_token_label = session.label,
            mcp_identity = session.identity,
        },
    }

    local compiled, err = compiler.compile(synthetic)
    if err or not compiled then
        return nil, "compile failed: " .. tostring(err)
    end

    local tools = {}
    for name, tool in pairs(compiled.tools or {}) do tools[name] = tool end

    return {
        tools = tools,
        prompt = compiled.prompt or "",
        prompt_funcs = compiled.prompt_funcs or {},
        step_funcs = compiled.step_funcs or {},
    }
end

-- tools_only mode: resolve the tool_filter against the registry tool catalog
-- and materialize matching tool ids via tools_disc, bypassing the trait layer.
function M.resolve_tools_only(session)
    local filter = session and session.tool_filter
    local entries = fetch_tool_entries_with_meta()

    local tools = {}
    for _, e in ipairs(entries) do
        local tags = (e.meta and e.meta.tags) or {}
        if filter_matches(filter, e.id, tags) then
            local schema, err = tools_disc.get_tool_schema(e.id)
            if schema then
                tools[schema.name] = {
                    name = schema.name,
                    description = schema.description,
                    schema = schema.schema,
                    registry_id = e.id,
                    meta = schema.meta or {},
                    context = {
                        _mcp_session = true,
                        mcp_token_label = session.label,
                        mcp_identity = session.identity,
                    },
                }
            end
        end
    end
    return { tools = tools, prompt = "", prompt_funcs = {}, step_funcs = {} }
end

return M
