local registry = require("registry")
local json = require("json")
local traits = require("traits")
local llm = require("llm")
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

    if not params.prompt or type(params.prompt) ~= "string" or params.prompt == "" then
        response.error = "Missing required parameter: prompt"
        return response
    end

    if not params.comment or type(params.comment) ~= "string" or params.comment == "" then
        response.error = "Missing required parameter: comment"
        return response
    end

    -- Add default namespace if none provided
    local agent_id = params.agent_id
    if not agent_id:match(":") then
        agent_id = "app.agents:" .. agent_id
    end

    local namespace, name = agent_id:match("^([^:]+):([^:]+)$")
    if not namespace or not name then
        response.error = "Invalid agent_id format. Must be namespace:name or just name (will use app.agents:name)"
        return response
    end

    local existing_agent, _ = registry.get(agent_id)
    if existing_agent then
        response.error = "Agent already exists: " .. agent_id
        return response
    end

    local model = params.model
    if model then
        local available_models, models_err = llm.available_models()
        if models_err then
            response.error = "Failed to check available models: " .. models_err
            return response
        end

        local model_found = false
        local model_supports_thinking = false
        for _, model_info in ipairs(available_models) do
            if model_info.name == model then
                model_found = true
                if model_info.capabilities then
                    for _, cap in ipairs(model_info.capabilities) do
                        if cap == "thinking" then
                            model_supports_thinking = true
                            break
                        end
                    end
                end
                break
            end
        end

        if not model_found then
            response.error = "Model not available: " .. model
            return response
        end

        if params.thinking_effort and params.thinking_effort > 0 and not model_supports_thinking then
            response.error = "Model " .. model .. " does not support thinking capability"
            return response
        end
    else
        model = "claude-4-5-sonnet"
    end

    if params.traits then
        for _, trait_config in ipairs(params.traits) do
            local trait_id = trait_config.id
            local trait_spec, trait_err = traits.get_by_id(trait_id)
            if not trait_spec then
                response.error = "Trait not found: " .. trait_id .. " (" .. (trait_err or "unknown error") .. ")"
                return response
            end
        end
    end

    if params.tools then
        for _, tool_config in ipairs(params.tools) do
            local tool_id = tool_config.id
            if tool_id:match(":%*$") then
                local namespace_part = tool_id:gsub(":%*$", "")
                local namespace_tools, _ = registry.find({
                    [".ns"] = namespace_part,
                    ["meta.type"] = "tool"
                })
                if not namespace_tools or #namespace_tools == 0 then
                    response.error = "No tools found in namespace: " .. namespace_part
                    return response
                end
            else
                local tool_entry, _ = registry.get(tool_id)
                if not tool_entry then
                    response.error = "Tool not found: " .. tool_id
                    return response
                end
                if not tool_entry.meta or tool_entry.meta.type ~= "tool" then
                    response.error = "Entry is not a tool: " .. tool_id
                    return response
                end
            end
        end
    end

    -- Validate delegates (now as array)
    if params.delegates then
        if type(params.delegates) ~= "table" then
            response.error = "Delegates must be an array"
            return response
        end

        for i, delegate_config in ipairs(params.delegates) do
            if type(delegate_config) ~= "table" then
                response.error = "Delegate " .. i .. " must be an object"
                return response
            end

            if not delegate_config.name or type(delegate_config.name) ~= "string" then
                response.error = "Delegate " .. i .. " missing required field: name"
                return response
            end

            if not delegate_config.id or type(delegate_config.id) ~= "string" then
                response.error = "Delegate " .. i .. " missing required field: id"
                return response
            end

            if not delegate_config.rule or type(delegate_config.rule) ~= "string" then
                response.error = "Delegate " .. i .. " missing required field: rule"
                return response
            end

            local target_agent, _ = registry.get(delegate_config.id)
            if not target_agent then
                response.error = "Delegate target not found: " .. delegate_config.id
                return response
            end
            if not target_agent.meta or target_agent.meta.type ~= "agent.gen1" then
                response.error = "Delegate target is not an agent: " .. delegate_config.id
                return response
            end
        end
    end

    -- Ensure agent has public class by default
    local class = params.class or {"public"}
    if type(class) == "string" then
        class = { class }
    end

    -- Add public if not already present
    local has_public = false
    for _, cls in ipairs(class) do
        if cls == "public" then
            has_public = true
            break
        end
    end

    local meta = {
        type = "agent.gen1",
        comment = params.comment
    }

    if params.title then
        meta.title = params.title
    end

    if params.icon then
        meta.icon = params.icon
    end

    meta.class = class

    local data = {
        prompt = params.prompt,
        model = model
    }

    if params.max_tokens then
        data.max_tokens = params.max_tokens
    end

    if params.temperature then
        data.temperature = params.temperature
    end

    if params.thinking_effort and params.thinking_effort > 0 then
        data.thinking_effort = params.thinking_effort
    end

    if params.memory then
        data.memory = params.memory
    end

    if params.tools then
        data.tools = params.tools
    end

    if params.traits then
        data.traits = params.traits
    end

    if params.delegates then
        data.delegates = params.delegates
    end

    local changeset = {
        {
            kind = "entry.create",
            entry = {
                id = agent_id,
                kind = "registry.entry",
                meta = meta,
                data = data
            }
        }
    }

    local result, err = governance_client.request_changes(changeset)
    if not result then
        response.error = "Failed to create agent: " .. (err or "unknown error")
        return response
    end

    response.success = true
    response.agent_id = agent_id
    response.message = "Agent created successfully"
    response.version = result.version
    return response
end

return { handler = handler }
