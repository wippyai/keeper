local list_agents = require("list_agents")

local CLASS_NAME = "research"
local AGENTS_LIST_HEADER = "## Available Research Agents"

local function handler()
    local response = list_agents.handler({
        class = CLASS_NAME,
        limit = 50
    })

    if not response.success then
        return "Error loading \"" .. CLASS_NAME .. "\" agents"
    end

    if response.count == 0 then
        return "No \"" .. CLASS_NAME .. "\" agents available"
    end

    local agent_lines = {AGENTS_LIST_HEADER}

    for _, agent in ipairs(response.agents) do
        local title = agent.title or "Untitled Agent"
        local description = agent.comment or "No description available"

        local line = "- **" .. agent.id .. "** - " .. title .. ": " .. description
        table.insert(agent_lines, line)
    end

    table.insert(agent_lines, "")
    table.insert(agent_lines, "Use the develop tool with agent_id parameter to delegate to a specific agent.")

    return table.concat(agent_lines, "\n")
end

return { handler = handler }