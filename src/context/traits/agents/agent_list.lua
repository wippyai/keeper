local ctx = require("ctx")
local agent_registry = require("agent_registry")

local DEFAULT_CLASS = "context_gatherer"

local function handler(params)
    local target_class = params and params.target_agent_class

    if not target_class or target_class == "" then
        local context_class, err = ctx.get("target_agent_class")
        if not err and context_class and context_class ~= "" then
            target_class = context_class
        else
            target_class = DEFAULT_CLASS
        end
    end

    if not target_class or target_class == "" then
        return nil, "target_agent_class not set in context or params"
    end

    local agents, err = agent_registry.list_by_class(target_class)
    if err then
        return nil, "Failed to fetch agents: " .. err
    end

    if not agents or #agents == 0 then
        return "No agents found with class: " .. target_class
    end

    local agent_list = {}
    for _, agent in ipairs(agents) do
        local meta = agent.meta or {}
        local capabilities = meta.capabilities or ""
        table.insert(agent_list, {
            id = agent.id,
            title = meta.title or agent.name or "",
            description = meta.comment or "",
            capabilities = capabilities,
            requirements = meta.requirements or ""
        })
    end

    table.sort(agent_list, function(a, b)
        return a.id < b.id
    end)

    local lines = {}
    table.insert(lines, "Available Context Agents (" .. #agent_list .. "):")
    table.insert(lines, "")

    for _, agent in ipairs(agent_list) do
        table.insert(lines, "- Agent ID: " .. agent.id)
        if agent.capabilities ~= "" then
            table.insert(lines, "  Capabilities: " .. agent.capabilities)
        elseif agent.description ~= "" then
            table.insert(lines, "  Description: " .. agent.description)
        end
        if agent.requirements ~= "" then
            table.insert(lines, "  Requirements: " .. agent.requirements)
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

return { handler = handler }
