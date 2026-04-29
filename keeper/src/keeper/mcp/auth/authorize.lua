local registry = require("registry")
local sql = require("sql")

local consts = require("mcp_consts")

local M = {}

local ROOT_SCOPE = "mcp.root"
local INTROSPECT_SCOPE = "mcp.introspect"

local TOOL_SCOPE_FALLBACKS = {
    ["app.agents:navigate_to"] = { "app.ui" },

    ["keeper.agents.tools:data"] = { "state.read" },
    ["keeper.agents.tools:dataflow"] = { "state.read" },
    ["keeper.agents.tools:manager"] = { "agents.read" },
    ["keeper.agents.tools:run_test"] = { "tests.run" },
    ["keeper.agents.tools:sessions"] = { "state.read" },
    ["keeper.agents.tools:system"] = { "pm.read", "logger.read" },
    ["keeper.agents.tools:test_endpoint"] = { "tests.run" },
    ["keeper.agents.tools.task:debug"] = { "tasks.read" },

    ["keeper.components.tools:build_component"] = { "components.build" },
    ["keeper.components.tools:fs"] = { "components.read" },
    ["keeper.components.tools:screenshot_ui"] = { "components.capture" },
    ["keeper.components.tools:ui"] = { "components.capture" },

    ["keeper.git.tools:push"] = { "registry.write", "registry.sync" },
    ["keeper.git.tools:rebuild"] = { "state.read" },

    ["keeper.gov.tools:sync_from_fs"] = { "registry.sync" },
    ["keeper.gov.tools:sync_to_fs"] = { "registry.sync" },

    ["keeper.knowledge.tools:fetch_docs"] = { "knowledge.read" },
    ["keeper.knowledge.tools:kb_read"] = { "knowledge.read" },
    ["keeper.knowledge.tools:kb_write"] = { "knowledge.write" },

    ["keeper.state.tools:abandon"] = { "registry.write" },
    ["keeper.state.tools:branch"] = { "state.read" },
    ["keeper.state.tools:compare"] = { "state.read" },
    ["keeper.state.tools:edit"] = { "state.read" },
    ["keeper.state.tools:explore"] = { "state.read" },
    ["keeper.state.tools:get_entries"] = { "state.read" },
    ["keeper.state.tools:push"] = { "registry.write", "registry.sync" },
    ["keeper.state.tools:reset"] = { "registry.write" },

    ["keeper.task.tools:e2e_launch"] = { "tasks.run" },
    ["keeper.task.tools:read_context"] = { "tasks.read" },
    ["keeper.task.tools:save_context"] = { "tasks.write" },
    ["keeper.task.tools:step_block"] = { "tasks.write" },
    ["keeper.task.tools:step_done"] = { "tasks.write" },
    ["keeper.task.tools:write_plan"] = { "tasks.write" },
    ["keeper.task.tools:write_spec"] = { "tasks.write" },
}

local TOOL_ACTION_SCOPE_FALLBACKS = {
    ["keeper.components.tools:fs"] = {
        str_replace = "components.write",
        create = "components.write",
        rewrite = "components.write",
        delete = "components.write",
    },
    ["keeper.state.tools:branch"] = {
        set = "state.write",
        clear = "state.write",
    },
    ["keeper.state.tools:edit"] = {
        str_replace = "registry.write",
        create = "registry.write",
        delete = "registry.write",
    },
}

local function raw_array_get(list, index)
    if type(list) ~= "table" then return nil end
    return rawget(list, index)
end

local function has_items(list)
    if type(list) ~= "table" then return false end
    return raw_array_get(list, 1) ~= nil
end

local function list_to_set(list)
    local set = {}
    if type(list) ~= "table" then return set end
    local i = 1
    while true do
        local value = raw_array_get(list, i)
        if value == nil then break end
        if type(value) == "string" and value ~= "" then
            set[value] = true
        end
        i = i + 1
    end
    return set
end

local function meta_mcp(entry)
    local meta = entry and entry.meta
    if type(meta) ~= "table" then return {} end
    if type(meta.mcp) == "table" then return meta.mcp end
    return {}
end

