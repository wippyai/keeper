local registry = require("registry")

local function as_array(v)
    if type(v) ~= "table" then return {} end
    return v
end

local function has_class(meta, name)
    if not meta or not meta.class then return false end
    if type(meta.class) == "string" then return meta.class == name end
    if type(meta.class) ~= "table" then return false end
    for _, c in ipairs(meta.class) do
        if c == name then return true end
    end
    return false
end

local function is_capable(model_entry, capability)
    if not model_entry or not model_entry.data then return false end
    local d = model_entry.data
    if d[capability] == true then return true end
    if type(d.capabilities) == "table" then
        for _, c in ipairs(d.capabilities) do
            if c == capability then return true end
        end
    end
    return false
end

local function resolve_model(model_id)
    if not model_id or model_id == "" then return nil end
    -- class:* aliases route through llm.model entries with that class tag
    if model_id:sub(1, 6) == "class:" then
        local class_name = model_id:sub(7)
        local matches = registry.find({
            [".kind"] = "registry.entry",
            ["meta.type"] = "llm.model",
        }) or {}
        for _, e in ipairs(matches) do
            if has_class(e.meta, class_name) then
                return e
            end
        end
        return nil
    end
    return (registry.get(model_id))
end

local function handler(params)
    local out = {
        success = false,
        agent_id = params and params.agent_id,
        analysis = {},
        error = nil,
    }

    if not params or type(params.agent_id) ~= "string" or params.agent_id == "" then
        out.error = "Missing required parameter: agent_id"
        return out
    end

    local entry, err = registry.get(params.agent_id)
    if not entry then
        out.error = "Agent not found: " .. params.agent_id
        return out
    end
    if not entry.meta or entry.meta.type ~= "agent.gen1" then
        out.error = "Entry is not an agent.gen1: " .. params.agent_id
        return out
    end

    local data = entry.data or {}
    local meta = entry.meta or {}

    local analysis = {
        basic_info = {
            id              = entry.id,
            title           = meta.title or "",
            comment         = meta.comment or "",
            icon            = meta.icon or "",
            class           = meta.class or {},
            is_visible      = has_class(meta, "public"),
            model           = data.model or "",
            max_tokens      = data.max_tokens or 0,
            temperature     = data.temperature,
            thinking_effort = data.thinking_effort or 0,
            prompt_length   = type(data.prompt) == "string" and #data.prompt or 0,
            memory_count    = #as_array(data.memory),
        },
        model_validation = {
            model_exists       = false,
            supports_thinking  = false,
            capabilities       = {},
            max_tokens         = 0,
        },
        tools_analysis = {
            total_count    = 0,
            direct_tools   = {},
            wildcard_tools = {},
            missing_tools  = {},
            invalid_tools  = {},
        },
        traits_analysis = {
            total_count    = 0,
            valid_traits   = {},
            invalid_traits = {},
        },
        delegates_analysis = {
            total_count       = 0,
            valid_delegates   = {},
            invalid_delegates = {},
            missing_targets   = {},
            duplicate_names   = {},
        },
        configuration_issues = {},
        recommendations      = {},
        warnings             = {},
    }

    if not analysis.basic_info.is_visible then
        table.insert(analysis.configuration_issues,
            "Agent is not publicly accessible (missing 'public' class)")
    end

    -- Model validation
    if data.model and data.model ~= "" then
        local model_entry = resolve_model(data.model)
        if model_entry then
            analysis.model_validation.model_exists      = true
            analysis.model_validation.capabilities      = as_array(model_entry.data and model_entry.data.capabilities)
            analysis.model_validation.max_tokens        = (model_entry.data and model_entry.data.max_tokens) or 0
            analysis.model_validation.supports_thinking = is_capable(model_entry, "thinking")
                or is_capable(model_entry, "extended_thinking")
        else
            table.insert(analysis.configuration_issues, "Model not available: " .. data.model)
        end
        if (data.thinking_effort or 0) > 0 and not analysis.model_validation.supports_thinking then
            table.insert(analysis.configuration_issues,
                "thinking_effort > 0 but model doesn't support thinking")
        end
    else
        table.insert(analysis.configuration_issues, "No model specified")
    end

    -- Tools
    local tools_data = as_array(data.tools)
    analysis.tools_analysis.total_count = #tools_data
    for _, t in ipairs(tools_data) do
        local tool_id = type(t) == "string" and t or (type(t) == "table" and t.id)
        if type(tool_id) ~= "string" or tool_id == "" then
            table.insert(analysis.tools_analysis.invalid_tools, "<empty tool ref>")
        elseif tool_id:match(":%*$") then
            table.insert(analysis.tools_analysis.wildcard_tools, tool_id)
            local ns = tool_id:gsub(":%*$", "")
            local ns_tools = registry.find({
                [".ns"]      = ns,
                ["meta.type"]= "tool",
            }) or {}
            if #ns_tools == 0 then
                table.insert(analysis.tools_analysis.missing_tools, tool_id .. " (empty namespace)")
            end
        else
            table.insert(analysis.tools_analysis.direct_tools, tool_id)
            local te = registry.get(tool_id)
            if not te then
                table.insert(analysis.tools_analysis.missing_tools, tool_id)
            elseif not te.meta or te.meta.type ~= "tool" then
                table.insert(analysis.tools_analysis.invalid_tools, tool_id .. " (not a tool)")
            end
        end
    end

    -- Traits
    local traits_data = as_array(data.traits)
    analysis.traits_analysis.total_count = #traits_data
    for _, t in ipairs(traits_data) do
        local trait_id = type(t) == "string" and t or (type(t) == "table" and t.id)
        if type(trait_id) ~= "string" or trait_id == "" then
            table.insert(analysis.traits_analysis.invalid_traits, "<empty trait ref>")
        else
            local te = registry.get(trait_id)
            if not te then
                table.insert(analysis.traits_analysis.invalid_traits, trait_id .. " (not found)")
            elseif not te.meta or te.meta.type ~= "agent.trait" then
                table.insert(analysis.traits_analysis.invalid_traits, trait_id .. " (not a trait)")
            else
                table.insert(analysis.traits_analysis.valid_traits, trait_id)
            end
        end
    end

    -- Delegates
    local delegates_data = as_array(data.delegates)
    analysis.delegates_analysis.total_count = #delegates_data
    local seen_names = {}
    for i, d in ipairs(delegates_data) do
        if type(d) ~= "table" then
            table.insert(analysis.delegates_analysis.invalid_delegates,
                "Delegate #" .. i .. " is not an object")
        else
            if type(d.name) ~= "string" or d.name == "" then
                table.insert(analysis.delegates_analysis.invalid_delegates,
                    "Delegate #" .. i .. " missing name")
            elseif seen_names[d.name] then
                table.insert(analysis.delegates_analysis.duplicate_names, d.name)
            else
                seen_names[d.name] = true
            end
            if type(d.id) ~= "string" or d.id == "" then
                table.insert(analysis.delegates_analysis.invalid_delegates,
                    (d.name or "delegate#" .. i) .. " missing id")
            else
                local target = registry.get(d.id)
                if not target then
                    table.insert(analysis.delegates_analysis.missing_targets, d.id)
                elseif not target.meta or target.meta.type ~= "agent.gen1" then
                    table.insert(analysis.delegates_analysis.invalid_delegates,
                        d.id .. " (not an agent)")
                end
            end
            if type(d.rule) ~= "string" or d.rule == "" then
                table.insert(analysis.delegates_analysis.invalid_delegates,
                    (d.name or "delegate#" .. i) .. " missing rule")
            end
            if d.id and d.rule and d.name and seen_names[d.name] then
                table.insert(analysis.delegates_analysis.valid_delegates, d.name)
            end
        end
    end

    if #analysis.tools_analysis.missing_tools > 0 then
        table.insert(analysis.warnings,
            "Missing tools: " .. table.concat(analysis.tools_analysis.missing_tools, ", "))
    end
    if #analysis.traits_analysis.invalid_traits > 0 then
        table.insert(analysis.warnings,
            "Invalid traits: " .. table.concat(analysis.traits_analysis.invalid_traits, ", "))
    end
    if #analysis.delegates_analysis.missing_targets > 0 then
        table.insert(analysis.warnings,
            "Missing delegate targets: " .. table.concat(analysis.delegates_analysis.missing_targets, ", "))
    end
    if #analysis.delegates_analysis.duplicate_names > 0 then
        table.insert(analysis.warnings,
            "Duplicate delegate names: " .. table.concat(analysis.delegates_analysis.duplicate_names, ", "))
    end

    if analysis.basic_info.prompt_length < 50 then
        table.insert(analysis.recommendations,
            "Prompt is short (" .. analysis.basic_info.prompt_length .. " chars) — consider expanding")
    end
    if analysis.tools_analysis.total_count == 0 and analysis.traits_analysis.total_count == 0 then
        table.insert(analysis.recommendations,
            "Agent has no tools or traits — add at least one to extend capabilities")
    end
    if not meta.title or meta.title == "" then
        table.insert(analysis.recommendations, "Add a meta.title for nicer display")
    end
    if analysis.delegates_analysis.total_count > 0
       and #analysis.delegates_analysis.valid_delegates == 0 then
        table.insert(analysis.recommendations, "Fix delegate configuration issues")
    end

    out.success = true
    out.analysis = analysis
    return out
end

return { handler = handler }
