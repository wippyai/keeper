local registry = require("registry")
local json = require("json")
local governance_client = require("governance_client")

local function handler(params)
    local response = {
        success = false,
        agent_id = params.agent_id,
        error = nil
    }

    if not params.agent_id or type(params.agent_id) ~= "string" or params.agent_id == "" then
        response.error = "Missing required parameter: agent_id"
        return response
    end

    -- Retrieve the agent to verify it exists and is valid
    local agent_entry, err = registry.get(params.agent_id)
    if not agent_entry then
        response.error = "Agent not found: " .. params.agent_id
        return response
    end

    if not agent_entry.meta or agent_entry.meta.type ~= "agent.gen1" then
        response.error = "Entry is not a valid agent: " .. params.agent_id
        return response
    end

    -- Check if other agents delegate to this one
    local dependent_agents = {}
    if not params.force then
        local all_agents, find_err = registry.find({
            [".kind"] = "registry.entry",
            ["meta.type"] = "agent.gen1"
        })

        if not find_err and all_agents then
            for _, other_agent in ipairs(all_agents) do
                if other_agent.id ~= params.agent_id and other_agent.data and other_agent.data.delegates then
                    for _, delegate_config in ipairs(other_agent.data.delegates) do
                        if delegate_config.id == params.agent_id then
                            table.insert(dependent_agents, {
                                agent_id = other_agent.id,
                                delegate_name = delegate_config.name
                            })
                        end
                    end
                end
            end
        end

        if #dependent_agents > 0 then
            response.error = "Cannot delete agent - other agents depend on it. Use force=true to override."
            response.dependent_agents = dependent_agents
            return response
        end
    end

    -- Create deletion changeset
    local changeset = {
        {
            kind = "entry.delete",
            entry = {
                id = params.agent_id
            }
        }
    }

    local result, err = governance_client.request_changes(changeset)
    if not result then
        response.error = "Failed to delete agent: " .. (err or "unknown error")
        return response
    end

    response.success = true
    response.message = "Agent deleted successfully"
    response.version = result.version
    response.agent_title = agent_entry.meta.title or agent_entry.id

    if #dependent_agents > 0 then
        response.warning = "Deleted agent that other agents depend on - those delegations may now fail"
        response.dependent_agents = dependent_agents
    end

    return response
end

return { handler = handler }