local function normalize_scope_list(scopes)
    if type(scopes) ~= "table" then return nil end
    local out = {}
    local count = 0
    local i = 1
    while true do
        local scope = raw_array_get(scopes, i)
        if scope == nil then break end
        if type(scope) == "string" and scope ~= "" then
            count = count + 1
            out[count] = scope
        end
        i = i + 1
    end
    return out
end

local function normalize_action_scope_value(scopes)
    if type(scopes) ~= "string" then return nil end
    if scopes == "" then return {} end
    return { scopes }
end

local function required_scopes_from_entry(entry)
    if type(entry) ~= "table" then return nil end
    local meta = entry.meta or {}
    local mcp = meta_mcp(entry)

    return normalize_scope_list(mcp.required_scopes)
        or normalize_scope_list(meta.required_scopes)
        or TOOL_SCOPE_FALLBACKS[entry.id]
end

local function action_scope_map(entry)
    if type(entry) ~= "table" then return nil end
    if entry and TOOL_ACTION_SCOPE_FALLBACKS[entry.id] then return TOOL_ACTION_SCOPE_FALLBACKS[entry.id] end
    local mcp = meta_mcp(entry)
    if type(mcp.action_scopes) == "table" then return mcp.action_scopes end
    local meta = entry.meta or {}
    if type(meta.action_scopes) == "table" then return meta.action_scopes end
    return nil
end

local function action_key(arguments)
    if type(arguments) ~= "table" then return nil end
    local key = arguments.command or arguments.action
    if type(key) == "string" and key ~= "" then return key end
    return nil
end

function M.required_scopes(tool_id, entry)
    if not entry and tool_id then
        entry = registry.get(tool_id)
    end
    return required_scopes_from_entry(entry) or {}
end

function M.scope_set(session)
    if type(session) ~= "table" then return {} end
    local scopes = session.scopes
    if type(scopes) ~= "table" and type(scopes) ~= "string" then return {} end
    return list_to_set(scopes)
end

function M.is_root(session)
    if not session then return false end
    if session.internal_root == true then return true end
    return M.scope_set(session)[ROOT_SCOPE] == true
end

function M.has_scope(session, scope)
    if M.is_root(session) then return true end
    return M.scope_set(session)[scope] == true
end

local function require_normalized_scopes(session, scopes)
    if M.is_root(session) then return true end
    local set = M.scope_set(session)
    local missing = ""
    local missing_count = 0
    local i = 1
    while true do
        local scope = raw_array_get(scopes, i)
        if scope == nil then break end
        if type(scope) == "string" and scope ~= "" and not set[scope] then
            if missing_count > 0 then
                missing = missing .. ", " .. scope
            else
                missing = scope
            end
            missing_count = missing_count + 1
        end
        i = i + 1
    end
    if missing_count > 0 then
        return false, "insufficient MCP scope: requires " .. missing
    end
    return true
end

local function require_scopes_with_set(is_root, set, scopes)
    if is_root then return true end
    local missing = ""
    local missing_count = 0
    local i = 1
    while true do
        local scope = raw_array_get(scopes, i)
        if scope == nil then break end
        if type(scope) == "string" and scope ~= "" and not set[scope] then
            if missing_count > 0 then
                missing = missing .. ", " .. scope
            else
                missing = scope
            end
            missing_count = missing_count + 1
        end
        i = i + 1
    end
    if missing_count > 0 then
        return false, "insufficient MCP scope: requires " .. missing
    end
    return true
end

function M.require_scopes(session, scopes)
    scopes = normalize_scope_list(scopes) or {}
    return require_normalized_scopes(session, scopes)
end

function M.can_introspect(session)
    if M.is_root(session) then return true end
    if M.has_scope(session, INTROSPECT_SCOPE) then return true end
    return has_items(session and session.scopes)
end

function M.tool(session, tool_id, entry)
    if type(tool_id) ~= "string" or tool_id == "" then
        return false, "tool id required"
    end
    if not entry then
        local got, err = registry.get(tool_id)
        if not got then return false, err or "tool not found: " .. tool_id end
        entry = got
    end
    if not entry.meta or entry.meta.type ~= "tool" then
        return false, "entry is not a tool: " .. tool_id
    end

    local required = M.required_scopes(tool_id, entry)
    if not has_items(required) and consts.STRICT_TOOL_SCOPES then
        return false, "tool has no MCP required_scopes: " .. tool_id
    end
    local ok, err = M.require_scopes(session, required)
    if not ok then return false, err end
    return true, nil, entry
