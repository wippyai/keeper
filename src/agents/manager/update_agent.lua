local registry = require("registry")
local json = require("json")
local traits = require("traits")
local llm = require("llm")
local governance_client = require("governance_client")

local function handler(params)
    local response = {
        success = false,
        agent_id = params.agent_id,
        changes_made = {},
        error = nil
    }

    if not params.agent_id or type(params.agent_id) ~= "string" or params.agent_id == "" then
        response.error = "Missing required parameter: agent_id"
        return response
    end

    local agent_entry, err = registry.get(params.agent_id)
    if not agent_entry then
        response.error = "Agent not found: " .. params.agent_id
        return response
    end

    if not agent_entry.meta or agent_entry.meta.type ~= "agent.gen1" then
        response.error = "Entry is not a valid agent: " .. params.agent_id
        return response
    end

    local updated_data = {}
    local updated_meta = {}

    for k, v in pairs(agent_entry.data or {}) do
        updated_data[k] = v
    end
    for k, v in pairs(agent_entry.meta or {}) do
        updated_meta[k] = v
    end

    if params.prompt then
        updated_data.prompt = params.prompt
        table.insert(response.changes_made, "prompt updated")
    end

    if params.max_tokens then
        updated_data.max_tokens = params.max_tokens
        table.insert(response.changes_made, "max_tokens updated")
    end

    if params.temperature then
        updated_data.temperature = params.temperature
        table.insert(response.changes_made, "temperature updated")
    end

    if params.model then
        local available_models, models_err = llm.available_models()
        if models_err then
            response.error = "Failed to check available models: " .. models_err
            return response
        end

        local model_found = false
        local model_supports_thinking = false
        for _, model_info in ipairs(available_models) do
            if model_info.name == params.model then
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
            response.error = "Model not available: " .. params.model
            return response
        end

        local thinking_effort = params.thinking_effort or updated_data.thinking_effort
        if thinking_effort and thinking_effort > 0 and not model_supports_thinking then
            response.error = "Model " .. params.model .. " does not support thinking capability"
            return response
        end

        updated_data.model = params.model
        table.insert(response.changes_made, "model updated")
    end

    if params.thinking_effort then
        if params.thinking_effort > 0 then
            local current_model = params.model or updated_data.model
            if current_model then
                local available_models, _ = llm.available_models()
                local supports_thinking = false
                for _, model_info in ipairs(available_models or {}) do
                    if model_info.name == current_model and model_info.capabilities then
                        for _, cap in ipairs(model_info.capabilities) do
                            if cap == "thinking" then
                                supports_thinking = true
                                break
                            end
                        end
                        break
                    end
                end
                if not supports_thinking then
                    response.error = "thinking_effort > 0 requires a model with thinking capability"
                    return response
                end
            end
        end
        updated_data.thinking_effort = params.thinking_effort
        table.insert(response.changes_made, "thinking_effort updated")
    end

    -- Memory operations
    if params.set_memory then
        updated_data.memory = params.set_memory
        table.insert(response.changes_made, "memory replaced")
    elseif params.add_memory or params.remove_memory then
        local current_memory = updated_data.memory or {}

        if params.add_memory then
            for _, item in ipairs(params.add_memory) do
                local exists = false
                for _, existing in ipairs(current_memory) do
                    if existing == item then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(current_memory, item)
                end
            end
            table.insert(response.changes_made, "memory items added")
        end

        if params.remove_memory then
            local filtered_memory = {}
            for _, existing in ipairs(current_memory) do
                local should_remove = false
                for _, remove_item in ipairs(params.remove_memory) do
                    if existing == remove_item then
                        should_remove = true
                        break
                    end
                end
                if not should_remove then
                    table.insert(filtered_memory, existing)
                end
            end
            current_memory = filtered_memory
            table.insert(response.changes_made, "memory items removed")
        end

        updated_data.memory = current_memory
    end

    -- Traits operations
    if params.set_traits then
        for _, trait_config in ipairs(params.set_traits) do
            local trait_id = trait_config.id
            local trait_spec, trait_err = traits.get_by_id(trait_id)
            if not trait_spec then
                response.error = "Trait not found: " .. trait_id .. " (" .. (trait_err or "unknown error") .. ")"
                return response
            end
        end
        updated_data.traits = params.set_traits
        table.insert(response.changes_made, "traits replaced")
    elseif params.add_traits or params.remove_traits then
        local current_traits = updated_data.traits or {}

        if params.add_traits then
            for _, trait_config in ipairs(params.add_traits) do
                local trait_id = trait_config.id
                local trait_spec, trait_err = traits.get_by_id(trait_id)
                if not trait_spec then
                    response.error = "Trait not found: " .. trait_id .. " (" .. (trait_err or "unknown error") .. ")"
                    return response
                end

                local exists = false
                for _, existing in ipairs(current_traits) do
                    local existing_id = type(existing) == "string" and existing or existing.id
                    if existing_id == trait_id then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(current_traits, trait_config)
                end
            end
            table.insert(response.changes_made, "traits added")
        end

        if params.remove_traits then
            local filtered_traits = {}
            for _, existing in ipairs(current_traits) do
                local existing_id = type(existing) == "string" and existing or existing.id
                local should_remove = false
                for _, remove_trait in ipairs(params.remove_traits) do
                    if existing_id == remove_trait then
                        should_remove = true
                        break
                    end
                end
                if not should_remove then
                    table.insert(filtered_traits, existing)
                end
            end
            current_traits = filtered_traits
            table.insert(response.changes_made, "traits removed")
        end

        updated_data.traits = current_traits
    end

    -- Tools operations
    if params.set_tools then
        for _, tool_config in ipairs(params.set_tools) do
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
        updated_data.tools = params.set_tools
        table.insert(response.changes_made, "tools replaced")
    elseif params.add_tools or params.remove_tools then
        local current_tools = updated_data.tools or {}

        if params.add_tools then
            for _, tool_config in ipairs(params.add_tools) do
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

                local exists = false
                for _, existing in ipairs(current_tools) do
                    local existing_id = type(existing) == "string" and existing or existing.id
                    if existing_id == tool_id then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(current_tools, tool_config)
                end
            end
            table.insert(response.changes_made, "tools added")
        end

        if params.remove_tools then
            local filtered_tools = {}
            for _, existing in ipairs(current_tools) do
                local existing_id = type(existing) == "string" and existing or existing.id
                local should_remove = false
                for _, remove_tool in ipairs(params.remove_tools) do
                    if existing_id == remove_tool then
                        should_remove = true
                        break
                    end
                end
                if not should_remove then
                    table.insert(filtered_tools, existing)
                end
            end
            current_tools = filtered_tools
            table.insert(response.changes_made, "tools removed")
        end

        updated_data.tools = current_tools
    end

    -- Delegates operations (corrected for array format)
    if params.set_delegates then
        -- Validate all delegates first
        for i, delegate_config in ipairs(params.set_delegates) do
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

        updated_data.delegates = params.set_delegates
        table.insert(response.changes_made, "delegates replaced")
    elseif params.add_delegates or params.remove_delegates then
        local current_delegates = updated_data.delegates or {}

        if params.add_delegates then
            for i, delegate_config in ipairs(params.add_delegates) do
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

                -- Check if delegate with this name already exists
                local exists = false
                for _, existing in ipairs(current_delegates) do
                    if existing.name == delegate_config.name then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(current_delegates, delegate_config)
                end
            end
            table.insert(response.changes_made, "delegates added")
        end

        if params.remove_delegates then
            local filtered_delegates = {}
            for _, existing in ipairs(current_delegates) do
                local should_remove = false
                for _, remove_name in ipairs(params.remove_delegates) do
                    if existing.name == remove_name then
                        should_remove = true
                        break
                    end
                end
                if not should_remove then
                    table.insert(filtered_delegates, existing)
                end
            end
            current_delegates = filtered_delegates
            table.insert(response.changes_made, "delegates removed")
        end

        updated_data.delegates = current_delegates
    end

    -- Metadata operations
    if params.update_metadata then
        for key, value in pairs(params.update_metadata) do
            updated_meta[key] = value
            table.insert(response.changes_made, "metadata." .. key .. " updated")
        end
    end

    local changeset = {
        {
            kind = "entry.update",
            entry = {
                id = params.agent_id,
                kind = "registry.entry",
                meta = updated_meta,
                data = updated_data
            }
        }
    }

    local result, err = governance_client.request_changes(changeset)
    if not result then
        response.error = "Failed to update agent: " .. (err or "unknown error")
        return response
    end

    response.success = true
    response.message = "Agent updated successfully"
    response.version = result.version
    return response
end

return { handler = handler }