local registry = require("registry")
local json = require("json")
local agent_registry = require("agent_registry")

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

    -- Check if the agent exists - try by name first, then by ID
    local agent_exists = false
    local agent_entry = nil
    local target_agent_id = params.agent_id

    -- Try to get the agent by name first
    local entries = registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = "agent.gen1",
        ["meta.name"] = params.agent_id
    })

    if entries and #entries > 0 then
        agent_exists = true
        agent_entry = entries[1]
        target_agent_id = agent_entry.id
    else
        -- Try to get the agent by ID
        agent_entry, err = registry.get(params.agent_id)
        if agent_entry and agent_entry.meta and agent_entry.meta.type == "agent.gen1" then
            agent_exists = true
            target_agent_id = params.agent_id
        end
    end

    -- Fail if agent doesn't exist
    if not agent_exists then
        response.error = "Agent not found: " .. params.agent_id
        return response
    end

    -- Create control protocol structure
    local control = {
        config = {}
    }

    -- Use agent name for control if available, otherwise use ID
    if agent_entry.meta and agent_entry.meta.name then
        control.config.agent = agent_entry.meta.name
    else
        control.config.agent = target_agent_id
    end

    -- Add model change if specified
    if params.model then
        control.config.model = params.model
    end

    -- Return result with _control field for controller
    response.success = true
    response.message = "Redirecting to agent: " .. (agent_entry.meta.title or agent_entry.meta.name or target_agent_id)
    response.agent = {
        id = target_agent_id,
        name = agent_entry.meta.name,
        title = agent_entry.meta.title,
        description = agent_entry.meta.comment
    }
    response._control = control
    return response
end

return { handler = handler }