end

function M.tool_call(session, tool_id, entry, arguments)
    if type(tool_id) ~= "string" or tool_id == "" then
        return false, "tool id required"
    end
    if not entry then
        local got, err = registry.get(tool_id)
        if not got then return false, err or "tool not found: " .. tool_id end
        entry = got
    end
    if type(entry) ~= "table" then
        return false, "tool entry unavailable: " .. tostring(tool_id)
    end
    if not entry.meta or entry.meta.type ~= "tool" then
        return false, "entry is not a tool: " .. tool_id
    end

    local set = M.scope_set(session)
    local is_root = session and session.internal_root == true or set[ROOT_SCOPE] == true
    local required = M.required_scopes(tool_id, entry)
    if not has_items(required) and consts.STRICT_TOOL_SCOPES then
        return false, "tool has no MCP required_scopes: " .. tool_id
    end
    local ok, err = require_scopes_with_set(is_root, set, required)
    if not ok then return false, err end

    local scopes_by_action = action_scope_map(entry)
    if not scopes_by_action then return true end

    local key = action_key(arguments)
    local scopes = nil
    if key ~= nil then
        scopes = rawget(scopes_by_action, key)
    end
    if scopes == nil then
        scopes = rawget(scopes_by_action, "_default")
    end
    if scopes == nil then return true end
    scopes = normalize_action_scope_value(scopes)
    if type(scopes) ~= "table" then
        return false, "invalid MCP action scope list for " .. tostring(tool_id)
    end
    if is_root then return true end
    local missing = ""
    local missing_count = 0
    local i = 1
    while true do
        local scope = raw_array_get(scopes, i)
        if scope == nil then break end
        if type(scope) == "string" and scope ~= "" and not set[scope] then
            if missing_count > 0 then
                missing = missing .. ", " .. scope
            else
                missing = scope
            end
            missing_count = missing_count + 1
        end
        i = i + 1
    end
    if missing_count > 0 then
        return false, "insufficient MCP scope: requires " .. missing
    end
    return true
end

function M.filter_matches(filter, entry_id, tags)
    if filter == nil then return true end
    if type(filter) ~= "table" then return false end

    if filter.exclude_ids and #filter.exclude_ids > 0 then
        for _, id in ipairs(filter.exclude_ids) do
            if id == entry_id then return false end
        end
    end

    if filter.include_ids and #filter.include_ids > 0 then
        for _, id in ipairs(filter.include_ids) do
            if id == entry_id then return true end
        end
        return false
    end

    if filter.namespaces and #filter.namespaces > 0 then
        local ns = type(entry_id) == "string" and (entry_id:match("^([^:]+):") or "") or ""
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
        local tag_set = list_to_set(tags)
        for _, required in ipairs(filter.tags_all) do
            if not tag_set[required] then return false end
        end
    end

    if filter.tags_any and #filter.tags_any > 0 then
        local tag_set = list_to_set(tags)
        local any = false
        for _, tag in ipairs(filter.tags_any) do
            if tag_set[tag] then any = true; break end
        end
        if not any then return false end
    end

    return true
end

function M.validate_subject(session)
    if not session or not session.identity or session.identity == "" then
        return false, "MCP session identity required"
    end
    if session.internal_root == true then return true end

    local db, db_err = sql.get(consts.DB_ID)
    if db_err then return false, "db unavailable: " .. tostring(db_err) end
    local rows, q_err = db:query([[
        SELECT user_id, status FROM app_users WHERE user_id = ? LIMIT 1
    ]], { session.identity })
    db:release()

    if q_err then return false, "user lookup failed: " .. tostring(q_err) end
    if not rows or #rows == 0 then
        return false, "MCP token subject not found: " .. tostring(session.identity)
    end
    if rows[1].status ~= "active" then
        return false, "MCP token subject is not active: " .. tostring(session.identity)
    end
    return true
end

function M.broker_key(session)
    if session and session.token_hash and session.token_hash ~= "" then
        return session.token_hash
    end
    return nil
end

return M
