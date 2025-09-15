local registry = require("registry")
local json = require("json")

local function handler(params)
    local response = {
        success = false,
        agents = {},
        error = nil,
        count = 0,
        filters_applied = {}
    }

    params = params or {}
    local limit = params.limit or 100

    if limit < 1 or limit > 1000 then
        response.error = "Invalid limit: must be between 1 and 1000"
        return response
    end

    local criteria = {
        [".kind"] = "registry.entry",
        ["meta.type"] = "agent.gen1"
    }

    if params.namespace then
        criteria[".ns"] = params.namespace
        response.filters_applied.namespace = params.namespace
    end

    if params.model then
        criteria["data.model"] = params.model
        response.filters_applied.model = params.model
    end

    local entries, err = registry.find(criteria)
    if err then
        response.error = "Failed to query registry: " .. tostring(err)
        return response
    end

    if not entries or #entries == 0 then
        response.success = true
        response.agents = {}
        response.count = 0
        return response
    end

    local filtered_agents = {}

    for _, entry in ipairs(entries) do
        if params.class then
            local matches_class = false
            if entry.meta and entry.meta.class then
                if type(entry.meta.class) == "string" then
                    matches_class = entry.meta.class == params.class
                elseif type(entry.meta.class) == "table" then
                    for _, cls in ipairs(entry.meta.class) do
                        if cls == params.class then
                            matches_class = true
                            break
                        end
                    end
                end
            end
            if not matches_class then
                goto continue
            end
        end

        if params.has_tools ~= nil then
            local has_tools = entry.data and entry.data.tools and #entry.data.tools > 0
            if params.has_tools ~= has_tools then
                goto continue
            end
        end

        if params.has_delegates ~= nil then
            local has_delegates = entry.data and entry.data.delegate and next(entry.data.delegate) ~= nil
            if params.has_delegates ~= has_delegates then
                goto continue
            end
        end

        local agent = {
            id = entry.id,
            title = entry.meta and entry.meta.title or "",
            comment = entry.meta and entry.meta.comment or "",
            model = entry.data and entry.data.model or "",
            class = entry.meta and entry.meta.class or nil,
            icon = entry.meta and entry.meta.icon or nil,
            tools_count = entry.data and entry.data.tools and #entry.data.tools or 0,
            traits_count = entry.data and entry.data.traits and #entry.data.traits or 0,
            delegates_count = 0,
            has_memory = entry.data and entry.data.memory and #entry.data.memory > 0 or false,
            visible = false
        }

        -- Check if agent is visible (has public class)
        if entry.meta and entry.meta.class then
            if type(entry.meta.class) == "string" then
                agent.visible = entry.meta.class == "public"
            elseif type(entry.meta.class) == "table" then
                for _, cls in ipairs(entry.meta.class) do
                    if cls == "public" then
                        agent.visible = true
                        break
                    end
                end
            end
        end

        if entry.data and entry.data.delegate then
            for _ in pairs(entry.data.delegate) do
                agent.delegates_count = agent.delegates_count + 1
            end
        end

        table.insert(filtered_agents, agent)

        ::continue::
    end

    table.sort(filtered_agents, function(a, b)
        return a.id < b.id
    end)

    if limit < #filtered_agents then
        local limited_agents = {}
        for i = 1, limit do
            table.insert(limited_agents, filtered_agents[i])
        end
        filtered_agents = limited_agents
    end

    if params.class then
        response.filters_applied.class = params.class
    end
    if params.has_tools ~= nil then
        response.filters_applied.has_tools = params.has_tools
    end
    if params.has_delegates ~= nil then
        response.filters_applied.has_delegates = params.has_delegates
    end

    response.success = true
    response.agents = filtered_agents
    response.count = #filtered_agents
    response.total_before_limit = #entries
    response.limit = limit
    return response
end

return { handler = handler }