local http = require("http")
local json = require("json")
local registry = require("registry")
local security = require("security")

local function handler()
    -- Get response object
    local res = http.response()
    local req = http.request()
    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    -- Security check: Ensure user is authenticated
    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({ success = false, error = "Authentication required" })
        return
    end

    -- Get query parameters for pagination and filtering
    local limit = tonumber(req:query("limit")) or 500
    local offset = tonumber(req:query("offset")) or 0
    local search = req:query("search") -- Optional search filter
    local class_filter = req:query("class") -- Optional class filter

    -- Get a snapshot of the registry
    local snapshot, err = registry.snapshot()
    if not snapshot then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to get registry snapshot: " .. (err or "unknown error")
        })
        return
    end

    -- Get all entries
    local all_entries = snapshot:entries()

    -- Filter for agents only (registry.entry with type agent.gen1)
    local agents = {}
    for _, entry in ipairs(all_entries) do
        if entry.kind == "registry.entry" and
           entry.meta and
           entry.meta.type == "agent.gen1" then

            -- Apply search filter if specified
            local matches_search = true
            if search and search ~= "" then
                local search_lower = string.lower(search)
                local title = string.lower(entry.meta.title or "")
                local name = string.lower(entry.meta.name or "")
                local id = string.lower(entry.id or "")
                local comment = string.lower(entry.meta.comment or "")

                matches_search = string.find(title, search_lower, 1, true) or
                               string.find(name, search_lower, 1, true) or
                               string.find(id, search_lower, 1, true) or
                               string.find(comment, search_lower, 1, true)
            end

            -- Apply class filter if specified
            local matches_class = true
            if class_filter and class_filter ~= "" then
                matches_class = false
                if entry.meta.class then
                    if type(entry.meta.class) == "string" then
                        matches_class = entry.meta.class == class_filter or
                                      string.find(entry.meta.class, class_filter, 1, true)
                    elseif type(entry.meta.class) == "table" then
                        for _, cls in ipairs(entry.meta.class) do
                            if cls == class_filter then
                                matches_class = true
                                break
                            end
                        end
                    end
                end
            end

            if matches_search and matches_class then
                table.insert(agents, entry)
            end
        end
    end

    local total_count = #agents

    -- Sort agents by title/name
    table.sort(agents, function(a, b)
        local a_name = (a.meta and (a.meta.title or a.meta.name)) or a.id or ""
        local b_name = (b.meta and (b.meta.title or b.meta.name)) or b.id or ""
        return string.lower(a_name) < string.lower(b_name)
    end)

    -- Apply pagination
    local paged_entries = {}
    local end_index = math.min(offset + limit, total_count)

    for i = offset + 1, end_index do
        local entry = agents[i]
        if entry then -- Check if entry exists
            -- Extract model information
            local model = nil
            local max_tokens = nil
            local temperature = nil
            local thinking_effort = nil

            if entry.data then
                model = entry.data.model
                max_tokens = entry.data.max_tokens
                temperature = entry.data.temperature
                thinking_effort = entry.data.thinking_effort
            end

            -- Count tools, traits, delegates
            local tools_count = 0
            local traits_count = 0
            local delegates_count = 0
            local memory_count = 0
            local start_prompts_count = 0

            if entry.data then
                if entry.data.tools and type(entry.data.tools) == "table" then
                    tools_count = #entry.data.tools
                end
                if entry.data.traits and type(entry.data.traits) == "table" then
                    traits_count = #entry.data.traits
                end
                if entry.data.delegates and type(entry.data.delegates) == "table" then
                    delegates_count = #entry.data.delegates
                end
                if entry.data.memory and type(entry.data.memory) == "table" then
                    memory_count = #entry.data.memory
                end
                if entry.data.start_prompts and type(entry.data.start_prompts) == "table" then
                    start_prompts_count = #entry.data.start_prompts
                end
            end

            -- Format the output
            table.insert(paged_entries, {
                id = entry.id,
                title = entry.meta.title or "",
                name = entry.meta.name or "",
                description = entry.meta.comment or "",
                class = entry.meta.class or {},
                tags = entry.meta.tags or {},
                group = entry.meta.group or {},
                -- Model information
                model = model,
                max_tokens = max_tokens,
                temperature = temperature,
                thinking_effort = thinking_effort,
                -- Component counts
                tools_count = tools_count,
                traits_count = traits_count,
                delegates_count = delegates_count,
                memory_count = memory_count,
                start_prompts_count = start_prompts_count,
                -- Has memory contract
                has_memory_contract = entry.data and entry.data.memory_contract and
                                    entry.data.memory_contract.implementation_id and
                                    entry.data.memory_contract.implementation_id ~= ""
            })
        end
    end

    -- Return JSON response
    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        count = #paged_entries,
        total = total_count,
        offset = offset,
        limit = limit,
        search = search or nil,
        class_filter = class_filter or nil,
        has_more = end_index < total_count,
        agents = paged_entries
    })
end

return {
    handler = handler
}