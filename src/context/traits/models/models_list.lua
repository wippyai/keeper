local models = require("models")

local function handler(params)
    local all_models, err = models.get_all()
    if err then
        return nil, "Failed to fetch models: " .. err
    end

    if not all_models or #all_models == 0 then
        return "No models available"
    end

    local function extract_provider(model_card)
        if model_card.providers and #model_card.providers > 0 then
            return model_card.providers[1]
        end
        return "unknown"
    end

    table.sort(all_models, function(a, b)
        local provider_a = extract_provider(a)
        local provider_b = extract_provider(b)
        if provider_a == provider_b then
            return a.name < b.name
        end
        return provider_a.name < provider_b.name
    end)

    local lines = {}
    table.insert(lines, "Available Models (" .. #all_models .. "):")
    table.insert(lines, "")

    for _, model in ipairs(all_models) do
        table.insert(lines, "- Model: " .. model.name)
        if model.title and model.title ~= "" then
            table.insert(lines, "  Title: " .. model.title)
        end
        local provider = extract_provider(model)
        table.insert(lines, "  Provider: " .. provider)
        if model.capabilities and #model.capabilities > 0 then
            table.insert(lines, "  Capabilities: " .. table.concat(model.capabilities, ", "))
        end
        if model.class and #model.class > 0 then
            table.insert(lines, "  Classes: " .. table.concat(model.class, ", "))
        end
        table.insert(lines,
            "  Max Tokens: " .. (model.max_tokens or 0) .. " (output: " .. (model.output_tokens or 0) .. ")")
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

return { handler = handler }
