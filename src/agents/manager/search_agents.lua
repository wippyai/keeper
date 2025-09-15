local registry = require("registry")
local json = require("json")
local agent_registry = require("agent_registry")
local llm = require("llm")

local function handler(params)
    local response = {
        success = false,
        query = params.query,
        agents = {},
        total_searched = 0,
        error = nil
    }

    if not params.query or type(params.query) ~= "string" or params.query:gsub("%s", "") == "" then
        response.error = "Missing or empty query parameter"
        return response
    end

    local limit = params.limit or 5
    local include_scores = params.include_scores or false
    local filters = params.filters or {}

    -- Build search criteria based on filters
    local criteria = {
        [".kind"] = "registry.entry",
        ["meta.type"] = "agent.gen1"
    }

    if filters.namespace then
        criteria[".ns"] = filters.namespace
    end

    if filters.model then
        criteria["data.model"] = filters.model
    end

    -- Get all matching agents from registry
    local entries, err = registry.find(criteria)
    if err then
        response.error = "Failed to search registry: " .. tostring(err)
        return response
    end

    if not entries or #entries == 0 then
        response.success = true
        response.agents = {}
        response.total_searched = 0
        return response
    end

    -- Apply additional filters that can't be done at registry level
    local filtered_agents = {}
    for _, entry in ipairs(entries) do
        -- Skip private agents
        if entry.meta and entry.meta.private then
            goto continue
        end

        -- Filter by class if specified
        if filters.class then
            local matches_class = false
            if entry.meta and entry.meta.class then
                if type(entry.meta.class) == "string" then
                    matches_class = entry.meta.class == filters.class
                elseif type(entry.meta.class) == "table" then
                    for _, cls in ipairs(entry.meta.class) do
                        if cls == filters.class then
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

        -- Filter by has_tools if specified
        if filters.has_tools ~= nil then
            local has_tools = entry.data and entry.data.tools and #entry.data.tools > 0
            if filters.has_tools ~= has_tools then
                goto continue
            end
        end

        -- Filter by has_delegates if specified
        if filters.has_delegates ~= nil then
            local has_delegates = entry.data and entry.data.delegates and #entry.data.delegates > 0
            if filters.has_delegates ~= has_delegates then
                goto continue
            end
        end

        -- Filter by has_traits if specified
        if filters.has_traits ~= nil then
            local has_traits = entry.data and entry.data.traits and #entry.data.traits > 0
            if filters.has_traits ~= has_traits then
                goto continue
            end
        end

        -- Build agent info for semantic matching
        local agent_info = {
            id = entry.id,
            name = entry.meta and entry.meta.name or "",
            title = entry.meta and entry.meta.title or "",
            comment = entry.meta and entry.meta.comment or "",
            description = entry.meta and entry.meta.description or "",
            class = entry.meta and entry.meta.class or {},
            model = entry.data and entry.data.model or "",
            tools_count = entry.data and entry.data.tools and #entry.data.tools or 0,
            traits_count = entry.data and entry.data.traits and #entry.data.traits or 0,
            delegates_count = entry.data and entry.data.delegates and #entry.data.delegates or 0,
            has_memory = entry.data and entry.data.memory and #entry.data.memory > 0 or false
        }

        table.insert(filtered_agents, agent_info)

        ::continue::
    end

    response.total_searched = #filtered_agents

    if #filtered_agents == 0 then
        response.success = true
        response.agents = {}
        return response
    end

    -- If only one agent found, return it directly
    if #filtered_agents == 1 then
        local agent = filtered_agents[1]
        if include_scores then
            agent.relevance_score = 1.0
            agent.match_reason = "Only matching agent found"
        end
        response.success = true
        response.agents = {agent}
        return response
    end

    -- Use LLM for semantic ranking when multiple agents found
    local ranking_prompt = string.format([[
You are an agent selection specialist. Analyze the user's query and rank the available agents by relevance.

User Query: "%s"

Available Agents:
%s

Rank ALL agents by relevance to the user's query. Consider:
1. How well the agent's description matches the query intent
2. The agent's capabilities (tools, traits, delegates)
3. The agent's specialization and focus area
4. Whether the agent can fulfill the user's specific needs

Return a JSON array of ALL agents, ordered from most to least relevant, with relevance scores (0.0-1.0) and brief match explanations.

Format:
[
  {
    "id": "agent_id",
    "relevance_score": 0.95,
    "match_reason": "Perfect match for X because Y"
  },
  ...
]
]], params.query, json.encode(filtered_agents))

    local ranking_schema = {
        type = "array",
        items = {
            type = "object",
            properties = {
                id = {type = "string"},
                relevance_score = {type = "number", minimum = 0, maximum = 1},
                match_reason = {type = "string"}
            },
            required = {"id", "relevance_score", "match_reason"}
        }
    }

    local ranking_response, llm_err = llm.structured_output(ranking_schema, ranking_prompt, {
        model = "gpt-4.1",
        temperature = 0.1
    })

    if llm_err or not ranking_response or not ranking_response.result then
        -- Fallback: return first N agents without ranking
        local fallback_agents = {}
        for i = 1, math.min(limit, #filtered_agents) do
            local agent = filtered_agents[i]
            if include_scores then
                agent.relevance_score = 0.5
                agent.match_reason = "Unable to compute relevance score"
            end
            table.insert(fallback_agents, agent)
        end
        response.success = true
        response.agents = fallback_agents
        response.warning = "LLM ranking failed, returning unranked results"
        return response
    end

    local rankings = ranking_response.result

    -- Create agent lookup map
    local agent_map = {}
    for _, agent in ipairs(filtered_agents) do
        agent_map[agent.id] = agent
    end

    -- Build ranked results
    local ranked_agents = {}
    for _, ranking in ipairs(rankings) do
        local agent = agent_map[ranking.id]
        if agent then
            if include_scores then
                agent.relevance_score = ranking.relevance_score
                agent.match_reason = ranking.match_reason
            end
            table.insert(ranked_agents, agent)

            if #ranked_agents >= limit then
                break
            end
        end
    end

    -- If we don't have enough ranked results, fill with remaining agents
    if #ranked_agents < limit then
        local used_ids = {}
        for _, agent in ipairs(ranked_agents) do
            used_ids[agent.id] = true
        end

        for _, agent in ipairs(filtered_agents) do
            if not used_ids[agent.id] and #ranked_agents < limit then
                if include_scores then
                    agent.relevance_score = 0.1
                    agent.match_reason = "Lower relevance"
                end
                table.insert(ranked_agents, agent)
            end
        end
    end

    response.success = true
    response.agents = ranked_agents
    return response
end

return { handler = handler }