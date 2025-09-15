local json = require("json")
local llm = require("llm")

local function handler(params)
    local response = {
        success = false,
        models = {},
        error = nil,
        count = 0,
        filters_applied = {}
    }

    params = params or {}

    if params.capabilities then
        if type(params.capabilities) ~= "table" then
            response.error = "Invalid capabilities parameter: must be an array of strings"
            return response
        end

        local valid_capabilities = {
            tool_use = true,
            vision = true,
            thinking = true,
            caching = true,
            multilingual = true
        }

        for _, cap in ipairs(params.capabilities) do
            if type(cap) ~= "string" or not valid_capabilities[cap] then
                response.error = "Invalid capability: " .. tostring(cap) .. ". Valid capabilities: tool_use, vision, thinking, caching, multilingual"
                return response
            end
        end

        response.filters_applied.capabilities = params.capabilities
    end

    if params.provider then
        if type(params.provider) ~= "string" then
            response.error = "Invalid provider parameter: must be a string"
            return response
        end

        response.filters_applied.provider = params.provider:lower()
    end

    if params.max_tokens_min then
        if type(params.max_tokens_min) ~= "number" or params.max_tokens_min < 1 then
            response.error = "Invalid max_tokens_min parameter: must be a positive number"
            return response
        end

        response.filters_applied.max_tokens_min = params.max_tokens_min
    end

    local all_models, err = llm.available_models()
    if err then
        response.error = "Failed to retrieve models from LLM library: " .. tostring(err)
        return response
    end

    if not all_models or #all_models == 0 then
        response.success = true
        response.models = {}
        response.count = 0
        return response
    end

    local function extract_provider(model_card)
        local provider = "unknown"

        if model_card.handlers and model_card.handlers.generate then
            local provider_match = model_card.handlers.generate:match("wippy%.llm%.([^:]+):")
            if provider_match then
                provider = provider_match
            end
        end

        if provider == "unknown" and model_card.handlers and model_card.handlers.call_tools then
            local provider_match = model_card.handlers.call_tools:match("wippy%.llm%.([^:]+):")
            if provider_match then
                provider = provider_match
            end
        end

        if provider == "unknown" and model_card.handlers and model_card.handlers.embeddings then
            local provider_match = model_card.handlers.embeddings:match("wippy%.llm%.([^:]+):")
            if provider_match then
                provider = provider_match
            end
        end

        return provider
    end

    local function matches_capabilities(model_card, filter_caps)
        if not filter_caps or #filter_caps == 0 then
            return true
        end

        local model_caps = model_card.capabilities or {}
        local model_cap_set = {}
        for _, cap in ipairs(model_caps) do
            model_cap_set[cap] = true
        end

        for _, required_cap in ipairs(filter_caps) do
            if not model_cap_set[required_cap] then
                return false
            end
        end

        return true
    end

    local function matches_provider(model_card, filter_provider)
        if not filter_provider then
            return true
        end

        local model_provider = extract_provider(model_card):lower()
        return model_provider == filter_provider
    end

    local function matches_max_tokens(model_card, min_tokens)
        if not min_tokens then
            return true
        end

        local model_max_tokens = model_card.max_tokens or 0
        return model_max_tokens >= min_tokens
    end

    local filtered_models = {}
    for _, model_card in ipairs(all_models) do
        if not matches_capabilities(model_card, params.capabilities) then
            goto continue
        end

        if not matches_provider(model_card, response.filters_applied.provider) then
            goto continue
        end

        if not matches_max_tokens(model_card, params.max_tokens_min) then
            goto continue
        end

        local model = {
            name = model_card.name or "unknown",
            title = model_card.title or model_card.name or "Unknown Model",
            capabilities = model_card.capabilities or {},
            max_tokens = model_card.max_tokens or 0,
            output_tokens = model_card.output_tokens or 0,
            provider = extract_provider(model_card)
        }

        table.insert(filtered_models, model)

        ::continue::
    end

    table.sort(filtered_models, function(a, b)
        if a.provider == b.provider then
            return a.name < b.name
        else
            return a.provider < b.provider
        end
    end)

    response.success = true
    response.models = filtered_models
    response.count = #filtered_models
    response.total_before_filter = #all_models
    return response
end

return { handler = handler }