local registry = require("registry")
local json = require("json")
local traits = require("traits")
local llm = require("llm")
local governance_client = require("governance_client")

local function handler(params)
    local response = {
        success = false,
        source_agent_id = params.source_agent_id,
        new_agent_id = params.new_agent_id,
        error = nil
    }

    if not params.source_agent_id or type(params.source_agent_id) ~= "string" or params.source_agent_id == "" then
        response.error = "Missing required parameter: source_agent_id"
        return response
    end

    if not params.new_agent_id or type(params.new_agent_id) ~= "string" or params.new_agent_id == "" then
        response.error = "Missing required parameter: new_agent_id"
        return response
    end

    -- Add default namespace if none provided
    local new_agent_id = params.new_agent_id
    if not new_agent_id:match(":") then
        new_agent_id = "app.agents:" .. new_agent_id
    end

    local namespace, name = new_agent_id:match("^([^:]+):([^:]+)$")
    if not namespace or not name then
        response.error = "Invalid new_agent_id format. Must be namespace:name or just name (will use app.agents:name)"
        return response
    end

    local source_agent, err = registry.get(params.source_agent_id)
    if not source_agent then
        response.error = "Source agent not found: " .. params.source_agent_id
        return response
    end

    if not source_agent.meta or source_agent.meta.type ~= "agent.gen1" then
        response.error = "Source entry is not a valid agent: " .. params.source_agent_id
        return response
    end

    local existing_agent, _ = registry.get(new_agent_id)
    if existing_agent then
        response.error = "Agent already exists: " .. new_agent_id
        return response
    end

    -- Deep copy data and meta
    local cloned_data = {}
    local cloned_meta = {}

    for k, v in pairs(source_agent.data or {}) do
        if type(v) == "table" then
            cloned_data[k] = {}
            for i, item in ipairs(v) do
                if type(item) == "table" then
                    -- Deep copy table items (for delegates, traits, tools)
                    cloned_data[k][i] = {}
                    for key, value in pairs(item) do
                        cloned_data[k][i][key] = value
                    end
                else
                    cloned_data[k][i] = item
                end
            end
        else
            cloned_data[k] = v
        end
    end

    for k, v in pairs(source_agent.meta or {}) do
        if type(v) == "table" then
            cloned_meta[k] = {}
            for i, item in ipairs(v) do
                cloned_meta[k][i] = item
            end
        else
            cloned_meta[k] = v
        end
    end

    -- Apply modifications if provided
    if params.modifications then
        local mods = params.modifications

        if mods.prompt then
            cloned_data.prompt = mods.prompt
        end

        if mods.max_tokens then
            cloned_data.max_tokens = mods.max_tokens
        end

        if mods.temperature then
            cloned_data.temperature = mods.temperature
        end

        if mods.thinking_effort then
            if mods.thinking_effort > 0 then
                local model_to_check = mods.model or cloned_data.model
                if model_to_check then
                    local available_models, models_err = llm.available_models()
                    if models_err then
                        response.error = "Failed to check available models: " .. models_err
                        return response
                    end

                    local supports_thinking = false
                    for _, model_info in ipairs(available_models) do
                        if model_info.name == model_to_check and model_info.capabilities then
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
            cloned_data.thinking_effort = mods.thinking_effort
        end

        if mods.model then
            local available_models, models_err = llm.available_models()
            if models_err then
                response.error = "Failed to check available models: " .. models_err
                return response
            end

            local model_found = false
            local model_supports_thinking = false
            for _, model_info in ipairs(available_models) do
                if model_info.name == mods.model then
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
                response.error = "Model not available: " .. mods.model
                return response
            end

            local thinking_effort = mods.thinking_effort or cloned_data.thinking_effort
            if thinking_effort and thinking_effort > 0 and not model_supports_thinking then
                response.error = "Model " .. mods.model .. " does not support thinking capability"
                return response
            end

            cloned_data.model = mods.model
        end

        if mods.comment then
            cloned_meta.comment = mods.comment
        end

        if mods.title then
            cloned_meta.title = mods.title
        end

        if mods.icon then
            cloned_meta.icon = mods.icon
        end

        if mods.class then
            cloned_meta.class = mods.class
        end
    end

    -- Ensure cloned agent has public class
    if not cloned_meta.class then
        cloned_meta.class = {"public"}
    elseif type(cloned_meta.class) == "string" then
        cloned_meta.class = {cloned_meta.class}
    end

    local has_public = false
    for _, cls in ipairs(cloned_meta.class) do
        if cls == "public" then
            has_public = true
            break
        end
    end
    if not has_public then
        table.insert(cloned_meta.class, "public")
    end

    local changeset = {
        {
            kind = "entry.create",
            entry = {
                id = new_agent_id,
                kind = "registry.entry",
                meta = cloned_meta,
                data = cloned_data
            }
        }
    }

    local result, err = governance_client.request_changes(changeset)
    if not result then
        response.error = "Failed to create cloned agent: " .. (err or "unknown error")
        return response
    end

    response.success = true
    response.new_agent_id = new_agent_id
    response.message = "Agent cloned successfully"
    response.version = result.version
    return response
end

return { handler = handler }