local registry = require("registry")
local json = require("json")
local traits = require("traits")
local llm = require("llm")

local function handler(params)
    local response = {
        success = false,
        agent_id = params.agent_id,
        analysis = {},
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

    local analysis = {
        basic_info = {},
        model_validation = {},
        tools_analysis = {},
        traits_analysis = {},
        delegates_analysis = {},
        configuration_issues = {},
        recommendations = {},
        warnings = {}
    }

    analysis.basic_info = {
        id = agent_entry.id,
        title = agent_entry.meta.title or "",
        comment = agent_entry.meta.comment or "",
        model = agent_entry.data.model or "",
        max_tokens = agent_entry.data.max_tokens or 0,
        temperature = agent_entry.data.temperature or 0,
        thinking_effort = agent_entry.data.thinking_effort or 0,
        prompt_length = agent_entry.data.prompt and #agent_entry.data.prompt or 0,
        class = agent_entry.meta.class,
        icon = agent_entry.meta.icon
    }

    -- Check if agent is visible (has public class)
    local is_visible = false
    if agent_entry.meta and agent_entry.meta.class then
        if type(agent_entry.meta.class) == "string" then
            is_visible = agent_entry.meta.class == "public"
        elseif type(agent_entry.meta.class) == "table" then
            for _, cls in ipairs(agent_entry.meta.class) do
                if cls == "public" then
                    is_visible = true
                    break
                end
            end
        end
    end
    analysis.basic_info.is_visible = is_visible

    if not is_visible then
        table.insert(analysis.configuration_issues, "Agent is not publicly accessible (missing 'public' class)")
    end

    -- Model validation
    if agent_entry.data.model then
        local available_models, models_err = llm.available_models()
        if models_err then
            table.insert(analysis.configuration_issues, "Failed to validate model: " .. models_err)
        else
            local model_found = false
            local model_supports_thinking = false
            local model_info = nil

            for _, model in ipairs(available_models) do
                if model.name == agent_entry.data.model then
                    model_found = true
                    model_info = model
                    if model.capabilities then
                        for _, cap in ipairs(model.capabilities) do
                            if cap == "thinking" then
                                model_supports_thinking = true
                                break
                            end
                        end
                    end
                    break
                end
            end

            analysis.model_validation = {
                model_exists = model_found,
                supports_thinking = model_supports_thinking,
                capabilities = model_info and model_info.capabilities or {},
                max_tokens = model_info and model_info.max_tokens or 0
            }

            if not model_found then
                table.insert(analysis.configuration_issues, "Model not available: " .. agent_entry.data.model)
            end

            if agent_entry.data.thinking_effort and agent_entry.data.thinking_effort > 0 and not model_supports_thinking then
                table.insert(analysis.configuration_issues, "thinking_effort > 0 but model doesn't support thinking")
            end
        end
    else
        table.insert(analysis.configuration_issues, "No model specified")
    end

    -- Tools analysis
    local tools_data = agent_entry.data.tools or {}
    analysis.tools_analysis = {
        total_count = #tools_data,
        direct_tools = {},
        wildcard_tools = {},
        missing_tools = {},
        invalid_tools = {}
    }

    for _, tool_entry in ipairs(tools_data) do
        local tool_id = type(tool_entry) == "string" and tool_entry or tool_entry.id
        if tool_id:match(":%*$") then
            local namespace = tool_id:gsub(":%*$", "")
            table.insert(analysis.tools_analysis.wildcard_tools, tool_id)

            local namespace_tools, _ = registry.find({
                [".ns"] = namespace,
                ["meta.type"] = "tool"
            })

            if not namespace_tools or #namespace_tools == 0 then
                table.insert(analysis.tools_analysis.missing_tools, tool_id .. " (no tools in namespace)")
            end
        else
            table.insert(analysis.tools_analysis.direct_tools, tool_id)

            local tool_registry_entry, _ = registry.get(tool_id)
            if not tool_registry_entry then
                table.insert(analysis.tools_analysis.missing_tools, tool_id)
            elseif not tool_registry_entry.meta or tool_registry_entry.meta.type ~= "tool" then
                table.insert(analysis.tools_analysis.invalid_tools, tool_id .. " (not a tool)")
            end
        end
    end

    -- Traits analysis
    local traits_data = agent_entry.data.traits or {}
    analysis.traits_analysis = {
        total_count = #traits_data,
        valid_traits = {},
        invalid_traits = {}
    }

    for _, trait_entry in ipairs(traits_data) do
        local trait_id = type(trait_entry) == "string" and trait_entry or trait_entry.id
        local trait_spec, trait_err = traits.get_by_id(trait_id)
        if not trait_spec then
            table.insert(analysis.traits_analysis.invalid_traits, trait_id .. " (" .. (trait_err or "not found") .. ")")
        else
            table.insert(analysis.traits_analysis.valid_traits, trait_id)
        end
    end

    -- Delegates analysis (corrected for array format)
    local delegates_data = agent_entry.data.delegates or {}
    analysis.delegates_analysis = {
        total_count = #delegates_data,
        valid_delegates = {},
        invalid_delegates = {},
        missing_targets = {},
        duplicate_names = {}
    }

    local delegate_names = {}
    for i, delegate_config in ipairs(delegates_data) do
        if type(delegate_config) ~= "table" then
            table.insert(analysis.delegates_analysis.invalid_delegates, "Delegate " .. i .. " is not an object")
            goto continue
        end

        local delegate_name = delegate_config.name
        if not delegate_name or type(delegate_name) ~= "string" then
            table.insert(analysis.delegates_analysis.invalid_delegates, "Delegate " .. i .. " missing name field")
            goto continue
        end

        -- Check for duplicate names
        if delegate_names[delegate_name] then
            table.insert(analysis.delegates_analysis.duplicate_names, delegate_name)
        else
            delegate_names[delegate_name] = true
        end

        if not delegate_config.id or type(delegate_config.id) ~= "string" then
            table.insert(analysis.delegates_analysis.invalid_delegates, delegate_name .. " (missing target ID)")
            goto continue
        end

        if not delegate_config.rule or type(delegate_config.rule) ~= "string" then
            table.insert(analysis.delegates_analysis.invalid_delegates, delegate_name .. " (missing rule)")
            goto continue
        end

        local target_agent, _ = registry.get(delegate_config.id)
        if not target_agent then
            table.insert(analysis.delegates_analysis.missing_targets, delegate_config.id)
        elseif not target_agent.meta or target_agent.meta.type ~= "agent.gen1" then
            table.insert(analysis.delegates_analysis.invalid_delegates, delegate_config.id .. " (not an agent)")
        else
            table.insert(analysis.delegates_analysis.valid_delegates, delegate_name)
        end

        ::continue::
    end

    -- Generate warnings
    if #analysis.tools_analysis.missing_tools > 0 then
        table.insert(analysis.warnings, "Missing tools: " .. table.concat(analysis.tools_analysis.missing_tools, ", "))
    end

    if #analysis.traits_analysis.invalid_traits > 0 then
        table.insert(analysis.warnings, "Invalid traits: " .. table.concat(analysis.traits_analysis.invalid_traits, ", "))
    end

    if #analysis.delegates_analysis.missing_targets > 0 then
        table.insert(analysis.warnings, "Missing delegate targets: " .. table.concat(analysis.delegates_analysis.missing_targets, ", "))
    end

    if #analysis.delegates_analysis.duplicate_names > 0 then
        table.insert(analysis.warnings, "Duplicate delegate names: " .. table.concat(analysis.delegates_analysis.duplicate_names, ", "))
    end

    -- Generate recommendations
    if analysis.basic_info.prompt_length < 50 then
        table.insert(analysis.recommendations, "Consider expanding the prompt for clearer agent behavior")
    end

    if analysis.tools_analysis.total_count == 0 and analysis.traits_analysis.total_count == 0 then
        table.insert(analysis.recommendations, "Consider adding tools or traits to extend agent capabilities")
    end

    if not agent_entry.meta.title or agent_entry.meta.title == "" then
        table.insert(analysis.recommendations, "Add a title for better display")
    end

    if analysis.delegates_analysis.total_count > 0 and #analysis.delegates_analysis.valid_delegates == 0 then
        table.insert(analysis.recommendations, "Fix delegate configuration issues")
    end

    response.success = true
    response.analysis = analysis
    return response
end

return { handler = handler }